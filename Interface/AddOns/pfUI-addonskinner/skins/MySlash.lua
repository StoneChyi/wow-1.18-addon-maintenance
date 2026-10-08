-- MySlashSkin.lua
-- pfUI 皮肤模块，为 MySlash 提供统一风格
-- 仅在 pfUI 存在时加载

if not pfUI or not pfUI.addonskinner then
    return
end

pfUI.addonskinner:RegisterSkin("MySlash", function()
    -- 获取 pfUI 的皮肤工具函数
    local penv = pfUI:GetEnvironment()
    local StripTextures, CreateBackdrop, SkinCloseButton, SkinButton,
          SkinCheckbox, SkinCollapseButton, SetAllPointsOffset, SetHighlight,
          SkinScrollbar, HookScript, SkinDropDown =
        penv.StripTextures, penv.CreateBackdrop, penv.SkinCloseButton, penv.SkinButton,
        penv.SkinCheckbox, penv.SkinCollapseButton, penv.SetAllPointsOffset,
        penv.SetHighlight, penv.SkinScrollbar, penv.HookScript, penv.SkinDropDown

    -- 辅助：递归查找并美化滚动条
    local function SkinScrollbarRecursive(parent)
        if not parent then return false end
        for _, child in ipairs({parent:GetChildren()}) do
            if child:GetObjectType() == "ScrollBar" then
                SkinScrollbar(child)
                return true
            end
        end
        return false
    end

    -- ============================================================
    -- 1. 主框架 (SlibFrame)
    -- ============================================================
    if SlibFrame then
        StripTextures(SlibFrame)
        CreateBackdrop(SlibFrame, nil, nil, 0.75)

        -- 关闭按钮
        if SlibBtnCloseX then
            SkinCloseButton(SlibBtnCloseX, SlibFrame.backdrop, -6, -6)
        end

        -- 标题文字居中
        if SlibTitre then
            SlibTitre:SetPoint("CENTER", SlibFrame.backdrop, "TOP", 0, -8)
        end

        -- 主框架中的所有按钮（除关闭按钮外）
        for _, child in ipairs({SlibFrame:GetChildren()}) do
            if child:GetObjectType() == "Button" and child ~= SlibBtnCloseX then
                SkinButton(child)
            end
        end
    end

    -- ============================================================
    -- 2. 列表行按钮 (SlibFrameLine_1 ~ SLIBVISLINE)
    -- ============================================================
    if SLIBVISLINE then
        for i = 1, SLIBVISLINE do
            local line = _G["SlibFrameLine_" .. i]
            if line then
                local btnTitre = _G[line:GetName() .. "_BtnTitre"]
                if btnTitre then SkinButton(btnTitre) end
                local btnCmd = _G[line:GetName() .. "_BtnCmd"]
                if btnCmd then SkinButton(btnCmd) end
            end
        end
    end

    -- ============================================================
    -- 3. 主滚动条 (SlibFrameScroller)
    -- ============================================================
    if SlibFrameScroller then
        StripTextures(SlibFrameScroller)
        if not SkinScrollbarRecursive(SlibFrameScroller) then
            -- 备选：直接尝试已知名称
            local scrollBar = _G["SlibFrameScrollerScrollBar"] or _G["SlibFrameScrollerScrollBar"]
            if scrollBar then SkinScrollbar(scrollBar) end
        end
    end

    -- ============================================================
    -- 4. 编辑框架 (SlibEditFrame)
    -- ============================================================
    if SlibEditFrame then
        StripTextures(SlibEditFrame)
        CreateBackdrop(SlibEditFrame, nil, nil, 0.75)

        -- 编辑框架中的所有按钮
        for _, child in ipairs({SlibEditFrame:GetChildren()}) do
            if child:GetObjectType() == "Button" then
                SkinButton(child)
            end
        end
    end

    -- ============================================================
    -- 5. 单行编辑框 (名称)
    -- ============================================================
    if SlibNameDef then
        StripTextures(SlibNameDef, true, "BACKGROUND")
        CreateBackdrop(SlibNameDef, nil, true)
    end

    -- ============================================================
    -- 6. 多行编辑框 (脚本) 及其滚动条
    -- ============================================================
    if SlibCmdDef then
        StripTextures(SlibCmdDef, true, "BACKGROUND")
        CreateBackdrop(SlibCmdDef, nil, true)
    end

    if SlibCmdDefScrollBar then
        if not SkinScrollbarRecursive(SlibCmdDefScrollBar) then
            local scrollBar = _G["SlibCmdDefScrollBarScrollBar"] or _G["SlibCmdDefScrollBarScrollBar"]
            if scrollBar then SkinScrollbar(scrollBar) end
        end
    end

    -- 注意：无需 UnregisterSkin，保持注册即可
end)