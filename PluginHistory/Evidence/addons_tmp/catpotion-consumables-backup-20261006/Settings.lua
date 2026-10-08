--[[
设置界面维护说明

界面采用 Cat2 风格的深色扁平组件，但所有控件都在本文件内创建，不依赖 Cat2 代码。
当前固定尺寸为 780x620；普通物品三列排列，武器强化和毒药两列并提供主手/副手开关。
药剂小窗的横/纵优先与每行或列数量在这里设置，具体排版由 Window.lua 计算。
右下角是跟随当前配置的只读宏框；默认配置显示 /catpotion，其他配置附加配置名。
原生热键由 Bindings.xml 注册，并固定执行默认配置。

多配置约定：主窗口只显示 activeProfileId；配置管理窗口负责新建、切换、删除和改名。
默认配置由 defaultProfileId 判断，显示金色 [默认]，不可删除或改名。管理窗口打开时必须
显示 mainWindowDim，关闭时恢复。两个只读宏框都必须通过 GetProfileCommand 生成文本。

普通药剂的宏调用开关仅由药剂小窗右键控制，状态保存在当前配置的 macroExcluded。
主设置界面只负责药剂勾选；取消勾选或全部清除时同时清除对应的宏排除标记。

武器强化和毒药不是普通复选项：weaponSlotButtons 的 main/off 独立写入当前配置的 weaponSlots，
“药剂全选”不能开启它们，“全部清除”则必须同时清空 weaponSlots。
]]

local addon = CatPotionAddon
-- 设置主界面显示版本；发布时可按 Cat2 的格式手动调整此日期字符串。
local DISPLAY_VERSION = "2026-10-01"
local window = nil
local itemChecks = {}
local weaponSlotButtons = {}
local lockCheck = nil
local minimizedCheck = nil
local messageCheck = nil
local displayCheck = nil
local combatHideCheck = nil
local horizontalButton = nil
local verticalButton = nil
local layoutLimitText = nil
local scaleSlider = nil
local scaleValue = nil
local warningSlider = nil
local warningValue = nil
local activeProfileText = nil
local profileManager = nil
local profileEntries = {}
local inputDialog = nil
local confirmDialog = nil
local mainWindowDim = nil
local mainMacroBox = nil
local mainMacroCommand = "/catpotion"

local function CreateText(parent, text, size, red, green, blue)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
    label:SetTextColor(red, green, blue)
    label:SetText(text)
    return label
end

local function CreateFlatButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(height)
    addon.ApplyFlatBackdrop(button, 0.08, 0.18, 0.27, 0.98)
    local label = CreateText(button, text, 11, 0.82, 0.9, 1)
    label:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.label = label
    button.selected = false
    button:SetScript("OnEnter", function()
        this:SetBackdropColor(0.12, 0.32, 0.46, 1)
        this:SetBackdropBorderColor(0.45, 0.82, 1, 1)
    end)
    button:SetScript("OnLeave", function()
        if this.selected then
            this:SetBackdropColor(0.12, 0.4, 0.58, 0.98)
        else
            this:SetBackdropColor(0.08, 0.18, 0.27, 0.98)
        end
        this:SetBackdropBorderColor(0.3, 0.4, 0.52, 0.9)
    end)
    return button
end

local function CreateCloseButton(parent)
    local button = CreateFlatButton(parent, "X", 24, 24)
    button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, -12)
    button:SetBackdropColor(0.35, 0.08, 0.08, 0.98)
    button:SetBackdropBorderColor(0.3, 0.4, 0.52, 0.9)
    button:SetScript("OnEnter", function()
        this:SetBackdropColor(0.55, 0.12, 0.12, 1)
        this:SetBackdropBorderColor(0.9, 0.35, 0.35, 1)
    end)
    button:SetScript("OnLeave", function()
        this:SetBackdropColor(0.35, 0.08, 0.08, 0.98)
        this:SetBackdropBorderColor(0.3, 0.4, 0.52, 0.9)
    end)
    button:SetScript("OnClick", function() parent:Hide() end)
    return button
end

local function SetFlatButtonSelected(button, selected)
    button.selected = selected
    if selected then
        button:SetBackdropColor(0.12, 0.4, 0.58, 0.98)
    else
        button:SetBackdropColor(0.08, 0.18, 0.27, 0.98)
    end
end

local function CreateCheck(parent, text, width, itemTexture)
    -- itemTexture 为空时用于顶部普通复选框；有纹理时用于三列物品项并启用较大字体。
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(24)
    local box = CreateFrame("Frame", nil, button)
    box:SetWidth(17)
    box:SetHeight(17)
    -- 物品项左侧预留红色冲突提示的位置；顶部普通复选框保持原布局。
    box:SetPoint("LEFT", button, "LEFT", itemTexture and 14 or 0, 0)
    addon.ApplyFlatBackdrop(box, 0.035, 0.055, 0.09, 1)
    local mark = box:CreateTexture(nil, "OVERLAY")
    mark:SetTexture("Interface\\Buttons\\WHITE8X8")
    mark:SetPoint("TOPLEFT", box, "TOPLEFT", 4, -4)
    mark:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -4, 4)
    mark:SetVertexColor(0.25, 0.75, 1, 1)
    button.mark = mark

    local labelAnchor = box
    local labelGap = 7
    local labelWidth = width - 25
    if itemTexture then
        local conflictWarning = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        conflictWarning:SetPoint("RIGHT", box, "LEFT", -2, 0)
        conflictWarning:SetWidth(10)
        conflictWarning:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
        conflictWarning:SetJustifyH("CENTER")
        conflictWarning:SetText("|cffff3030！|r")
        conflictWarning:Hide()
        button.conflictWarning = conflictWarning

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(18)
        icon:SetHeight(18)
        icon:SetPoint("LEFT", box, "RIGHT", 6, 0)
        icon:SetTexture(itemTexture)
        icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
        button.itemIcon = icon
        labelAnchor = icon
        labelGap = 5
        labelWidth = width - 60
    end

    local labelSize = itemTexture and 12 or 11
    local label = CreateText(button, text, labelSize, 0.76, 0.83, 0.92)
    label:SetPoint("LEFT", labelAnchor, "RIGHT", labelGap, 0)
    label:SetWidth(labelWidth)
    label:SetJustifyH("LEFT")
    button.label = label
    button:SetScript("OnEnter", function()
        this.label:SetTextColor(0.5, 0.82, 1)
    end)
    button:SetScript("OnLeave", function()
        this.label:SetTextColor(0.76, 0.83, 0.92)
    end)
    return button
end

local function SetCheckState(button, checked)
    if checked then button.mark:Show() else button.mark:Hide() end
end

local function CreateWeaponChoice(parent, item)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(346)
    frame:SetHeight(26)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("LEFT", frame, "LEFT", 0, 0)
    icon:SetTexture(addon.GetItemTexture(item))
    icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
    local itemText = item.label
    local detail = addon.ItemDetails[item.key]
    if detail then itemText = itemText .. "（" .. detail .. "）" end
    local label = CreateText(frame, itemText, 11, 0.76, 0.83, 0.92)
    label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    label:SetWidth(214)
    label:SetJustifyH("LEFT")
    local mainButton = CreateFlatButton(frame, "主手", 44, 22)
    mainButton:SetPoint("RIGHT", frame, "RIGHT", -50, 0)
    local offButton = CreateFlatButton(frame, "副手", 44, 22)
    offButton:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    local function ToggleSlot(slotKey)
        local selections = addon.GetWeaponSlotSelections()
        if type(selections[item.key]) ~= "table" then selections[item.key] = {} end
        selections[item.key][slotKey] = addon.ToBoolean(selections[item.key][slotKey]) and 0 or 1
        addon.RefreshSettings()
        addon.RefreshPotionWindow()
    end
    mainButton:SetScript("OnClick", function() ToggleSlot("main") end)
    offButton:SetScript("OnClick", function() ToggleSlot("off") end)
    weaponSlotButtons[item.key] = { main = mainButton, off = offButton }
    return frame
end

local function ValidateProfileName(value, ignoredProfileId)
    local length = string.len(value or "")
    if length < 2 or length > 36 then
        return false, "名称长度必须为 2-12 个汉字或字符。"
    end
    local database = addon.GetDatabase()
    local index, profileId, profile
    for index, profileId in ipairs(database.profileOrder) do
        profile = database.profiles[profileId]
        if profileId ~= ignoredProfileId and profile and profile.name == value then
            return false, "已经存在同名配置。"
        end
    end
    return true
end

local function GetProfileCommand(profileName, profileId)
    if addon.IsDefaultProfile(profileId) then
        return "/catpotion"
    end
    return "/catpotion " .. (profileName or "")
end

local function ShowInputDialog(titleText, initialText, ignoredProfileId, acceptText, callback)
    if not inputDialog then
        inputDialog = CreateFrame("Frame", "CatPotionProfileInputDialog", UIParent)
        inputDialog:SetWidth(380)
        inputDialog:SetHeight(162)
        inputDialog:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
        inputDialog:SetFrameStrata("FULLSCREEN_DIALOG")
        inputDialog:SetFrameLevel(140)
        inputDialog:EnableMouse(true)
        addon.ApplyFlatBackdrop(inputDialog, 0.04, 0.05, 0.08, 1)
        inputDialog.title = CreateText(inputDialog, "", 14, 1, 0.78, 0.16)
        inputDialog.title:SetPoint("TOPLEFT", inputDialog, "TOPLEFT", 18, -17)
        inputDialog.edit = CreateFrame("EditBox", nil, inputDialog)
        inputDialog.edit:SetWidth(340)
        inputDialog.edit:SetHeight(30)
        inputDialog.edit:SetPoint("TOPLEFT", inputDialog, "TOPLEFT", 18, -50)
        inputDialog.edit:SetAutoFocus(false)
        inputDialog.edit:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
        inputDialog.edit:SetTextColor(0.86, 0.92, 1)
        inputDialog.edit:SetTextInsets(8, 8, 0, 0)
        addon.ApplyFlatBackdrop(inputDialog.edit, 0.035, 0.055, 0.09, 1)
        inputDialog.errorText = CreateText(inputDialog, "", 10, 1, 0.35, 0.35)
        inputDialog.errorText:SetPoint("TOPLEFT", inputDialog, "TOPLEFT", 19, -86)
        inputDialog.accept = CreateFlatButton(inputDialog, "确定", 76, 26)
        inputDialog.accept:SetPoint("BOTTOMRIGHT", inputDialog, "BOTTOMRIGHT", -100, 14)
        local cancel = CreateFlatButton(inputDialog, "取消", 76, 26)
        cancel:SetPoint("BOTTOMRIGHT", inputDialog, "BOTTOMRIGHT", -18, 14)
        cancel:SetScript("OnClick", function() inputDialog:Hide() end)
        inputDialog.edit:SetScript("OnEscapePressed", function() inputDialog:Hide() end)
        inputDialog.accept:SetScript("OnClick", function()
            local value = inputDialog.edit:GetText() or ""
            local valid, reason = ValidateProfileName(value, inputDialog.ignoredProfileId)
            if not valid then
                inputDialog.errorText:SetText(reason)
                return
            end
            local accepted = inputDialog.callback
            inputDialog:Hide()
            if accepted then accepted(value) end
        end)
    end
    inputDialog.title:SetText(titleText)
    inputDialog.accept.label:SetText(acceptText or "确定")
    inputDialog.edit:SetText(initialText or "")
    inputDialog.errorText:SetText("")
    inputDialog.ignoredProfileId = ignoredProfileId
    inputDialog.callback = callback
    inputDialog:Show()
    inputDialog.edit:SetFocus()
    inputDialog.edit:HighlightText()
end

local function ShowConfirmDialog(message, callback)
    if not confirmDialog then
        confirmDialog = CreateFrame("Frame", "CatPotionProfileConfirmDialog", UIParent)
        confirmDialog:SetWidth(380)
        confirmDialog:SetHeight(150)
        confirmDialog:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
        confirmDialog:SetFrameStrata("FULLSCREEN_DIALOG")
        confirmDialog:SetFrameLevel(140)
        confirmDialog:EnableMouse(true)
        addon.ApplyFlatBackdrop(confirmDialog, 0.04, 0.05, 0.08, 1)
        confirmDialog.message = CreateText(confirmDialog, "", 12, 0.86, 0.9, 0.96)
        confirmDialog.message:SetPoint("TOPLEFT", confirmDialog, "TOPLEFT", 20, -24)
        confirmDialog.message:SetWidth(340)
        confirmDialog.message:SetJustifyH("LEFT")
        local accept = CreateFlatButton(confirmDialog, "删除", 76, 26)
        accept:SetPoint("BOTTOMRIGHT", confirmDialog, "BOTTOMRIGHT", -100, 14)
        accept:SetBackdropColor(0.35, 0.08, 0.08, 0.98)
        local cancel = CreateFlatButton(confirmDialog, "取消", 76, 26)
        cancel:SetPoint("BOTTOMRIGHT", confirmDialog, "BOTTOMRIGHT", -18, 14)
        cancel:SetScript("OnClick", function() confirmDialog:Hide() end)
        accept:SetScript("OnClick", function()
            local accepted = confirmDialog.callback
            confirmDialog:Hide()
            if accepted then accepted() end
        end)
    end
    confirmDialog.message:SetText(message)
    confirmDialog.callback = callback
    confirmDialog:Show()
end

local function CreateSlider(parent, title, minimum, maximum, step, x, y, inline)
    local label = CreateText(parent, title, 11, 0.76, 0.83, 0.92)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, inline and y - 3 or y)
    local valueText = CreateText(parent, "", 11, 0.5, 0.82, 1)
    if inline then
        valueText:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 240, y - 3)
    else
        valueText:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -x, y)
    end
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetOrientation("HORIZONTAL")
    slider:SetWidth(inline and 200 or parent:GetWidth() - x * 2)
    slider:SetHeight(16)
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", inline and x + 32 or x, inline and y or y - 20)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(step)
    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetTexture("Interface\\Buttons\\WHITE8X8")
    track:SetHeight(4)
    track:SetPoint("LEFT", slider, "LEFT", 0, 0)
    track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
    track:SetVertexColor(0.08, 0.12, 0.18, 1)
    slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    local thumb = slider:GetThumbTexture()
    thumb:SetWidth(10)
    thumb:SetHeight(18)
    thumb:SetVertexColor(0.25, 0.68, 0.95, 1)
    return slider, valueText
end

local function RefreshProfileManager()
    if not profileManager then return end
    local database = addon.GetDatabase()
    local index, profileId, profile, entry
    for index = 1, table.getn(profileEntries) do profileEntries[index]:Hide() end
    for index, profileId in ipairs(database.profileOrder) do
        profile = database.profiles[profileId]
        entry = profileEntries[index]
        if not entry then
            entry = CreateFrame("Button", nil, profileManager.listContent)
            entry:SetWidth(170)
            entry:SetHeight(29)
            addon.ApplyFlatBackdrop(entry, 0.06, 0.08, 0.12, 0.94)
            entry.text = CreateText(entry, "", 11, 0.78, 0.88, 0.96)
            entry.text:SetPoint("LEFT", entry, "LEFT", 9, 0)
            entry.text:SetWidth(108)
            entry.text:SetJustifyH("LEFT")
            entry.defaultTag = CreateText(entry, "[默认]", 10, 1, 0.72, 0.2)
            entry.defaultTag:SetPoint("RIGHT", entry, "RIGHT", -7, 0)
            entry.defaultTag:Hide()
            entry:SetScript("OnClick", function()
                if addon.SelectProfile(this.profileId) then
                    addon.RefreshSettings()
                    addon.RefreshPotionWindow()
                    RefreshProfileManager()
                end
            end)
            profileEntries[index] = entry
        end
        entry.profileId = profileId
        entry.text:SetText(profile and profile.name or "未命名配置")
        if addon.IsDefaultProfile(profileId) then entry.defaultTag:Show() else entry.defaultTag:Hide() end
        entry:ClearAllPoints()
        entry:SetPoint("TOPLEFT", profileManager.listContent, "TOPLEFT", 0, -(index - 1) * 32)
        if profileId == database.activeProfileId then
            entry:SetBackdropColor(0.1, 0.28, 0.42, 0.98)
            entry.text:SetTextColor(1, 0.84, 0.28)
        else
            entry:SetBackdropColor(0.06, 0.08, 0.12, 0.94)
            entry.text:SetTextColor(0.78, 0.88, 0.96)
        end
        entry:Show()
    end
    profileManager.listContent:SetHeight(math.max(profileManager.listViewportHeight, table.getn(database.profileOrder) * 32 - 3))
    profileManager.UpdateListScroll()
    local active = database.profiles[database.activeProfileId]
    profileManager.activeName:SetText(active and active.name or "")
    SetCheckState(displayCheck, addon.ToBoolean(active.windowVisible))
    SetCheckState(combatHideCheck, addon.ToBoolean(active.hideInCombat))
    SetCheckState(lockCheck, addon.ToBoolean(active.locked))
    SetCheckState(minimizedCheck, addon.ToBoolean(active.minimized))
    SetCheckState(messageCheck, addon.ToBoolean(active.showMessages))
    warningSlider:SetValue(active.warningMinutes)
    warningValue:SetText(active.warningMinutes)
    layoutLimitText:SetText(active.layoutLimit)
    SetFlatButtonSelected(horizontalButton, active.layout == "horizontal")
    SetFlatButtonSelected(verticalButton, active.layout == "vertical")
    scaleSlider:SetValue(active.scale)
    scaleValue:SetText(string.format("%.1f", active.scale))
    profileManager.countText:SetText("数量：" .. table.getn(database.profileOrder))
    local protected = addon.IsDefaultProfile(database.activeProfileId)
    profileManager.removeButton:SetAlpha(protected and 0.42 or 1)
    profileManager.renameButton:SetAlpha(protected and 0.42 or 1)
    if profileManager.UpdateCommandText then
        profileManager.UpdateCommandText(active and active.name or "", database.activeProfileId)
    end
end

local function ShowProfileManager()
    if not profileManager then
        profileManager = CreateFrame("Frame", "CatPotionProfileManager", UIParent)
        profileManager:SetWidth(500)
        profileManager:SetHeight(478)
        profileManager:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        profileManager:SetFrameStrata("FULLSCREEN_DIALOG")
        profileManager:SetFrameLevel(120)
        profileManager:SetMovable(true)
        profileManager:SetClampedToScreen(true)
        profileManager:EnableMouse(true)
        -- 配置管理自行接管 ESC；注册到 UISpecialFrames 会与主设置窗一起被关闭。
        profileManager:EnableKeyboard(true)
        profileManager:SetScript("OnKeyDown", function()
            if arg1 == "ESCAPE" then profileManager:Hide() end
        end)
        profileManager:RegisterForDrag("LeftButton")
        profileManager:SetScript("OnDragStart", function() profileManager:StartMoving() end)
        profileManager:SetScript("OnDragStop", function() profileManager:StopMovingOrSizing() end)
        profileManager:SetScript("OnHide", function()
            if mainWindowDim then mainWindowDim:Hide() end
        end)
        addon.ApplyFlatBackdrop(profileManager, 0.04, 0.05, 0.08, 0.99)
        local title = CreateText(profileManager, "药剂配置管理", 16, 1, 0.78, 0.16)
        title:SetPoint("TOPLEFT", profileManager, "TOPLEFT", 18, -17)
        CreateCloseButton(profileManager)

        -- 两侧面板共用高度；列表为标题和底部操作按钮预留相同边距。
        local panelHeight = 410
        local listViewportHeight = panelHeight - 86
        profileManager.listViewportHeight = listViewportHeight
        local list = CreateFrame("Frame", nil, profileManager)
        list:SetWidth(190)
        list:SetHeight(panelHeight)
        list:SetPoint("TOPLEFT", profileManager, "TOPLEFT", 16, -52)
        addon.ApplyFlatBackdrop(list, 0.06, 0.08, 0.12, 0.96)
        local listTitle = CreateText(list, "配置列表", 12, 0.5, 0.82, 1)
        listTitle:SetPoint("TOPLEFT", list, "TOPLEFT", 10, -18)
        local scroll = CreateFrame("ScrollFrame", nil, list)
        scroll:SetWidth(170)
        scroll:SetHeight(listViewportHeight)
        scroll:SetPoint("TOPLEFT", list, "TOPLEFT", 10, -36)
        scroll:EnableMouseWheel(true)
        profileManager.listContent = CreateFrame("Frame", nil, scroll)
        profileManager.listContent:SetWidth(170)
        profileManager.listContent:SetHeight(listViewportHeight)
        scroll:SetScrollChild(profileManager.listContent)

        local listSlider = CreateFrame("Slider", nil, list)
        listSlider:SetOrientation("VERTICAL")
        listSlider:SetWidth(8)
        listSlider:SetHeight(listViewportHeight)
        listSlider:SetPoint("TOPRIGHT", list, "TOPRIGHT", -10, -36)
        listSlider:SetMinMaxValues(0, 0)
        listSlider:SetValueStep(1)
        local track = listSlider:CreateTexture(nil, "BACKGROUND")
        track:SetTexture("Interface\\Buttons\\WHITE8X8")
        track:SetAllPoints(listSlider)
        track:SetVertexColor(0.08, 0.12, 0.18, 1)
        listSlider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
        local thumb = listSlider:GetThumbTexture()
        thumb:SetWidth(8)
        thumb:SetVertexColor(0.25, 0.68, 0.95, 1)
        listSlider:SetScript("OnValueChanged", function() scroll:SetVerticalScroll(arg1) end)
        listSlider:SetValue(0)
        listSlider:Hide()
        profileManager.UpdateListScroll = function()
            local contentHeight = profileManager.listContent:GetHeight()
            local maximum = math.max(0, contentHeight - scroll:GetHeight())
            local value = math.min(maximum, math.max(0, scroll:GetVerticalScroll()))
            local width = maximum > 0 and 154 or 170
            scroll:SetWidth(width)
            profileManager.listContent:SetWidth(width)
            local index, entry
            for index, entry in ipairs(profileEntries) do
                entry:SetWidth(width)
                entry.text:SetWidth(width - 62)
            end
            listSlider:SetMinMaxValues(0, maximum)
            thumb:SetHeight(math.max(20, scroll:GetHeight() * scroll:GetHeight() / contentHeight))
            listSlider:SetValue(value)
            scroll:SetVerticalScroll(value)
            if maximum > 0 then listSlider:Show() else listSlider:Hide() end
        end
        scroll:SetScript("OnMouseWheel", function()
            local minimum, maximum = listSlider:GetMinMaxValues()
            local value = listSlider:GetValue() - arg1 * 64
            if value < 0 then value = 0 end
            if value > maximum then value = maximum end
            listSlider:SetValue(value)
        end)

        local content = CreateFrame("Frame", nil, profileManager)
        content:SetWidth(264)
        content:SetHeight(panelHeight)
        content:SetPoint("TOPRIGHT", profileManager, "TOPRIGHT", -16, -52)
        addon.ApplyFlatBackdrop(content, 0.06, 0.08, 0.12, 0.96)
        local currentLabel = CreateText(content, "当前配置", 12, 0.72, 0.84, 0.96)
        currentLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -18)
        profileManager.activeName = CreateText(content, "", 14, 1, 0.82, 0.2)
        profileManager.activeName:SetPoint("LEFT", currentLabel, "RIGHT", 10, 0)
        profileManager.activeName:SetWidth(172)
        profileManager.activeName:SetJustifyH("LEFT")
        profileManager.countText = CreateText(list, "", 10, 0.5, 0.56, 0.64)
        profileManager.countText:SetPoint("TOPRIGHT", list, "TOPRIGHT", -10, -20)

        local create = CreateFlatButton(list, "新建", 52, 26)
        create:SetPoint("BOTTOMLEFT", list, "BOTTOMLEFT", 10, 16)
        create:SetScript("OnClick", function()
            ShowInputDialog("新建配置（空白）", "", nil, "创建", function(value)
                addon.CreateProfile(value)
                addon.RefreshSettings()
                addon.RefreshPotionWindow()
                RefreshProfileManager()
            end)
        end)
        local remove = CreateFlatButton(list, "删除", 52, 26)
        remove:SetPoint("LEFT", create, "RIGHT", 7, 0)
        remove:SetBackdropColor(0.35, 0.08, 0.08, 0.98)
        profileManager.removeButton = remove
        remove:SetScript("OnClick", function()
            local database = addon.GetDatabase()
            if addon.IsDefaultProfile(database.activeProfileId) then
                addon.Print("默认配置不可删除。", true)
                return
            end
            if table.getn(database.profileOrder) <= 1 then
                addon.Print("至少需要保留一个配置。", true)
                return
            end
            local profile = database.profiles[database.activeProfileId]
            if not profile then return end
            local deletingId = database.activeProfileId
            ShowConfirmDialog("确定删除配置「" .. profile.name .. "」吗？\n此操作无法撤销。", function()
                addon.DeleteProfile(deletingId)
                addon.RefreshSettings()
                addon.RefreshPotionWindow()
                RefreshProfileManager()
            end)
        end)
        local rename = CreateFlatButton(list, "重命名", 52, 26)
        rename:SetPoint("LEFT", remove, "RIGHT", 7, 0)
        profileManager.renameButton = rename
        rename:SetScript("OnClick", function()
            local database = addon.GetDatabase()
            if addon.IsDefaultProfile(database.activeProfileId) then
                addon.Print("默认配置不可重命名。", true)
                return
            end
            local profile = database.profiles[database.activeProfileId]
            if not profile then return end
            ShowInputDialog("重命名配置", profile.name, database.activeProfileId, "保存", function(value)
                addon.RenameProfile(database.activeProfileId, value)
                addon.RefreshSettings()
                RefreshProfileManager()
            end)
        end)

        scaleSlider, scaleValue = CreateSlider(content, "缩放", 0.5, 1.5, 0.1, 16, -226)
        scaleSlider:SetScript("OnValueChanged", function()
            local value = math.floor(arg1 * 10 + 0.5) / 10
            local database = addon.GetActiveProfile()
            database.scale = value
            scaleValue:SetText(string.format("%.1f", value))
            addon.RefreshPotionWindow()
        end)
        local limitLabel = CreateText(content, "每行或列项目数", 11, 0.76, 0.83, 0.92)
        limitLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -149)
        local decrease = CreateFlatButton(content, "-", 24, 22)
        decrease:SetPoint("TOPLEFT", content, "TOPLEFT", 126, -140)
        layoutLimitText = CreateText(content, "2", 12, 1, 0.82, 0.2)
        layoutLimitText:SetPoint("TOPLEFT", content, "TOPLEFT", 158, -147)
        layoutLimitText:SetWidth(20)
        layoutLimitText:SetJustifyH("CENTER")
        local increase = CreateFlatButton(content, "+", 24, 22)
        increase:SetPoint("TOPLEFT", content, "TOPLEFT", 186, -140)
        decrease:SetScript("OnClick", function()
            local database = addon.GetActiveProfile()
            database.layoutLimit = database.layoutLimit - 1
            if database.layoutLimit < 1 then database.layoutLimit = 1 end
            addon.RefreshSettings()
            addon.RefreshPotionWindow()
        end)
        increase:SetScript("OnClick", function()
            local database = addon.GetActiveProfile()
            database.layoutLimit = database.layoutLimit + 1
            if database.layoutLimit > 10 then database.layoutLimit = 10 end
            addon.RefreshSettings()
            addon.RefreshPotionWindow()
        end)
        local directionLabel = CreateText(content, "排列方向", 11, 0.76, 0.83, 0.92)
        directionLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -185)
        horizontalButton = CreateFlatButton(content, "横向优先", 72, 22)
        horizontalButton:SetPoint("TOPLEFT", content, "TOPLEFT", 79, -176)
        horizontalButton:SetScript("OnClick", function()
            local database = addon.GetActiveProfile()
            database.layout = "horizontal"
            addon.RefreshSettings()
            addon.RefreshPotionWindow()
        end)
        verticalButton = CreateFlatButton(content, "纵向优先", 72, 22)
        verticalButton:SetPoint("TOPLEFT", content, "TOPLEFT", 156, -176)
        verticalButton:SetScript("OnClick", function()
            local database = addon.GetActiveProfile()
            database.layout = "vertical"
            addon.RefreshSettings()
            addon.RefreshPotionWindow()
        end)

        lockCheck = CreateCheck(content, "锁定小窗位置", 120)
        lockCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -74)
        lockCheck:SetScript("OnClick", function()
            local database = addon.GetActiveProfile()
            database.locked = addon.ToBoolean(database.locked) and 0 or 1
            addon.RefreshSettings()
        end)
        minimizedCheck = CreateCheck(content, "最小化小窗", 120)
        minimizedCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -102)
        minimizedCheck:SetScript("OnClick", function()
            local profile = addon.GetActiveProfile()
            profile.minimized = addon.ToBoolean(profile.minimized) and 0 or 1
            addon.RefreshSettings()
            addon.RefreshPotionWindow()
        end)
        messageCheck = CreateCheck(content, "聊天栏提示", 104)
        messageCheck:SetPoint("LEFT", lockCheck, "RIGHT", 8, 0)
        messageCheck:SetScript("OnClick", function()
            local database = addon.GetActiveProfile()
            database.showMessages = addon.ToBoolean(database.showMessages) and 0 or 1
            addon.RefreshSettings()
        end)

        warningSlider, warningValue = CreateSlider(content, "剩余时间警告（分钟）", 1, 10, 1, 16, -282)
        warningSlider:SetScript("OnValueChanged", function()
            local value = math.floor(arg1 + 0.5)
            local database = addon.GetActiveProfile()
            database.warningMinutes = value
            warningValue:SetText(value)
            addon.RefreshPotionTimers()
        end)

        displayCheck = CreateCheck(content, "显示快捷小窗", 120)
        displayCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -46)
        displayCheck:SetScript("OnClick", function() addon.TogglePotionWindow() end)
        combatHideCheck = CreateCheck(content, "战斗中隐藏", 104)
        combatHideCheck:SetPoint("LEFT", displayCheck, "RIGHT", 8, 0)
        combatHideCheck:SetScript("OnClick", function()
            local profile = addon.GetActiveProfile()
            profile.hideInCombat = addon.ToBoolean(profile.hideInCombat) and 0 or 1
            addon.RefreshSettings()
            addon.RefreshPotionWindow()
        end)

        local commandLabel = CreateText(content, "宏命令（点击全选后 Ctrl+C 复制）", 10, 0.72, 0.84, 0.96)
        local commandBox = CreateFrame("EditBox", nil, content)
        commandBox:SetWidth(230)
        commandBox:SetHeight(27)
        commandBox:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 16, 16)
        commandLabel:SetPoint("BOTTOMLEFT", commandBox, "TOPLEFT", 0, 8)
        commandBox:SetAutoFocus(false)
        commandBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        commandBox:SetTextColor(0.68, 0.78, 0.88)
        commandBox:SetTextInsets(8, 8, 0, 0)
        commandBox:SetMaxLetters(64)
        addon.ApplyFlatBackdrop(commandBox, 0.04, 0.06, 0.1, 0.98)
        local commandValue = ""
        local commandUpdating = false
        profileManager.UpdateCommandText = function(profileName, profileId)
            commandValue = GetProfileCommand(profileName, profileId)
            commandUpdating = true
            commandBox:SetText(commandValue)
            commandUpdating = false
        end
        commandBox:SetScript("OnEditFocusGained", function() this:HighlightText() end)
        commandBox:SetScript("OnMouseUp", function()
            this:SetFocus()
            this:HighlightText()
        end)
        commandBox:SetScript("OnTextChanged", function()
            if not commandUpdating and this:GetText() ~= commandValue then
                commandUpdating = true
                this:SetText(commandValue)
                this:HighlightText()
                commandUpdating = false
            end
        end)
        commandBox:SetScript("OnEscapePressed", function()
            this:ClearFocus()
            this:HighlightText(0, 0)
            profileManager:Hide()
        end)
    end
    RefreshProfileManager()
    if mainWindowDim then mainWindowDim:Show() end
    profileManager:Show()
end

local function CreateShortcutToggleGlyph(button, owner)
    local glyphFrame = CreateFrame("Frame", nil, button)
    glyphFrame:SetWidth(14)
    glyphFrame:SetHeight(11)
    glyphFrame:SetPoint("CENTER", button, "CENTER", 0, 0)
    glyphFrame:SetFrameLevel(button:GetFrameLevel() + 1)

    local body = glyphFrame:CreateTexture(nil, "BACKGROUND")
    body:SetTexture("Interface\\Buttons\\WHITE8X8")
    body:SetPoint("TOPLEFT", glyphFrame, "TOPLEFT", 1, -1)
    body:SetPoint("BOTTOMRIGHT", glyphFrame, "BOTTOMRIGHT", -1, 1)

    local top = glyphFrame:CreateTexture(nil, "ARTWORK")
    top:SetTexture("Interface\\Buttons\\WHITE8X8")
    top:SetPoint("TOPLEFT", glyphFrame, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", glyphFrame, "TOPRIGHT", 0, 0)
    top:SetHeight(1)

    local bottom = glyphFrame:CreateTexture(nil, "ARTWORK")
    bottom:SetTexture("Interface\\Buttons\\WHITE8X8")
    bottom:SetPoint("BOTTOMLEFT", glyphFrame, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", glyphFrame, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(1)

    local left = glyphFrame:CreateTexture(nil, "ARTWORK")
    left:SetTexture("Interface\\Buttons\\WHITE8X8")
    left:SetPoint("TOPLEFT", glyphFrame, "TOPLEFT", 0, -1)
    left:SetPoint("BOTTOMLEFT", glyphFrame, "BOTTOMLEFT", 0, 1)
    left:SetWidth(1)

    local right = glyphFrame:CreateTexture(nil, "ARTWORK")
    right:SetTexture("Interface\\Buttons\\WHITE8X8")
    right:SetPoint("TOPRIGHT", glyphFrame, "TOPRIGHT", 0, -1)
    right:SetPoint("BOTTOMRIGHT", glyphFrame, "BOTTOMRIGHT", 0, 1)
    right:SetWidth(1)

    local header = glyphFrame:CreateTexture(nil, "OVERLAY")
    header:SetTexture("Interface\\Buttons\\WHITE8X8")
    header:SetPoint("TOPLEFT", glyphFrame, "TOPLEFT", 2, -3)
    header:SetPoint("TOPRIGHT", glyphFrame, "TOPRIGHT", -2, -3)
    header:SetHeight(1)

    owner.shortcutToggleGlyphFrame = glyphFrame
    owner.shortcutToggleGlyph = {
        body = body,
        top = top,
        bottom = bottom,
        left = left,
        right = right,
        header = header
    }
end


local shortcutToggleButton
local function SetShortcutGlyphColor(red, green, blue, alpha)
    if not shortcutToggleButton then return end
    local glyph = shortcutToggleButton.shortcutToggleGlyph
    local _, key
    for _, key in ipairs({ "top", "bottom", "left", "right" }) do
        glyph[key]:SetVertexColor(red, green, blue, 1)
    end
    glyph.header:SetVertexColor(red, green, blue, 0.9)
    glyph.body:SetVertexColor(red, green, blue, alpha)
end

function addon.RefreshShortcutToggle()
    if addon.ToBoolean(addon.GetActiveProfile().windowVisible) then
        SetShortcutGlyphColor(0.38, 0.82, 1, 0.34)
    else
        SetShortcutGlyphColor(0.42, 0.56, 0.68, 0.08)
    end
end

local function CreateShortcutToggle(parent, anchor)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(24)
    button:SetHeight(24)
    button:SetPoint("RIGHT", anchor, "LEFT", -10, 0)
    addon.ApplyFlatBackdrop(button, 0.08, 0.22, 0.34, 0.98)
    CreateShortcutToggleGlyph(button, button)
    shortcutToggleButton = button
    local function ResetGlyphPosition()
        button.shortcutToggleGlyphFrame:ClearAllPoints()
        button.shortcutToggleGlyphFrame:SetPoint("CENTER", button, "CENTER", 0, 0)
    end
    button:SetScript("OnEnter", function()
        button:SetBackdropColor(0.12, 0.4, 0.58, 1)
        button:SetBackdropBorderColor(0.45, 0.82, 1, 1)
        SetShortcutGlyphColor(1, 0.84, 0.28, 0.22)
        GameTooltip:SetOwner(button, "ANCHOR_TOP")
        GameTooltip:SetText(addon.ToBoolean(addon.GetActiveProfile().windowVisible) and "关闭快捷小窗" or "显示快捷小窗")
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        button:SetBackdropColor(0.08, 0.22, 0.34, 0.98)
        button:SetBackdropBorderColor(0.3, 0.4, 0.52, 0.9)
        ResetGlyphPosition()
        addon.RefreshShortcutToggle()
        GameTooltip:Hide()
    end)
    button:SetScript("OnMouseDown", function()
        button:SetBackdropColor(0.05, 0.14, 0.22, 1)
        button.shortcutToggleGlyphFrame:ClearAllPoints()
        button.shortcutToggleGlyphFrame:SetPoint("CENTER", button, "CENTER", 1, -1)
        SetShortcutGlyphColor(0.32, 0.58, 0.7, 0.2)
    end)
    button:SetScript("OnMouseUp", function()
        ResetGlyphPosition()
        button:SetBackdropColor(0.12, 0.4, 0.58, 1)
        SetShortcutGlyphColor(1, 0.84, 0.28, 0.22)
    end)
    button:SetScript("OnClick", function()
        addon.TogglePotionWindow()
        addon.RefreshShortcutToggle()
        GameTooltip:Hide()
    end)
    addon.RefreshShortcutToggle()
end

local function CreateWindow()
    if window then return end
    window = CreateFrame("Frame", "CatPotionSettings", UIParent)
    if type(UISpecialFrames) == "table" then
        table.insert(UISpecialFrames, "CatPotionSettings")
    end
    -- 调整窗口高度时，scrollFrame、content 与 scrollSlider 的高度必须同步增减。
    window:SetWidth(780)
    window:SetHeight(620)
    window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    window:SetFrameStrata("HIGH")
    window:SetFrameLevel(30)
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function() window:StartMoving() end)
    window:SetScript("OnDragStop", function() window:StopMovingOrSizing() end)
    window:SetScript("OnHide", function()
        if profileManager then profileManager:Hide() end
    end)
    addon.ApplyFlatBackdrop(window, 0.04, 0.05, 0.08, 0.99)

    -- 配置管理窗口打开时遮暗并拦截主设置窗口，保持管理操作的层级焦点。
    mainWindowDim = CreateFrame("Frame", nil, window)
    mainWindowDim:SetAllPoints(window)
    mainWindowDim:SetFrameLevel(window:GetFrameLevel() + 50)
    mainWindowDim:EnableMouse(true)
    addon.ApplyFlatBackdrop(mainWindowDim, 0, 0, 0, 0.62)
    mainWindowDim:Hide()

    local title = CreateText(window, "Cat - Potion  药剂管理", 16, 1, 0.78, 0.16)
    title:SetPoint("TOPLEFT", window, "TOPLEFT", 18, -17)
    local version = CreateText(window, "版本：" .. DISPLAY_VERSION, 10, 0.5, 0.56, 0.64)
    version:SetPoint("LEFT", title, "RIGHT", 10, -1)

    CreateCloseButton(window)

    local profileLabel = CreateText(window, "当前配置：", 11, 0.72, 0.84, 0.96)
    profileLabel:SetPoint("TOPRIGHT", window, "TOPRIGHT", -214, -21)
    CreateShortcutToggle(window, profileLabel)
    activeProfileText = CreateText(window, "", 11, 1, 0.82, 0.2)
    activeProfileText:SetPoint("LEFT", profileLabel, "RIGHT", 3, 0)
    activeProfileText:SetWidth(96)
    activeProfileText:SetJustifyH("LEFT")
    local manageProfiles = CreateFlatButton(window, "配置管理", 72, 24)
    manageProfiles:SetPoint("TOPRIGHT", window, "TOPRIGHT", -42, -12)
    manageProfiles:SetScript("OnClick", function() ShowProfileManager() end)

    local sectionTitle = CreateText(window, "选择显示在药剂窗口中的物品", 13, 0.5, 0.8, 1)
    sectionTitle:SetPoint("TOPLEFT", window, "TOPLEFT", 24, -58)
    local sectionLine = window:CreateTexture(nil, "ARTWORK")
    sectionLine:SetTexture("Interface\\Buttons\\WHITE8X8")
    sectionLine:SetHeight(1)
    sectionLine:SetPoint("LEFT", sectionTitle, "RIGHT", 10, 0)
    sectionLine:SetPoint("RIGHT", window, "RIGHT", -24, 0)
    sectionLine:SetVertexColor(0.18, 0.3, 0.42, 0.9)

    -- 设置列表保留滚动条；与不会滚动、自动扩展的小药剂窗是两套独立机制。
    local scrollFrame = CreateFrame("ScrollFrame", nil, window)
    scrollFrame:SetWidth(718)
    scrollFrame:SetHeight(474)
    scrollFrame:SetPoint("TOPLEFT", window, "TOPLEFT", 24, -82)
    scrollFrame:EnableMouseWheel(true)
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(716)
    content:SetHeight(474)
    scrollFrame:SetScrollChild(content)

    local scrollSlider = CreateFrame("Slider", nil, window)
    scrollSlider:SetOrientation("VERTICAL")
    scrollSlider:SetWidth(12)
    scrollSlider:SetHeight(474)
    scrollSlider:SetPoint("TOPRIGHT", window, "TOPRIGHT", -24, -82)
    scrollSlider:SetMinMaxValues(0, 0)
    scrollSlider:SetValueStep(1)
    local sliderTrack = scrollSlider:CreateTexture(nil, "BACKGROUND")
    sliderTrack:SetTexture("Interface\\Buttons\\WHITE8X8")
    sliderTrack:SetAllPoints(scrollSlider)
    sliderTrack:SetVertexColor(0.05, 0.06, 0.08, 0.95)
    scrollSlider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    local scrollThumb = scrollSlider:GetThumbTexture()
    scrollThumb:SetWidth(12)
    scrollThumb:SetHeight(36)
    scrollThumb:SetVertexColor(0.35, 0.65, 0.9, 0.95)
    scrollSlider:SetScript("OnValueChanged", function() scrollFrame:SetVerticalScroll(arg1) end)
    scrollFrame:SetScript("OnMouseWheel", function()
        local value = scrollSlider:GetValue() - arg1 * 70
        local minimum, maximum = scrollSlider:GetMinMaxValues()
        if value < minimum then value = minimum end
        if value > maximum then value = maximum end
        scrollSlider:SetValue(value)
    end)

    local y = 0
    local categoryIndex, category
    for categoryIndex, category in ipairs(addon.Categories) do
        local categoryLabel = CreateText(content, category, 13, 1, 0.7, 0.24)
        categoryLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 2, -y)
        y = y + 24
        local column = 0
        local itemIndex, item
        for itemIndex, item in ipairs(addon.SettingsOrderItems) do
            if item.category == category then
                if addon.IsWeaponCategory(category) then
                    local choice = CreateWeaponChoice(content, item)
                    choice:SetPoint("TOPLEFT", content, "TOPLEFT", 4 + column * 360, -y)
                    column = column + 1
                    if column >= 2 then
                        column = 0
                        y = y + 28
                    end
                else
                    local itemText = item.label
                    local detail = addon.ItemDetails[item.key]
                    if detail then
                        itemText = itemText .. " （" .. detail .. "）"
                    end
                    local check = CreateCheck(content, itemText, 226, addon.GetItemTexture(item))
                    local x = 4 + column * 240
                    check:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y)
                    check.itemKey = item.key
                    check:SetScript("OnClick", function()
                        local selected = addon.GetSelectedItems()
                        local excluded = addon.GetMacroExcludedItems()
                        local key = this.itemKey
                        if addon.ToBoolean(selected[key]) then
                            selected[key] = 0
                            excluded[key] = 0
                        else
                            selected[key] = 1
                        end
                        addon.RefreshSettings()
                        addon.RefreshPotionWindow()
                    end)
                    itemChecks[item.key] = check
                    column = column + 1
                    -- 每项高 24，纵向步进 25，仅保留 1 像素行间距以提高信息密度。
                    if column >= 3 then
                        column = 0
                        y = y + 25
                    end
                end
            end
        end
        if column > 0 then y = y + (addon.IsWeaponCategory(category) and 28 or 25) end
        y = y + 8
    end
    content:SetHeight(y)
    local maximum = y - scrollFrame:GetHeight()
    if maximum < 0 then maximum = 0 end
    scrollSlider:SetMinMaxValues(0, maximum)
    scrollSlider:SetValue(0)
    scrollSlider:Show()
    sliderTrack:Show()
    scrollThumb:Show()

    local selectAll = CreateFlatButton(window, "药剂全选", 92, 25)
    selectAll:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 24, 18)
    selectAll:SetScript("OnClick", function()
        local selected = addon.GetSelectedItems()
        local itemIndex, item
        for itemIndex, item in ipairs(addon.Items) do
            if not addon.IsWeaponCategory(item.category) then selected[item.key] = 1 end
        end
        addon.RefreshSettings()
        addon.RefreshPotionWindow()
    end)
    local clearAll = CreateFlatButton(window, "全部清除", 92, 25)
    clearAll:SetPoint("LEFT", selectAll, "RIGHT", 8, 0)
    clearAll:SetScript("OnClick", function()
        local profile = addon.GetActiveProfile()
        profile.selected = {}
        profile.macroExcluded = {}
        profile.weaponSlots = {}
        addon.RefreshSettings()
        addon.RefreshPotionWindow()
    end)
    local resetPosition = CreateFlatButton(window, "窗口归位", 92, 25)
    resetPosition:SetPoint("LEFT", clearAll, "RIGHT", 8, 0)
    resetPosition:SetScript("OnClick", function() addon.ResetPotionWindowPosition() end)
    local toggleWindow = CreateFlatButton(window, "显示 / 隐藏药剂窗口", 150, 25)
    toggleWindow:SetPoint("LEFT", resetPosition, "RIGHT", 8, 0)
    toggleWindow:SetScript("OnClick", function() addon.TogglePotionWindow() end)

    -- EditBox 保留选择与复制能力；OnTextChanged 会立即还原内容，从而实现只读。
    mainMacroBox = CreateFrame("EditBox", nil, window)
    mainMacroBox:SetWidth(168)
    mainMacroBox:SetHeight(25)
    mainMacroBox:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -24, 18)
    mainMacroBox:SetAutoFocus(false)
    mainMacroBox:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    mainMacroBox:SetTextColor(0.82, 0.9, 1)
    mainMacroBox:SetJustifyH("CENTER")
    mainMacroBox:SetTextInsets(7, 7, 0, 0)
    mainMacroBox:SetText(mainMacroCommand)
    addon.ApplyFlatBackdrop(mainMacroBox, 0.035, 0.055, 0.09, 1)
    mainMacroBox:SetScript("OnEditFocusGained", function()
        this:HighlightText()
    end)
    mainMacroBox:SetScript("OnMouseUp", function()
        this:SetFocus()
        this:HighlightText()
    end)
    mainMacroBox:SetScript("OnEscapePressed", function()
        this:ClearFocus()
    end)
    mainMacroBox:SetScript("OnTextChanged", function()
        if this:GetText() ~= mainMacroCommand then
            this:SetText(mainMacroCommand)
            this:HighlightText()
        end
    end)

    local macroLabel = CreateText(window, "当前配置补药宏", 11, 1, 0.7, 0.24)
    macroLabel:SetPoint("RIGHT", mainMacroBox, "LEFT", -10, 0)
    window:Hide()
end

function addon.RefreshSettings()
    CreateWindow()
    local database = addon.GetDatabase()
    local profile = addon.GetActiveProfile()
    local selected = addon.GetSelectedItems()
    local weaponSlots = addon.GetWeaponSlotSelections()
    activeProfileText:SetText(profile and profile.name or "")
    mainMacroCommand = GetProfileCommand(profile and profile.name or "", database.activeProfileId)
    mainMacroBox:SetText(mainMacroCommand)
    local key, check
    for key, check in pairs(itemChecks) do
        SetCheckState(check, addon.ToBoolean(selected[key]))
        if check.conflictWarning then
            if addon.HasSelectedItemConflict(key, selected) then
                check.conflictWarning:Show()
            else
                check.conflictWarning:Hide()
            end
        end
    end
    for key, buttons in pairs(weaponSlotButtons) do
        local slots = weaponSlots[key]
        SetFlatButtonSelected(buttons.main, type(slots) == "table" and addon.ToBoolean(slots.main))
        SetFlatButtonSelected(buttons.off, type(slots) == "table" and addon.ToBoolean(slots.off))
    end
    if profileManager then RefreshProfileManager() end
end

function addon.ShowSettings()
    addon.RefreshSettings()
    window:Show()
end

SLASH_CATPOTIONUI1 = "/cpui"
SlashCmdList["CATPOTIONUI"] = function()
    addon.ShowSettings()
end

function addon.ToggleSettings()
    CreateWindow()
    if window:IsVisible() then
        window:Hide()
    else
        addon.ShowSettings()
    end
end
