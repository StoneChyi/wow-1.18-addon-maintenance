--[[
药剂小窗维护说明

本文件只负责可点击小窗、排列和状态刷新；物品数据、背包/Buff/附魔缓存均来自 Core.lua。
小窗不使用滚动条，会根据已勾选项目、layout（横向/纵向优先）和 layoutLimit 自动改变尺寸。
每行状态的固定优先级是：效果倒计时 > 物品冷却 > 点击使用 > 背包无物品。

武器强化/毒药约定：设置中的 main/off 分别映射装备槽位 16/17；同一物品选择双手时会生成
两个 row，共享背包数量但各自携带 row.weaponSlot，并读取独立的临时附魔倒计时。
点击时必须把 row.weaponSlot 传给 Core.UseItem，不能退回让玩家再手动选择武器。

性能约定：事件只设置 pending 标记并短暂合并，真正扫描在 OnUpdate 中执行；平时每秒仅刷新
可见行的剩余时间；有可见毒药条目时每秒重扫一次双手附魔以更新次数。
进食期间每秒重读 Buff，结束后再每秒补扫两次，覆盖同名烹饪 Buff 延迟续期。
不要改成逐帧扫描背包、Buff 或武器提示。

2026-08-21 边缘拖动事故记录（WoW build 5875，实机复现 ERROR #132 / ACCESS_VIOLATION）：
1. CatPotionWindow 启用 SetClampedToScreen(true) 后，拖到屏幕边缘会使游戏客户端直接退出。
2. 禁用原生夹紧、在 OnDragStop 中读取 GetLeft/GetRight/GetTop/GetBottom 并立即 SetPoint
   做“软贴边”，实机同样会在到达边缘时直接退出；不要恢复这条方案。
3. 曾尝试把坐标换成 TOPLEFT/BOTTOMLEFT 后下一帧回拉，虽然未立即崩溃，但松手后窗口会
   弹回旧位置，用户已判定不可用。
4. 随后禁用原生夹紧并只保存 GetPoint，确认可以避开崩溃，但窗口会被拖出屏幕。

2026-08-23 参考长期运行的 ShaguDPS 改用其窗口生命周期：
1. SetClampedToScreen(true) 只在窗口创建时设置一次，刷新和重排期间不切换。
2. OnDragStop 只执行 StopMovingOrSizing、GetCenter 和比例坐标保存，不在这里 SetPoint。
3. ClearAllPoints/SetPoint 只在登录、进入世界或点击“窗口归位”后的加载阶段执行。
4. 继续禁止读取四边后立即回拉的“软贴边”方案；它与本方案不是同一种实现。
]]

-- 每个实例固定绑定 profileId；所有实例共用底部的事件/计时驱动和 Core 缓存。
local addon = CatPotionAddon
local inCombat = type(UnitAffectingCombat) == "function" and UnitAffectingCombat("player")
local function ShouldShowProfileWindow(profile)
    return addon.ToBoolean(profile.windowVisible)
        and not (inCombat and addon.ToBoolean(profile.hideInCombat))
end
local elapsed = 0
local wasEating = false
local eatingFollowupScans = 0
-- 多个游戏事件共用一次延迟刷新，避免喝药时 BAG_UPDATE、光环和冷却事件连续重扫。
local pendingBagRefresh = false
local pendingAuraRefresh = false
local pendingWeaponRefresh = false
local pendingStatusRefresh = false
local pendingRefreshDelay = 0
local pendingUseRefreshStage = 0
local pendingUseRefreshDelay = 0

-- 所有物品使用入口共用的延迟复扫。旧客户端刷新同名 Buff 时事件并不总是可靠，
-- 因此在使用请求后的0.2秒与约1秒主动重建一次效果缓存。
function addon.RequestPotionUseRefresh()
    addon.MarkAuraCacheDirty()
    addon.MarkWeaponEnchantCacheDirty()
    pendingUseRefreshStage = 1
    pendingUseRefreshDelay = 0.2
end

local function CreateProfileWindow(profileId)
    local database = addon.GetDatabase()
    local profile = database.profiles[profileId]
    local ui = {}
    local disposed = false
    local window = CreateFrame("Frame", nil, UIParent)
    local rows = {}
    local visibleRowCount = 0
    local visiblePoisonRowCount = 0
    -- 边缘拖动的历史和当前约束记录在文件头。所有结构性重排继续由独立驱动器合并，
    -- 在下一帧内原子执行“隐藏 -> 重排 -> 恢复”；拖动停止只保存中心点，不重新挂锚。
    local layoutRefreshRequested = false
    local layoutRefreshDriver = CreateFrame("Frame")
    local positionRefreshRequested = true
    local FALLBACK_ITEM_TEXTURE = "Interface\\Icons\\INV_Misc_QuestionMark"

    ui.window = window
    ui.rows = rows
    ui.profile = profile
    ui.layoutDriver = layoutRefreshDriver

    window:SetWidth(270)
    window:SetHeight(78)
    window:SetFrameStrata("MEDIUM")
    window:SetFrameLevel(10)
    window:SetMovable(true)
    -- 与 ShaguDPS 一致，只在创建阶段开启一次，后续刷新不反复切换夹紧状态。
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    addon.ApplyFlatBackdrop(window, 0.04, 0.05, 0.08, 0.55)
    layoutRefreshDriver:Hide()

    -- 避免把相同尺寸反复写回旧客户端的原生界面对象。
    local function SetFrameSizeIfChanged(frame, width, height)
        local currentWidth = frame:GetWidth()
        local currentHeight = frame:GetHeight()
        if not currentWidth or math.abs(currentWidth - width) > 0.01 then
            frame:SetWidth(width)
        end
        if not currentHeight or math.abs(currentHeight - height) > 0.01 then
            frame:SetHeight(height)
        end
    end

    local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- 标题显示所属配置，右侧提供配置切换、设置和关闭按钮。
    title:SetPoint("TOPLEFT", window, "TOPLEFT", 10, -8)
    title:SetHeight(22)
    title:SetJustifyH("LEFT")
    title:SetJustifyV("MIDDLE")
    title:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    title:SetTextColor(1, 0.78, 0.16)
    title:SetText(profile.name)

    local function CreateHeaderButton(text, width, red, green, blue)
        local button = CreateFrame("Button", nil, window)
        button:SetWidth(width)
        button:SetHeight(22)
        addon.ApplyFlatBackdrop(button, red, green, blue, 0.98)
        local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("CENTER", button, "CENTER", 0, 0)
        label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        label:SetTextColor(0.86, 0.92, 1)
        label:SetText(text)
        button:SetScript("OnEnter", function()
            this:SetBackdropBorderColor(0.45, 0.82, 1, 1)
        end)
        button:SetScript("OnLeave", function()
            this:SetBackdropBorderColor(0.3, 0.4, 0.52, 0.9)
        end)
        return button
    end

    local settingsButton = CreateHeaderButton("设置", 42, 0.08, 0.22, 0.34)
    ui.settingsButton = settingsButton
    settingsButton:SetPoint("TOPRIGHT", window, "TOPRIGHT", -36, -8)
    settingsButton:SetScript("OnClick", function()
        addon.SelectProfile(profileId)
        if addon.RefreshSettings then addon.RefreshSettings() end
        if addon.ToggleSettings then
            addon.ToggleSettings()
        end
    end)

    local closeButton = CreateHeaderButton("X", 22, 0.35, 0.08, 0.08)
    ui.closeButton = closeButton
    closeButton:SetPoint("TOPRIGHT", window, "TOPRIGHT", -10, -8)
    closeButton:SetScript("OnClick", function()
        database = addon.GetDatabase()
        addon.SetProfileWindowVisible(profileId, false)
    end)

    ui.profileMenuEntries = {}
    ui.profileMenuOffset = 0
    ui.profileMenuBlocker = CreateFrame("Frame", nil, window)
    ui.profileMenuBlocker:SetAllPoints(UIParent)
    ui.profileMenuBlocker:SetFrameStrata("DIALOG")
    ui.profileMenuBlocker:SetFrameLevel(30)
    ui.profileMenuBlocker:EnableMouse(true)
    ui.profileMenuBlocker:SetScript("OnMouseUp", function() ui.profileMenu:Hide() end)
    ui.profileMenuBlocker:Hide()
    ui.profileMenu = CreateFrame("Frame", nil, window)
    ui.profileMenu:SetWidth(210)
    ui.profileMenu:SetFrameStrata("DIALOG")
    ui.profileMenu:SetFrameLevel(40)
    ui.profileMenu:EnableMouse(true)
    ui.profileMenu:EnableMouseWheel(true)
    addon.ApplyFlatBackdrop(ui.profileMenu, 0.04, 0.05, 0.08, 0.98)
    ui.profileMenu:SetScript("OnShow", function() ui.profileMenuBlocker:Show() end)
    ui.profileMenu:SetScript("OnHide", function() ui.profileMenuBlocker:Hide() end)
    ui.profileMenu:Hide()

    -- 菜单按物理屏幕坐标计算，再换回自己的缩放坐标。
    -- 只调整弹出菜单，不在主窗拖动回调中读取四边或纠正主窗位置。
    local function GetProfileMenuViewport()
        local rootScale = tonumber((UIParent:GetEffectiveScale())) or tonumber((UIParent:GetScale())) or 1
        local rootWidth = tonumber((UIParent:GetWidth()))
        local rootHeight = tonumber((UIParent:GetHeight()))
        if not rootWidth or not rootHeight or rootWidth <= 0 or rootHeight <= 0 or rootScale <= 0 then return nil end
        return rootWidth * rootScale, rootHeight * rootScale, 8 * rootScale, rootScale
    end

    function ui.PositionProfileMenu()
        if not ui.profileSwitchButton then return end
        local centerX, centerY = ui.profileSwitchButton:GetCenter()
        local screenWidth, screenHeight, margin, rootScale = GetProfileMenuViewport()
        if not centerX or not centerY or not screenWidth then return end
        local windowScale = tonumber((window:GetEffectiveScale())) or (window:GetScale() or 1) * rootScale
        local buttonScale = tonumber((ui.profileSwitchButton:GetEffectiveScale())) or windowScale
        local menuScale = tonumber((ui.profileMenu:GetEffectiveScale())) or windowScale * (ui.profileMenu:GetScale() or 1)
        if buttonScale <= 0 or menuScale <= 0 then return end
        centerX, centerY = centerX * buttonScale, centerY * buttonScale
        local menuWidth = ui.profileMenu:GetWidth() * menuScale
        local menuHeight = ui.profileMenu:GetHeight() * menuScale
        local buttonHalfWidth = ui.profileSwitchButton:GetWidth() * buttonScale / 2
        local buttonHalfHeight = ui.profileSwitchButton:GetHeight() * buttonScale / 2
        local gap = 4 * menuScale
        local left = centerX + buttonHalfWidth - menuWidth
        local bottom = centerY - buttonHalfHeight - gap - menuHeight
        local above = centerY + buttonHalfHeight + gap
        if bottom < margin and above + menuHeight <= screenHeight - margin then bottom = above end
        left = math.max(margin, math.min(left, screenWidth - margin - menuWidth))
        bottom = math.max(margin, math.min(bottom, screenHeight - margin - menuHeight))
        ui.profileMenu:ClearAllPoints()
        ui.profileMenu:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left / menuScale, bottom / menuScale)
    end

    function ui.RefreshProfileMenu()
        local db = addon.GetDatabase()
        local total = table.getn(db.profileOrder)
        local pageSize = 8
        local screenWidth, screenHeight, margin, rootScale = GetProfileMenuViewport()
        if screenWidth then
            local windowScale = tonumber((window:GetEffectiveScale())) or (window:GetScale() or 1) * rootScale
            -- 常规屏幕继承小窗缩放；特别窄的屏幕只缩小菜单，确保整行文字和分页按钮可见。
            local menuScale = math.min(1, (screenWidth - margin * 2) / (210 * windowScale),
                (screenHeight - margin * 2) / (80 * windowScale))
            menuScale = math.max(0.01, menuScale)
            if ui.profileMenu:GetScale() ~= menuScale then ui.profileMenu:SetScale(menuScale) end
            local availableHeight = (screenHeight - margin * 2) / (windowScale * menuScale)
            pageSize = math.max(1, math.min(8, math.floor((availableHeight - 12) / 26)))
            if total > pageSize then
                pageSize = math.max(1, math.min(8, math.floor((availableHeight - 38) / 26)))
            end
        end
        ui.profileMenuPageSize = pageSize
        ui.profileMenuOffset = math.max(0, math.min(ui.profileMenuOffset, math.max(0, total - pageSize)))
        local count = math.min(total, pageSize)
        for index = 1, 8 do
            local entry = ui.profileMenuEntries[index]
            if index <= count then
                if not entry then
                    entry = CreateFrame("Button", nil, ui.profileMenu)
                    entry:SetWidth(198)
                    entry:SetHeight(24)
                    entry:SetPoint("TOPLEFT", ui.profileMenu, "TOPLEFT", 6, -6 - (index - 1) * 26)
                    addon.ApplyFlatBackdrop(entry, 0.08, 0.12, 0.18, 0.95)
                    entry.text = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    entry.text:SetPoint("LEFT", entry, "LEFT", 6, 0)
                    entry.text:SetWidth(186)
                    entry.text:SetJustifyH("LEFT")
                    entry.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
                    entry:SetScript("OnEnter", function() this:SetBackdropColor(0.1, 0.2, 0.29, 1) end)
                    entry:SetScript("OnLeave", function() this:SetBackdropColor(0.08, 0.12, 0.18, 0.95) end)
                    entry:SetScript("OnClick", function()
                        local targetId = this.targetProfileId
                        ui.profileMenu:Hide()
                        addon.SwitchPotionWindowProfile(profileId, targetId)
                    end)
                    ui.profileMenuEntries[index] = entry
                end
                local id = db.profileOrder[ui.profileMenuOffset + index]
                local target = db.profiles[id]
                entry.targetProfileId = id
                entry.text:SetText(target.name .. (id == profileId and "（当前）" or
                    (addon.ToBoolean(target.windowVisible) and "（已开启）" or "")))
                entry.text:SetTextColor(id == profileId and 1 or 0.86, 0.82, id == profileId and 0.2 or 0.92)
                entry:Show()
            elseif entry then
                entry:Hide()
            end
        end
        ui.profileMenu:SetHeight(count * 26 + 12 + (total > pageSize and 26 or 0))
        if ui.profileMenuPrevious then
            if total > pageSize then ui.profileMenuPrevious:Show(); ui.profileMenuNext:Show()
            else ui.profileMenuPrevious:Hide(); ui.profileMenuNext:Hide() end
        end
        ui.PositionProfileMenu()
    end

    ui.profileMenu:SetScript("OnMouseWheel", function()
        ui.profileMenuOffset = ui.profileMenuOffset - (arg1 or 0)
        ui.RefreshProfileMenu()
    end)
    for index = 1, 2 do
        local button = CreateFrame("Button", nil, ui.profileMenu)
        button:SetWidth(94)
        button:SetHeight(22)
        button:SetPoint("BOTTOMLEFT", ui.profileMenu, "BOTTOMLEFT", 6 + (index - 1) * 104, 6)
        addon.ApplyFlatBackdrop(button, 0.08, 0.22, 0.34, 0.98)
        local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER", button, "CENTER", 0, 0)
        text:SetText(index == 1 and "上一页" or "下一页")
        button.direction = index == 1 and -1 or 1
        button:SetScript("OnClick", function()
            ui.profileMenuOffset = ui.profileMenuOffset + this.direction * (ui.profileMenuPageSize or 8)
            ui.RefreshProfileMenu()
        end)
        if index == 1 then ui.profileMenuPrevious = button else ui.profileMenuNext = button end
    end

    ui.profileSwitchButton = CreateHeaderButton("", 22, 0.08, 0.22, 0.34)
    ui.profileSwitchButton:SetPoint("TOPRIGHT", window, "TOPRIGHT", -82, -8)
    ui.profileSwitchOffset = -82
    for index = 1, 5 do
        local strip = ui.profileSwitchButton:CreateTexture(nil, "OVERLAY")
        strip:SetTexture("Interface\\Buttons\\WHITE8X8")
        strip:SetVertexColor(0.86, 0.92, 1, 1)
        strip:SetWidth(11 - index * 2)
        strip:SetHeight(1)
        strip:SetPoint("CENTER", ui.profileSwitchButton, "CENTER", 0, 3 - index)
    end
    ui.profileMenu:SetPoint("TOPRIGHT", ui.profileSwitchButton, "BOTTOMRIGHT", 0, -4)
    ui.profileSwitchButton:SetScript("OnClick", function()
        if ui.profileMenu:IsVisible() then ui.profileMenu:Hide(); return end
        for _, other in pairs(addon.Windows) do other.profileMenu:Hide() end
        ui.profileMenuOffset = 0
        ui.RefreshProfileMenu()
        ui.profileMenu:Show()
    end)
    window:SetScript("OnHide", function() ui.profileMenu:Hide() end)

    local scrollFrame = CreateFrame("ScrollFrame", nil, window)
    scrollFrame:SetWidth(250)
    scrollFrame:SetHeight(38)
    scrollFrame:SetPoint("TOPLEFT", window, "TOPLEFT", 10, -38)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(250)
    content:SetHeight(38)
    scrollFrame:SetScrollChild(content)

    local emptyText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyText:SetPoint("TOP", content, "TOP", 0, -12)
    emptyText:SetWidth(236)
    emptyText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    emptyText:SetTextColor(0.55, 0.62, 0.72)
    emptyText:SetText("尚未选择药剂，请点击“设置”添加。")

    local function GetItemEffectTime(item, weaponSlot)
        -- 武器强化和毒药没有普通 Buff，必须读取主/副手临时附魔缓存。
        if addon.IsWeaponCategory(item.category) then
            return addon.GetWeaponEnchantTime(item.item, weaponSlot)
        end
        return addon.GetBuffTime(item.buff, item.buffIcon)
    end

    -- 仅改变颜色，不触碰尺寸或锚点；悬停和每秒刷新也必须保留禁宏红底。
    local function RefreshRowBackground(row)
        local rowProfile = profile
        row.macroExcluded = row.itemData and not addon.IsWeaponCategory(row.itemData.category)
            and addon.IsMacroExcluded(row.itemData, rowProfile)
        if row.macroExcluded then
            row:SetBackdropColor(0.32, 0.15, 0.11, row.hovered and 0.8 or 0.65)
            row:SetBackdropBorderColor(0.46, 0.25, 0.19, row.hovered and 0.8 or 0.5)
        elseif row.hovered then
            row:SetBackdropColor(0.1, 0.2, 0.29, 1)
            row:SetBackdropBorderColor(0.36, 0.64, 0.78, 0.75)
        else
            row:SetBackdropColor(0.065, 0.08, 0.115, 0.42)
            row:SetBackdropBorderColor(0.22, 0.28, 0.34, 0.38)
        end
    end

    local function ShowRowTooltip(row)
        if not row.itemData then return end
        local bag, slot, itemCount = addon.FindBagItem(row.itemData.item)
        local cooldown, cooldownKind, unavailable = addon.GetCooldownInfo(row.itemData.item)
        local buffTime = GetItemEffectTime(row.itemData, row.weaponSlot)
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        local tooltipName = row.itemData.item
        if row.weaponSlot then tooltipName = (row.weaponSlot == 16 and "主手 · " or "副手 · ") .. tooltipName end
        GameTooltip:AddLine(tooltipName, 1, 0.82, 0.2)
        if bag then
            GameTooltip:AddLine("背包数量：" .. itemCount, 0.85, 0.85, 0.85)
        else
            GameTooltip:AddLine("背包中没有该物品", 1, 0.3, 0.3)
        end
        if buffTime > 0 then
            GameTooltip:AddLine("剩余：" .. addon.SecondsToText(buffTime), 0.35, 0.9, 0.45)
        end
        if row.itemData.category == "毒药" then
            local charges = addon.GetWeaponEnchantCharges(row.itemData.item, row.weaponSlot)
            if charges ~= nil then
                GameTooltip:AddLine("毒药剩余次数：" .. charges, 1, 0.82, 0.2)
            end
        end
        if addon.ItemDetails[row.itemData.key] then
            GameTooltip:AddLine(addon.ItemDetails[row.itemData.key], 0.85, 0.85, 0.85)
        end
        if cooldown > 0 then
            local prefix = cooldownKind == "gcd" and "公共冷却：" or (cooldownKind == "shared" and "共享冷却：" or "冷却：")
            GameTooltip:AddLine(prefix .. addon.SecondsToText(cooldown), 1, 0.55, 0.2)
        end
        local item = row.itemData
        if item.cooldown and item.cooldown > 0 then GameTooltip:AddLine("自身冷却：" .. addon.SecondsToText(item.cooldown), 0.55, 0.7, 0.85) end
        if item.categoryCooldown and item.categoryCooldown > 0 then GameTooltip:AddLine("类别共享冷却：" .. addon.SecondsToText(item.categoryCooldown), 0.55, 0.7, 0.85) end
        if bag then GameTooltip:AddLine("左键：使用物品", 0.48, 0.55, 0.62) end
        if item.category == "常用炸药" then GameTooltip:AddLine("投掷类物品需手动选择地面位置", 0.55, 0.7, 0.85) end
        if item.manualOnly then
            GameTooltip:AddLine("仅手动使用，不参与一键补药", 0.55, 0.7, 0.85)
        elseif not addon.IsWeaponCategory(row.itemData.category) then
            GameTooltip:AddLine(row.macroExcluded and "宏调用：已关闭" or "宏调用：已开启", 1, 0.75, 0.3)
            GameTooltip:AddLine(row.macroExcluded and "右键：开启宏调用" or "右键：关闭宏调用", 0.55, 0.7, 0.85)
        else
            GameTooltip:AddLine(row.itemData.category .. "不参与一键补药", 0.55, 0.7, 0.85)
        end
        GameTooltip:Show()
    end

    local function CreateRow(index)
        local row = CreateFrame("Button", nil, content)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetWidth(135)
        row:SetHeight(40)
        addon.ApplyFlatBackdrop(row, 0.065, 0.08, 0.115, 0.42)
        row:SetBackdropBorderColor(0.22, 0.28, 0.34, 0.38)

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(34)
        icon:SetHeight(34)
        icon:SetPoint("LEFT", row, "LEFT", 3, 0)
        icon:SetTexture(FALLBACK_ITEM_TEXTURE)
        icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
        row.icon = icon

        local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        name:SetPoint("TOPLEFT", row, "TOPLEFT", 43, -5)
        name:SetWidth(86)
        name:SetHeight(16)
        name:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
        name:SetJustifyH("LEFT")
        name:SetTextColor(0.86, 0.91, 1)
        row.nameText = name

        local status = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        status:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 43, 5)
        status:SetWidth(86)
        status:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        status:SetJustifyH("LEFT")
        row.statusText = status

        local count = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
        count:SetFont("Fonts\\FRIZQT__.TTF", 11, "THICKOUTLINE")
        count:SetTextColor(1, 1, 1)
        row.countText = count

        -- 左上角为该手武器的毒药剩余次数，右下角继续显示背包物品数量。
        local charges = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        charges:SetPoint("TOPLEFT", icon, "TOPLEFT", 1, -1)
        charges:SetFont("Fonts\\FRIZQT__.TTF", 12, "THICKOUTLINE")
        charges:SetTextColor(1, 0.82, 0.2)
        charges:SetText("")
        row.chargeText = charges

        row:SetScript("OnEnter", function()
            this.hovered = true
            RefreshRowBackground(this)
            ShowRowTooltip(this)
        end)
        row:SetScript("OnLeave", function()
            this.hovered = false
            RefreshRowBackground(this)
            GameTooltip:Hide()
        end)
        row:SetScript("OnHide", function()
            if this.hovered then GameTooltip:Hide() end
            this.hovered = false
        end)
        row:SetScript("OnClick", function()
            if this.itemData then
                local clickedRow = this
                local item = clickedRow.itemData
                if arg1 == "RightButton" then
                    -- 右键只切换当前配置的宏标记，绝不发送使用请求。
                    if not addon.IsWeaponCategory(item.category) and not item.manualOnly then
                        local excluded = profile.macroExcluded
                        excluded[item.key] = addon.IsMacroExcluded(item, profile) and 0 or 1
                        ui.RefreshPotionTimers()
                        if clickedRow.hovered then ShowRowTooltip(clickedRow) end
                    end
                    return
                end
                addon.UseItem(item.item, item, clickedRow.weaponSlot, profileId)
                ui.RefreshPotionTimers()
            end
        end)
        rows[index] = row
        return row
    end

    local function PositionRow(row, index, layoutLimit)
        local minimized = addon.ToBoolean(profile.minimized)
        -- vertical：先向下填满一列；horizontal：先向右填满一行。
        if row.layoutIndex == index and row.layoutLimit == layoutLimit and row.layoutDirection == profile.layout and row.minimized == minimized then
            return
        end
        local line
        local column
        row:ClearAllPoints()
        if profile.layout == "vertical" then
            column = math.floor((index - 1) / layoutLimit)
            line = (index - 1) - column * layoutLimit
        else
            line = math.floor((index - 1) / layoutLimit)
            column = (index - 1) - line * layoutLimit
        end
        row.minimized = minimized
        row:SetWidth(minimized and 40 or 135)
        row:SetHeight(40)
        row.icon:ClearAllPoints()
        row.statusText:ClearAllPoints()
        if minimized then
            row.nameText:Hide()
            row.icon:SetPoint("TOP", row, "TOP", 0, -3)
            row.statusText:SetPoint("BOTTOM", row.icon, "BOTTOM", 0, 1)
            row.statusText:SetWidth(34)
            row.statusText:SetJustifyH("CENTER")
        else
            row.nameText:Show()
            row.icon:SetPoint("LEFT", row, "LEFT", 3, 0)
            row.statusText:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 43, 5)
            row.statusText:SetWidth(86)
            row.statusText:SetJustifyH("LEFT")
            row.statusText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        end
        row.fittedTimerText = nil
        row:SetPoint("TOPLEFT", content, "TOPLEFT", column * (minimized and 44 or 139), -line * 42)
        row.layoutIndex = index
        row.layoutLimit = layoutLimit
        row.layoutDirection = profile.layout
    end

    local function SetTimerText(row, text, minimized)
        row.statusText:SetText(text)
        if not minimized or row.fittedTimerText == text then return end
        -- 留出描边边距，从大字号逐步缩小，保证完整倒计时在图标内居中显示。
        local fontSize = 14
        local availableWidth = row.icon:GetWidth() - 2
        while fontSize > 1 do
            row.statusText:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
            local textWidth = row.statusText:GetStringWidth()
            if type(textWidth) ~= "number" or textWidth <= availableWidth then break end
            fontSize = fontSize - 1
        end
        row.fittedTimerText = text
    end

    local function RefreshRowStatus(row)
        -- 用户明确要求效果倒计时优先；即使物品仍在冷却，也不要覆盖正在生效的倒计时。
        local item = row.itemData
        RefreshRowBackground(row)
        local count = row.itemCount or 0
        local buffTime = GetItemEffectTime(item, row.weaponSlot)
        local minimized = addon.ToBoolean(profile.minimized)
        row.countText:Show()
        local charges
        if item.category == "毒药" then
            charges = addon.GetWeaponEnchantCharges(item.item, row.weaponSlot)
        end
        -- 行对象会跨配置复用；普通物品、附魔失效和无法读取时都清空旧次数。
        row.chargeText:SetText(charges ~= nil and tostring(charges) or "")
        if charges ~= nil and charges < 20 then
            row.chargeText:SetTextColor(1, 0.3, 0.3)
        else
            row.chargeText:SetTextColor(1, 0.82, 0.2)
        end
        if buffTime > 0 then
            local warning = item.macroWarningSeconds or ((profile.warningMinutes or 4) * 60)
            if buffTime < warning then
                row.statusText:SetTextColor(1, 0.3, 0.3)
            else
                row.statusText:SetTextColor(0.35, 0.9, 0.45)
            end
            SetTimerText(row, addon.SecondsToText(buffTime, minimized), minimized)
            if minimized then row.countText:Hide() end
            return
        end
        if row.weaponSlot and not GetInventoryItemLink("player", row.weaponSlot) then
            row.statusText:SetTextColor(1, 0.35, 0.35)
            row.statusText:SetText(minimized and "" or (row.weaponSlot == 16 and "主手无武器" or "副手无武器"))
            return
        end
        local cooldown, cooldownKind, unavailable = addon.GetCooldownInfo(item.item)
        if cooldown > 0 then
            row.statusText:SetTextColor(1, 0.55, 0.2)
            local prefix = cooldownKind == "gcd" and "公CD " or (cooldownKind == "shared" and "共享 " or "冷却 ")
            SetTimerText(row, (minimized and "" or prefix) .. addon.SecondsToText(cooldown, minimized), minimized)
            if minimized then row.countText:Hide() end
        elseif unavailable then
            row.statusText:SetTextColor(1, 0.55, 0.2)
            row.statusText:SetText(minimized and "" or "暂不可用")
        elseif count and count > 0 then
            row.statusText:SetTextColor(0.48, 0.55, 0.62)
            row.statusText:SetText(minimized and "" or "点击使用")
        else
            row.statusText:SetTextColor(0.48, 0.52, 0.58)
            row.statusText:SetText(minimized and "" or "背包无物品")
        end
    end

    local function RefreshRow(row)
        local item = row.itemData
        local bag, slot, count, texture = addon.FindBagItem(item.item)
        local bagTexture = texture
        if type(bagTexture) ~= "string" or bagTexture == "" then
            bagTexture = nil
        end
        local displayTexture = bagTexture or addon.GetItemTexture(item)
        row.itemCount = count or 0
        local displayName = item.label
        if row.weaponSlot then displayName = (row.weaponSlot == 16 and "主手·" or "副手·") .. displayName end
        row.nameText:SetText(displayName)
        if displayTexture then
            row.icon:SetTexture(displayTexture)
            row.icon:SetDesaturated(not bagTexture)
        else
            row.icon:SetTexture(FALLBACK_ITEM_TEXTURE)
            row.icon:SetDesaturated(true)
        end
        row:SetAlpha(bag and 1 or 0.62)
        if row.itemCount > 0 then
            row.countText:SetText(row.itemCount)
        else
            row.countText:SetText("")
        end
        RefreshRowStatus(row)
    end

    function ui.RefreshPotionTimers()
        database = addon.GetDatabase()
        local rowIndex
        for rowIndex = 1, visibleRowCount do
            if rows[rowIndex] and rows[rowIndex].itemData then
                local row = rows[rowIndex]
                RefreshRowStatus(row)
            end
        end
    end

    -- 背包变化只更新已有行的数据，不再顺带重设锚点或窗口尺寸。
    -- 结构变化只能由隐藏状态下的安全重排驱动器执行。
    function ui.RefreshPotionRowData()
        database = addon.GetDatabase()
        local rowIndex
        for rowIndex = 1, visibleRowCount do
            if rows[rowIndex] and rows[rowIndex].itemData then
                RefreshRow(rows[rowIndex])
            end
        end
    end

    function ui.RefreshPotionRows()
        database = addon.GetDatabase()
        local selected = profile.selected
        local weaponSlots = profile.weaponSlots
        local layoutLimit = profile.layoutLimit or 2
        local visibleCount = 0
        visiblePoisonRowCount = 0
        local itemIndex, item
        for itemIndex, item in ipairs(addon.SettingsOrderItems) do
            if not addon.IsWeaponCategory(item.category) and addon.IsItemAvailableForPlayer(item) and addon.ToBoolean(selected[item.key]) then
                visibleCount = visibleCount + 1
                local row = rows[visibleCount] or CreateRow(visibleCount)
                row.itemData = item
                row.weaponSlot = nil
                PositionRow(row, visibleCount, layoutLimit)
                row:Show()
                RefreshRow(row)
            elseif addon.IsWeaponCategory(item.category) then
                local slots = weaponSlots[item.key]
                local slotIndex, slot
                local chosenSlots = { 16, 17 }
                for slotIndex, slot in ipairs(chosenSlots) do
                    local slotKey = slot == 16 and "main" or "off"
                    if type(slots) == "table" and addon.ToBoolean(slots[slotKey]) then
                        if item.category == "毒药" then
                            -- 再次打开或切换配置后立即刷新，不能复用隐藏期间的旧次数。

                            visiblePoisonRowCount = visiblePoisonRowCount + 1
                        end
                        visibleCount = visibleCount + 1
                        local row = rows[visibleCount] or CreateRow(visibleCount)
                        row.itemData = item
                        row.weaponSlot = slot
                        PositionRow(row, visibleCount, layoutLimit)
                        row:Show()
                        RefreshRow(row)
                    end
                end
            end
        end
        local rowIndex
        for rowIndex = visibleCount + 1, table.getn(rows) do
            rows[rowIndex]:Hide()
        end
        visibleRowCount = visibleCount
        ui.poisonCount = visiblePoisonRowCount
        if visibleCount == 0 then
            emptyText:Show()
            SetFrameSizeIfChanged(content, 274, 38)
            SetFrameSizeIfChanged(scrollFrame, 274, 38)
            scrollFrame:SetVerticalScroll(0)
            title:SetWidth(174)
            title:SetText(profile.name)
            title:Show()
            SetFrameSizeIfChanged(window, 294, 84)
        else
            emptyText:Hide()
            -- 由可见数量推导真实行列数，小窗始终完整展示全部条目，不产生滚动区域。
            local actualColumns = layoutLimit
            local lineCount = 1
            if profile.layout == "vertical" then
                lineCount = layoutLimit
                if visibleCount < lineCount then lineCount = visibleCount end
                actualColumns = math.ceil(visibleCount / layoutLimit)
            else
                if visibleCount < actualColumns then actualColumns = visibleCount end
                lineCount = math.ceil(visibleCount / layoutLimit)
            end
            if actualColumns < 1 then actualColumns = 1 end
            if lineCount < 1 then lineCount = 1 end
            local minimized = addon.ToBoolean(profile.minimized)
            local contentWidth = actualColumns * (minimized and 40 or 135) + (actualColumns - 1) * 4
            local contentHeight = lineCount * 42 - 2
            -- 最窄图标窗也为配置切换与关闭按钮保留 68 像素。
            local windowWidth = math.max(minimized and 68 or 150, contentWidth + 20)
            title:SetWidth(math.max(20, windowWidth - 120))
            title:SetText(profile.name)
            title:Show()
            SetFrameSizeIfChanged(content, contentWidth, contentHeight)
            SetFrameSizeIfChanged(scrollFrame, contentWidth, contentHeight)
            scrollFrame:SetVerticalScroll(0)
            SetFrameSizeIfChanged(window, windowWidth, contentHeight + 46)
        end
        -- 标题栏按实际宽度分配空间，不能用药剂列数控制配置切换入口。
        -- 三个按钮需要 114 像素；窄图标窗省略设置，保留切换与关闭。
        local showSettings = window:GetWidth() >= 114
        local switchOffset = showSettings and -82 or -36
        if ui.profileSwitchOffset ~= switchOffset then
            ui.profileSwitchButton:ClearAllPoints()
            ui.profileSwitchButton:SetPoint("TOPRIGHT", window, "TOPRIGHT", switchOffset, -8)
            ui.profileSwitchOffset = switchOffset
        end
        if addon.ToBoolean(profile.minimized) then
            title:Hide()
        else
            local headerWidth = showSettings and 114 or 68
            title:SetWidth(math.max(20, window:GetWidth() - headerWidth - 10))
            title:Show()
        end
        if showSettings then settingsButton:Show() else settingsButton:Hide() end
        ui.profileSwitchButton:Show()
    end

    local function ApplyWindowPosition()
        database = addon.GetDatabase()
        window:ClearAllPoints()
        local position = profile.windowPosition
        local relativeX = type(position) == "table" and tonumber(position[1]) or nil
        local relativeY = type(position) == "table" and tonumber(position[2]) or nil
        local screenWidth = GetScreenWidth()
        local screenHeight = GetScreenHeight()
        if type(position) == "table" and position.rel == true and relativeX and relativeY
            and screenWidth and screenHeight and screenWidth > 0 and screenHeight > 0 then
            window:SetPoint("CENTER", UIParent, "BOTTOMLEFT", relativeX * screenWidth, relativeY * screenHeight)
        else
            -- 旧存档继续按原锚点恢复；第一次拖动后会写入上面的中心点比例格式。
            window:SetPoint(
                profile.windowPoint or "CENTER",
                UIParent,
                profile.windowRelativePoint or "CENTER",
                profile.windowX or 0,
                profile.windowY or 0
            )
        end
        positionRefreshRequested = false
    end

    local function ApplyWindowScale()
        database = addon.GetDatabase()
        local targetScale = profile.scale or 0.8
        local currentScale = window:GetScale()
        if not currentScale or math.abs(currentScale - targetScale) > 0.001 then
            window:SetScale(targetScale)
        end
    end

    -- 只登记请求，不在复选框、滑块或配置按钮的鼠标回调里直接修改可见窗口结构。
    function ui.RequestPotionWindowRefresh(refreshPosition)
        if refreshPosition then positionRefreshRequested = true end
        layoutRefreshRequested = true
        layoutRefreshDriver:Show()
    end

    -- 实例刷新只安排该配置的安全跨帧重排。
    function ui.RefreshPotionWindow()
        database = addon.GetDatabase()
        if not ShouldShowProfileWindow(profile) then
            window:Hide()
        end
        ui.RequestPotionWindowRefresh()
    end

    function ui.ResetPotionWindowPosition()
        database = addon.GetDatabase()
        profile.windowPosition = nil
        profile.windowPoint = "CENTER"
        profile.windowRelativePoint = "CENTER"
        profile.windowX = 0
        profile.windowY = 0
        positionRefreshRequested = true
        ui.RequestPotionWindowRefresh()
    end

    window:SetScript("OnDragStart", function()
        database = addon.GetDatabase()
        if not addon.ToBoolean(profile.locked) then
            window:StartMoving()
        end
    end)
    window:SetScript("OnDragStop", function()
        window:StopMovingOrSizing()
        database = addon.GetDatabase()
        -- 与 ShaguDPS 一致：松手只保存中心点比例，不在同一次回调中 ClearAllPoints/SetPoint。
        local centerX, centerY = window:GetCenter()
        local screenWidth = GetScreenWidth()
        local screenHeight = GetScreenHeight()
        if centerX and centerY and screenWidth and screenHeight and screenWidth > 0 and screenHeight > 0 then
            profile.windowPosition = { centerX / screenWidth, centerY / screenHeight, rel = true }
        end
    end)

    layoutRefreshDriver:SetScript("OnUpdate", function()
        if disposed or not layoutRefreshRequested then
            this:Hide()
            return
        end
        -- 鼠标回调只登记请求；下一帧的 OnUpdate 中临时隐藏并原子完成重排。
        -- 在本次界面渲染前已经恢复最终可见状态，因此不会产生空白帧闪烁。
        layoutRefreshRequested = false
        database = addon.GetDatabase()
        window:Hide()
        ApplyWindowScale()
        if positionRefreshRequested then
            ApplyWindowPosition()
        end
        ui.RefreshPotionRows()
        if ShouldShowProfileWindow(profile) then
            window:Show()
        end
        if not layoutRefreshRequested then
            this:Hide()
        end
    end)


    function ui.Dispose()
        disposed = true
        layoutRefreshDriver:Hide()
        window:Hide()
    end
    window:Hide()
    return ui
end

local windows = {}
addon.Windows = windows
local function HasVisibleWindow()
    local _, ui
    for _, ui in pairs(windows) do if ui.window:IsVisible() then return true end end
    return false
end
local function HasVisiblePoison()
    local _, ui
    for _, ui in pairs(windows) do
        if ui.window:IsVisible() and (ui.poisonCount or 0) > 0 then return true end
    end
    return false
end
function addon.RefreshPotionTimers()
    local _, ui
    for _, ui in pairs(windows) do if ui.window:IsVisible() then ui.RefreshPotionTimers() end end
end
function addon.RefreshPotionRowData()
    local _, ui
    for _, ui in pairs(windows) do if ui.window:IsVisible() then ui.RefreshPotionRowData() end end
end
function addon.RefreshPotionRows()
    addon.MarkWeaponEnchantCacheDirty()
    local _, ui
    for _, ui in pairs(windows) do ui.RefreshPotionRows() end
end
function addon.RefreshPotionWindow()
    addon.MarkWeaponEnchantCacheDirty()
    local db = addon.GetDatabase()
    local id, ui
    for id, ui in pairs(windows) do
        if db.profiles[id] ~= ui.profile then ui.Dispose(); windows[id] = nil end
    end
    local count = 0
    for _, id in ipairs(db.profileOrder) do
        local profile = db.profiles[id]
        if addon.ToBoolean(profile.windowVisible) then
            count = count + 1
            if count > 10 then profile.windowVisible = 0 end
        end
        if addon.ToBoolean(profile.windowVisible) and not windows[id] then
            if profile.windowX == nil and profile.windowPosition == nil then
                profile.windowX = (count - 1) * 24
                profile.windowY = -(count - 1) * 24
            end
            windows[id] = CreateProfileWindow(id)
        end
        if windows[id] then windows[id].RefreshPotionWindow() end
    end
    if addon.RefreshShortcutToggle then addon.RefreshShortcutToggle() end
end
addon.RequestPotionWindowRefresh = addon.RefreshPotionWindow
function addon.SetProfileWindowVisible(profileId, visible)
    local db = addon.GetDatabase()
    local profile = db.profiles[profileId]
    if not profile then return false end
    if visible and not addon.ToBoolean(profile.windowVisible) then
        local count = 0
        local _, other
        for _, other in pairs(db.profiles) do
            if addon.ToBoolean(other.windowVisible) then count = count + 1 end
        end
        if count >= 10 then
            addon.Print("最多同时打开 10 个快捷小窗，请先关闭其他小窗。", true)
            return false
        end
    end
    profile.windowVisible = visible and 1 or 0
    addon.RefreshPotionWindow()
    if addon.RefreshSettings then addon.RefreshSettings() end
    return true
end
function addon.TogglePotionWindow()
    local db = addon.GetDatabase()
    return addon.SetProfileWindowVisible(db.activeProfileId, not addon.ToBoolean(db.profiles[db.activeProfileId].windowVisible))
end

-- 保持实例与配置固定绑定：切换转移开关和屏幕位置，下一帧显示目标实例。
function addon.SwitchPotionWindowProfile(sourceId, targetId)
    local db = addon.GetDatabase()
    local source, target = db.profiles[sourceId], db.profiles[targetId]
    if not source or not target then return false end
    if sourceId == targetId then return false end
    -- 战斗中暂时隐藏的配置仍属于已开启，不能因此产生重复切换。
    if addon.ToBoolean(target.windowVisible) then
        addon.Print("配置「" .. target.name .. "」的小窗已经开启，未切换。", true, sourceId)
        return false
    end
    if not addon.ToBoolean(source.windowVisible) then return false end
    local sourceUI = windows[sourceId]
    local centerX, centerY
    if sourceUI then centerX, centerY = sourceUI.window:GetCenter() end
    local screenWidth, screenHeight = GetScreenWidth(), GetScreenHeight()
    if centerX and centerY and screenWidth and screenHeight and screenWidth > 0 and screenHeight > 0 then
        target.windowPosition = { centerX / screenWidth, centerY / screenHeight, rel = true }
    else
        target.windowPosition = source.windowPosition
        target.windowPoint, target.windowRelativePoint = source.windowPoint, source.windowRelativePoint
        target.windowX, target.windowY = source.windowX, source.windowY
    end
    source.windowVisible = 0
    target.windowVisible = 1
    addon.SelectProfile(targetId)
    if windows[targetId] then windows[targetId].RequestPotionWindowRefresh(true) end
    addon.RefreshPotionWindow()
    if addon.RefreshSettings then addon.RefreshSettings() end
    return true
end
function addon.ResetPotionWindowPosition()
    local db = addon.GetDatabase()
    local ui = windows[db.activeProfileId]
    if ui then ui.ResetPotionWindowPosition() else
        local profile = db.profiles[db.activeProfileId]
        profile.windowPosition = nil
        profile.windowPoint, profile.windowRelativePoint = "CENTER", "CENTER"
        profile.windowX, profile.windowY = 0, 0
    end
end
local refreshDriver = CreateFrame("Frame")
addon.RefreshDriver = refreshDriver
refreshDriver:SetScript("OnUpdate", function()
    if not HasVisibleWindow() then return end
    local refreshedThisFrame = false
    if pendingBagRefresh or pendingAuraRefresh or pendingWeaponRefresh or pendingStatusRefresh then
        pendingRefreshDelay = pendingRefreshDelay - arg1
        if pendingRefreshDelay <= 0 then
            if pendingBagRefresh then
                addon.RefreshBagCache()
            end
            if pendingAuraRefresh then
                addon.RefreshAuraCache()
            end
            if pendingWeaponRefresh then
                addon.RefreshWeaponEnchantCache()
            end
            if pendingBagRefresh then
                addon.RefreshPotionRowData()
            elseif pendingAuraRefresh or pendingWeaponRefresh or pendingStatusRefresh then
                addon.RefreshPotionTimers()
            end
            refreshedThisFrame = true
            pendingBagRefresh = false
            pendingAuraRefresh = false
            pendingWeaponRefresh = false
            pendingStatusRefresh = false
            pendingRefreshDelay = 0
        end
    end
    -- 鼠标点击后在 0.2 秒和约 1 秒各补扫一次，覆盖旧客户端物品消耗与 Buff 到达不同步。
    if pendingUseRefreshStage > 0 then
        pendingUseRefreshDelay = pendingUseRefreshDelay - arg1
        if pendingUseRefreshDelay <= 0 then
            addon.RefreshAuraCache()
            addon.RefreshWeaponEnchantCache()
            addon.RefreshPotionTimers()
            refreshedThisFrame = true
            if pendingUseRefreshStage == 1 then
                pendingUseRefreshStage = 2
                pendingUseRefreshDelay = 0.8
            else
                pendingUseRefreshStage = 0
                pendingUseRefreshDelay = 0
            end
        end
    end
    elapsed = elapsed + arg1
    if elapsed >= 1 then
        elapsed = elapsed - math.floor(elapsed)
        -- 先保留上一轮进食状态，即使进食光环已消失/到期，也要读取最后的效果。
        local eating = addon.PlayerIsEating()
        if eating or wasEating or eatingFollowupScans > 0 then
            addon.RefreshAuraCache()
            eating = addon.PlayerIsEating()
            if eating then
                eatingFollowupScans = 0
            elseif wasEating then
                eatingFollowupScans = 2
            elseif eatingFollowupScans > 0 then
                eatingFollowupScans = eatingFollowupScans - 1
            end
            addon.RefreshPotionTimers()
            refreshedThisFrame = true
        end
        wasEating = eating
        if HasVisiblePoison() then
            -- 次数消耗不一定触发装备事件；仅在有可见毒药条目时每秒合并扫描双手。
            addon.MarkWeaponEnchantCacheDirty()
            addon.RefreshPotionTimers()
        elseif not refreshedThisFrame and not pendingBagRefresh and not pendingAuraRefresh and not pendingWeaponRefresh then
            addon.RefreshPotionTimers()
        end
    end
end)

local eventFrame = CreateFrame("Frame")
addon.WindowEvents = eventFrame
-- 窗口隐藏时仍标脏缓存；再次打开时 FindBagItem/GetBuffTime 会按需重建。
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("PLAYER_AURAS_CHANGED")
eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("UI_ERROR_MESSAGE")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:SetScript("OnEvent", function()
    if event == "UI_ERROR_MESSAGE" then
        addon.CancelPendingItemUses()
        return
    end
    if event == "SPELLS_CHANGED" then
        addon.MarkSpellCacheDirty()
        return
    end
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        inCombat = type(UnitAffectingCombat) == "function" and UnitAffectingCombat("player")
        addon.MarkSpellCacheDirty()
        addon.MarkBagCacheDirty()
        addon.MarkAuraCacheDirty()
        addon.MarkWeaponEnchantCacheDirty()
        addon.RefreshPotionWindow()
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        inCombat = event == "PLAYER_REGEN_DISABLED"
        addon.RefreshPotionWindow()
    elseif event == "BAG_UPDATE" then
        addon.MarkBagCacheDirty()
        addon.ConfirmPendingItemUses()
        if HasVisibleWindow() then
            pendingBagRefresh = true
            pendingRefreshDelay = 0.12
        end
    elseif event == "PLAYER_AURAS_CHANGED" then
        addon.MarkAuraCacheDirty()
        if HasVisibleWindow() then
            pendingAuraRefresh = true
            pendingRefreshDelay = 0.08
        end
    elseif event == "UNIT_INVENTORY_CHANGED" and (not arg1 or arg1 == "player") then
        addon.MarkWeaponEnchantCacheDirty()
        if HasVisibleWindow() then
            pendingWeaponRefresh = true
            pendingRefreshDelay = 0.08
        end
    elseif event == "BAG_UPDATE_COOLDOWN" then
        addon.CaptureItemCooldowns()
        if HasVisibleWindow() then
            pendingStatusRefresh = true
            pendingRefreshDelay = 0.05
        end
    end
end)

addon.RefreshPotionWindow()
