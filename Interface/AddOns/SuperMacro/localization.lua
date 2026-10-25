--[[
    localization.lua - 超级宏本地化文件
    提供简体中文(zhCN)和英文(enUS)两种语言的界面文本翻译
    包含界面标签、选项文本、斜杠命令帮助和按键绑定名称的本地化
--]]

if GetLocale() == "zhCN" then
    -- ==================== 简体中文本地化 ====================
    
    -- 字符计数显示文本
    SUPERMACROFRAME_REGULAR_CHAR_LIMIT = "%d/%d 字符已使用";
    SUPERMACROFRAME_EXTEND_CHAR_LIMIT = "%d/"..EXTEND_MAX_LETTERS.." 字符已使用";
    SUPERMACROFRAME_SUPER_CHAR_LIMIT = "%d/"..SUPER_MAX_LETTERS.." 字符已使用";
    
    -- 标签和按钮文本
    REGULAR = "常规宏";
    SUPER = "超级宏";
    SAVE_MACRO = "保存";
    ENTER_EXTEND_LABEL = "输入 LUA 代码:";
    SAVE_EXTEND = "保存代码";
    DELETE_EXTEND = "删除代码";
    SHOW_EXTEND = "显示Lua编辑框";
    HIDE_EXTEND = "隐藏Lua编辑框";
    SAVE_SUPERMACRO = "保存";
    NEW_SUPERMACRO = "新建超级宏";
    DELETE_SUPERMACRO = "删除";
    SUPERMACRO_TITLE = "超级宏";
    SUPERMACRO_BUTTON = "超\n级\n宏";
    SUPERMACRO_BUTTON_H = "超级宏设置";
    SUPERMACRO_OPTIONS = "设置";
    SUPERMACRO_NEW_ACCOUNT = "新建通用宏";
    SUPERMACRO_NEW_CHARACTER = "新建专用宏";
    SUPERMACRO_OPTIONS_TITLE = "超级宏设置";
    SUPERMACRO_MINIMAP = "打开超级宏窗口";

    -- 选项面板文本
    SM_HIDE_ACTION = "隐藏动作条宏名字";
    SM_MACRO_TIP_1 = "显示技能和物品的鼠标提示";
    SM_MACRO_TIP_2 = "显示宏脚本的的鼠标提示";
    SM_PRINT_COLOR = "设置 SM_print() 和 /print 的颜色";
    SM_PRINT_COLOR_EXAMPLE_TEXT = "测试颜色: 你现在能看到我吗?";
    SM_MINIMAP = "小地图显示按钮";
    SM_REPLACE_ICON = "自动替换技能图标";
    SM_CHECK_COOLDOWN = "自动检查CD";
    SM_SHOW_MENU = "显示菜单超级宏按钮";
    SM_EDITBOX_FONT_SIZE = "字体大小"

    -- 斜杠命令帮助文本
    SLASH_SUPERMACRO1 = "/supermacro";
    SUPERMACRO_HELP_LINE1 = "输入 /supermacro 显示帮助"
    SUPERMACRO_HELP_LINE2 = "/macro <宏名字> 运行宏"
    SUPERMACRO_HELP_LINE3 = "/supermacro hideaction 1 或 0 在动作按钮上隐藏或显示宏名称"
    SUPERMACRO_HELP_LINE4 = "/supermacro printcolor <red> <green> <blue>, 每个从0到1改变颜色用于打印"
    SUPERMACRO_HELP_LINE5 = "/supermacro macrotip 0-3, 默认为1"
    SUPERMACRO_HELP_LINE6 = "0是一般, 1是显示法术, 2是显示宏代码, 3是显示法术和/或者代码"

    -- 斜杠命令注册（中文环境同样使用这些命令）
    SLASH_SMUSE1 = "/use";
    SLASH_SMUSE2 = "/smuse";
    SLASH_SMEQUIP1 = "/equip";
    SLASH_SMEQUIP2 = "/smequip";
    SLASH_SMEQUIP3 = "/eq";
    SLASH_SMEQUIP4 = "/smeq";
    SLASH_SMEQUIPOFF1 = "/equipoff";
    SLASH_SMEQUIPOFF2 = "/smequipoff";
    SLASH_SMEQUIPOFF3 = "/eqoff";
    SLASH_SMEQUIPOFF4 = "/smeqoff";
    SLASH_SMUNEQUIP1 = "/unequip";
    SLASH_SMUNEQUIP2 = "/smunequip";
    SLASH_SMUNEQUIP3 = "/uneq";
    SLASH_SMUNEQUIP4 = "/smuneq";
    SLASH_SMPRINT1 = "/print";
    SLASH_SMPRINT2 = "/smprint";
    SLASH_SMPASS1 = "/pass";
    SLASH_SMPASS2 = "/smpass";
    SLASH_SMFAIL1 = "/fail";
    SLASH_SMFAIL2 = "/smfail";
    SLASH_SMDOORDER1 = "/order";
    SLASH_SMDOORDER2 = "/smorder";
    SLASH_SMCHANNEL1 = "/smchan";
    SLASH_SMCHANNEL2 = "/smchannel";
    SLASH_SMIN1 = "/in";
    SLASH_SMIN2 = "/smin";
    SLASH_SMSHIFT1 = "/shift";
    SLASH_SMSHIFT2 = "/smshift";
    SLASH_SMCRAFT1 = "/craft";
    SLASH_SMCRAFT2 = "/smcraft";
    SLASH_SMSAYRANDOM1 = "/sayrandom";
    SLASH_SMSAYRANDOM2 = "/smsayrandom";
    SLASH_SMCANCELBUFF1 = "/unbuff";
    SLASH_SMCANCELBUFF2 = "/smunbuff";
    SLASH_SMRUNSUPER1 = "/smacro";

    -- 按键绑定名称
    BINDING_HEADER_SUPERMACROHEADER = "超级宏";
    BINDING_NAME_TOGGLESUPERMACRO = "切换超级宏框架";
    BINDING_NAME_OPENCHATSCRIPT = "Open Chat /script";
    BINDING_NAME_OPENCHATMACRO = "Open Chat /macro";
    BINDING_NAME_SM_ATTACK = "Attack";
    BINDING_NAME_SM_PETATTACK = "PetAttack";
    BINDING_NAME_SM_MACRO1 = "Macro 1";
    BINDING_NAME_SM_MACRO2 = "Macro 2";
    BINDING_NAME_SM_MACRO3 = "Macro 3";
    BINDING_NAME_SM_MACRO4 = "Macro 4";
    BINDING_NAME_SM_MACRO5 = "Macro 5";
    BINDING_NAME_SM_MACRO6 = "Macro 6";
    BINDING_NAME_SM_MACRO7 = "Macro 7";
    BINDING_NAME_SM_MACRO8 = "Macro 8";
    BINDING_NAME_SM_MACRO9 = "Macro 9";
    BINDING_NAME_SM_MACRO10 = "Macro 10";
    BINDING_NAME_SM_MACRO11 = "Macro 11";
    BINDING_NAME_SM_MACRO12 = "Macro 12";
    BINDING_NAME_SM_MACRO13 = "Macro 13";
    BINDING_NAME_SM_MACRO14 = "Macro 14";
    BINDING_NAME_SM_MACRO15 = "Macro 15";
    BINDING_NAME_SM_MACRO16 = "Macro 16";
    BINDING_NAME_SM_MACRO17 = "Macro 17";
    BINDING_NAME_SM_MACRO18 = "Macro 18";
    BINDING_NAME_SM_MACRO19 = "Macro 19";
    BINDING_NAME_SM_MACRO20 = "Macro 20";
    BINDING_NAME_SM_MACRO21 = "Macro 21";
    BINDING_NAME_SM_MACRO22 = "Macro 22";
    BINDING_NAME_SM_MACRO23 = "Macro 23";
    BINDING_NAME_SM_MACRO24 = "Macro 24";
    BINDING_NAME_SM_MACRO25 = "Macro 25";
    BINDING_NAME_SM_MACRO26 = "Macro 26";
    BINDING_NAME_SM_MACRO27 = "Macro 27";
    BINDING_NAME_SM_MACRO28 = "Macro 28";
    BINDING_NAME_SM_MACRO29 = "Macro 29";
    BINDING_NAME_SM_MACRO30 = "Macro 30";
    BINDING_NAME_SM_MACRO31 = "Macro 31";
    BINDING_NAME_SM_MACRO32 = "Macro 32";
    BINDING_NAME_SM_MACRO33 = "Macro 33";
    BINDING_NAME_SM_MACRO34 = "Macro 34";
    BINDING_NAME_SM_MACRO35 = "Macro 35";
    BINDING_NAME_SM_MACRO36 = "Macro 36";
    BINDING_NAME_SM_SUPERMACRO1 = "SuperMacro 1";
    BINDING_NAME_SM_SUPERMACRO2 = "SuperMacro 2";
    BINDING_NAME_SM_SUPERMACRO3 = "SuperMacro 3";
    BINDING_NAME_SM_SUPERMACRO4 = "SuperMacro 4";
    BINDING_NAME_SM_SUPERMACRO5 = "SuperMacro 5";
    BINDING_NAME_SM_SUPERMACRO6 = "SuperMacro 6";
    BINDING_NAME_SM_SUPERMACRO7 = "SuperMacro 7";
    BINDING_NAME_SM_SUPERMACRO8 = "SuperMacro 8";
    BINDING_NAME_SM_SUPERMACRO9 = "SuperMacro 9";
    BINDING_NAME_SM_SUPERMACRO10 = "SuperMacro 10";
else
    -- ==================== 英文本地化（默认） ====================
    
    -- 字符计数显示文本
    SUPERMACROFRAME_REGULAR_CHAR_LIMIT = "%d/%d Characters Used";
    SUPERMACROFRAME_EXTEND_CHAR_LIMIT = "%d/"..EXTEND_MAX_LETTERS.." Characters Used";
    SUPERMACROFRAME_SUPER_CHAR_LIMIT = "%d/"..SUPER_MAX_LETTERS.." Characters Used";
    
    -- 标签和按钮文本
    REGULAR = "Regular";
    SUPER = "Super";
    SAVE_MACRO = "Save Macro";
    ENTER_EXTEND_LABEL = "Enter Extended LUA code:";
    SAVE_EXTEND = "Save Extend";
    DELETE_EXTEND = "Delete Extend";
    SHOW_EXTEND = "Show LUA Editor";
    HIDE_EXTEND = "Hide LUA Editor";
    SAVE_SUPERMACRO = "Save Super";
    NEW_SUPERMACRO = "New Super";
    DELETE_SUPERMACRO = "Delete Super";
    SUPERMACRO_TITLE = "SuperMacro";
    SUPERMACRO_BUTTON = "M\nA\nC\nR\nO\nS";
    SUPERMACRO_BUTTON_H = "SuperMacro Options";
    SUPERMACRO_OPTIONS = "SM Options";
    SUPERMACRO_NEW_ACCOUNT = "New account macro";
    SUPERMACRO_NEW_CHARACTER = "New character macro";
    SUPERMACRO_OPTIONS_TITLE = "SuperMacro Options";
    SUPERMACRO_MINIMAP = "Open SuperMacro frame";
    
    -- 选项面板文本
    SM_HIDE_ACTION = "Hide names on action bars";
    SM_MACRO_TIP_1 = "Show tooltip about spell or item";
    SM_MACRO_TIP_2 = "Show tooltip about macro's script";
    SM_PRINT_COLOR = "Output color of SM_print() and /print";
    SM_PRINT_COLOR_EXAMPLE_TEXT = "Ex: Can you see me now?";
    SM_MINIMAP = "Show minimap button";
    SM_REPLACE_ICON = "Auto-replace action icons";
    SM_CHECK_COOLDOWN = "Auto-check cooldown for actions";
    SM_SHOW_MENU = "Show menu button";
    SM_EDITBOX_FONT_SIZE = "Script editbox text font size"
    
    -- 斜杠命令帮助文本
    SLASH_SUPERMACRO1 = "/supermacro";
    SUPERMACRO_HELP_LINE1 = "just /supermacro to show help"
    SUPERMACRO_HELP_LINE2 = "/macro <macro_name> to run a macro by name"
    SUPERMACRO_HELP_LINE3 = "/supermacro hideaction 1 or 0 to hide or show macro names on action buttons"
    SUPERMACRO_HELP_LINE4 = "/supermacro printcolor <red> <green> <blue>, each from 0 to 1 to change color used in /print"
    SUPERMACRO_HELP_LINE5 = "/supermacro macrotip 0-3, 1 default"
    SUPERMACRO_HELP_LINE6 = "0 is normal, 1 show spells, 2 show macro code, 3 show  spell and/or code"
    
    -- 斜杠命令注册
    SLASH_SMUSE1 = "/use";
    SLASH_SMUSE2 = "/smuse";
    SLASH_SMEQUIP1 = "/equip";
    SLASH_SMEQUIP2 = "/smequip";
    SLASH_SMEQUIP3 = "/eq";
    SLASH_SMEQUIP4 = "/smeq";
    SLASH_SMEQUIPOFF1 = "/equipoff";
    SLASH_SMEQUIPOFF2 = "/smequipoff";
    SLASH_SMEQUIPOFF3 = "/eqoff";
    SLASH_SMEQUIPOFF4 = "/smeqoff";
    SLASH_SMUNEQUIP1 = "/unequip";
    SLASH_SMUNEQUIP2 = "/smunequip";
    SLASH_SMUNEQUIP3 = "/uneq";
    SLASH_SMUNEQUIP4 = "/smuneq";
    SLASH_SMPRINT1 = "/print";
    SLASH_SMPRINT2 = "/smprint";
    SLASH_SMPASS1 = "/pass";
    SLASH_SMPASS2 = "/smpass";
    SLASH_SMFAIL1 = "/fail";
    SLASH_SMFAIL2 = "/smfail";
    SLASH_SMDOORDER1 = "/order";
    SLASH_SMDOORDER2 = "/smorder";
    SLASH_SMCHANNEL1 = "/smchan";
    SLASH_SMCHANNEL2 = "/smchannel";
    SLASH_SMIN1 = "/in";
    SLASH_SMIN2 = "/smin";
    SLASH_SMSHIFT1 = "/shift";
    SLASH_SMSHIFT2 = "/smshift";
    SLASH_SMCRAFT1 = "/craft";
    SLASH_SMCRAFT2 = "/smcraft";
    SLASH_SMSAYRANDOM1 = "/sayrandom";
    SLASH_SMSAYRANDOM2 = "/smsayrandom";
    SLASH_SMCANCELBUFF1 = "/unbuff";
    SLASH_SMCANCELBUFF2 = "/smunbuff";
    SLASH_SMRUNSUPER1 = "/smacro";
    
    -- 按键绑定名称
    BINDING_HEADER_SUPERMACROHEADER = "SuperMacro";
    BINDING_NAME_TOGGLESUPERMACRO = "Toggle SuperMacro Frame";
    BINDING_NAME_OPENCHATSCRIPT = "Open Chat /script";
    BINDING_NAME_OPENCHATMACRO = "Open Chat /macro";
    BINDING_NAME_SM_ATTACK = "Attack";
    BINDING_NAME_SM_PETATTACK = "PetAttack";
    BINDING_NAME_SM_MACRO1 = "Macro 1";
    BINDING_NAME_SM_MACRO2 = "Macro 2";
    BINDING_NAME_SM_MACRO3 = "Macro 3";
    BINDING_NAME_SM_MACRO4 = "Macro 4";
    BINDING_NAME_SM_MACRO5 = "Macro 5";
    BINDING_NAME_SM_MACRO6 = "Macro 6";
    BINDING_NAME_SM_MACRO7 = "Macro 7";
    BINDING_NAME_SM_MACRO8 = "Macro 8";
    BINDING_NAME_SM_MACRO9 = "Macro 9";
    BINDING_NAME_SM_MACRO10 = "Macro 10";
    BINDING_NAME_SM_MACRO11 = "Macro 11";
    BINDING_NAME_SM_MACRO12 = "Macro 12";
    BINDING_NAME_SM_MACRO13 = "Macro 13";
    BINDING_NAME_SM_MACRO14 = "Macro 14";
    BINDING_NAME_SM_MACRO15 = "Macro 15";
    BINDING_NAME_SM_MACRO16 = "Macro 16";
    BINDING_NAME_SM_MACRO17 = "Macro 17";
    BINDING_NAME_SM_MACRO18 = "Macro 18";
    BINDING_NAME_SM_MACRO19 = "Macro 19";
    BINDING_NAME_SM_MACRO20 = "Macro 20";
    BINDING_NAME_SM_MACRO21 = "Macro 21";
    BINDING_NAME_SM_MACRO22 = "Macro 22";
    BINDING_NAME_SM_MACRO23 = "Macro 23";
    BINDING_NAME_SM_MACRO24 = "Macro 24";
    BINDING_NAME_SM_MACRO25 = "Macro 25";
    BINDING_NAME_SM_MACRO26 = "Macro 26";
    BINDING_NAME_SM_MACRO27 = "Macro 27";
    BINDING_NAME_SM_MACRO28 = "Macro 28";
    BINDING_NAME_SM_MACRO29 = "Macro 29";
    BINDING_NAME_SM_MACRO30 = "Macro 30";
    BINDING_NAME_SM_MACRO31 = "Macro 31";
    BINDING_NAME_SM_MACRO32 = "Macro 32";
    BINDING_NAME_SM_MACRO33 = "Macro 33";
    BINDING_NAME_SM_MACRO34 = "Macro 34";
    BINDING_NAME_SM_MACRO35 = "Macro 35";
    BINDING_NAME_SM_MACRO36 = "Macro 36";
    BINDING_NAME_SM_SUPERMACRO1 = "SuperMacro 1";
    BINDING_NAME_SM_SUPERMACRO2 = "SuperMacro 2";
    BINDING_NAME_SM_SUPERMACRO3 = "SuperMacro 3";
    BINDING_NAME_SM_SUPERMACRO4 = "SuperMacro 4";
    BINDING_NAME_SM_SUPERMACRO5 = "SuperMacro 5";
    BINDING_NAME_SM_SUPERMACRO6 = "SuperMacro 6";
    BINDING_NAME_SM_SUPERMACRO7 = "SuperMacro 7";
    BINDING_NAME_SM_SUPERMACRO8 = "SuperMacro 8";
    BINDING_NAME_SM_SUPERMACRO9 = "SuperMacro 9";
    BINDING_NAME_SM_SUPERMACRO10 = "SuperMacro 10";
end