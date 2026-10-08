



-- 安全获取方案数量
function getSchemeCount()
    if not AutoMarkerDB or not AutoMarkerDB.schemes then return 0 end
    local count = 0
    for _ in pairs(AutoMarkerDB.schemes) do
        count = count + 1
    end
    return count
end

-- 全局框架创建函数
function GetOrCreateFrame(frameName)
    local frame = _G[frameName]
    if not frame then
        frame = CreateFrame("Frame", frameName, UIParent)
        -- 设置基本框架属性
        frame:SetToplevel(true)
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:SetClampedToScreen(true)
        frame:SetFrameStrata("HIGH")
        frame:SetWidth(480)
        frame:SetHeight(580)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        frame:SetHitRectInsets(0, 0, 0, 0)
        frame:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" then
                frame:StartMoving()
            end
        end)
        frame:SetScript("OnMouseUp", function(_, button)
            frame:StopMovingOrSizing()
        end)
        tinsert(UISpecialFrames, frame:GetName())
        
        -- 设置背景和标题
        frame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        frame:SetBackdropColor(0, 0, 0, 0.8)
        
        local titleText = frame:CreateFontString("$parentTitleText", "ARTWORK", "GameFontNormalLarge")
        titleText:SetText("自动标记 目标配置")
        titleText:SetWidth(300)
        titleText:SetHeight(14)
        titleText:SetPoint("TOP", frame, "TOP", 60, -15)
        
        local closeButton = CreateFrame("Button", "$parentCloseButton", frame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
        
        -- 注册目标变更事件
        frame:RegisterEvent("PLAYER_TARGET_CHANGED")
        frame:SetScript("OnEvent", function(self, event, ...)
            if event == "PLAYER_TARGET_CHANGED" then
                UpdateTargetNameFromCurrentTarget()
            end
        end)
    end
    return frame
end

AutoMarkerTargetConfig = {}

-- 面板初始化时设置目标名称输入框和事件监听
local function initTargetNameFeature()
    -- 获取配置面板
    local configPanel = _G["AutoMarkerTargetConfigPanel"]
    if not configPanel then return end

    -- 面板显示时初始化目标名称
    configPanel:SetScript("OnShow", function()
        local targetEditBox = _G["AutoMarkerTargetNameEditBox"]
        if targetEditBox then
            local targetName = UnitName("target") or ""
            targetEditBox:SetText(targetName)
        end
    end)

    -- 注册目标切换事件监听
    -- 将事件框架存储为面板属性防止垃圾回收
    -- 创建事件框架时直接指定名称，避免使用SetName
    configPanel.eventFrame = CreateFrame("Frame", "AutoMarker_TargetEventFrame")
    configPanel.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    configPanel.eventFrame:SetScript("OnEvent", function()
        local targetEditBox = _G["AutoMarkerTargetNameEditBox"]
        if targetEditBox and configPanel:IsShown() then
            local targetName = UnitName("target") or ""
            targetEditBox:SetText(targetName)
        end
    end)
end

-- 在面板加载完成后执行初始化
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "AutoMarker" then
        initTargetNameFeature()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
-- 切换调试模式
function AutoMarkerTargetConfig_ToggleDebug()
    if not AutoMarkerDB.settings then
        AutoMarkerDB.settings = {
            enabled = true,
            debug = false
        }
    end
    
    AutoMarkerDB.settings.debug = not AutoMarkerDB.settings.debug
    print("[AutoMarker] 调试模式: " .. (AutoMarkerDB.settings.debug and "开启" or "关闭"))
end

-- 切换插件启用状态
function AutoMarkerTargetConfig_ToggleEnabled()
    if not AutoMarkerDB.settings then
        AutoMarkerDB.settings = {
            enabled = true,
            debug = false
        }
    end
    
    AutoMarkerDB.settings.enabled = not AutoMarkerDB.settings.enabled
    print("[AutoMarker] 插件状态: " .. (AutoMarkerDB.settings.enabled and "启用" or "禁用"))
end

-- 初始化配置表
-- 确保只有一组默认方案
if not AutoMarkerDB then
    AutoMarkerDB = {
        schemes = {
            [1] = { name = "默认方案", targets = {} }
        },
        selectedScheme = 1,  -- 初始化选择的方案ID
        settings = {
            enabled = true,   -- 默认启用插件
            debug = false     -- 默认关闭调试模式
        }
    }
elseif not AutoMarkerDB.schemes or getn(AutoMarkerDB.schemes) == 0 then
    AutoMarkerDB.schemes = {
        [1] = { name = "默认方案", targets = {} }
    }
    AutoMarkerDB.selectedScheme = 1  -- 确保选择的方案ID存在
end

-- 确保settings存在
if not AutoMarkerDB.settings then
    AutoMarkerDB.settings = {
        enabled = true,   -- 默认启用插件
        debug = false     -- 默认关闭调试模式
    }
end

-- 确保selectedScheme存在且有效
if not AutoMarkerDB.selectedScheme then
    AutoMarkerDB.selectedScheme = 1
    print("[AutoMarker] 初始化: 设置默认方案选择(ID=1)")
else
    print("[AutoMarker] 初始化: 加载已保存的方案选择(ID=" .. AutoMarkerDB.selectedScheme .. ")")
end

-- 初始化当前方案
AutoMarkerTargetConfig_currentScheme = AutoMarkerDB.selectedScheme

-- -- 目标变更处理函数
-- function AutoMarkerTargetConfig_ProcessNameMarking()
--     -- 检查插件是否启用
--     if not AutoMarkerDB or not AutoMarkerDB.settings or not AutoMarkerDB.settings.enabled then
--         return
--     end

--     -- 检查是否有目标
--     if not UnitExists("target") then
--         return
--     end

--     -- 检查目标是否为玩家或友方单位
--     if UnitIsPlayer("target") or UnitIsFriend("player", "target") then
--         return
--     end

--     -- 检查目标是否已死亡
--     if UnitIsDead("target") then
--         return
--     end

--     -- 获取目标名称
--     local targetName = UnitName("target")
--     if not targetName then
--         return
--     end

--     -- 遍历所有方案查找匹配的目标配置
--     if AutoMarkerDB.schemes then
--         for _, scheme in ipairs(AutoMarkerDB.schemes) do
--             if scheme.targets then
--                 for _, targetConfig in ipairs(scheme.targets) do
--                     if targetConfig.name and string.lower(targetConfig.name) == string.lower(targetName) then
--                         -- 检查标记ID
--                         if targetConfig.marks and table.getn(targetConfig.marks) > 0 then
--                             -- 使用第一个可用的标记
--                             local markID = targetConfig.marks[1]
--                             if markID and markID >= 1 and markID <= 8 then
--                                 -- 检查当前标记
--                                 local currentMark = GetRaidTargetIndex("target")
--                                 if currentMark ~= markID then
--                                     SetRaidTarget("target", markID)
--                                     if AutoMarkerDB.settings.debug then
--                                         print("[AutoMarker] 标记目标: " .. targetName .. " 使用标记ID: " .. markID)
--                                     end
--                                 end
--                                 return
--                             end
--                         end
--                     end
--                 end
--             end
--         end
--     end
-- end

-- UI创建函数
function CreateAutoMarkerTargetConfigUI()
    -- 检查窗口是否已存在，存在则切换显示状态
    
    local configPanel = _G["AutoMarkerTargetConfigPanel"]
    if configPanel then
        if configPanel:IsShown() then
            configPanel:Hide()
        else
            configPanel:Show()
        end
        return
    end


    local frame = GetOrCreateFrame("AutoMarkerTargetConfigPanel")

    -- 使用OnUpdate延迟检查确保编辑框已创建
    frame:SetScript("OnShow", function()
        local checkEditBox = function()
            local targetEditBox = _G["AutoMarkerTargetNameEditBox"]
            if targetEditBox then
                local targetName = UnitName("target") or ""
                targetEditBox:SetText(targetName)
                frame:SetScript("OnUpdate", nil) -- 完成后移除检查
            end
        end
        frame:SetScript("OnUpdate", checkEditBox)
    end)

    -- 注册目标切换事件监听
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:SetScript("OnEvent", function()
        local targetEditBox = _G["AutoMarkerTargetNameEditBox"]
        if targetEditBox and frame:IsShown() then
            local targetName = UnitName("target") or ""
            targetEditBox:SetText(targetName)
        end
    end)
    
    -- 如果UI元素已创建，则只切换显示状态
    if frame.uiCreated then
        frame:Show()
        AutoMarkerTargetConfig_RefreshTargetList()
        return
    end

    
    -- 背景纹理
    local portrait = frame:CreateTexture("$parentPortrait", "ARTWORK")
    portrait:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")
    portrait:SetWidth(60)
    portrait:SetHeight(60)
    portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -14)
    


    -- 方案管理区域
    local schemePanel = CreateFrame("Frame", "$parentSchemePanel", frame)
    schemePanel:SetWidth(460)
    schemePanel:SetHeight(40)
    schemePanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 70, -40)
    

    -- 方案下拉菜单
    local function InitDropdown()
        local schemeDropdown = _G["AutoMarkerSchemeDropdown"] or CreateFrame("Frame", "AutoMarkerSchemeDropdown", schemePanel, "UIDropDownMenuTemplate")
        if not schemeDropdown then return end
        
        -- 从持久化存储中获取选择的方案ID
        local selectedScheme = AutoMarkerDB.selectedScheme or 1
        UIDropDownMenu_ClearAll(schemeDropdown)
        
        -- 调试输出当前选择的方案
        -- print("[AutoMarker] 初始化下拉菜单 - 当前选择方案ID:", selectedScheme)
        
        for i, scheme in ipairs(AutoMarkerDB.schemes or {}) do
            local info = {} 
            info.text = scheme.name
            info.value = i
            info.func = (function(index)
                return function()
                    -- 更新UI显示
                    UIDropDownMenu_SetSelectedID(schemeDropdown, index)
                    -- 更新局部变量
                    AutoMarkerTargetConfig_currentScheme = index
                    -- 更新持久化存储
                    AutoMarkerDB.selectedScheme = index
                    -- 调试输出
                    -- 检查scheme是否存在
                    --   if scheme then
                    --       print("[AutoMarker] 选择方案 - 名称:", scheme.name or "未知", "ID:", index)
                    --       print("[AutoMarker] 方案数据:", scheme.name or "未知", "目标数量:", scheme.targets and table.getn(scheme.targets) or 0)
                    --   else
                    --       print("[AutoMarker] 警告: 无效方案数据，ID:", index)
                    --   end
                    AutoMarkerTargetConfig_RefreshTargetList()
                end
            end)(i)
            UIDropDownMenu_AddButton(info)
        end
        
        -- 设置初始选中项
        UIDropDownMenu_SetSelectedID(schemeDropdown, selectedScheme)
        -- 确保局部变量与持久化存储同步
        AutoMarkerTargetConfig_currentScheme = selectedScheme
    end

    -- 创建时直接指定名称，避免使用SetName
    local schemeDropdown = CreateFrame("Frame", "AutoMarkerSchemeDropdown", schemePanel, "UIDropDownMenuTemplate")
    if not schemeDropdown then return end
    local dropdownButton = _G[schemeDropdown:GetName() .. "Button"]
    if dropdownButton then
        dropdownButton:SetScript("OnClick", function()
            ToggleDropDownMenu(1, nil, schemeDropdown, "AutoMarkerSchemeDropdownButton", 0, 0)
        end)
    end
    schemeDropdown:SetPoint("LEFT", schemePanel, "LEFT", 0, -4)
    UIDropDownMenu_SetWidth(180, schemeDropdown)
    UIDropDownMenu_Initialize(schemeDropdown, InitDropdown)
    UIDropDownMenu_SetSelectedID(schemeDropdown, 1)
    
    schemeDropdown:Show()
    UIDropDownMenu_SetSelectedID(schemeDropdown, 1)
    
    -- 添加方案按钮
    local addSchemeBtn = CreateFrame("Button", "$parentAddSchemeBtn", schemePanel, "UIPanelButtonTemplate")
    addSchemeBtn:SetText("添加方案")
    addSchemeBtn:SetWidth(80)
    addSchemeBtn:SetHeight(22)
    addSchemeBtn:SetPoint("LEFT", schemePanel, "LEFT", 220, -4)
    -- Helper function to add new scheme
    local function addNewScheme(schemeName)
        if schemeName and schemeName ~= "" then
            -- Check for duplicate names
            for _, s in ipairs(AutoMarkerDB.schemes) do
                if s.name == schemeName then
                    UIErrorsFrame:AddMessage("方案名称已存在!", 1.0, 0.1, 0.1, 1.0)
                    return false
                end
            end
            table.insert(AutoMarkerDB.schemes, { name = schemeName, targets = {} })
            UIDropDownMenu_Initialize(schemeDropdown, InitDropdown)
            UIDropDownMenu_SetSelectedID(schemeDropdown, table.getn(AutoMarkerDB.schemes))
            return true
        end
        return false
    end
    
    addSchemeBtn:SetScript("OnClick", function()
        StaticPopup_Show("AUTOMARKER_ADD_SCHEME")
    end)
    
    -- Move popup definition outside function to prevent reinitialization
    if not StaticPopupDialogs["AUTOMARKER_ADD_SCHEME"] then
        StaticPopupDialogs["AUTOMARKER_ADD_SCHEME"] = {
        text = "输入新方案名称:",
        button1 = ACCEPT,
        button2 = CANCEL,
        hasEditBox = 1,
        maxLetters = 32,
        OnShow = function()
            this:SetScript("OnUpdate", function()
                local editBox = _G[this:GetName() .. "EditBox"]
                if editBox then
                    editBox:SetText(GetRealZoneText())
                    this:SetScript("OnUpdate", nil)
                end
            end)
        end,
        OnAccept = function(self)
            local editBox = _G["StaticPopup1EditBox"]
            local schemeName = editBox and editBox:GetText() or ""
            if schemeName and schemeName ~= "" then
                addNewScheme(schemeName)
            end
        end,
        --[[
            当编辑框按下回车时触发
            @param self - 编辑框对象
            @usage 输入方案名称后按回车会添加新方案并隐藏父级窗口
        ]]
        EditBoxOnEnterPressed = function(self)
            -- 初始化目标名称输入框
            local targetEditBox = _G["AutoMarkerTargetNameEditBox"]
            if targetEditBox then
                local targetName = UnitName("target") or ""
                targetEditBox:SetText(targetName)
            end

            -- 注册目标切换事件监听
            local eventFrame = CreateFrame("Frame")
            eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
            eventFrame:SetScript("OnEvent", function()
                local targetEditBox = _G["AutoMarkerTargetNameEditBox"]
                if targetEditBox then
                    local targetName = UnitName("target") or ""
                    targetEditBox:SetText(targetName)
                end
            end)

            local schemeName = self:GetText()
            if schemeName and schemeName ~= "" then
                addNewScheme(schemeName)
            end
            self:GetParent():Hide()
        end,
        timeout = 0,
        exclusive = 1,
        whileDead = 1,
        hideOnEscape = 1
    }
end

    -- 添加目标按钮
    local addTargetBtn = CreateFrame("Button", "AutoMarkerAddTargetBtn", targetNamePanel, "UIPanelButtonTemplate")
    addTargetBtn:SetText("添加目标")
    addTargetBtn:SetWidth(80)
    addTargetBtn:SetHeight(22)
    addTargetBtn:SetPoint("LEFT", targetEditBox, "RIGHT", 10, 0)
    addTargetBtn:SetScript("OnClick", handleAddTarget)

    -- 添加方案按钮
    addSchemeBtn:SetScript("OnClick", function()
        StaticPopup_Show("AUTOMARKER_ADD_SCHEME")
    end)
    
    -- Move popup definition outside function to prevent reinitialization
    if not StaticPopupDialogs["AUTOMARKER_ADD_SCHEME"] then
        StaticPopupDialogs["AUTOMARKER_ADD_SCHEME"] = {
        text = "输入新方案名称:",
        button1 = ACCEPT,
        button2 = CANCEL,
        hasEditBox = 1,
        maxLetters = 32,
        OnShow = function()
            this:SetScript("OnUpdate", function()
                local editBox = _G[this:GetName() .. "EditBox"]
                if editBox then
                    editBox:SetText(GetRealZoneText())
                    this:SetScript("OnUpdate", nil)
                end
            end)
        end,
        OnAccept = function(self)
            if not self then return end -- 防止self为nil
            local editBox = _G["StaticPopup1EditBox"]
            local schemeName = editBox and editBox:GetText() or ""
            if schemeName ~= "" then
                addNewScheme(schemeName)
            end
        end,
        --[[
            当编辑框按下回车时触发
            @param self - 编辑框对象
            @usage 输入方案名称后按回车会添加新方案并隐藏父级窗口
        ]]
        EditBoxOnEnterPressed = function(self)
              if not self then return end -- 防止self为nil
              local schemeName = self:GetText() or ""
            if schemeName ~= "" then
                addNewScheme(schemeName)
            end
            self:GetParent():Hide()
        end,
        timeout = 0,
        exclusive = 1,
        whileDead = 1,
        hideOnEscape = 1
    }
end
    -- 删除方案按钮
    local delSchemeBtn = CreateFrame("Button", "$parentDelSchemeBtn", schemePanel, "UIPanelButtonTemplate")
    delSchemeBtn:SetText("删除方案")
    delSchemeBtn:SetWidth(80)
    delSchemeBtn:SetHeight(22)
    delSchemeBtn:SetPoint("LEFT", schemePanel, "LEFT", 310, -4)
    -- Add confirmation dialog for scheme deletion
    if not StaticPopupDialogs["AUTOMARKER_DELETE_SCHEME"] then
        StaticPopupDialogs["AUTOMARKER_DELETE_SCHEME"] = {
            text = "确定要删除方案 '%s' 吗?",
            button1 = ACCEPT,
            button2 = CANCEL,
            OnAccept = function()
        local selected = UIDropDownMenu_GetSelectedID(schemeDropdown)
         if AutoMarkerDB.schemes[selected] and AutoMarkerDB.schemes[selected].name == "默认方案" then
            print("AutoMarker: 默认方案不能被删除")
            return
        end
      table.remove(AutoMarkerDB.schemes, selected)
        UIDropDownMenu_Initialize(schemeDropdown, InitDropdown)
        UIDropDownMenu_SetSelectedID(schemeDropdown, 1)
          
            end,
            timeout = 0,
            exclusive = 1,
            whileDead = 1,
            hideOnEscape = 1
        }
    end
    
    delSchemeBtn:SetScript("OnClick", function()
        local schemeDropdown = _G["AutoMarkerSchemeDropdown"]
        if not schemeDropdown then return end
    local selectedID = UIDropDownMenu_GetSelectedID(schemeDropdown)
        local schemeCount = table.getn(AutoMarkerDB.schemes)
        if selectedID and selectedID <= schemeCount then
            local schemeName = AutoMarkerDB.schemes[selectedID].name
            StaticPopup_Show("AUTOMARKER_DELETE_SCHEME", schemeName, nil, selectedID)
        end
        if selectedID and schemeCount > 1 then
            local schemeName = AutoMarkerDB.schemes[selectedID].name
            StaticPopup_Show("AUTOMARKER_DELETE_SCHEME", schemeName, nil, selectedID)
        elseif schemeCount <= 1 then
            UIErrorsFrame:AddMessage("至少保留一个方案!", 1.0, 0.1, 0.1, 1.0)
        end
    end)
    

    -- 添加范围设置
    local rangePanel = CreateFrame("Frame", "$parentRangePanel", frame)
    rangePanel:SetWidth(200)
    rangePanel:SetHeight(30)
    rangePanel:SetPoint("TOPLEFT", portrait, "BOTTOMLEFT", 0, -16)
    
    local rangeLabel = rangePanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    rangeLabel:SetText("范围:")
    rangeLabel:SetPoint("LEFT", portrait, "RIGHT", 16, 15)
    
    local rangeEditBox = CreateFrame("EditBox", "$parentRangeEditBox", rangePanel, "InputBoxTemplate")
    rangeEditBox:SetAutoFocus(false)
    rangeEditBox:SetWidth(50)
    rangeEditBox:SetHeight(20)
    rangeEditBox:SetPoint("LEFT", rangeLabel, "RIGHT", 5, 0)
    rangeEditBox:SetText("50")
    rangeEditBox:SetScript("OnEscapePressed", function()
        this:ClearFocus()
    end)
    _G["AutoMarkerRangeEditBox"] = rangeEditBox
    
    -- 执行按钮
    local executeBtn = CreateFrame("Button", "$parentExecuteBtn", frame)
    executeBtn:SetWidth(60)
    executeBtn:SetHeight(60)
    executeBtn:SetPoint("LEFT", portrait, "LEFT", 0, 0)
    
    local executeTex = executeBtn:CreateTexture(nil, "ARTWORK")
    executeTex:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")
    executeTex:SetAllPoints(executeBtn)
    executeBtn:SetNormalTexture(executeTex)
    local AutoMarker = CreateFrame("Frame","AutoMarkerFrame")
    -- 添加自动标记开关状态
    AutoMarker.isAutoMarking = AutoMarker.isAutoMarking or false
    AutoMarker.markTimer = AutoMarker.markTimer or nil

    executeBtn:SetScript("OnClick", function()
        -- 检查插件是否启用
        if not AutoMarkerDB or not AutoMarkerDB.settings or not AutoMarkerDB.settings.enabled then
         
            return
        end
        if not AutoMarker.isAutoMarking then
            -- 开始自动标记
            local range = tonumber(_G["AutoMarkerRangeEditBox"]:GetText()) or 50
            AutoMarker:StartAutoMarking(range)
            executeBtn:SetText("停止自动标记")
        else
            -- 停止自动标记
            AutoMarker:StopAutoMarking()
            executeBtn:SetText("开始自动标记")
        end
    end)
    function AutoMarker:StartAutoMarking(range)
    self.isAutoMarking = true
    print("AutoMarker: 开始自动标记 (范围: "..range..")")

    -- 使用GetTime()实现更精确的定时扫描
    local updateInterval = 1.0
    local lastExecutionTime = 0

    self.markTimer = CreateFrame("Frame")
    self.markTimer:SetScript("OnUpdate", function(frame)
        local currentTime = GetTime()
        if currentTime - lastExecutionTime >= updateInterval then
            self:PerformMarking(range)
            lastExecutionTime = currentTime
        end
    end)
    end

    function AutoMarker:StopAutoMarking()
    self.isAutoMarking = false
    if self.markTimer then
        self.markTimer:SetScript("OnUpdate", nil)
        self.markTimer = nil
    end
    print("AutoMarker: 停止自动标记")
    end

    function AutoMarker:PerformMarking(range)
        local selectedSchemeIndex = AutoMarkerDB.selectedScheme or 1
        local currentScheme = AutoMarkerDB.schemes[selectedSchemeIndex]
        if not currentScheme or not currentScheme.targets then
            print("AutoMarker: 未选择方案或方案无目标")
            return
        end

        local assignedMarks = {}
        local unitList = {}

        -- 检查是否启用调试模式
        local debugMode = AutoMarkerDB.settings and AutoMarkerDB.settings.debug or false

        for guid, cachedName in pairs(AutoMarkerDB.unitCache) do
            -- 确保guid是有效的单位ID
            if UnitExists(guid) and not UnitIsDead(guid) then
                -- 使用用户确认的1.12版本距离计算API
                local distance = UnitXP and UnitXP("distanceBetween", "player", guid) or 999
            
                if distance and distance <= range then
                    local unitName = UnitName(guid)
                
                    if debugMode then
                        DEFAULT_CHAT_FRAME:AddMessage("[AutoMarker] 调试: 检查单位 " .. tostring(unitName) .. " (距离: " .. tostring(distance) .. ")")
                    end
                
                    -- 匹配目标类型和优先级
                    local targetType, priority = nil, -1
                
                    for i, t in ipairs(currentScheme.targets) do
                        if t and t.name and unitName and string.find(string.lower(unitName), string.lower(t.name)) then
                            if debugMode then
                                DEFAULT_CHAT_FRAME:AddMessage("[AutoMarker] 调试: 匹配到目标配置 - " .. t.name)
                            end
                        
                            if i > priority then
                                targetType = t
                                priority = i
                            end
                        end
                    end

                    if targetType then
                        -- 确保marks字段存在
                        if not targetType.marks then
                            if debugMode then
                                DEFAULT_CHAT_FRAME:AddMessage("[AutoMarker] 警告: 目标配置缺少marks字段")
                            end
                            -- 尝试使用单个mark字段
                            if targetType.mark then
                                targetType.marks = {tonumber(targetType.mark)}
                            else
                                targetType.marks = {}
                            end
                        end
                    
                        table.insert(unitList, {
                            guid = guid,
                            name = unitName,
                            targetType = targetType,
                            priority = priority,
                            distance = distance
                        })
                    end
                else
                    -- 超出范围或死亡，清除标记
                    SetRaidTarget(guid, 0)
                end
            end
        end

        -- 按优先级和距离排序
        table.sort(unitList, function(a, b)
            if a.priority ~= b.priority then
                return a.priority < b.priority
            end
            return a.distance < b.distance
        end)

        -- 分配标记
        for _, unit in ipairs(unitList) do
            -- 确保使用正确的guid作为unitId
            local guid = unit.guid
        
            if guid and UnitExists(guid) then
                local currentMark = GetRaidTargetIndex(guid)
            
                -- 检查当前标记是否在目标配置的marks列表中
                local isInMarks = false
                if currentMark and currentMark ~= 0 and unit.targetType.marks then
                    for _, mid in ipairs(unit.targetType.marks) do
                        if mid == currentMark then
                            isInMarks = true
                            assignedMarks[mid] = guid
                            break
                        end
                    end
                end
            
                -- 如果当前标记不在marks列表中，重新分配标记
                if not isInMarks then
                    -- 清除当前标记
                    if currentMark and currentMark ~= 0 then
                        SetRaidTarget(guid, 0)
                    end
                
                    -- 尝试分配新标记
                    if unit.targetType.marks then
                        local marks = unit.targetType.marks
                        for i = table.getn(marks), 1, -1 do
                            local markId = marks[i]
                            if not assignedMarks[markId] then
                                if GetNumRaidMembers() ~= 0 or GetNumPartyMembers() ~= 0 then SetRaidTarget(guid, markId) else SetRaidTarget(guid, markId,1) end
                                if debugMode then
                                    DEFAULT_CHAT_FRAME:AddMessage("[AutoMarker] 标记: " .. unit.name .. " 使用标记 " .. markId)
                                end
                                assignedMarks[markId] = guid
                                break
                            else
                                -- 检查是否应该覆盖现有标记
                                local occupiedGuid = assignedMarks[markId]
                                local occupiedUnit = nil
                                for _, u in ipairs(unitList) do
                                    if u.guid == occupiedGuid then 
                                        occupiedUnit = u
                                        break
                                    end
                                end
                            
                                if not occupiedUnit or unit.priority < occupiedUnit.priority then
                                    if occupiedUnit and UnitExists(occupiedGuid) then
                                        SetRaidTarget(occupiedGuid, 0)
                                    end
                                    if GetNumRaidMembers() ~= 0 or GetNumPartyMembers() ~= 0 then SetRaidTarget(guid, markId) else SetRaidTarget(guid, markId,1) end
                                    if debugMode then
                                        DEFAULT_CHAT_FRAME:AddMessage("[AutoMarker] 标记: " .. unit.name .. " 使用标记 " .. markId .. " (覆盖)")
                                    end
                                    assignedMarks[markId] = guid
                                    break
                                end
                            end
                        end
                    end
                end
            elseif debugMode then
                DEFAULT_CHAT_FRAME:AddMessage("[AutoMarker] 警告: 单位不存在 - " .. tostring(guid))
            end
        end

        -- 死亡监听
        local eventFrame = _G.AutoMarkerMarkEventFrame or CreateFrame("Frame", "AutoMarkerMarkEventFrame")
        eventFrame:RegisterEvent("UNIT_HEALTH")
        eventFrame:SetScript("OnEvent", function(self, event, unitId)
            -- 确保unitId是有效的字符串
            if type(unitId) == "string" and UnitExists(unitId) and UnitIsDead(unitId) == 1 then
                local markId = GetRaidTargetIndex(unitId)
                if markId and markId ~= 0 then
                    SetRaidTarget(unitId, 0)
                    for m, g in pairs(assignedMarks) do
                        if "unit:"..g == unitId then
                            assignedMarks[m] = nil
                            break
                        end
                    end
                end
            end
        end)
    end

    -- 目标列表滚动区域
    local targetScrollFrame = CreateFrame("ScrollFrame", "$parentTargetScrollFrame", frame, "UIPanelScrollFrameTemplate")
    targetScrollFrame:SetWidth(472)
    targetScrollFrame:SetHeight(404)  -- 14行 × 24像素/行 = 336像素
    targetScrollFrame:SetPoint("LEFT", frame, "LEFT", 4, 4)
    
    -- 滚动背景
    local scrollBackground = targetScrollFrame:CreateTexture(nil, "BACKGROUND")
    scrollBackground:SetTexture(0, 0, 0, 0.5)
    scrollBackground:SetAllPoints(targetScrollFrame)
    
    -- 滚动内容区域
    local scrollChild = CreateFrame("Frame", "$parentScrollChild", targetScrollFrame)
    scrollChild:SetWidth(440)
    targetScrollFrame:SetScrollChild(scrollChild)
    
    -- 滚动条设置
    local scrollBar = _G[targetScrollFrame:GetName() .. "ScrollBar"]
    scrollBar:SetPoint("TOPLEFT", targetScrollFrame, "TOPRIGHT", -16, -16)
    scrollBar:SetPoint("BOTTOMLEFT", targetScrollFrame, "BOTTOMRIGHT", -16, 16)
    
    -- 标记图标容器
    local markContainer = CreateFrame("Frame", "$parentMarkContainer", frame)
    markContainer:SetWidth(240)
    markContainer:SetHeight(40)
    markContainer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 60)
    
  
    -- 全局目标列表刷新函数
    function AutoMarkerTargetConfig_RefreshTargetList()
        -- 清除现有列表项
        if _G["AutoMarkerTargetListItems"] then
            for _, item in ipairs(_G["AutoMarkerTargetListItems"]) do
                item:Hide()
                item:SetParent(nil)
            end
        end
        _G["AutoMarkerTargetListItems"] = {}
         
        -- 检查数据是否有效
        if not AutoMarkerDB or not AutoMarkerDB.schemes or not AutoMarkerTargetConfig_currentScheme then return end
         
        local scheme = AutoMarkerDB.schemes[AutoMarkerTargetConfig_currentScheme]
        if not scheme then
            scheme = {targets = {}}
            AutoMarkerDB.schemes[AutoMarkerTargetConfig_currentScheme] = scheme
        end
        if not scheme.targets then
            scheme.targets = {}
        end
        if not scheme or not scheme.targets then return end
         
        -- 获取目标列表面板
        -- 使用正确的frame名称构造面板名称
        local scrollChild = _G[frame:GetName() .. "TargetScrollFrameScrollChild"]
        if not scrollChild then
            print("AutoMarker Error: scrollChild not found")
            return
        end
         
        -- 创建列表项
        for i, target in ipairs(scheme.targets) do
            local item = CreateFrame("Button", nil, scrollChild)
            item:SetWidth(435)
            item:SetHeight(24)
            item:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -4 - (i-1)*28)
            -- 背景
           local bg = item:CreateTexture(nil, "BACKGROUND")
            bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            bg:SetVertexColor(0.2, 0.2, 0.2, 0.5)
            bg:SetAllPoints(item)
             
            -- 目标名称
            local nameText = item:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            nameText:SetText(target.name)
            nameText:SetPoint("LEFT", item, "LEFT", 5, 0)
            
            -- 备注文本
            local noteText = item:CreateFontString(nil, "ARTWORK")
            noteText:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE") -- 直接设置字体和大小
            noteText:SetTextColor(1, 0, 0, 1) -- 红色
            noteText:SetText(target.note or "")
            noteText:SetPoint("LEFT", nameText, "RIGHT", 10, 0)
            
            -- 标记图标
            local markContainer = CreateFrame("Frame", nil, item)
            markContainer:SetWidth(160)
            markContainer:SetHeight(16)
            markContainer:SetPoint("RIGHT", item, "RIGHT", -36, 0) -- 右移贴到底
            
            for j, markId in ipairs(target.marks) do
                local markTex = markContainer:CreateTexture(nil, "ARTWORK")
                markTex:SetTexture("Interface/TargetingFrame/UI-RaidTargetingIcons")
                markTex:SetWidth(16) 
                markTex:SetHeight(16)  
                markTex:SetPoint("LEFT", (j-1)*16, 0)
                
                -- 设置标记纹理坐标
                local coords = {
                     {0, 0.25, 0, 0.25},        -- 1: 黄星 
                     {0.25, 0.5, 0, 0.25},      -- 2: 橙圆
                     {0.5, 0.75, 0, 0.25},      -- 3: 紫菱形
                     {0.75, 1, 0, 0.25},        -- 4: 绿三角
                     {0, 0.25, 0.25, 0.5},      -- 5: 月亮
                     {0.25, 0.5, 0.25, 0.5},    -- 6: 蓝方
                     {0.5, 0.75, 0.25, 0.5},    -- 7: 红叉
                     {0.75, 1, 0.25, 0.5},       -- 8: 骷髅
 
                }
                markTex:SetTexCoord(unpack(coords[markId]))
            end
            
            -- 名称点击事件：添加备注
            item:SetScript("OnMouseDown", (function(currentTarget, noteTextRef) 
                return function() 
                    -- 创建输入对话框
                    local editBoxText = currentTarget.note or ""
                    StaticPopupDialogs["AUTOMARKER_ADD_NOTE"] = {
                        text = "添加备注:",
                        button1 = ACCEPT,
                        button2 = CANCEL,
                        hasEditBox = 1,
                        editBoxWidth = 300,
                        OnAccept = function() 
                            local note = _G["StaticPopup1EditBox"]:GetText() 
                            currentTarget.note = note 
                            noteTextRef:SetText(note) 
                            AutoMarkerTargetConfig_RefreshTargetList() 
                        end,
                        OnShow = function(popup) 
                            local editBox = _G["StaticPopup1EditBox"]
                            if editBox then
                                editBox:SetText(editBoxText) 
                                editBox:SetFocus() 
                            end
                        end,
                        timeout = 0,
                        exclusive = 1,
                        whileDead = 1,
                        hideOnEscape = 1
                    }
                    StaticPopup_Show("AUTOMARKER_ADD_NOTE") 
                end 
            end)(target, noteText))
             
            -- 优先级调整按钮 - 上移
            local upBtn = CreateFrame("Button", nil, item)
            upBtn:SetWidth(24)
            upBtn:SetHeight(24)
            upBtn:SetPoint("RIGHT", item, "RIGHT", -45, 0)
            upBtn:SetNormalTexture("Interface/Buttons/UI-ScrollBar-ScrollUpButton-Up")
            upBtn:SetDisabledTexture("Interface/Buttons/UI-ScrollBar-ScrollUpButton-Disabled")
            upBtn:SetPushedTexture("Interface/Buttons/UI-ScrollBar-ScrollUpButton-Down")
            upBtn:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight")
            upBtn:SetScript("OnClick", (function(index)
                return function()
                    if index and index > 1 and scheme.targets then
                        -- 交换位置
                        scheme.targets[index], scheme.targets[index-1] = scheme.targets[index-1], scheme.targets[index]
                        AutoMarkerTargetConfig_RefreshTargetList()
                    end
                end
            end)(i))
            if i == 1 then upBtn:Disable() end

            -- 优先级调整按钮 - 下移
            local downBtn = CreateFrame("Button", nil, item)
            downBtn:SetWidth(24)
            downBtn:SetHeight(24)
            downBtn:SetPoint("RIGHT", item, "RIGHT", -25, 0)
            downBtn:SetNormalTexture("Interface/Buttons/UI-ScrollBar-ScrollDownButton-Up")
            downBtn:SetDisabledTexture("Interface/Buttons/UI-ScrollBar-ScrollDownButton-Disabled")
            downBtn:SetPushedTexture("Interface/Buttons/UI-ScrollBar-ScrollDownButton-Down")
            downBtn:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight")
            downBtn:SetScript("OnClick", (function(index)
                return function()
                    local targetCount = scheme.targets and table.getn(scheme.targets) or 0
                    if index and index < targetCount then
                        -- 交换位置
                        scheme.targets[index], scheme.targets[index+1] = scheme.targets[index+1], scheme.targets[index]
                        AutoMarkerTargetConfig_RefreshTargetList()
                    end
                end
            end)(i))
            if i == table.getn(scheme.targets) then downBtn:Disable() end

            -- 删除按钮
            local delBtn = CreateFrame("Button", nil, item, "UIPanelCloseButton")
            delBtn:SetWidth(24)
            delBtn:SetHeight(24)
            delBtn:SetPoint("RIGHT", item, "RIGHT", -5, 0)
            delBtn:SetScript("OnClick", (function(index)
                return function()
                    print(scheme.targets, index)
                    table.remove(scheme.targets, index)
                    AutoMarkerTargetConfig_RefreshTargetList()
                end
            end)(i))
             
            -- 条目点击事件：反向填充表单
            item:SetScript("OnClick", (function(currentTarget)
                return function()
                    local targetEditBox = _G["AutoMarkerTargetNameEditBox"]
                    if targetEditBox then
                        targetEditBox:SetText(currentTarget.name)
                    end
                    
                    local markButtons = _G.markButtons or {}
                    -- 清除现有标记选择
                    for i=1,8 do
                        if markButtons[i] then
                            markButtons[i]:SetChecked(false)
                        end
                    end
                    
                    -- 设置当前目标的标记
                    for _, markId in ipairs(currentTarget.marks) do
                        if markButtons[markId] then
                            markButtons[markId]:SetChecked(true)
                        end
                    end
                end
            end)(target))
            
            item:Show()
            table.insert(_G["AutoMarkerTargetListItems"], item)
        end
        
      -- 设置滚动内容高度
        local targetCount = 0
        if scheme and scheme.targets then
            targetCount = table.getn(scheme.targets)
        end
        local scrollHeight = math.max(404, 60 + targetCount * 28)
        scrollChild:SetHeight(scrollHeight)
        -- 设置滚动条范围
        local targetScrollFrame = _G[frame:GetName() .. "TargetScrollFrame"]
        local scrollBar = _G[targetScrollFrame:GetName() .. "ScrollBar"]
        local maxScroll = math.max(0, scrollHeight - targetScrollFrame:GetHeight())
        scrollBar:SetMinMaxValues(0, maxScroll)
        scrollBar:SetValueStep(1)
        scrollBar:Show()  -- 确保滚动条可见
        -- 添加滚动条值变化事件处理
        scrollBar:SetScript("OnValueChanged", function(self, value)
            if type(value) == "number" then
                local clampedValue = math.max(0, math.min(value, maxScroll))
                -- 直接控制scrollChild位置而非使用SetVerticalScroll
                targetScrollFrame:SetVerticalScroll(clampedValue)
                self:SetValue(clampedValue)
            end
        end)
        -- 添加鼠标滚轮支持
        targetScrollFrame:Show()  -- 确保滚动框架可见
        targetScrollFrame:SetScript("OnMouseWheel", function(delta)
            delta = delta or arg1 or 0
            if type(delta) == "number" then
                local current = scrollBar:GetValue()
                local new = current - delta * 20
                local clamped = math.max(0, math.min(new, maxScroll))
                scrollBar:SetValue(clamped)
                targetScrollFrame:SetVerticalScroll(clamped)
            end
        end)
        
        -- 确保滑块可见并设置最小高度
        -- 确保滑块纹理存在并正确配置
        local thumb = scrollBar:GetThumbTexture()
        if not thumb then
            thumb = scrollBar:CreateTexture(nil, "ARTWORK")
            scrollBar:SetThumbTexture(thumb)
        end
        thumb:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
        thumb:SetWidth(16)
        thumb:SetHeight(16) -- 设置固定滑块高度
        thumb:Show()
        
        -- 确保scrollChild正确关联到滚动框架
        scrollChild:SetParent(targetScrollFrame)
        scrollChild:ClearAllPoints()
        -- Set scroll child for native WoW 1.12 ScrollFrame clipping
        targetScrollFrame:SetScrollChild(scrollChild)
        scrollChild:SetWidth(targetScrollFrame:GetWidth())
        -- 添加裁剪区域以隐藏超出部分
        -- WoW 1.12 uses natural parent clipping
        scrollChild:SetPoint("TOPLEFT", targetScrollFrame, "TOPLEFT", 0, 0)
        
        -- 根据内容高度启用/禁用滚动条
        if maxScroll > 0 then
            scrollBar:Show()
        else
            scrollBar:Hide()
        end
        

    end
    
    -- 初始刷新列表
    AutoMarkerTargetConfig_RefreshTargetList()
    
    -- 获取XML中定义的标记图标容器
    local markIcons = _G["AutoMarkerTargetConfigFrameMarkIcons"] or CreateFrame("Frame", "$parentMarkIcons", frame)
    -- 调整标记图标区域位置以匹配截图
    markIcons:SetWidth(240)
    markIcons:SetHeight(40)
    markIcons:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -50)
    markIcons:Show()
    markIcons:SetAlpha(1)
    
    -- 分隔线
    local divider = markIcons:CreateTexture("$parentDivider", "ARTWORK")
    divider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    divider:SetWidth(472)
    divider:SetHeight(8)
    divider:SetPoint("LEFT", portrait, "LEFT", -10, -40)
    divider:SetTexCoord(0.81, 0.94, 0.5, 1)
        -- 分隔线
    local divider = markIcons:CreateTexture("$parentDivider", "ARTWORK")
    divider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    divider:SetWidth(472)
    divider:SetHeight(8)
    divider:SetPoint("LEFT", portrait, "LEFT", -10, -444)
    divider:SetTexCoord(0.81, 0.94, 0.5, 1)
    
    -- 目标管理区域
    local targetNamePanel = CreateFrame("Frame", "AutoMarkerTargetNamePanel", frame)
    targetNamePanel:SetWidth(320)
    targetNamePanel:SetHeight(50)
    targetNamePanel:SetPoint("TOPLEFT", schemePanel, "BOTTOMLEFT", -50, -420)
    local targetLabel = targetNamePanel:CreateFontString("$parentLabel", "ARTWORK", "GameFontNormalLarge")
    targetLabel:SetText("目标名称:")
    targetLabel:SetPoint("TOPLEFT", targetNamePanel, "TOPLEFT", 0, 0)
    
    -- 目标名称输入框
    targetEditBox = CreateFrame("EditBox", "AutoMarkerTargetNameEditBox", targetNamePanel, "InputBoxTemplate")
    targetEditBox:SetAutoFocus(false)
    targetEditBox:SetWidth(260)
    targetEditBox:SetHeight(32)
    targetEditBox:SetPoint("LEFT", targetLabel, "LEFT", 80, 0)
    targetEditBox:SetFontObject(GameFontNormal)
    targetEditBox:SetTextInsets(5, 5, 0, 0)
    targetEditBox:SetMaxLetters(50)

    -- 添加自动获取目标名称功能
    local function UpdateTargetNameFromCurrentTarget()
        if UnitExists("target") then
            local targetName = UnitName("target")
            targetEditBox:SetText(targetName)
    targetEditBox:EnableKeyboard(true)
        end
    end
    -- 初始获取目标名称
    UpdateTargetNameFromCurrentTarget()
    -- 优化目标名称更新：使用事件监听而非OnUpdate
    local function UpdateTargetOnEvent(self, event)
        if event == "PLAYER_TARGET_CHANGED" then
            UpdateTargetNameFromCurrentTarget()
        end
    end
    local function RegisterTargetEvents()
        -- 确保只注册一次事件
        if not frame.targetEventRegistered then
            frame:RegisterEvent("PLAYER_TARGET_CHANGED")
            frame:SetScript("OnEvent", UpdateTargetOnEvent)
            frame.targetEventRegistered = true
        end
        frame.lastTargetName = frame.lastTargetName or ""
        frame:SetScript("OnEvent", function(_, event) local self = frame; if not self then self = {} end
            self.lastTargetName = self.lastTargetName or ""
            if event == "PLAYER_TARGET_CHANGED" then
                targetEditBox:SetText("") -- 重置编辑框内容，防止名称堆叠
                if UnitExists("target") then
                    local targetName = UnitName("target")
                    if targetName ~= self.lastTargetName then
                        self.lastTargetName = targetName
                        targetEditBox:SetText(targetName)
                    end
                else
                    if self.lastTargetName ~= "" then
                        self.lastTargetName = ""
                        targetEditBox:SetText("")
                    end
                end
            end
        end)
    end
    RegisterTargetEvents()
    -- 初始获取目标名称
    UpdateTargetNameFromCurrentTarget()
    targetEditBox:SetScript("OnTextChanged", AutoMarkerTargetConfig_UpdateTargetName)
    targetEditBox:SetScript("OnEscapePressed", function()
        local editBox = getglobal("AutoMarkerTargetEditBox")
        if editBox then
            editBox:ClearFocus()
        end
    end)
    targetEditBox:SetScript("OnEnterPressed", function() 
        local editBox = getglobal("AutoMarkerTargetEditBox")
        if editBox then
            editBox:ClearFocus()
            AutoMarkerTargetConfig_AddTarget()
        end
    end)
        targetEditBox:SetScript("OnEscapePressed", function()
        this:ClearFocus()
    end)
    -- 确保目标编辑框可编辑
    targetEditBox:EnableMouse(true)
    targetEditBox:EnableKeyboard(true)
    targetEditBox:SetAutoFocus(false)
    
    -- 标记图标纹理路径 (使用单个整合纹理)
    local MARK_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
    local markTexCoords = {
                     {0, 0.25, 0, 0.25},        -- 1: 黄星 
                     {0.25, 0.5, 0, 0.25},      -- 2: 橙圆
                     {0.5, 0.75, 0, 0.25},      -- 3: 紫菱形
                     {0.75, 1, 0, 0.25},        -- 4: 绿三角
                     {0, 0.25, 0.25, 0.5},      -- 5: 月亮
                     {0.25, 0.5, 0.25, 0.5},    -- 6: 蓝方
                     {0.5, 0.75, 0.25, 0.5},    -- 7: 红叉
                     {0.75, 1, 0.25, 0.5},       -- 8: 骷髅
    }
    
    -- 初始化标记按钮
    if not _G.markButtons then
        _G.markButtons = {}
    end
    local markButtons = _G.markButtons
    local previousButton = nil
    
    for i=1,8 do
        local btnName = "AutoMarkerMarkButton"..i
        local btn = _G[btnName]
        if not btn then
            -- 创建新按钮
            btn = CreateFrame("CheckButton", btnName, frame, "OptionsCheckButtonTemplate")
            btn:SetWidth(40)
            btn:SetHeight(40)
            btn:Show() -- 确保按钮可见
            
            -- 设置背景
            local bgTex = btn:CreateTexture(nil, "BACKGROUND")
            bgTex:SetAllPoints()
            btn.bgTex = bgTex
            
            -- 设置图标
            local normalTex = btn:CreateTexture(nil, "ARTWORK")
            normalTex:SetTexture(MARK_TEXTURE)
            local coords = markTexCoords[i]
            normalTex:SetTexCoord(unpack(coords))
            normalTex:SetAllPoints()
            btn:SetNormalTexture(normalTex)
            
            
            -- 使用模板默认勾选框纹理并调整样式
              local checkedTex = btn:GetCheckedTexture()
              if checkedTex then
                  checkedTex:SetWidth(10)
                  checkedTex:SetHeight(10)
                  checkedTex:SetPoint("CENTER", btn, "CENTER", 0, 0)
              end

              -- 确保按钮可见并可交互
              btn:Show()
              btn:Enable()
              btn:SetHitRectInsets(0, 0, 0, 0)
              btn:SetChecked(false) -- 初始化为未选中状态
              
              -- 添加点击事件切换选中状态
            -- 使用模板内置勾选功能，仅添加状态打印
              btn:SetScript("OnClick", (function(currentBtn, index)
                      return function()
                        local checked = currentBtn:GetChecked() or false -- 确保checked不为nil
                        -- print("AutoMarker: 标记按钮"..index.."状态变为"..tostring(checked)..", GetChecked()返回"..tostring(checked))
                    end
                end)(btn, i))
            
            -- 设置鼠标悬停效果
            btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
            local highlightTex = btn:GetHighlightTexture()
            highlightTex:SetBlendMode("ADD")
            highlightTex:SetAllPoints()
            
            -- 启用鼠标交互
            btn:EnableMouse(true)
            btn:Enable()
            btn:SetHitRectInsets(0, 0, 0, 0)
            
            -- 将按钮存储到数组
            markButtons[i] = btn
            
            -- 初始状态
            btn:SetChecked(false)
        --     print("AutoMarker: 创建、标记按钮"..i)
        -- else
        --     print("AutoMarker: 找、到现有标记按钮"..i)
        end
        
        -- 设置位置
        if i == 1 then
            btn:SetPoint("LEFT", targetEditBox, "LEFT", -75, -40)
        else
            btn:SetPoint("LEFT", previousButton, "RIGHT", 16, 0)
        end
        
        
        previousButton = btn
    end

    -- 添加目标按钮
    local addTargetBtn = CreateFrame("Button", "$parentAddTargetBtn", frame, "UIPanelButtonTemplate")
    addTargetBtn:SetText("添加目标")
    addTargetBtn:SetWidth(90)
    addTargetBtn:SetHeight(26)
    addTargetBtn:SetPoint("RIGHT", targetEditBox, "RIGHT", 100, 0)
    addTargetBtn:SetScript("OnClick", function()
        -- print("AutoMarker: 添加目标按钮被点击")
        if not AutoMarkerDB then
            AutoMarkerDB = {schemes = {}}
            -- print("AutoMarker: 初始化AutoMarkerDB")
        end
        if not AutoMarkerDB.schemes then
            AutoMarkerDB.schemes = {}
            -- print("AutoMarker: 初始化方案列表")
        end
        if not AutoMarkerTargetConfig_currentScheme then
            -- print("AutoMarker: 未选择当前方案")
            StaticPopup_Show("AUTOMARKER_NO_SCHEME_SELECTED")
            return
        end
        local targetName = targetEditBox:GetText()
        if targetName and targetName ~= "" then
            local selectedMarks = {}
            local markButtons = _G.markButtons or {}
            
            -- print("AutoMarker: 收集选中标记")
            selectedMarks = {}
            for i=1,8 do
                if markButtons[i] then
                    local isChecked = markButtons[i]:GetChecked()
                    -- print("AutoMarker: 标记按钮"..i..(isChecked and "已选中" or "未选中"))
                    if isChecked then
                        table.insert(selectedMarks, i)
                    end
                else
                    -- print("AutoMarker: 标记按钮"..i.."不存在")
                end
            end
            
            -- print("AutoMarker: 选中标记数量: " .. table.getn(selectedMarks))
            if table.getn(selectedMarks) > 0 and AutoMarkerDB and AutoMarkerDB.schemes and AutoMarkerTargetConfig_currentScheme then
                local scheme = AutoMarkerDB.schemes[AutoMarkerTargetConfig_currentScheme]
                if not scheme then
                    scheme = {targets = {}}
                    AutoMarkerDB.schemes[AutoMarkerTargetConfig_currentScheme] = scheme
                end
                if not scheme.targets then
                    scheme.targets = {}
                end
                
                -- 检查是否已存在同名目标
                local existingIndex = nil
                for i, t in ipairs(scheme.targets) do
                    if t.name == targetName then
                        existingIndex = i
                        break
                    end
                end
                
                if existingIndex then
                    -- 更新现有目标
                    scheme.targets[existingIndex].marks = selectedMarks
                    -- print("AutoMarker: 更新现有目标: " .. targetName)
                else
                    -- 添加新目标
                    local newTarget = {
                        name = targetName,
                        marks = selectedMarks
                    }
                    table.insert(scheme.targets, newTarget)
                    -- print("AutoMarker: 添加新目标到方案: " .. targetName)
                end
                -- print("AutoMarker: 添加、新目标到方案: " .. targetName .. ", 标记: " .. table.concat(selectedMarks, ","))
                
                targetEditBox:SetText("")
                -- 清除标记选择
                for i=1,8 do
                    if markButtons[i] then
                        markButtons[i]:SetChecked(false)
                    end
                end
                AutoMarkerTargetConfig_RefreshTargetList()
            else
                print("AutoMarker: 未选择标记或方案无效")
                StaticPopup_Show("AUTOMARKER_NO_MARKS_SELECTED")
            end
        else
            -- print("AutoMarker: 目标名称为空")
            StaticPopup_Show("AUTOMARKER_EMPTY_TARGET_NAME")
        end
    end)
    

    -- 窗口拖动功能
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)
    
    -- 确保所有标记图标可见
    local markButtonsCount = 0
    if markButtons then
        for _ in pairs(markButtons) do markButtonsCount = markButtonsCount + 1 end
    end
    for i=1,markButtonsCount do
        markButtons[i]:Show()
        local texture = markButtons[i]:GetNormalTexture()
        if texture then
            texture:Show()
        end
    end
    
    frame.uiCreated = true
    frame:Show()
    return frame
end