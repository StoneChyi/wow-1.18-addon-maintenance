pfUI.addonskinner:RegisterSkin("RaidCheck", function()
    local penv = pfUI:GetEnvironment()
    local StripTextures, CreateBackdrop, SkinCloseButton, SkinButton, SkinArrowButton,
          SkinCheckbox, SkinCollapseButton, SetAllPointsOffset, SetHighlight, SkinScrollbar,
          HookScript, SkinDropDown =
        penv.StripTextures, penv.CreateBackdrop, penv.SkinCloseButton, penv.SkinButton, penv.SkinArrowButton,
        penv.SkinCheckbox, penv.SkinCollapseButton, penv.SetAllPointsOffset, penv.SetHighlight, penv.SkinScrollbar,
        penv.HookScript, penv.SkinDropDown

    local frame = RC_MainFrame
    if not frame then return end

    -- 主框架美化
    frame:DisableDrawLayer("BACKGROUND")
    StripTextures(frame)
    CreateBackdrop(frame, nil, nil, 0.75)

    -- 标题文本位置调整
    local title = _G["RC_MainFrameMainLabel"]
    if title then
        title:SetPoint("TOP", frame.backdrop, "TOP", 0, -5)
    end

    -- 关闭按钮
    local closeBtn = RC_MainFrameCloseButton
    if closeBtn then
        SkinCloseButton(closeBtn, frame.backdrop, -6, -6)
    end

    -- 底部按钮
    SkinButton(RC_MainFrameCheckButton)
    SkinButton(RC_MainFrameAllButton)
    SkinButton(RC_MainFrameCleanButton)
    if RC_MainFrameBuffAssignButton then SkinButton(RC_MainFrameBuffAssignButton) end

    -- Buff 按钮 (A组 1~11)
    for i = 1, 11 do
        local btn = _G["RC_MainFrameBuffa" .. i .. "Button"]
        if btn then SkinButton(btn) end
    end

    -- Buff 按钮 (B组 1~7)
    for i = 1, 7 do
        local btn = _G["RC_MainFrameBuffb" .. i .. "Button"]
        if btn then SkinButton(btn) end
    end

    -- Buff 按钮 (C组 1~6)
    for i = 1, 6 do
        local btn = _G["RC_MainFrameBuffc" .. i .. "Button"]
        if btn then SkinButton(btn) end
    end

    -- 特殊按钮 (血量相关)
    SkinButton(RC_MainFrameHpNowButton)
    SkinButton(RC_MainFrameBuffcHpButton)

    -- 复选框 (D组 1~11)
    for i = 1, 11 do
        local cb = _G["RC_MainFrameBuffd" .. i .. "CheckBox"]
        if cb then SkinCheckbox(cb) end
    end

    -- 下拉菜单 (频道选择)
    SkinDropDown(RC_MainFrameChannelsDropdown, nil, nil, nil, true)

    -- 编辑框 (血量输入)
    local edit1 = RC_MainFrameEditBox
    if edit1 then
        StripTextures(edit1, true, "BACKGROUND")
        CreateBackdrop(edit1, nil, true)
    end

    local edit2 = RC_MainFrameBuffcHpEditBox
    if edit2 then
        StripTextures(edit2, true, "BACKGROUND")
        CreateBackdrop(edit2, nil, true)
    end

    --------------------------------------------------------------------
    -- 团队BUFF分配窗口（RCBA_，懒加载：首次 RCBA_Toggle 才创建）
    --------------------------------------------------------------------
    local keys = { "Fortitude", "Intellect", "WildMark", "Curse", "Tank" }

    local function RestyleFontStrings(frame)
        for _, r in ipairs({ frame:GetRegions() }) do
            if r.GetObjectType and r:GetObjectType() == "FontString" then
                local _, size = r:GetFont()
                r:SetFont(pfUI.font_default, size or 12, "OUTLINE")
            end
        end
    end

    -- 骑士祝福列表的动态按钮（每次 RefreshBlessingFrame 重建，旧件进回收池）
    -- 注意：插件会把旧按钮 SetParent(palPool) 后用同名新建，1.12 下 _G 旧引用
    -- 可能不覆盖 → 按 _G 名字查会拿到回收池里的旧件。改扫 blessingFrame 的
    -- GetChildren()（新建件都是它的子件，旧件已被挪走）最可靠。
    local function SkinPalButtons()
        local bf = RCBA_BlessingFrame
        if not bf then return end
        local children = { bf:GetChildren() }
        for i = 1, table.getn(children) do
            local c = children[i]
            local cname = c.GetName and c:GetName()
            if cname and string.find(cname, "^RCBA_PalName%d+$")
                and not c.pfRCBASkinned then
                c.pfRCBASkinned = true
                SkinButton(c)
            end
        end
    end

    local function SkinRCBA()
        local mainFrame = RCBA_MainFrame
        if not mainFrame then return end

        if not mainFrame.pfRCBASkinned then
            mainFrame.pfRCBASkinned = true

            -- 主框架：去掉自绘 tooltip 底板与石质标题条，换 pfUI 底板
            StripTextures(mainFrame)
            mainFrame:SetBackdrop(nil)
            CreateBackdrop(mainFrame, nil, nil, 0.75)

            -- 标题文字贴回顶部（石质贴图已清除，原锚点挂在贴图上）
            for _, r in ipairs({ mainFrame:GetRegions() }) do
                if r.GetObjectType and r:GetObjectType() == "FontString"
                    and r.GetText and r:GetText() == "团队BUFF分配" then
                    r:ClearAllPoints()
                    r:SetPoint("TOP", mainFrame, "TOP", 0, -6)
                    r:SetTextColor(1, 1, 1, 1)
                end
            end
            RestyleFontStrings(mainFrame)

            -- 主框架按钮
            for _, name in ipairs({ "RCBA_CloseButton", "RCBA_BlessingButton",
                                    "RCBA_TankAdvButton", "RCBA_TaskButton",
                                    "RCBA_AutoButton", "RCBA_ReportButton",
                                    "RCBA_CheckButton", "RCBA_MonitorButton" }) do
                local b = _G[name]
                if b then SkinButton(b) end
            end

            -- 分组容器框（真言术/奥术智慧/野性印记/诅咒/坦克）
            for _, key in ipairs(keys) do
                local f = _G["RCBA_" .. key .. "Frame"]
                if f and not f.pfRCBASkinned then
                    f.pfRCBASkinned = true
                    f:SetBackdrop(nil)
                    CreateBackdrop(f, nil, true, 0.75)
                    RestyleFontStrings(f)
                end
            end

            -- 骑士祝福子窗口（注意：不能 StripTextures，会清掉职业图标）
            local bf = RCBA_BlessingFrame
            if bf and not bf.pfRCBASkinned then
                bf.pfRCBASkinned = true
                bf:SetBackdrop(nil)
                CreateBackdrop(bf, nil, true, 0.75)
                RestyleFontStrings(bf)

                for _, name in ipairs({ "RCBA_BlessingCloseButton", "RCBA_BlessingRefreshButton" }) do
                    local b = _G[name]
                    if b then SkinButton(b) end
                end

                -- 每次打开/刷新骑士祝福列表后补皮肤（列表按钮是动态重建的）
                -- OnShow 兜底覆盖「骑士祝福设置」打开；重新检测/自动分配
                -- 会在窗口可见时重建列表，也要挂 OnClick 包装
                HookScript(bf, "OnShow", SkinPalButtons)
                local rb = _G["RCBA_BlessingRefreshButton"]
                if rb then HookScript(rb, "OnClick", SkinPalButtons) end
                local ab2 = _G["RCBA_AutoButton"]
                if ab2 then HookScript(ab2, "OnClick", SkinPalButtons) end
            end

            -- 坦克分配（高级）子窗口（框架无自有纹理，直接换底板）
            local taf = RCBA_TankAdvFrame
            if taf and not taf.pfRCBASkinned then
                taf.pfRCBASkinned = true
                taf:SetBackdrop(nil)
                CreateBackdrop(taf, nil, true, 0.75)
                RestyleFontStrings(taf)

                for _, name in ipairs({ "RCBA_TankAdvCloseButton", "RCBA_TankAdvReportButton" }) do
                    local b = _G[name]
                    if b then SkinButton(b) end
                end

                -- 8 行：坦克下拉 + 拉的目标输入框 + 2 个治疗下拉
                for i = 1, 8 do
                    local tdd = _G["RCBA_TankAdv_Tank" .. i]
                    if tdd and not tdd.pfRCBASkinned then
                        tdd.pfRCBASkinned = true
                        SkinDropDown(tdd, nil, nil, nil, true)
                    end

                    local ed = _G["RCBA_TankAdv_Target" .. i]
                    if ed and not ed.pfRCBASkinned then
                        ed.pfRCBASkinned = true
                        StripTextures(ed, true)
                        CreateBackdrop(ed, nil, true)
                    end

                    for s = 1, 2 do
                        local hdd = _G["RCBA_TankAdv_Heal" .. i .. "_" .. s]
                        if hdd and not hdd.pfRCBASkinned then
                            hdd.pfRCBASkinned = true
                            SkinDropDown(hdd, nil, nil, nil, true)
                        end
                    end
                end
            end

            -- 任务分配子窗口（框架无自有纹理，直接换底板）
            local tkf = RCBA_TaskFrame
            if tkf and not tkf.pfRCBASkinned then
                tkf.pfRCBASkinned = true
                tkf:SetBackdrop(nil)
                CreateBackdrop(tkf, nil, true, 0.75)
                RestyleFontStrings(tkf)

                for _, name in ipairs({ "RCBA_TaskCloseButton", "RCBA_TaskSaveButton",
                                        "RCBA_TaskReportButton" }) do
                    local b = _G[name]
                    if b then SkinButton(b) end
                end

                -- 8 行任务输入框
                for i = 1, 8 do
                    local ed = _G["RCBA_TaskEdit" .. i]
                    if ed and not ed.pfRCBASkinned then
                        ed.pfRCBASkinned = true
                        StripTextures(ed, true)
                        CreateBackdrop(ed, nil, true)
                    end
                end
            end
        end

        -- 下拉菜单（换字体后仍需幂等补套，防插件重置贴图）
        for _, key in ipairs(keys) do
            for i = 1, 8 do
                local dd = _G["RCBA_Drop_" .. key .. i]
                if dd and not dd.pfRCBASkinned then
                    dd.pfRCBASkinned = true
                    SkinDropDown(dd, nil, nil, nil, true)
                end
            end
        end

        SkinPalButtons()
    end

    -- 窗口懒加载：包装全局开关函数，创建后套皮肤
    if RCBA_Toggle then
        local origToggle = RCBA_Toggle
        RCBA_Toggle = function()
            origToggle()
            pcall(SkinRCBA)
        end
    end

    -- 皮肤应用后注销自身，避免重复执行
    pfUI.addonskinner:UnregisterSkin("RaidCheck")
end)