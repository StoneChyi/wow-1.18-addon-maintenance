--[[
    SM_Options.lua - 超级宏选项面板逻辑
    处理设置窗口的显示、各选项控件的状态同步、
    颜色选择器、动作条宏名称显示切换、菜单按钮、
    等宽字体切换等功能。
--]]

-- 复选框与变量映射表
SuperMacroOptionsFrameCheckButtons = { };
SuperMacroOptionsFrameCheckButtons["SM_HIDE_ACTION"] = { index = 1, var = "hideAction"};
SuperMacroOptionsFrameCheckButtons["SM_MACRO_TIP_1"] = { index = 2, var = "macroTip1"};
SuperMacroOptionsFrameCheckButtons["SM_MACRO_TIP_2"] = { index = 3, var = "macroTip2"};
SuperMacroOptionsFrameCheckButtons["SM_MINIMAP"] = { index = 4, var = "minimap"};
SuperMacroOptionsFrameCheckButtons["SM_REPLACE_ICON"] = { index = 5, var = "replaceIcon"};
SuperMacroOptionsFrameCheckButtons["SM_CHECK_COOLDOWN"] = { index = 6, var = "checkCooldown"};
SuperMacroOptionsFrameCheckButtons["SM_SHOW_MENU"] = { index = 7, var = "showMenu"};

-- 颜色选择器与变量映射表
SuperMacroOptionsFrameColorSwatches = { };
SuperMacroOptionsFrameColorSwatches["SM_PRINT_COLOR"] = { index = 1, var = "printColor", exampleText=SM_PRINT_COLOR_EXAMPLE_TEXT};

-- 输入框与变量映射表（仅保留字体大小；窗口宽/高设置已移除） by 武藤纯子酱 2026.9.10
SuperMacroOptionsFrameEditBoxes = { };
SuperMacroOptionsFrameEditBoxes["SM_EDITBOX_FONT_SIZE"] = { index = 1, var = "editBoxFontSize"};

-- 选项面板显示时调用，初始化所有控件的状态
function SuperMacroOptionsFrame_OnShow()
    SuperMacroOptionsFrame:ClearAllPoints()
    SuperMacroOptionsFrame:SetPoint("CENTER", nil, "CENTER", 0, 0)

    -- 清除编辑框焦点
    SuperMacroFrameText:ClearFocus();
    SuperMacroFrameSuperText:ClearFocus();

    PlaySound("igMainMenuOption")

    -- 禁用主窗口的一些按钮，防止在设置时误操作
    SuperMacroEditButton:Disable();
    SuperMacroDeleteButton:Disable();
    SuperMacroNewAccountButton:Disable();
    SuperMacroNewCharacterButton:Disable();

    -- 遍历所有复选框，设置文本和选中状态
    for k, v in SuperMacroOptionsFrameCheckButtons do
        local button = getglobal("SuperMacroOptionsFrameCheckButton"..v.index);
        local string = getglobal("SuperMacroOptionsFrameCheckButton"..v.index.."Text");
        local checked;
        checked = SM_VARS[v.var];
        button:SetChecked(checked);
        string:SetText(TEXT(getglobal(k)));
    end

    -- 遍历颜色选择器控件，设置文本和颜色
    for k, v in SuperMacroOptionsFrameColorSwatches do
        local button = getglobal("SuperMacroOptionsFrameColorSwatch"..v.index);
        button.var = v.var;
        local string = getglobal("SuperMacroOptionsFrameColorSwatch"..v.index.."Text");
        string:SetText(TEXT(getglobal(k)));
        button.r = SM_VARS[v.var].r;
        button.g = SM_VARS[v.var].g;
        button.b = SM_VARS[v.var].b;
        getglobal(button:GetName().."NormalTexture"):SetVertexColor( button.r, button.g, button.b );
        button.opacity = 1;
        local example = getglobal("SuperMacroOptionsFrameColorSwatch"..v.index.."ExampleText");
        if ( v.exampleText ) then
            example:SetText(v.exampleText);
            example:SetTextColor(button.r, button.g, button.b);
        end
    end

    -- 遍历输入框控件，设置文本和数值
    for k, v in SuperMacroOptionsFrameEditBoxes do
        local button = getglobal("SuperMacroOptionsFrameEditBox"..v.index);
        local string = getglobal("SuperMacroOptionsFrameEditBox"..v.index.."Text");
        local text = SM_VARS[v.var];
        button:SetText(text);
        string:SetText(TEXT(getglobal(k)));
    end
end

-- 选项面板隐藏时调用，恢复主窗口按钮状态并更新配置
function SuperMacroOptionsFrame_OnHide()
    PlaySound("igMainMenuOptionCheckBoxOff")
    SuperMacroEditButton:Enable();
    SuperMacroDeleteButton:Enable();
    SuperMacroNewAccountButton:Enable();
    SuperMacroNewCharacterButton:Enable();
    SuperMacroUpdateConfig();
    SuperMacroFrame_Update();
end

-- 打开颜色选择器弹窗
function SuperMacroOptions_OpenColorPicker(this)
    -- 设置颜色改变时的回调函数
    ColorPickerFrame.func = function()
        SM_VARS[this.var].r, SM_VARS[this.var].g, SM_VARS[this.var].b = ColorPickerFrame:GetColorRGB();
        -- 修正：确认取色后误隐藏了设置面板，与 cancel/opacity 回调不一致，改为保持显示 by 武藤纯子酱 2026.9.10
        SuperMacroOptionsFrame:Show();
    end
    ColorPickerFrame.hasOpacity = this.hasOpacity;
    ColorPickerFrame.opacityFunc = function ()
        SuperMacroOptionsFrame:Show()
    end
    ColorPickerFrame.opacity = this.opacity;
    ColorPickerFrame:SetColorRGB(this.r, this.g, this.b);
    -- 保存之前的值，用于取消时恢复
    ColorPickerFrame.previousValues = {r = this.r, g = this.g, b = this.b, opacity = this.opacity};
    ColorPickerFrame.cancelFunc = function()
        SM_VARS[this.var].r, SM_VARS[this.var].g, SM_VARS[this.var].b = ColorPickerFrame.previousValues.r, ColorPickerFrame.previousValues.g, ColorPickerFrame.previousValues.b;
        SuperMacroOptionsFrame:Show()
    end
    ShowUIPanel(ColorPickerFrame);
end

-- 隐藏或显示动作条上的宏名称
function HideActionText()
    local func=ActionButton1Name.Show;
    if ( SM_VARS.hideAction == 1 ) then
        func = ActionButton1Name.Hide;
    elseif ( SM_VARS.hideAction == 0 ) then
        func = ActionButton1Name.Show;
    end
    -- 遍历标准动作条 1-12
    for i = 1,12 do
        if ( getglobal("ActionButton"..i) ) then
            func(getglobal("ActionButton"..i.."Name"));
        else
            break;
        end
        if ( getglobal("BonusActionButton"..i.."Name")) then
            func(getglobal("BonusActionButton"..i.."Name"));
        end
        if ( getglobal("MultiBarBottomLeftButton"..i.."Name") ) then
            func(getglobal("MultiBarBottomLeftButton"..i.."Name"));
            func(getglobal("MultiBarBottomRightButton"..i.."Name"))
            func(getglobal("MultiBarLeftButton"..i.."Name"));
            func(getglobal("MultiBarRightButton"..i.."Name"));
        end
    end
    -- 支持 FlexBar 等动作条插件
    for i = 1,72 do
        if ( getglobal("FUActionButton"..i) ) then
            func(getglobal("FUActionButton"..i.."Name"));
        else
            break;
        end
    end
    -- 支持 Discord 动作条
    for i = 1,120 do
        if ( getglobal("DiscordActionButton"..i.."Name")) then
            func(getglobal("DiscordActionButton"..i.."Name"));
        else
            break;
        end
    end
end

-- 根据设置切换游戏菜单中的超级宏按钮显示
function ToggleSMMenu()
    if ( SM_VARS.showMenu == 1 ) then
        GameMenuButtonSuperMacro:Show();
    else
        GameMenuButtonSuperMacro:Hide();
    end
end

-- 已移除：ToggleSMWordWrap（换行）与等宽字体选项，均不受支持 by 武藤纯子酱 2026.9.10