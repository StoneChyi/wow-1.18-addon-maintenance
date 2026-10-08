-- XyTracker pfUI 皮肤支持
-- 当 pfUI 存在时，为 XyTracker 的各窗口应用 pfUI 风格
-- 全部改动仅作用于外观，不触碰任何现有逻辑
-- 已整合拍卖模块 (xy_auction) 的美化

local noop = function() end
local layoutApplied = false
local pfui_env = nil

local function GetPFUIEnv()
    if pfui_env then return pfui_env end
    if pfUI and type(pfUI.GetEnvironment) == "function" then
        pfui_env = pfUI:GetEnvironment()
        return pfui_env
    end
    return nil
end

-- =======================
-- 辅助：Skin 标准按钮 (UIPanelButtonTemplate/OptionsButtonTemplate)
-- =======================
local function SkinPanelButton(btn)
    if not btn or btn.pfUISkinned then return end
    local penv = GetPFUIEnv()
    if not penv then return end
    btn.pfUISkinned = true

    penv.StripTextures(btn)
    if btn.Left then
        btn.Left:SetTexture("")
        btn.Left.SetTexture = noop
    end
    if btn.Middle then
        btn.Middle:SetTexture("")
        btn.Middle.SetTexture = noop
    end
    if btn.Right then
        btn.Right:SetTexture("")
        btn.Right.SetTexture = noop
    end
    penv.SkinButton(btn)
end

-- 辅助：Skin 输入框
local function SkinEditBox(eb)
    if not eb or eb.pfUISkinned then return end
    local penv = GetPFUIEnv()
    if not penv then return end
    eb.pfUISkinned = true
    penv.StripTextures(eb, true, "BACKGROUND")
    penv.CreateBackdrop(eb, nil, true)
end

-- 辅助：Skin 列表表头（XyColumnHeaderTemplate，去掉纹理只留文字）
local function SkinColumnHeader(btn)
    if not btn or btn.pfUISkinned then return end
    local penv = GetPFUIEnv()
    if not penv then return end
    btn.pfUISkinned = true
    penv.StripTextures(btn)
end

-- 辅助：Skin 窗口（去 XML 原生 Backdrop 后换 pfUI 背景）
local function SkinWindow(frame)
    if not frame or frame.pfUISkinned then return false end
    local penv = GetPFUIEnv()
    if not penv then return false end
    frame.pfUISkinned = true
    frame:SetBackdrop(nil)
    penv.StripTextures(frame)
    penv.CreateBackdrop(frame, nil, nil, .75)
    return true
end

-- 辅助：Skin 关闭按钮（使用 pfUI 的 SkinCloseButton）
local function SkinCloseButton(btn, backdrop, offX, offY)
    if not btn then return end
    local penv = GetPFUIEnv()
    if not penv then return end
    if backdrop then
        penv.SkinCloseButton(btn, backdrop, offX or -6, offY or -6)
    else
        penv.SkinCloseButton(btn)
    end
end

-- =======================
-- 全局：拍卖模块皮肤应用
-- =======================
function ApplyAuctionSkin(frame)
    local penv = GetPFUIEnv()
    if not penv then return end

    -- 如果传入特定框架，只美化该框架及其子元素
    if frame then
        SkinWindow(frame)

        -- 1. 处理关闭按钮（优先使用 frame.closeBtn 属性，或名称包含 "Close"）
        local closeBtn = frame.closeBtn
        if not closeBtn then
            for _, child in ipairs({frame:GetChildren()}) do
                if child:GetObjectType() == "Button" and child:GetName() and string.find(child:GetName(), "Close") then
                    closeBtn = child
                    break
                end
            end
        end
        if closeBtn then
            SkinCloseButton(closeBtn, frame.backdrop)
            closeBtn.pfUISkinned = true
        end

        -- 2. 处理标准按钮 (UIPanelButtonTemplate)
        for _, child in ipairs({frame:GetChildren()}) do
            if child:GetObjectType() == "Button" and not child.pfUISkinned then
                if closeBtn and child == closeBtn then
                    -- 跳过
                elseif child:GetName() and string.find(child:GetName(), "Close") then
                    -- 跳过
                else
                    SkinPanelButton(child)
                end
            end
        end

        -- 3. 处理输入框 (EditBox)
        for _, child in ipairs({frame:GetChildren()}) do
            if child:GetObjectType() == "EditBox" then
                SkinEditBox(child)
            end
        end

        -- 4. 处理复选框 (CheckButton)   <-- 新增
        for _, child in ipairs({frame:GetChildren()}) do
            if child:GetObjectType() == "CheckButton" and not child.pfUISkinned then
                child.pfUISkinned = true
                penv.SkinCheckbox(child, 20)   -- 使用 pfUI 的皮肤函数
            end
        end

        return
    end

    -- =======================
    -- 静态主拍卖窗口 (XyAuctionFrame) ...（以下原有代码不变）
    -- =======================
    -- 省略后续不变代码，因修改只针对传入 frame 的分支

    -- =======================
    -- 静态主拍卖窗口 (XyAuctionFrame)
    -- =======================
    local mainFrame = _G["XyAuctionFrame"]
    if SkinWindow(mainFrame) then
        -- 关闭按钮（优先使用 closeBtn 属性，或全局名）
        local closeBtn = mainFrame and mainFrame.closeBtn
        if not closeBtn then
            closeBtn = _G["XyAuctionFrameCloseButton"]
        end
        if closeBtn then
            SkinCloseButton(closeBtn, mainFrame.backdrop)
            closeBtn.pfUISkinned = true
        end

        -- 输入框
        for _, child in ipairs({mainFrame:GetChildren()}) do
            if child:GetObjectType() == "EditBox" then
                SkinEditBox(child)
            end
        end

        -- 标准按钮，跳过关闭按钮
        for _, child in ipairs({mainFrame:GetChildren()}) do
            if child:GetObjectType() == "Button" and not child.pfUISkinned then
                if closeBtn and child == closeBtn then
                    -- 跳过
                elseif child:GetName() and string.find(child:GetName(), "Close") then
                    -- 跳过
                else
                    SkinPanelButton(child)
                end
            end
        end
    end

    -- =======================
    -- 快捷按钮框架 (XyQuickFrame)
    -- =======================
    local quickFrame = _G["XyQuickFrame"]
    if SkinWindow(quickFrame) then
        for _, child in ipairs({quickFrame:GetChildren()}) do
            if child:GetObjectType() == "Button" and not child.pfUISkinned then
                SkinPanelButton(child)
            end
        end
    end
end

-- 将 ApplyAuctionSkin 暴露为全局，供拍卖模块动态调用
_G["ApplyAuctionSkin"] = ApplyAuctionSkin

-- =======================
-- 主皮肤应用函数 (XyTracker 原有窗口)
-- =======================
local function ApplySkin()
    local penv = GetPFUIEnv()
    if not penv then return false end

    -- =======================
    -- 主窗口 (XyTrackerFrame)
    -- =======================
    local mainFrame = _G["XyTrackerFrame"]
    if SkinWindow(mainFrame) then
        -- 关闭按钮
        SkinCloseButton(_G["XyTrackerFrameCloseButton"], mainFrame.backdrop, -6, -6)

        -- 所有 UIPanelButtonTemplate 按钮（XML 里是 $parentXxx，全局名 XyTrackerFrameXxx）
        local buttonNames = {
            "XyTrackerFrameStartButton",          -- 开始
            "XyTrackerFrameStopButton",           -- 停止
            "XyTrackerFrameResetButton",          -- 重置
            "XyTrackerFrameRefreshButton",        -- 刷新
            "XyTrackerFrameChuShiHua_DKP",        -- 初始化DKP
            "XyTrackerFrameSaveWishButton",       -- 保存许愿
            "XyTrackerFrameRestoreWishButton",    -- 恢复许愿
            "XyTrackerFrameLootListButton",       -- 拾取列表
            "XyTrackerFrameBlacklistButton",      -- 黑名单
            "XyTrackerFrameBroadcastButton",      -- 播报许愿
            "XyTrackerFrameAnnounceButton",       -- 未许愿人数
            "XyTrackerFrameExportButton",         -- 导出许愿
            "XyTrackerFrameEditStarttextButton",  -- 开团公告
            "XyTrackerFrameRelinquishButton",     -- 放弃权限
            "XyTrackerFrameDeclarationButton",    -- 宣言
            "XyTrackerFrameAnnounceDeclarationButton", -- 通告宣言
            "XyTrackerFrameAuctionButton", -- 拍卖模块
        }
        for _, name in ipairs(buttonNames) do
            SkinPanelButton(_G[name])
        end

        -- 七个模式/功能复选框（XML 为 virtual 模板，本客户端若未实例化则判空跳过）
        local checkNames = {
            "autoModeButtons", "autoAnnounceButton", "autoMinButtons",
            "greenModeButtons", "blueModeButtons", "purpleModeButtons",
            "autoBackupButton","clearOnLeaveButton",
        }
        for _, name in ipairs(checkNames) do
            local check = _G[name]
            if check and not check.pfUISkinned then
                check.pfUISkinned = true
                penv.SkinCheckbox(check, 20)
            end
        end

        -- 许愿列表行内 +/- 与"完"按钮（XyFrameListButton1..N，XML 静态创建）
        for i = 1, 40 do
            local rowFrame = _G["XyFrameListButton" .. i]
            if not rowFrame then break end

            for j = 1, 2 do
                local suffix = j == 1 and "AddDkp" or "MinusDkp"
                local txt = j == 1 and "+" or "-"
                local b = _G["XyFrameListButton" .. i .. suffix]
                if b and not b.pfUISkinned then
                    b.pfUISkinned = true
                    b:SetNormalTexture("")
                    b:SetPushedTexture("")
                    b:SetDisabledTexture("")
                    b:SetHighlightTexture("")
                    penv.SkinButton(b)
                    -- 纯纹理按钮没有文字层，补一个字符标签
                    if not b.text then
                        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                        b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
                    end
                    b.text:SetText(txt)
                end
            end

            local complete = _G["XyFrameListButton" .. i .. "CompleteWish"]
            if complete and not complete.pfUISkinned then
                complete.pfUISkinned = true
                complete:SetHighlightTexture("")
                penv.SkinButton(complete)  -- 保留其"完"文字（FontString 已在 XML 中定义）
            end
        end

        -- 许愿列表表头（角色名/职业/许愿/分数/操作）
        for i = 1, 5 do
            SkinColumnHeader(_G["XyFrameColumnHeader" .. i])
        end

        -- 许愿列表滚动条（FauxScrollFrameTemplate 子框架，名 <滚动框架名>ScrollBar）
        local scrollBar = _G["XyListScrollFrameScrollBar"]
        if scrollBar then
            penv.SkinScrollbar(scrollBar)

            -- >>> shiftX 就是左右移动滚动条的参数：调大右移，调小左移，0 = 原位 <<<
            if not scrollBar.xyShifted then
                scrollBar.xyShifted = true
                local shiftX = 17
                local pts = {}
                for i = 1, scrollBar:GetNumPoints() do
                    local p, rel, rp, x, y = scrollBar:GetPoint(i)
                    table.insert(pts, { p = p, rel = rel, rp = rp, x = x, y = y })
                end
                scrollBar:ClearAllPoints()
                if table.getn(pts) > 0 then
                    for _, pt in ipairs(pts) do
                        scrollBar:SetPoint(pt.p, pt.rel, pt.rp, pt.x + shiftX, pt.y)
                    end
                else
                    -- 兜底：按 FauxScrollFrameTemplate 的默认锚点重建
                    scrollBar:SetPoint("TOPRIGHT", scrollBar:GetParent(), "TOPRIGHT", shiftX, -16)
                    scrollBar:SetPoint("BOTTOMRIGHT", scrollBar:GetParent(), "BOTTOMRIGHT", shiftX, 16)
                end
            end
        end
    end   -- <-- 主窗口处理结束

    -- ===== 调整布局以解决按钮与标题重叠 =====
    if not layoutApplied and mainFrame then
        local topRowButtons = {
            "XyTrackerFrameStopButton",
        }
        local offsetY = -15
        local offsetX = 3
        local stopBtn = _G["XyTrackerFrameStopButton"]
        local baseY = 0
        if stopBtn then
            local _, _, _, _, yOff = stopBtn:GetPoint(1)
            if yOff then baseY = yOff end
        end
        for _, name in ipairs(topRowButtons) do
            local btn = _G[name]
            if btn then
                local point, relative, relPoint, xOff, _ = btn:GetPoint(1)
                if point then
                    btn:ClearAllPoints()
                    btn:SetPoint(point, relative, relPoint, xOff + offsetX, baseY + offsetY)
                end
            end
        end
        mainFrame:SetHeight(mainFrame:GetHeight() + 30)
        layoutApplied = true
    end

    -- =======================
    -- 默认DKP输入窗口 (allDKPFrame，XyTrackerFrame 子框架)
    -- =======================
    local allDKPFrame = _G["allDKPFrame"]
    if SkinWindow(allDKPFrame) then
        SkinCloseButton(_G["allDKPFrameCloseButton"], allDKPFrame.backdrop, -6, -6)
        SkinPanelButton(_G["XyAddDkpFrameDone"])
        SkinEditBox(_G["allDKPFrameTXT"])
    end

    -- =======================
    -- 拾取列表窗口 (XyTrackerLootListFrame)
    -- =======================
    local lootFrame = _G["XyTrackerLootListFrame"]
    if SkinWindow(lootFrame) then
        SkinCloseButton(_G["XyTrackerLootListFrameCloseButton"], lootFrame.backdrop, -6, -6)
        SkinPanelButton(_G["XyTrackerLootListFrameRestoreButton"]) -- 恢复
        SkinPanelButton(_G["XyTrackerLootListFrameSaveButton"])    -- 保存
        SkinPanelButton(_G["XyTrackerLootListFrameClearButton"])   -- 清除列表

        for i = 1, 5 do
            SkinColumnHeader(_G["LootFrameColumnHeader" .. i])
        end

        local lootScrollBar = _G["LootListScrollFrameScrollBar"]
        if lootScrollBar then
            penv.SkinScrollbar(lootScrollBar)
        end
    end

    -- 品质筛选复选框（XyTrackerQualityFilterFrame 内，XML 已实例化，QualityFilter.lua 可能动态补建）
    local qualityChecks = {
        "OrangeQualityCheck", "PurpleQualityCheck", "BlueQualityCheck",
        "GreenQualityCheck", "WhiteQualityCheck",
    }
    for _, name in ipairs(qualityChecks) do
        local check = _G[name]
        if check and not check.pfUISkinned then
            check.pfUISkinned = true
            penv.SkinCheckbox(check, 20)
        end
    end

    -- =======================
    -- 加/减分窗口 (XyAddDkpFrame / XyMinusDkpFrame)
    -- =======================
    local addFrame = _G["XyAddDkpFrame"]
    if SkinWindow(addFrame) then
        SkinCloseButton(_G["XyAddDkpFrameCloseButton"], addFrame.backdrop, -6, -6)
        SkinPanelButton(_G["XyAddDkpFrameDone"])
        SkinEditBox(_G["XyAddDkpFramePoint"])
    end

    local minusFrame = _G["XyMinusDkpFrame"]
    if SkinWindow(minusFrame) then
        SkinCloseButton(_G["XyMinusDkpFrameCloseButton"], minusFrame.backdrop, -6, -6)
        SkinPanelButton(_G["XyMinusDkpFrameDone"])
        SkinEditBox(_G["XyMinusDkpFramePoint"])
    end

    -- =======================
    -- 导出窗口 (XyExportFrame)
    -- =======================
    local exportFrame = _G["XyExportFrame"]
    if SkinWindow(exportFrame) then
        SkinEditBox(_G["XyExportEdit"])
    end

    -- =======================
    -- 宣言窗口 (XyTrackerDeclarationFrame)
    -- =======================
    local declFrame = _G["XyTrackerDeclarationFrame"]
    if SkinWindow(declFrame) then
        SkinPanelButton(_G["XyTrackerDeclarationConfirmButton"])
        SkinPanelButton(_G["XyTrackerDeclarationCancelButton"])
        SkinEditBox(_G["XyTrackerDeclarationLargeEditBox"])
    end

    -- =======================
    -- 黑名单配置窗口 (XyTrackerBlacklistConfigFrame)
    -- =======================
    local blFrame = _G["XyTrackerBlacklistConfigFrame"]
    if SkinWindow(blFrame) then
        local enableCheck = _G["XyTrackerBlacklistConfigFrameEnableCheckbox"]
        if enableCheck and not enableCheck.pfUISkinned then
            enableCheck.pfUISkinned = true
            penv.SkinCheckbox(enableCheck, 20)
        end

        local blEdits = {
            "XyTrackerBlacklistConfigFrameAnnouncementText",
            "XyTrackerBlacklistConfigFrameAddPlayerText",
            "XyTrackerBlacklistConfigFrameRemoveIndexEdit",
            "XyTrackerBlacklistConfigFrameReasonText",
        }
        for _, name in ipairs(blEdits) do
            SkinEditBox(_G[name])
        end

        local blButtons = {
            "XyTrackerBlacklistConfigFrameAddButton",
            "XyTrackerBlacklistConfigFrameRemoveButton",
            "XyTrackerBlacklistConfigFrameShowListButton",
            "XyTrackerBlacklistConfigFrameCloseButton",
        }
        for _, name in ipairs(blButtons) do
            SkinPanelButton(_G[name])
        end
    end

    -- =======================
    -- 开团公告编辑窗口 (XyTrackerStarttextEditBoxFrame，动态创建，可能尚不存在)
    -- =======================
    local stFrame = _G["XyTrackerStarttextEditBoxFrame"]
    if SkinWindow(stFrame) then
        SkinEditBox(_G["XyTrackerStarttextEditBox"])
        for _, child in ipairs({stFrame:GetChildren()}) do
            if child:GetObjectType() == "Button" then
                SkinPanelButton(child)
            end
        end
    end

    -- =======================
    -- 拍卖模块静态窗口美化 (主窗口和快捷栏)
    -- =======================
    ApplyAuctionSkin()  -- 不带参数，美化已知静态框架

    return true
end

-- =======================
-- Hook 动态创建入口：开团公告编辑窗口首次打开时才创建
-- =======================
if XyTracker_ShowStarttextEditBox then
    local origShowStarttext = XyTracker_ShowStarttextEditBox
    XyTracker_ShowStarttextEditBox = function()
        local result = origShowStarttext()
        ApplySkin()
        return result
    end
end

-- =======================
-- 等待 pfUI 就绪后应用皮肤
-- =======================
local skinner = CreateFrame("Frame")
skinner:RegisterEvent("ADDON_LOADED")
skinner:RegisterEvent("PLAYER_LOGIN")
skinner:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "XyTracker" then
        if ApplySkin() then
            this:UnregisterAllEvents()
        end
    elseif event == "PLAYER_LOGIN" then
        if ApplySkin() then
            this:UnregisterAllEvents()
        end
    end
end)