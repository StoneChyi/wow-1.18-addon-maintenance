-- ============================================================
-- 文件名: GoubayuHeal_MinimapButton.lua
-- 功能: 嵌入式小地图按钮库，为插件提供可拖拽的小地图按钮
--       支持自定义图标、点击事件、拖拽位置记忆
-- 版本: 1.0
-- ============================================================

local version = 1.0

if not MyMinimapButton or MyMinimapButton.Version < version then

    MyMinimapButton = {

        Version = version,

        -- 动态创建小地图按钮
        -- modName: 插件名（必须）
        -- modSettings: 存储按钮状态的 SavedVariables 表（可选）
        -- initSettings: 默认设置表（可选）
        Create = function(self, modName, modSettings, initSettings)
            if not modName or getglobal(modName .. "MinimapButton") then
                return
            end
            initSettings = initSettings or {}
            modSettings = modSettings or {}
            self.Buttons = self.Buttons or {}

            local frameName = modName .. "MinimapButton"
            local frame = CreateFrame("Button", frameName, Minimap)
            frame:SetWidth(31)
            frame:SetHeight(31)
            frame:SetFrameStrata("LOW")
            frame:SetToplevel(1)   -- 1.10.2 启用
            frame:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
            frame:SetPoint("TOPLEFT", Minimap, "TOPLEFT")

            -- 图标
            local icon = frame:CreateTexture(frameName .. "Icon", "BACKGROUND")
            icon:SetTexture(initSettings.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            icon:SetWidth(20)
            icon:SetHeight(20)
            icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -5)

            -- 边框覆盖层
            local overlay = frame:CreateTexture(frameName .. "Overlay", "OVERLAY")
            overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
            overlay:SetWidth(53)
            overlay:SetHeight(53)
            overlay:SetPoint("TOPLEFT", frame, "TOPLEFT")

            -- 注册点击事件
            frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            frame:SetScript("OnClick", self.OnClick)

            -- 鼠标悬停/拖动事件
            frame:SetScript("OnMouseDown", self.OnMouseDown)
            frame:SetScript("OnMouseUp", self.OnMouseUp)
            frame:SetScript("OnEnter", self.OnEnter)
            frame:SetScript("OnLeave", self.OnLeave)

            frame:RegisterForDrag("LeftButton")
            frame:SetScript("OnDragStart", self.OnDragStart)
            frame:SetScript("OnDragStop", self.OnDragStop)

            -- 存储配置
            frame.tooltipTitle = modName
            frame.leftClick = initSettings.left
            frame.rightClick = initSettings.right
            frame.tooltipText = initSettings.tooltip

            -- 首次使用：用 initSettings 填充默认值
            local firstUse = 1
            for i in modSettings do
                firstUse = nil
            end
            if firstUse then
                modSettings.drag = initSettings.drag or "CIRCLE"
                modSettings.enabled = initSettings.enabled or 1
                modSettings.position = initSettings.position or self:GetDefaultPosition()
                modSettings.locked = initSettings.locked or nil
            end
            frame.modSettings = modSettings

            table.insert(self.Buttons, modName)
            self:SetEnable(modName, modSettings.enabled)
        end,

        -- 启用/禁用按钮显示
        SetEnable = function(self, modName, value)
            local button = getglobal(modName .. "MinimapButton")
            if value == 0 then value = nil end
            if button then
                button.modSettings.enabled = (value and 1) or nil
                if value then
                    button:Show()
                    self:Move(modName, nil, 1)
                else
                    button:Hide()
                end
            end
        end,

        -- 移动按钮到指定角度位置
        Move = function(self, modName, newPosition, force)
            local button = getglobal(modName .. "MinimapButton")
            if button and (not button.modSettings.locked or force) then
                button.modSettings.position = newPosition or button.modSettings.position
                local xpos, ypos
                local angle = button.modSettings.position
                if button.modSettings.drag == "SQUARE" then
                    xpos = 110 * cos(angle)
                    ypos = 110 * sin(angle)
                    xpos = math.max(-82, math.min(xpos, 84))
                    ypos = math.max(-86, math.min(ypos, 82))
                else
                    xpos = 80 * cos(angle)
                    ypos = 80 * sin(angle)
                end
                button:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", 54 - xpos, ypos - 54)
            end
        end,

        -- ============================================================
        -- 内部函数（供事件回调使用）
        -- ============================================================

        -- 获取默认位置（避免重叠）
        GetDefaultPosition = function(self)
            local position, found = 0, 1
            while found do
                found = nil
                for i = 1, table.getn(self.Buttons) do
                    if getglobal(self.Buttons[i] .. "MinimapButton").modSettings.position == position then
                        position = position + 20
                        found = 1
                    end
                end
                found = (position > 340) and 1 or found
            end
            return position
        end,

        -- 鼠标按下图标缩小
        OnMouseDown = function()
            getglobal(this:GetName() .. "Icon"):SetTexCoord(0.1, 0.9, 0.1, 0.9)
        end,

        -- 鼠标释放图标恢复
        OnMouseUp = function()
            getglobal(this:GetName() .. "Icon"):SetTexCoord(0, 1, 0, 1)
        end,

        -- 鼠标进入显示提示（tooltipTitle/tooltipText 可能为 nil，直接 AddLine(nil) 会产生空行/空提示）
        OnEnter = function()
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
            if this.tooltipTitle then
                GameTooltip:AddLine(this.tooltipTitle)
            end
            if this.tooltipText then
                GameTooltip:AddLine(this.tooltipText, 0.8, 0.8, 0.8, 1)
            end
            GameTooltip:Show()
        end,

        -- 鼠标离开隐藏提示
        OnLeave = function()
            GameTooltip:Hide()
        end,

        -- 开始拖拽
        OnDragStart = function()
            MyMinimapButton:OnMouseDown()
            this:LockHighlight()
            this:SetScript("OnUpdate", MyMinimapButton.OnUpdate)
        end,

        -- 结束拖拽
        OnDragStop = function()
            this:SetScript("OnUpdate", nil)
            this:UnlockHighlight()
            MyMinimapButton:OnMouseUp()
        end,

        -- 拖拽过程中更新位置
        OnUpdate = function()
            local xpos, ypos = GetCursorPosition()
            local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom()
            -- 1.12 无 GetEffectiveScale，光标物理像素换算用 UIParent:GetScale()
            xpos = xmin - xpos / UIParent:GetScale() + 70
            ypos = ypos / UIParent:GetScale() - ymin - 70
            this.modSettings.position = math.deg(math.atan2(ypos, xpos))
            local modName = string.gsub(this:GetName() or "", "MinimapButton$", "")
            MyMinimapButton:Move(modName)
        end,

        -- 点击分发
        OnClick = function()
            if arg1 == "LeftButton" and this.leftClick then
                this.leftClick()
            elseif arg1 == "RightButton" and this.rightClick then
                this.rightClick()
            end
        end
    }

end