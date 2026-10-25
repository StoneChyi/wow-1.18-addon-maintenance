--[[
    SM_MacroExtend.lua - 扩展代码编辑器管理
    处理超级宏内置的Lua代码扩展编辑器（Extend标签），
    支持按宏名称保存/加载扩展脚本，并提供运行、复制、删除功能。
    每个常规宏或超级宏都可以有一个同名的扩展脚本页面。
--]]

-- 当前显示的扩展脚本页面标识（对应宏名称）
local currentPageId
local loadingExtendPage

-- 确保 SM_EXTEND_CHAR 表存在且为表类型
local function EnsureExtendTable()
    if ( type(SM_EXTEND_CHAR) ~= "table" ) then
        SM_EXTEND_CHAR = {}
    end
end

-- 切换到指定名称的扩展脚本页面
-- 如果页面不存在则显示空文本
local function SetCurrentPage(pageId)
    EnsureExtendTable()
    currentPageId = pageId
    if ( not SuperMacroFrameExtendText ) then
        return
    end
    local extendText = ""
    if currentPageId and SM_EXTEND_CHAR[currentPageId] then
        extendText = SM_EXTEND_CHAR[currentPageId]
    end
    loadingExtendPage = 1
    SuperMacroFrameExtendText:SetText(extendText)
    loadingExtendPage = nil
    if ( SuperMacroFrameExtendCharLimitText ) then
        SuperMacroFrameExtendCharLimitText:SetText(format(TEXT(SUPERMACROFRAME_EXTEND_CHAR_LIMIT), SM_utf8len(extendText)))
    end
    if ( SuperMacroSaveExtendButton ) then
        SuperMacroSaveExtendButton:SetTextColor(0.5, 0.5, 0.5)
    end
end

-- 保存当前扩展脚本到 SM_EXTEND_CHAR 并更新界面
-- 若编辑框为空则自动删除该页面
local function SaveCurrentPage()
    EnsureExtendTable()
    if ( not currentPageId or not SuperMacroFrameExtendText ) then
        return
    end

    local text=SuperMacroFrameExtendText:GetText()
    if text and text~="" then
        SM_EXTEND_CHAR[currentPageId]=text
    else
        -- 自动删除空页面
        SM_EXTEND_CHAR[currentPageId]=nil
    end

    SuperMacroFrameExtendText:ClearFocus()
    -- 保存后按钮变灰，表示已保存
    if ( SuperMacroSaveExtendButton ) then
        SuperMacroSaveExtendButton:SetTextColor(0.5, 0.5, 0.5)
    end
end

-- 运行所有已保存的扩展脚本
-- 通常在插件加载或保存时执行
local function RunAllScripts()
    EnsureExtendTable()
    for m,e in pairs(SM_EXTEND_CHAR) do
        if ( e ) then
            -- 单个扩展脚本存在语法/运行错误时只提示，不中断加载/保存流程 by 武藤纯子酱 2026.9.10
            local ok, err = pcall(RunScript, e)
            if ( not ok ) then
                local msg = "|cffff5555SuperMacro: Extend 脚本 ["..tostring(m).."] 执行失败： "..tostring(err).."|r"
                if ( SM_print ) then
                    SM_print(msg)
                else
                    DEFAULT_CHAT_FRAME:AddMessage(msg)
                end
            end
        end
    end
end

-- ==================== 外部调用接口 ====================

-- 初始化扩展宏：加载时运行所有已保存脚本
function SuperMacroInitExtend()
    RunAllScripts()
end

-- 保存当前扩展脚本并重新运行所有脚本
function SuperMacroRunAllExtend()
    SaveCurrentPage()
    RunAllScripts()
end

-- 选择扩展脚本页面（切换宏时调用）
-- 自动保存旧页面并加载新页面
function SuperMacroSelectExtend(pageId)
    -- 重复选中同一页时不再保存/重载，避免打断正在输入 by 武藤纯子酱 2026.9.10
    if ( pageId == currentPageId ) then
        return
    end
    SaveCurrentPage()
    SetCurrentPage(pageId)
end

-- 复制扩展脚本内容
-- fromId 源页面名，toId 目标页面名（两者不能相同）
function SuperMacroCopyExtend(fromId, toId)
    EnsureExtendTable()
    assert(fromId ~= toId)
    SaveCurrentPage()

    local text = SM_EXTEND_CHAR[fromId]
    SM_EXTEND_CHAR[toId] = text
end

-- 删除指定扩展脚本页面
function SuperMacroDeleteExtend(pageId)
    EnsureExtendTable()
    SaveCurrentPage()
    SM_EXTEND_CHAR[pageId]=nil
    -- 如果删除的是当前显示页，刷新编辑框
    if pageId == currentPageId then
        SetCurrentPage(pageId)
    end
end

-- ==================== 按钮事件处理 ====================

-- 保存扩展按钮点击：调用全局保存并运行所有脚本
function SuperMacroSaveExtendButton_OnClick()
    SuperMacroRunAllExtend()
end

-- 删除扩展按钮点击：删除当前页面并重新运行脚本
function SuperMacroDeleteExtendButton_OnClick()
    if currentPageId then
        SuperMacroDeleteExtend(currentPageId)
    end
    SuperMacroRunAllExtend()
end

-- 扩展编辑框文本变化处理：更新字符计数和滚动条，按钮变黄色提示未保存
function SuperMacroFrameExtendText_OnTextChanged()
    if ( SuperMacroFrameExtendCharLimitText ) then
        SuperMacroFrameExtendCharLimitText:SetText(format(TEXT(SUPERMACROFRAME_EXTEND_CHAR_LIMIT), SM_utf8len(SuperMacroFrameExtendText:GetText())))
    end
    SuperMacroHandleEditBox(SuperMacroFrameExtendText)
    if ( not loadingExtendPage and SuperMacroSaveExtendButton ) then
        SuperMacroSaveExtendButton:SetTextColor(1, 0.82, 0)
    end
end

-- 按当前选中宏同步 Extend 页面
function SuperMacroUpdateExtendSelection()
    local pageId
    if ( SM_VARS.tabShown == "super" and SuperMacroFrame.selectedSuper ) then
        pageId = GetOrderedSuperMacroInfo(SuperMacroFrame.selectedSuper)
    elseif ( type(SuperMacroFrame.selectedMacro) == "number" and SuperMacroFrame.selectedMacro >= 1 ) then
        pageId = GetMacroInfo(SuperMacroFrame.selectedMacro, "name")
    end
    SuperMacroSelectExtend(pageId)
end

-- 显示/隐藏 Lua（Extend）编辑框，默认显示 by 武藤纯子酱 2026.9.10
function SuperMacroApplyExtendVisibility()
    local show = ( SM_VARS.showExtend ~= 0 );
    local scrollFrame = SuperMacroFrameExtendScrollFrame;
    local background = SuperMacroFrameExtendTextBackground;
    -- 移除 focusButton（原透明焦点按钮已删除） by 武藤纯子酱 2026.9.10
    if ( show ) then
        if ( scrollFrame ) then scrollFrame:Show(); end
        if ( background ) then background:Show(); end
        if ( SuperMacroToggleExtendButton and HIDE_EXTEND ) then
            SuperMacroToggleExtendButton:SetText(HIDE_EXTEND);
        end
    else
        if ( SuperMacroFrameExtendText ) then SuperMacroFrameExtendText:ClearFocus(); end
        if ( scrollFrame ) then scrollFrame:Hide(); end
        if ( background ) then background:Hide(); end
        if ( SuperMacroToggleExtendButton and SHOW_EXTEND ) then
            SuperMacroToggleExtendButton:SetText(SHOW_EXTEND);
        end
    end
end

-- 切换 Lua 编辑框显示/隐藏
function SuperMacroToggleExtend()
    SM_VARS.showExtend = ( SM_VARS.showExtend == 0 ) and 1 or 0;
    SuperMacroApplyExtendVisibility();
end

-- 设置默认工具提示颜色（辅助函数）
function SuperMacroSetDefaultTooltipColor(frame)
    frame:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
    frame:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);
end