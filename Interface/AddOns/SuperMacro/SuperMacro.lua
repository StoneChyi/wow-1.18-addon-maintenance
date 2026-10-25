--[[
    SuperMacro.lua - 超级宏主框架
    插件入口，定义主窗口、宏列表管理、编辑框逻辑、
    保存/删除/新建宏、超级宏的创建和排序、动作映射、
    宏执行引擎、别名替换等功能。
--]]

-- 版本号
SUPERMACRO_VERSION = "3.25";

-- 注册面板行为：允许在死亡时打开，可推动其他面板
UIPanelWindows["SuperMacroFrame"] = { area = "left", pushable = 7, whileDead = 1 };
UIPanelWindows["SuperMacroOptionsFrame"] = { area = "left", pushable = 0, whileDead = 1 };

-- 常量定义
MACRO_ROWS = 3;
MACRO_COLUMNS = 20;
MACROS_REGULAR_SHOWN = 36;          -- 常规宏显示数量（18账号+18角色）
MACROS_SUPER_SHOWN = MACRO_ROWS * MACRO_COLUMNS;  -- 超级宏每页显示数量（60个）
MAX_MACROS = 18;                    -- 每种宏（账号/角色）的最大数量
--MAX_TOTAL_MACROS = 36;
NUM_MACRO_ICONS_SHOWN = 30;         -- 图标选择弹窗显示数量
NUM_ICONS_PER_ROW = 5;
NUM_ICON_ROWS = 6;
MACRO_ROW_HEIGHT = 36;
MACRO_ICON_ROW_HEIGHT = 36;
--MACRO_MAX_LETTERS = 255;
EXTEND_MAX_LETTERS = 50000;         -- 扩展脚本最大字符数
SUPER_MAX_LETTERS = 50000;          -- 超级宏最大字符数
PRINT_COLOR_DEF = {r=1, g=1, b=1}; -- 默认打印颜色

-- 全局变量声明（SavedVariables）
SM_VARS = {};                       -- 选项设置表
SM_EXTEND_CHAR = {};                     -- 扩展脚本存储表
SM_SUPER_CHAR = {};                      -- 超级宏存储表（名称->{名称,纹理,内容}）
SM_ORDERED = {};                    -- 超级宏的排序后列表
SM_ACTION = {};                     -- 保存当前角色动作条上的超级宏映射
SM_ACTION_CHAR = {};               -- 各角色的超级宏动作映射（Saved per character）
SM_MACRO_ICON = {};                 -- 宏图标ID映射表
SM_ACTION_SPELL = {};               -- 缓存宏中的第一个法术/物品信息
SM_ACTION_SPELL.regular = {};
SM_ACTION_SPELL.super = {};
SM_AliasFunctions = {};             -- 别名替换函数队列
SM_AliasFunctions.low = 0;
SM_AliasFunctions.high = 0;
SM_AliasFunctions[0] = function (body) return body; end

-- ==================== UTF-8字符计数（兼容中文） ====================
function SM_utf8len(str)
    if ( not str ) then
        return 0;
    end
    str = tostring(str);
    local bytes = strlen(str);
    local byteFunc = strbyte or string.byte;
    local count = 0;
    local i = 1;
    while ( i <= bytes ) do
        local c = byteFunc(str, i);
        if ( not c ) then
            break;
        elseif ( c < 128 ) then
            i = i + 1;
        elseif ( c < 224 ) then
            i = i + 2;
        elseif ( c < 240 ) then
            i = i + 3;
        elseif ( c < 248 ) then
            i = i + 4;
        else
            i = i + 1;
        end
        count = count + 1;
    end
    return count;
end

-- 获取常规宏的最大字符数（兼容暴雪UI的不同本地化）
function SuperMacro_GetRegularMacroMaxLetters()
    local maxLetters
    if ( MACROFRAME_CHAR_LIMIT and type(MACROFRAME_CHAR_LIMIT) == "string" ) then
        _, _, maxLetters = string.find(MACROFRAME_CHAR_LIMIT, "/(%d+)")
        if ( not maxLetters ) then
            _, _, maxLetters = string.find(MACROFRAME_CHAR_LIMIT, "最多(%d+)")
        end
        maxLetters = tonumber(maxLetters)
        if ( maxLetters and maxLetters > 0 ) then
            return maxLetters
        end
    end
    maxLetters = tonumber(MACRO_MAX_LETTERS)
    if ( maxLetters and maxLetters > 0 ) then
        return maxLetters
    end
    return 255
end

-- ==================== 数据表完整性检查 ====================
local SM_ORDERED_DIRTY = 1

-- 复制打印颜色表并补齐 r/g/b，避免异常存档导致取色报错 by 武藤纯子酱 2026.9.10
local function SuperMacroCopyColor(color)
    if ( type(color) ~= "table" ) then
        return { r = PRINT_COLOR_DEF.r, g = PRINT_COLOR_DEF.g, b = PRINT_COLOR_DEF.b };
    end
    return {
        r = color.r or PRINT_COLOR_DEF.r,
        g = color.g or PRINT_COLOR_DEF.g,
        b = color.b or PRINT_COLOR_DEF.b,
    };
end

-- 超级宏排序函数（按名称字母顺序，不区分大小写）
local function SuperMacroSortNames(a, b)
    a = string.lower(tostring(a or ""));
    b = string.lower(tostring(b or ""));
    return a < b;
end

-- 标记排序列表需要更新
local function SuperMacroMarkOrderedDirty()
    SM_ORDERED_DIRTY = 1;
end

-- 存档表类型兜底，异常表被重置时标记排序需要重建 by 武藤纯子酱 2026.9.10
local function SuperMacroEnsureSavedTables()
    if ( type(SM_VARS) ~= "table" ) then SM_VARS = {}; end
    if ( type(SM_EXTEND_CHAR) ~= "table" ) then SM_EXTEND_CHAR = {}; end
    if ( type(SM_SUPER_CHAR) ~= "table" ) then
        SM_SUPER_CHAR = {};
        SuperMacroMarkOrderedDirty();
    end
    if ( type(SM_ACTION_CHAR) ~= "table" ) then SM_ACTION_CHAR = {}; end
    if ( type(SM_ORDERED) ~= "table" ) then
        SM_ORDERED = {};
        SuperMacroMarkOrderedDirty();
    end
    if ( type(SM_ACTION_SPELL) ~= "table" ) then SM_ACTION_SPELL = {}; end
    if ( type(SM_ACTION_SPELL.regular) ~= "table" ) then SM_ACTION_SPELL.regular = {}; end
    if ( type(SM_ACTION_SPELL.super) ~= "table" ) then SM_ACTION_SPELL.super = {}; end
end

-- 确保排序列表是最新的
local function SuperMacroEnsureOrdered()
    SuperMacroEnsureSavedTables();
    if ( SM_ORDERED_DIRTY or not SM_ORDERED ) then
        SM_ORDERED = SortSuperMacroList();
        SM_ORDERED_DIRTY = nil;
    end
end

-- 当前角色的存档键 by 武藤纯子酱 2026.9.10
local function SuperMacroGetPlayerKey()
    return UnitName("player").." of "..GetRealmName();
end

-- 由贴图文件名/索引反查图标索引 by 武藤纯子酱 2026.9.10
local function SuperMacroGetMacroIconIndex(texture)
    if ( not texture ) then
        return;
    end
    local index = tonumber(texture);
    if ( index and GetMacroIconInfo(index) ) then
        return index;
    end
    if ( SM_MACRO_ICON[texture] ) then
        return SM_MACRO_ICON[texture];
    end
    if ( GetStringAfterLastSlash ) then
        return SM_MACRO_ICON[GetStringAfterLastSlash(texture)];
    end
end

-- 设置弹窗当前贴图与图标索引 by 武藤纯子酱 2026.9.10
local function SuperMacroSetPopupTexture(texture)
    local index = tonumber(texture);
    if ( index ) then
        texture = GetMacroIconInfo(index);
    end
    SuperMacroPopupFrame.selectedTexture = texture;
    SuperMacroPopupFrame.selectedIcon = SuperMacroGetMacroIconIndex(texture);
end

-- 取弹窗当前贴图（优先精确贴图，其次图标索引） by 武藤纯子酱 2026.9.10
local function SuperMacroGetPopupTexture()
    if ( SuperMacroPopupFrame.selectedTexture ) then
        return SuperMacroPopupFrame.selectedTexture;
    end
    if ( SuperMacroPopupFrame.selectedIcon ) then
        return GetMacroIconInfo(SuperMacroPopupFrame.selectedIcon);
    end
end

-- 检查主窗口是否正在拖动
function SuperMacroFrame_IsDragging()
    return SuperMacroFrame and SuperMacroFrame.isDragging;
end

-- 拖动开始时清除所有编辑框焦点，防止出错
local function SuperMacroFrame_ClearEditFocusForDrag()
    if ( GameTooltip ) then GameTooltip:Hide(); end
    if ( SM_Tooltip ) then SM_Tooltip:Hide(); end
    if ( SuperMacroFrameText ) then SuperMacroFrameText:ClearFocus(); end
    if ( SuperMacroFrameSuperText ) then SuperMacroFrameSuperText:ClearFocus(); end
    if ( SuperMacroFrameExtendText ) then SuperMacroFrameExtendText:ClearFocus(); end
    if ( SuperMacroPopupEditBox ) then SuperMacroPopupEditBox:ClearFocus(); end
end

-- 拖动开始
local function OnDragStart()
    if ( not this ) then return; end
    if ( SuperMacroFrame ) then
        SuperMacroFrame.isDragging = 1;
        SuperMacroFrame.needsUpdateAfterDrag = nil;
        SuperMacroFrame.updateConfigAfterDrag = nil;
    end
    SuperMacroFrame_ClearEditFocusForDrag();
    this:StartMoving();
end

-- 拖动结束，处理延迟更新
local function OnDragStop()
    if ( this ) then this:StopMovingOrSizing(); end
    local needsUpdate;
    local needsConfig;
    if ( SuperMacroFrame ) then
        needsUpdate = SuperMacroFrame.needsUpdateAfterDrag;
        needsConfig = SuperMacroFrame.updateConfigAfterDrag;
        SuperMacroFrame.isDragging = nil;
        SuperMacroFrame.needsUpdateAfterDrag = nil;
        SuperMacroFrame.updateConfigAfterDrag = nil;
    end
    if ( needsConfig and SuperMacroUpdateConfig ) then SuperMacroUpdateConfig(); end
    if ( needsUpdate ) then SuperMacroFrame_Update(); end
end

-- 游戏主菜单按钮 GameMenuButtonSuperMacro 现由 SM_UI.lua 用 Lua 动态创建（原 XML 声明已移除） by 武藤纯子酱 2026.9.10

-- 逐槽探测所有常规宏
-- 本客户端宏编号连续、且 GetNumMacros() 返回值不能可靠反映槽位是否存在
-- （账号宏可能远超18，角色宏紧随其后），故用 pcall 逐槽探测真实存在的宏 by 武藤纯子酱 2026.9.10
local function SuperMacroScanRegularMacros()
    local slots = {};
    local count = 0;
    for i = 1, MAX_MACROS*2 do
        local ok, nm, tx, bd, loc = pcall(GetMacroInfo, i);
        if ( ok and nm and nm ~= "" ) then
            slots[i] = { name = nm, texture = tx, body = bd, isLocal = loc };
            count = count + 1;
        end
    end
    return slots, count;
end

-- 删除常规宏后选择最接近的有效宏
local function SuperMacroSelectNearestRegularMacro(preferredIndex)
    if ( type(preferredIndex) ~= "number" or preferredIndex < 1 ) then
        preferredIndex = 1;
    end
    local slots = SuperMacroScanRegularMacros();
    local firstAfter, lastSlot;
    for i = 1, MAX_MACROS*2 do
        if ( slots[i] ) then
            lastSlot = i;
            if ( not firstAfter and i >= preferredIndex ) then
                firstAfter = i;
            end
        end
    end
    if ( firstAfter ) then
        SuperMacroFrame_SelectMacro(firstAfter);
    elseif ( lastSlot ) then
        SuperMacroFrame_SelectMacro(lastSlot);
    else
        SuperMacroFrame_SelectMacro(nil);
    end
end

-- ==================== 主窗口加载 ====================
function SuperMacroFrame_OnLoad()
    PanelTemplates_SetNumTabs(this, 2);
    SuperMacroFrame.selectedTab = 1;
    PanelTemplates_UpdateTabs(this);
    SuperMacroFrameTitle:SetText(SUPERMACRO_TITLE.." "..SUPERMACRO_VERSION);
    SuperMacroFrameCharacterMacroText:SetText(format(CHARACTER_SPECIFIC_MACROS, UnitName("player")));
    SM_UpdateAction();  -- 更新动作条挂钩
    this:RegisterEvent("VARIABLES_LOADED");
    this:RegisterEvent("TRADE_SKILL_SHOW");
    this:RegisterEvent("CRAFT_SHOW");
    this:RegisterEvent("PLAYER_ENTERING_WORLD");
    lastActionUsed = nil;
    SuperMacroFrame_SetAccountMacros();
    SM_MACRO_ICON = SM_LoadMacroIcons();
    if ( not Print ) then Print = Printd; end  -- 确保有打印函数

    -- 设置窗口可拖动
    SuperMacroFrame:SetMovable(true)
    SuperMacroFrame:EnableMouse(true)
    SuperMacroFrame:RegisterForDrag("LeftButton")
    SuperMacroFrame:SetScript("OnDragStart", OnDragStart)
    SuperMacroFrame:SetScript("OnDragStop", OnDragStop)

    -- 根据上次保存的标签页显示对应按钮
    if SM_VARS.tabShown == "regular" then
        SuperMacroDeleteButton:Show()
        SuperMacroSaveButton:Show()
        SuperMacroDeleteSuperButton:Hide()
        SuperMacroSaveSuperButton:Hide()
        SuperMacroNewSuperButton:Hide()
        SuperMacroExitButton:Show()
        if ( SuperMacroExitSuperButton ) then SuperMacroExitSuperButton:Hide() end
    else
        SuperMacroDeleteButton:Hide()
        SuperMacroSaveButton:Hide()
        SuperMacroDeleteSuperButton:Show()
        SuperMacroSaveSuperButton:Show()
        SuperMacroNewSuperButton:Show()
        SuperMacroExitButton:Hide()
        if ( SuperMacroExitSuperButton ) then SuperMacroExitSuperButton:Show() end
    end
end

-- 窗口显示时更新内容并播放音效
function SuperMacroFrame_OnShow()
    SuperMacroFrame_Update();
    PlaySound("igCharacterInfoOpen");

    -- 恢复保存的窗口位置
    SuperMacroFrame:ClearAllPoints()
    if SuperMacroFrame.savedPoint then
        SuperMacroFrame:SetPoint("TOPLEFT", nil, "TOPLEFT", SuperMacroFrame.savedPoint.x, SuperMacroFrame.savedPoint.y)
    else
        local y = (math.floor(UIParent:GetTop()) - SuperMacroFrame:GetHeight()) / 2
        SuperMacroFrame:SetPoint("TOPLEFT", nil, "TOPLEFT", 0, -y)
    end
    if ( SuperMacroUpdateExtendSelection ) then
        SuperMacroUpdateExtendSelection()
    end
    if ( SuperMacroApplyExtendVisibility ) then
        SuperMacroApplyExtendVisibility()
    end
end

-- 保存当前编辑框中的文本
function SuperMacroFrame_SaveCurrentText()
    if ( SM_VARS.tabShown == "super" ) then
        SuperMacroFrame_SaveSuperMacro();
    else
        SuperMacroFrame_SaveMacro();
    end
end

-- 窗口隐藏时保存位置、清除焦点并隐藏子窗口，同时运行扩展脚本
function SuperMacroFrame_OnHide()
    SuperMacroFrame.savedPoint = {}
    _, _, _, SuperMacroFrame.savedPoint.x, SuperMacroFrame.savedPoint.y  = SuperMacroFrame:GetPoint()

    -- 清除所有编辑框焦点，防止按Esc关闭时崩溃
    SuperMacroFrameText:ClearFocus();
    SuperMacroFrameSuperText:ClearFocus();
    SuperMacroFrameExtendText:ClearFocus();

    SuperMacroPopupFrame:Hide();
    SuperMacroOptionsFrame:Hide();

    -- 如果颜色选择框打开，隐藏它
    if ColorPickerFrame:IsVisible() then
        ColorPickerFrame:Hide();
    end

    SuperMacroFrame_SaveCurrentText();
    PlaySound("igCharacterInfoClose");
    SuperMacroRunAllExtend()  -- 保存并运行扩展脚本
end

-- 首次加载时优先显示账号通用宏
function SuperMacroFrame_SetAccountMacros()
    -- 逐槽探测，选中第一个存在的常规宏 by 武藤纯子酱 2026.9.10
    local slots = SuperMacroScanRegularMacros();
    for i = 1, MAX_MACROS*2 do
        if ( slots[i] ) then
            SuperMacroFrame_SelectMacro(i);
            return;
        end
    end
    SuperMacroFrame_SelectMacro(nil);
end

-- 选择角色专用宏
function SuperMacroFrame_SetCharacterMacros()
    -- 选中第一个 isLocal 的角色专用宏 by 武藤纯子酱 2026.9.10
    local slots = SuperMacroScanRegularMacros();
    for i = 1, MAX_MACROS*2 do
        if ( slots[i] and slots[i].isLocal ) then
            SuperMacroFrame_SelectMacro(i);
            return;
        end
    end
    SuperMacroFrame_SelectMacro(nil);
end

-- 根据当前标签页切换显示常规宏或超级宏界面
function SuperMacroFrame_ShowFrame( tab )
    if ( tab~="regular" ) then
        SuperMacroFrameRegularFrame:Hide();
    else
        SuperMacroFrameRegularFrame:Show();
    end
    if ( tab~="super" ) then
        SuperMacroFrameSuperFrame:Hide();
    else
        SuperMacroEnsureOrdered();
        SuperMacroFrameSuperFrame:Show();
    end

    -- 控制按钮可见性
    if tab == "regular" then
        SuperMacroDeleteButton:Show()
        SuperMacroSaveButton:Show()
        SuperMacroDeleteSuperButton:Hide()
        SuperMacroSaveSuperButton:Hide()
        SuperMacroNewSuperButton:Hide()
        SuperMacroNewAccountButton:Show()
        SuperMacroNewCharacterButton:Show()
        SuperMacroExitButton:Show()
        if ( SuperMacroExitSuperButton ) then SuperMacroExitSuperButton:Hide() end
    else  -- super
        SuperMacroDeleteButton:Hide()
        SuperMacroSaveButton:Hide()
        SuperMacroDeleteSuperButton:Show()
        SuperMacroSaveSuperButton:Show()
        SuperMacroNewSuperButton:Show()
        SuperMacroNewAccountButton:Hide()
        SuperMacroNewCharacterButton:Hide()
        SuperMacroExitButton:Hide()
        if ( SuperMacroExitSuperButton ) then SuperMacroExitSuperButton:Show() end
    end

    -- 重新锚定扩展编辑框
    SuperMacroUpdateConfig()
end

-- 主更新函数：刷新宏列表、按钮状态、编辑框内容等
function SuperMacroFrame_Update()
    if ( SuperMacroFrame_IsDragging and SuperMacroFrame_IsDragging() ) then
        SuperMacroFrame.needsUpdateAfterDrag = 1;
        return;
    end

    -- ==================== 更新常规宏面板 ====================
    if ( SM_VARS.tabShown=="regular" ) then
        SuperMacroFrame_ShowFrame("regular");
        local macroButton, macroIcon, macroName;
        local name, texture, body, isLocal;
        local selectedName, selectedBody, selectedIcon;

        -- 逐槽探测所有常规宏（GetNumMacros 返回值不能可靠反映槽位是否存在） by 武藤纯子酱 2026.9.10
        local macroSlots, macroCount = SuperMacroScanRegularMacros();

        -- 选中宏失效时自动选中第一个存在的宏 by 武藤纯子酱 2026.9.10
        local selectedMacro = SuperMacroFrame.selectedMacro;
        if ( macroCount > 0 and ( type(selectedMacro) ~= "number" or not macroSlots[selectedMacro] ) ) then
            for i = 1, MAX_MACROS*2 do
                if ( macroSlots[i] ) then SuperMacroFrame_SelectMacro(i); break; end
            end
        end

        -- 弹窗打开时禁用部分按钮
        if ( SuperMacroPopupFrame:IsVisible() ) then
            SuperMacroEditButton:Disable();
            SuperMacroDeleteButton:Disable();
            SuperMacroSaveButton:Disable();
        else
            SuperMacroEditButton:Enable();
            SuperMacroDeleteButton:Enable();
            SuperMacroSaveButton:Enable();
        end

        -- 没有选中宏或没有宏时，禁用相应按钮并清空显示
        if ( not SuperMacroFrame.selectedMacro or macroCount==0 ) then
            SuperMacroDeleteButton:Disable();
            SuperMacroEditButton:Disable();
            SuperMacroSaveButton:Disable();
            SuperMacroFrameSelectedMacroName:SetText('');
            SuperMacroFrameText:SetText('');
            SuperMacroFrameSelectedMacroButtonIcon:SetTexture('');
        end

        -- 更新所有宏按钮（按绝对槽位连续填充，槽位存在才启用）
        for macroID = 1, MAX_MACROS*2 do
            getglobal("SuperMacroButton"..macroID.."ID"):SetText(macroID);
            macroButton = getglobal("SuperMacroButton"..macroID);
            macroIcon = getglobal("SuperMacroButton"..macroID.."Icon");
            macroName = getglobal("SuperMacroButton"..macroID.."Name");
            local slot = macroSlots[macroID];
            if ( slot ) then
                macroButton:SetID(macroID);
                macroIcon:SetTexture(slot.texture);
                macroName:SetText(slot.name);
                macroButton:Enable();
                -- 高亮选中的宏
                if ( macroID == SuperMacroFrame.selectedMacro ) then
                    macroButton:SetChecked(1);
                    SuperMacroFrameSelectedMacroName:SetText(slot.name);
                    SuperMacroFrameText:SetText(slot.body);
                    SuperMacroFrameSelectedMacroButton:SetID(macroID);
                    SuperMacroFrameSelectedMacroButtonIcon:SetTexture(slot.texture);
                else
                    macroButton:SetChecked(0);
                end
            else
                macroButton:SetChecked(0);
                macroIcon:SetTexture("");
                macroName:SetText("");
                macroButton:Disable();
            end
        end

        -- 更新新建按钮状态（上限处理，优先使用客户端上限常量） by 武藤纯子酱 2026.9.10
        local accountLimit = MAX_ACCOUNT_MACROS or MAX_MACROS;
        local characterLimit = MAX_CHARACTER_MACROS or MAX_MACROS;
        local numAccountMacros, numCharacterMacros = GetNumMacros();
        if ( (numAccountMacros or 0) >= accountLimit ) then
            SuperMacroNewAccountButton:Disable();
        else
            SuperMacroNewAccountButton:Enable();
        end
        if ( (numCharacterMacros or 0) >= characterLimit ) then
            SuperMacroNewCharacterButton:Disable();
        else
            SuperMacroNewCharacterButton:Enable();
        end
    end  -- 结束常规宏更新

    -- ==================== 更新超级宏面板 ====================
    if ( SM_VARS.tabShown=="super" ) then
        SuperMacroFrame_ShowFrame("super");
        local numMacros=GetNumSuperMacros(); -- 移除恒为 nil 的 SM_SUPER_CHAR_SIZE 死引用 by 武藤纯子酱 2026.9.10
        local macroButton, macroIcon, macroName;
        local name, texture, body;

        -- 选中超级宏失效时自动选中第1个，避免列表全空 by 武藤纯子酱 2026.9.10
        local selSuper = SuperMacroFrame.selectedSuper;
        local selSuperValid = ( type(selSuper) == "number" and selSuper >= 1 and selSuper <= numMacros );
        if ( numMacros > 0 and ( not selSuperValid or not GetOrderedSuperMacroInfo(selSuper) ) ) then
            SuperMacroFrame_SelectSuperMacro(1);
        end

        if ( SuperMacroPopupFrame:IsVisible() ) then
            SuperMacroNewSuperButton:Disable();
            SuperMacroSaveSuperButton:Disable();
            SuperMacroDeleteSuperButton:Disable();
            SuperMacroEditButton:Disable();
        else
            SuperMacroNewSuperButton:Enable();
            SuperMacroSaveSuperButton:Enable();
            SuperMacroDeleteSuperButton:Enable();
            SuperMacroEditButton:Enable();
        end

        -- 无选中超级宏时，清空显示
        if ( not SuperMacroFrame.selectedSuper or GetNumSuperMacros()==0) then
            SuperMacroSaveSuperButton:Disable();
            SuperMacroDeleteSuperButton:Disable();
            SuperMacroEditButton:Disable();
            SuperMacroFrameSelectedMacroName:SetText('');
            SuperMacroFrameSuperText:SetText('');
            SuperMacroFrameSelectedMacroSuperButtonIcon:SetTexture('');
        end

        -- 滚动翻页逻辑
        local offset=FauxScrollFrame_GetOffset(SuperMacroFrameSuperScrollFrame);
        local firstmacro = offset*MACRO_COLUMNS+1;
        -- 修正：分页总数原硬编码 /20，改用常量避免与 MACRO_COLUMNS 脱节 by 武藤纯子酱 2026.9.10
        for i=1, MACROS_SUPER_SHOWN do
            getglobal("SuperMacroSuperButton"..i.."ID"):SetText(firstmacro+i-1);
            macroButton = getglobal("SuperMacroSuperButton"..i);
            macroIcon = getglobal("SuperMacroSuperButton"..i.."Icon");
            macroName = getglobal("SuperMacroSuperButton"..i.."Name");
            local macroID = firstmacro+i-1;
            if ( macroID <= numMacros ) then
                name, texture, body = GetOrderedSuperMacroInfo(macroID);
                macroButton:SetID(macroID);
                macroIcon:SetTexture(texture);
                macroName:SetText(name);
                macroButton:Enable();
                if ( macroID == SuperMacroFrame.selectedSuper ) then
                    macroButton:SetChecked(1);
                    SuperMacroFrameSelectedMacroName:SetText(name);
                    SuperMacroFrameSuperText:SetText(body);
                    SuperMacroFrameSelectedMacroSuperButtonIcon:SetTexture(texture);
                else
                    macroButton:SetChecked(0);
                end
            else
                macroButton:SetChecked(0);
                macroIcon:SetTexture("");
                macroName:SetText("");
                macroButton:Disable();
            end
        end

        FauxScrollFrame_Update(SuperMacroFrameSuperScrollFrame, ceil(numMacros/MACRO_COLUMNS), MACRO_ROWS, MACRO_ROW_HEIGHT ); -- 分页用常量 by 武藤纯子酱 2026.9.10
    end  -- 结束超级宏更新
end

-- 向常规宏编辑框末尾追加一行文本（公共 API，供外部宏/脚本调用）
function SuperMacroFrame_AddMacroLine(line)
    if ( SuperMacroFrameText:IsVisible() ) then
        local currentText = SuperMacroFrameText:GetText() or "";
        SuperMacroFrameText:SetText(currentText..line);
    end
end

-- ==================== 宏按钮点击事件 ====================

-- 常规宏按钮点击（左键选中，右键运行）
function SuperMacroButton_OnClick( button )
    local id=this:GetID();
    SuperMacroFrame_SaveMacro();   -- 保存之前编辑的宏
    SuperMacroFrame_SelectMacro(id);
    SuperMacroFrame_Update();
    SuperMacroPopupFrame:Hide();
    SuperMacroFrameText:ClearFocus();
    if ( button=="RightButton" ) then
        SuperMacro_RunMacro(id);  -- 右键运行宏
    end
    SuperMacroSelectExtend(SuperMacroFrameSelectedMacroName:GetText())
end

-- 超级宏按钮点击（左键选中，右键运行）
function SuperMacroSuperButton_OnClick( button )
    local id = this:GetID()
    SuperMacroFrame_SaveSuperMacro()
    SuperMacroFrame_SelectSuperMacro(id)
    SuperMacroFrame_Update()
    SuperMacroPopupFrame:Hide()
    SuperMacroFrameSuperText:ClearFocus()
    if ( button == "RightButton" ) then
        RunSuperMacro(id)
    end
    SuperMacroSelectExtend(SuperMacroFrameSelectedMacroName:GetText())
end

-- 选中/取消选中
function SuperMacroFrame_SelectSuperMacro(id)
    SuperMacroFrame.selectedSuper = id;
end

function SuperMacroFrame_SelectMacro(id)
    -- 归一化：非法编号（0/负数/非数字）一律置 nil，避免后续 GetMacroInfo 越界报错 by 武藤纯子酱 2026.9.10
    if ( type(id) ~= "number" or id < 1 ) then id = nil; end
    SuperMacroFrame.selectedMacro = id;
end

-- 新建按钮逻辑
function SuperMacroNewAccountButton_OnClick()
    SuperMacroFrame_SaveMacro();
    SuperMacroPopupFrame.mode = "newaccount";
    SuperMacroPopupFrame:Show();
end

function SuperMacroNewCharacterButton_OnClick()
    SuperMacroFrame_SaveMacro();
    SuperMacroPopupFrame.mode = "newcharacter";
    SuperMacroPopupFrame:Show();
end

function SuperMacroNewSuperButton_OnClick()
    SuperMacroFrame_SaveSuperMacro();
    SuperMacroPopupFrame.mode = "newsuper";
    SuperMacroPopupFrame:Show();
end

-- 重命名/更改图标按钮
function SuperMacroEditButton_OnClick()
    SuperMacroFrame_SaveCurrentText();
    SuperMacroPopupFrame.mode = "edit";
    SuperMacroPopupFrame.oldname=SuperMacroFrameSelectedMacroName:GetText();
    SuperMacroPopupFrame:Show();
end

-- 隐藏/显示详情框架（公共 API，供外部脚本调用）
function SuperMacroFrame_HideDetails()
    SuperMacroEditButton:Hide();
    SuperMacroFrameCharLimitText:Hide();
    SuperMacroFrameText:Hide();
    SuperMacroFrameSelectedMacroName:Hide();
    SuperMacroFrameSelectedMacroBackground:Hide();
    SuperMacroFrameSelectedMacroButton:Hide();
end

function SuperMacroFrame_ShowDetails()
    SuperMacroEditButton:Show();
    SuperMacroFrameCharLimitText:Show();
    SuperMacroFrameEnterMacroText:Show();
    SuperMacroFrameText:Show();
    SuperMacroFrameSelectedMacroName:Show();
    SuperMacroFrameSelectedMacroBackground:Show();
    SuperMacroFrameSelectedMacroButton:Show();
end

-- 移除：SelectedMacroName() 死函数（唯一取值点均已直接用 SuperMacroFrameSelectedMacroName:GetText()） by 武藤纯子酱 2026.9.10

-- ==================== 弹窗框架（新建/编辑/图标选择） ====================
function SuperMacroPopupFrame_OnShow()
    SuperMacroPopupFrame:ClearAllPoints()
    if SuperMacroFrame:GetWidth() > 800 then
        SuperMacroPopupFrame:SetPoint("TOPRIGHT", "SuperMacroFrame", "TOPRIGHT", -60, -10)
    else
        SuperMacroPopupFrame:SetPoint("TOPLEFT", "SuperMacroFrame", "TOPRIGHT", -40, -40)
    end
    SuperMacroPopupFrame.selectedTexture = nil;
    if ( this.mode == "newaccount" or this.mode == "newcharacter" ) then
        SuperMacroPopupEditBox:SetText("");
        SuperMacroFrameText:Hide();
        SuperMacroFrameSelectedMacroButtonIcon:SetTexture("");
    elseif ( this.mode == "newsuper" ) then
        SuperMacroPopupEditBox:SetText("");
        SuperMacroFrameSuperText:Hide();
        SuperMacroFrameSelectedMacroSuperButtonIcon:SetTexture("");
    elseif ( this.mode == "edit" ) then
        -- 编辑时预填当前宏名称与图标 by 武藤纯子酱 2026.9.10
        local name, texture;
        if ( SM_VARS.tabShown=="regular" ) then
            name, texture = GetMacroInfo(SuperMacroFrame.selectedMacro);
            SuperMacroFrameSelectedMacroButtonIcon:SetTexture(texture or "");
        elseif ( SM_VARS.tabShown=="super" ) then
            name, texture = GetOrderedSuperMacroInfo(SuperMacroFrame.selectedSuper);
            SuperMacroFrameSelectedMacroSuperButtonIcon:SetTexture(texture or "");
        end
        SuperMacroPopupEditBox:SetText(name or "");
        SuperMacroSetPopupTexture(texture);
    end
    if ( this.mode ~= "edit" ) then
        SuperMacroPopupFrame.selectedIcon = nil;
    end
    SuperMacroFrameText:ClearFocus();
    SuperMacroFrameSuperText:ClearFocus();
    SuperMacroPopupEditBox:SetFocus();
    PlaySound("igCharacterInfoOpen");
    SuperMacroPopupFrame_Update();
    SuperMacroPopupOkayButton_Update();
    SuperMacroFrame_Update();

    -- 禁用外部按钮
    SuperMacroEditButton:Disable();
    SuperMacroDeleteButton:Disable();
    SuperMacroNewAccountButton:Disable();
    SuperMacroNewCharacterButton:Disable();
end

function SuperMacroPopupFrame_OnHide()
    PlaySound("igCharacterInfoClose");
    if ( this.mode == "newaccount" or this.mode == "newcharacter" ) then
        SuperMacroFrameText:Show();
        SuperMacroFrameText:SetFocus();
    elseif ( this.mode == "newsuper" ) then
        SuperMacroFrameSuperText:Show();
        SuperMacroFrameSuperText:SetFocus();
    end
    SuperMacroEditButton:Enable();
    SuperMacroDeleteButton:Enable();
    -- 新建按钮状态交由下方 SuperMacroFrame_Update 按客户端上限常量判定，避免此处误禁用 by 武藤纯子酱 2026.9.10
    -- 关闭弹窗后刷新主窗口，保证列表/按钮状态同步 by 武藤纯子酱 2026.9.10
    SuperMacroFrame_Update();
end

function SuperMacroPopupFrame_Update()
    local numMacroIcons = GetNumMacroIcons();
    local macroPopupOffset = FauxScrollFrame_GetOffset(SuperMacroPopupScrollFrame);
    local MAX_SHOWN = 30;
    local NUM_PER_ROW = 5;

    for i = 1, MAX_SHOWN do
        local macroPopupButton = getglobal("SuperMacroPopupButton" .. i);
        local macroPopupIcon = getglobal("SuperMacroPopupButton" .. i .. "Icon");
        local index = (macroPopupOffset * NUM_PER_ROW) + i;

        if index <= numMacroIcons then
            macroPopupIcon:SetTexture(GetMacroIconInfo(index));
            macroPopupButton:Show();
        else
            macroPopupIcon:SetTexture("");
            macroPopupButton:Hide();
        end

        if index == SuperMacroPopupFrame.selectedIcon then
            macroPopupButton:SetChecked(1);
        else
            macroPopupButton:SetChecked(nil);
        end
    end

    local totalRows = math.ceil(numMacroIcons / NUM_PER_ROW);
    FauxScrollFrame_Update(SuperMacroPopupScrollFrame, totalRows, NUM_ICON_ROWS, MACRO_ICON_ROW_HEIGHT);
end

function SuperMacroPopupOkayButton_Update()
    if ( (strlen(SuperMacroPopupEditBox:GetText()) > 0) and ( SuperMacroPopupFrame.selectedIcon or SuperMacroPopupFrame.selectedTexture ) ) then
        SuperMacroPopupOkayButton:Enable();
    else
        SuperMacroPopupOkayButton:Disable();
    end
    if ( SuperMacroPopupFrame.mode == "edit" and (strlen(SuperMacroPopupEditBox:GetText()) > 0) ) then
        SuperMacroPopupOkayButton:Enable();
    end
end

function SuperMacroPopupButton_OnClick()
    SuperMacroPopupFrame.selectedIcon = this:GetID() + (FauxScrollFrame_GetOffset(SuperMacroPopupScrollFrame) * NUM_ICONS_PER_ROW);
    SuperMacroPopupFrame.selectedTexture = GetMacroIconInfo(SuperMacroPopupFrame.selectedIcon);
    if ( SM_VARS.tabShown=="regular" ) then
        SuperMacroFrameSelectedMacroButtonIcon:SetTexture( SuperMacroPopupFrame.selectedTexture );
    elseif ( SM_VARS.tabShown=="super" ) then
        SuperMacroFrameSelectedMacroSuperButtonIcon:SetTexture( SuperMacroPopupFrame.selectedTexture );
    end
    SuperMacroPopupOkayButton_Update();
    SuperMacroPopupFrame_Update();
end

function SuperMacroPopupOkayButton_OnClick()
    local index = 1;
    local texture = SuperMacroGetPopupTexture();
    local iconIndex = SuperMacroPopupFrame.selectedIcon or SuperMacroGetMacroIconIndex(texture);
    local macroname=SuperMacroPopupEditBox:GetText();
    if ( SuperMacroPopupFrame.mode == "newaccount" ) then
        index = CreateMacro(macroname, iconIndex, nil, nil, false );
        SuperMacroFrame_SelectMacro(index);
    elseif ( SuperMacroPopupFrame.mode == "newcharacter" ) then
        -- 1.12 签名为 CreateMacro(name, icon, body, isLocal, perCharacter)：第4参 isLocal、第5参才是角色专用开关（经 Cat2/客户端验证，勿改成 4 参） by 武藤纯子酱 2026.9.10
        index = CreateMacro(macroname, iconIndex, nil, nil, true );
        SuperMacroFrame_SelectMacro(index);
    elseif ( SuperMacroPopupFrame.mode == "newsuper" ) then
        index = CreateSuperMacro(macroname, texture, '');
        SuperMacroFrame_SelectSuperMacro(index);
        SuperMacroSelectExtend(macroname);
    elseif ( SuperMacroPopupFrame.mode == "edit" ) then
        if ( SM_VARS.tabShown=="regular" ) then
            if SuperMacroPopupFrame.oldname ~= macroname then
                SuperMacroCopyExtend(SuperMacroPopupFrame.oldname, macroname)
                if not SameMacroName() then
                    SuperMacroDeleteExtend(SuperMacroPopupFrame.oldname)
                end
            end
            -- 常规宏改图标需传贴图文件名而非索引 by 武藤纯子酱 2026.9.10
            texture = texture or GetMacroInfo(SuperMacroFrame.selectedMacro, "texture");
            index = EditMacro(SuperMacroFrame.selectedMacro, macroname, GetStringAfterLastSlash(texture));
            if ( GetMacroIndexByName(SuperMacroPopupFrame.oldname)==0 ) then
                SM_UpdateActionSpell(SuperMacroPopupFrame.oldname, "regular", '');
            end
            SM_UpdateActionSpell(macroname, "regular", GetMacroInfo(index, "body"));
            SuperMacroFrame_SelectMacro(index);
        elseif ( SM_VARS.tabShown=="super" ) then
            local oldsuper=GetOrderedSuperMacroInfo(SuperMacroFrame.selectedSuper);
            if ( SM_SUPER_CHAR[macroname] ) then
                macroname=SuperMacroPopupFrame.oldname;
            end
            texture = texture or GetSuperMacroInfo(oldsuper, "texture");
            index = EditSuperMacro(SuperMacroFrame.selectedSuper, macroname, texture);
            SuperMacroFrame_SelectSuperMacro(index);
            SuperMacro_UpdateAction(oldsuper, macroname);
        end
    end
    SuperMacroSelectExtend(macroname)
    SuperMacroPopupFrame:Hide();
    SuperMacroFrame_Update();
end

function SuperMacroOptionsButton_OnClick()
    SuperMacroFrame_SaveCurrentText();
    if ( SuperMacroOptionsFrame:IsVisible() ) then
        SuperMacroOptionsFrame:Hide()
    else
        SuperMacroOptionsFrame:Show()
    end
end

-- ==================== 保存宏内容 ====================
function SuperMacroFrame_SaveMacro()
    if ( SuperMacroFrame.textChanged and SuperMacroFrame.selectedMacro ) then
        EditMacro(SuperMacroFrame.selectedMacro, nil, nil, SuperMacroFrameText:GetText());
        SuperMacroFrame.textChanged = nil;
        SM_UpdateActionSpell( GetMacroInfo(SuperMacroFrame.selectedMacro, "name"), "regular", SuperMacroFrameText:GetText());
    end
end

function SuperMacroFrame_SaveSuperMacro()
    if ( SuperMacroFrame.textChanged and SuperMacroFrame.selectedSuper ) then
        -- 用排序表里的真实宏名，避免重命名时存错键 by 武藤纯子酱 2026.9.10
        local macroName = GetOrderedSuperMacroInfo(SuperMacroFrame.selectedSuper);
        local macroTexture = SuperMacroFrameSelectedMacroSuperButtonIcon:GetTexture();
        local macroBody = SuperMacroFrameSuperText:GetText();
        if ( not macroName ) then
            SuperMacroFrame.textChanged = nil;
            return;
        end
        SM_SUPER_CHAR[macroName] = {macroName,macroTexture,macroBody};
        SuperMacroFrame.textChanged = nil;
        SM_UpdateActionSpell(macroName, "super", macroBody);
    end
end

-- ==================== 事件处理 ====================
function SuperMacroFrame_OnEvent(event)
    -- 专业技能窗口显示时，挂钩其点击事件以支持物品插入
    if ( event=="TRADE_SKILL_SHOW") then
        if ( not old_SM_TradeSkillSkillButton_OnClick) then
            old_SM_TradeSkillSkillButton_OnClick = TradeSkillSkillButton_OnClick;
            TradeSkillSkillButton_OnClick = SM_TradeSkillSkillButton_OnClick;
            SM_TradeSkillItem_OnClick();
        end
    end
    if ( event=="CRAFT_SHOW") then
        if ( not old_SM_CraftButton_OnClick) then
            old_SM_CraftButton_OnClick = CraftButton_OnClick;
            CraftButton_OnClick = SM_CraftButton_OnClick;
            SM_CraftItem_OnClick();
        end
    end
    -- 变量加载完成，初始化所有默认值并应用设置
    if ( event=="VARIABLES_LOADED" ) then
        -- 一次性迁移（按角色）：每个角色首次登录时，把旧「账号级」超级宏/扩展脚本复制到本角色。
        -- 旧账号数据保留不删，供其它角色/其它服务器角色继续各自迁移；本角色迁移后置标记不再迁移。
        -- by 武藤纯子酱 2026.10.12
        if ( not SM_MIGRATED_CHAR ) then
            if ( type(SM_SUPER_CHAR) ~= "table" ) then SM_SUPER_CHAR = {}; end
            if ( type(SM_EXTEND_CHAR) ~= "table" ) then SM_EXTEND_CHAR = {}; end
            local function SM_TableEmpty(t)
                return ( type(t) ~= "table" ) or ( next(t) == nil )
            end
            if ( SM_TableEmpty(SM_SUPER_CHAR) and type(SM_SUPER) == "table" and next(SM_SUPER) ~= nil ) then
                for k,v in pairs(SM_SUPER) do
                    if type(v) == "table" then
                        local copy = {}; for field,value in pairs(v) do copy[field] = value end
                        SM_SUPER_CHAR[k] = copy
                    else SM_SUPER_CHAR[k] = v end
                end
            end
            if ( SM_TableEmpty(SM_EXTEND_CHAR) and type(SM_EXTEND) == "table" and next(SM_EXTEND) ~= nil ) then
                for k,v in pairs(SM_EXTEND) do SM_EXTEND_CHAR[k] = v; end
            end
            -- 动作条槽位映射：把旧账号级里「本角色」那一份迁到按角色变量 by 武藤纯子酱 2026.10.12
            local player = SuperMacroGetPlayerKey();
            if ( type(SM_ACTION_CHAR) ~= "table" ) then SM_ACTION_CHAR = {}; end
            if ( SM_TableEmpty(SM_ACTION_CHAR[player]) and type(SM_ACTION_SUPER) == "table"
                 and type(SM_ACTION_SUPER[player]) == "table" and next(SM_ACTION_SUPER[player]) ~= nil ) then
                local t = {};
                for k,v in pairs(SM_ACTION_SUPER[player]) do t[k] = v; end
                SM_ACTION_CHAR[player] = t;
            end
            SM_MIGRATED_CHAR = 1;
        end
        SuperMacroEnsureSavedTables();
        -- 设置默认选项值
        if ( not SM_VARS.hideAction ) then SM_VARS.hideAction = 0; end
        SM_VARS.printColor = SuperMacroCopyColor(SM_VARS.printColor);
        if ( not SM_VARS.macroTip1 ) then SM_VARS.macroTip1= 1; end
        if ( not SM_VARS.macroTip2 ) then SM_VARS.macroTip2= 0; end
        if ( not SM_VARS.minimap ) then SM_VARS.minimap = 1; end
        if ( not SM_VARS.showMenu ) then SM_VARS.showMenu = 1; end
        if ( not SM_VARS.replaceIcon ) then SM_VARS.replaceIcon = 1; end
        if ( not SM_VARS.checkCooldown ) then SM_VARS.checkCooldown = 1; end
        if ( not SM_VARS.tabShown ) then SM_VARS.tabShown = "regular"; end
        if ( not SM_VARS.windowWidth ) then SM_VARS.windowWidth = 800; end
        if ( not SM_VARS.windowHeight ) then
            SM_VARS.windowHeight = 600;
        elseif ( SM_VARS.windowHeight < 600 ) then
            SM_VARS.windowHeight = 600;
        end
        if ( not SM_VARS.editBoxFontSize ) then SM_VARS.editBoxFontSize = 12; end

        -- 更新标签页状态
        if ( SM_VARS.tabShown=="regular" ) then
            SuperMacroFrame.selectedTab = 1;
            PanelTemplates_UpdateTabs(this);
        elseif ( SM_VARS.tabShown=="super" ) then
            SuperMacroFrame.selectedTab = 2;
            PanelTemplates_UpdateTabs(this);
        end

        -- 应用各项设置
        HideActionText();
        ToggleSMMinimap();
        ToggleSMMenu();
        if ( SuperMacroInitExtend ) then
            SuperMacroInitExtend()
        end

        -- 初始化超级宏排序列表
        SuperMacroEnsureOrdered();
        local player = SuperMacroGetPlayerKey();
        if ( type(SM_ACTION_CHAR[player]) ~= "table" ) then
            SM_ACTION_CHAR[player] = {};
        end
        SM_ACTION = SM_ACTION_CHAR[player];
        SM_UpdateActionSpell();

        -- 插入别名替换函数（兼容其他别名插件）
        if (ReplaceAlias and ASFOptions and ASFOptions.aliasOn) then
            SM_InsertAliasFunction(ReplaceAlias);
        end
        -- ChatAlias 需同时存在 ReplaceAlias 才可挂钩 by 武藤纯子酱 2026.9.10
        if (CA_ParseMessage and ReplaceAlias) then
            SM_InsertAliasFunction(ReplaceAlias, -1);
        end

        SuperMacroInitFrames()
        if ( SuperMacroApplyExtendVisibility ) then
            SuperMacroApplyExtendVisibility()
        end
    end

    -- 进入世界时刷新动作条缓存
    if ( event=="PLAYER_ENTERING_WORLD" ) then
        SM_UpdateActionSpell();
    end
end

-- ==================== 宏运行核心 ====================

-- 内部函数：运行常规宏（按索引或名称）
function SuperMacro_RunMacro(index)
    if ( SuperMacroFrame_SaveMacro ) then SuperMacroFrame_SaveMacro(); end
    if ( MacroFrame_SaveMacro ) then MacroFrame_SaveMacro(); end
    local body;
    if ( type(index) == "number" ) then
        body = GetMacroInfo(index, "body");
    elseif ( type(index) == "string" ) then
        -- 按名称未找到时 GetMacroIndexByName 返回 0，先判定避免无效下标 by 武藤纯子酱 2026.9.10
        local id = GetMacroIndexByName(index);
        if ( id and id > 0 ) then body = GetMacroInfo(id, "body"); end
    end
    if ( not body ) then return; end

    -- 关闭聊天输入框
    if ( ChatFrameEditBox:IsVisible() ) then ChatEdit_OnEscapePressed(ChatFrameEditBox); end

    -- 应用别名替换
    body = SM_ReplaceAlias(body);

    -- 逐行解析并执行
    while ( strlen(body)>0 ) do
        local block, line;
        body, block, line = FindBlock(body);
        if ( block ) then
            RunScript(block);
        else
            RunLine(line);
        end
    end
end

-- 全局封装，方便调用
function RunMacro(index) return SuperMacro_RunMacro(index) end
Macro = SuperMacro_RunMacro;

-- 运行超级宏
function RunSuperMacro(index)
    if ( SuperMacroFrame_SaveSuperMacro ) then SuperMacroFrame_SaveSuperMacro(); end
    local _,body=nil;
    if ( type(index)=="number") then
        _,_,body = GetOrderedSuperMacroInfo(index);
    elseif ( type(index) == "string" ) then
        body = GetSuperMacroInfo(index,"body");
    end
    if ( not body ) then return; end

    if ( ChatFrameEditBox:IsVisible() ) then ChatEdit_OnEscapePressed(ChatFrameEditBox); end

    body = SM_ReplaceAlias(body);

    while ( strlen(body)>0 ) do
        local block, line;
        body, block, line = FindBlock(body);
        if ( block ) then
            RunScript(block);
        else
            RunLine(line);
        end
    end
end

-- 分析宏文本块和行
function FindBlock(body)
    local a,b,block = strfind(body,"^/script (%-%-%-%-%[%[.-%-%-%-%-%]%])[\n]*");
    if ( block ) then
        body = strsub(body,b+1);
        -- 修正：捕获的是 ----[[ ... ----]] 注释壳，直接 RunScript 是空操作；剥掉首尾定界符再执行 by 武藤纯子酱 2026.9.10
        block = string.sub(block, 7, -8);
        return body, block;
    end
    local a,b,line = strfind(body,"^([^\n]*)[\n]*");
    if ( line ) then
        body = strsub(body,b+1);
        return body, nil, line;
    end
end

-- 运行一段宏文本（按行解析）
function RunBody(text)
    local body = text;
    for w in string.gfind(body, "[^\n]+") do
        RunLine(w);
    end
end
local dispatch = AceLibrary("KuBa-SlashDispatch-1.0")
-- 执行一行宏命令
function RunLine(...)
    for k = 1, arg.n do
        local text = arg[k]
        -- SuperMacro 别名替换
        text = SM_ReplaceAlias(text, -1)
        text = strtrim(text or "")
        if text == "" then
            -- 空行，跳过
        elseif string.find(text, "^/script ") then
            RunScript(gsub(text, "^/script ", ""))
        elseif string.sub(text, 1, 1) == "#" then
            -- 注释，跳过
        elseif string.sub(text, 1, 1) == "/" then
            -- slash 命令 → 走库
            if dispatch then
                local _, _, cmd = string.find(text, "^/(%S+)")
                if cmd and dispatch:GetHandler("/" .. cmd) then
                    dispatch:Execute(text)
                end
            end
            -- 库没加载或命令没注册 → 静默跳过
        else
            -- 纯文字 → 发聊天
            text = gsub(text, "\n", "")
            ChatFrameEditBox:SetText(text)
            ChatEdit_SendText(ChatFrameEditBox)
        end
    end
end

-- ==================== 别名替换功能 ====================
function SM_ReplaceAlias(body, after)
    local size, step;
    if ( after==-1 ) then size, step = SM_AliasFunctions.low, -1;
    else size, step = SM_AliasFunctions.high, 1; end
    for i=step, size, step do
        body = SM_AliasFunctions[i](body);
    end
    return body;
end

function SM_InsertAliasFunction(func, pos)
    if ( pos==-1 ) then
        SM_AliasFunctions.low = SM_AliasFunctions.low - 1;
        SM_AliasFunctions[SM_AliasFunctions.low]=func;
        return SM_AliasFunctions.low;
    else
        SM_AliasFunctions.high = SM_AliasFunctions.high + 1;
        SM_AliasFunctions[SM_AliasFunctions.high]=func;
        return SM_AliasFunctions.high;
    end
end

-- ==================== 法术查找函数 ====================
function SM_FindSpell(spell)
    local s = gsub(spell, "%s*(.*)%s*%(.*","%1");
    local r = "";
    -- 修正：rank 数字优先从括号段内提取，避免法术名自带数字时取错 by 武藤纯子酱 2026.9.10
    local paren = string.gsub(spell, "^.*%((.-)%).*$", "%1");
    if ( paren == spell ) then paren = ""; end
    local num = tonumber(paren ~= "" and string.gsub(paren, "%D*(%d+)%D*", "%1") or string.gsub(spell, "%D*(%d+)%D*", "%1"),10);
    -- 完整等级/后缀解析 by 武藤纯子酱 2026.9.10
    if ( string.find(spell, "%(%s*[Rr]acial")) then r = "racial"
    elseif ( string.find(spell, "%(%s*[Ss]ummon")) then r = "summon"
    elseif ( string.find(spell, "%(%s*[Aa]pprentice")) then r = "apprentice"
    elseif ( string.find(spell, "%(%s*[Jj]ourneyman")) then r = "journeyman"
    elseif ( string.find(spell, "%(%s*[Ee]xpert")) then r = "expert"
    elseif ( string.find(spell, "%(%s*[Aa]rtisan")) then r = "artisan"
    elseif ( string.find(spell, "%(%s*[Mm]aster")) then r = "master"
    elseif ( string.find(spell, "%(%s*[Mm]inor")) then s=s.."(Minor)"
    elseif ( string.find(spell, "%(%s*[Ll]esser")) then s=s.."(Lesser)"
    elseif ( string.find(spell, "%(%s*[Gg]reater")) then s=s.."(Greater)"
    elseif ( string.find(spell, "%(%s*[Ff]eral")) then s=s.."(Feral)"
    end
    if ( string.find(spell, "[Rr]ank%s*%d+") and num and num > 0) then
        r = gsub(spell, ".*%(.*[Rr]ank%s*(%d+).*", "Rank "..num);
    end
    return FindSpell(s,r);
end

-- 实际搜索法术书，支持多种等级格式
function FindSpell(spell, rank)
    local i = 1;
    local booktype = { "spell", "pet" };
    local s,r;
    local ys, yr;
    for k, book in booktype do
        while spell do
            s, r = GetSpellName(i,book);
            if ( not s ) then i = 1; break; end
            if ( string.lower(s) == string.lower(spell)) then ys=true; end
            if ( (r == rank) or (r and rank and string.lower(r) == string.lower(rank))) then yr=true; end
            if ( rank=='' and ys and (not GetSpellName(i+1, book) or string.lower(GetSpellName(i+1, book)) ~= string.lower(spell) )) then
                yr = true;
            end
            if ( ys and yr ) then return i,book; end
            i=i+1; ys = nil; yr = nil;
        end
    end
    return;
end

-- ==================== 删除宏相关 ====================
function SuperMacroDeleteButton_OnClick()
    local macro = GetMacroInfo(SuperMacroFrame.selectedMacro, "name");
    if not SameMacroName() then
        SuperMacroDeleteExtend(macro); -- 没有同名宏才删除扩展
    end
    SM_UpdateActionSpell(macro, "regular", nil);
    local deletedIndex = SuperMacroFrame.selectedMacro;
    DeleteMacro(SuperMacroFrame.selectedMacro);
    SuperMacroSelectNearestRegularMacro(deletedIndex);
    SuperMacroFrame_Update();
    SuperMacroFrameText:ClearFocus();
    SuperMacroSelectExtend(GetMacroInfo(SuperMacroFrame.selectedMacro, "name"))
end

function SuperMacroDeleteSuperButton_OnClick()
    DeleteSuperMacro(SuperMacroFrame.selectedSuper)
    SuperMacroFrame_Update()
    SuperMacroFrameSuperText:ClearFocus()
    if ( SuperMacroUpdateExtendSelection ) then SuperMacroUpdateExtendSelection() end
end

-- 检查是否有其他宏同名
function SameMacroName(macroindex)
    -- 修正：原条件方向反了，显式传参时恒返回 nil by 武藤纯子酱 2026.9.10
    if ( not macroindex ) then
        macroindex = SuperMacroFrame.selectedMacro;
    end
    if ( not macroindex ) then
        return; -- 没有选中宏，安全退出
    end
    local macro = GetMacroInfo(macroindex, "name");
    -- 用逐槽探测代替 GetNumMacros 求和（其返回值不可靠） by 武藤纯子酱 2026.9.10
    local slots = SuperMacroScanRegularMacros();
    for i = 1, MAX_MACROS*2 do
        if ( i ~= macroindex and slots[i] and slots[i].name == macro ) then
            return i;  -- 返回第一个找到的同名宏编号（非自身）
        end
    end
    return false;
end

-- 封装 GetMacroInfo 以支持按字段名获取
local oldGetMacroInfo=GetMacroInfo;
function GetMacroInfo(index, code)
    -- 严格校验：Lua 中 0 / true 都是真值，原 if(not index) 挡不住非法下标，
    -- 会触发 "Usage: GetMacroInfo(index)"；此处只放行 >=1 的数字 by 武藤纯子酱 2026.9.10
    if ( type(index) ~= "number" or index < 1 ) then return; end
    local a={};
    a.name,a.texture,a.body,a.islocal=oldGetMacroInfo(index);
    if (not code) then return a.name,a.texture,a.body,a.islocal;
    else return a[code]; end
end

-- 将宏放在动作条上
function SetActionMacro( actionid , macro )
    local macroid = GetMacroIndexByName( macro )
    if ( macroid and macroid > 0 and actionid > 0 and actionid <= 120 ) then
        PickupAction( actionid );
        PickupMacro( macroid );
        PlaceAction ( actionid );
    end
end

-- 小地图按钮显示切换
function ToggleSMMinimap()
    if ( SM_VARS.minimap == 1 ) then SuperMacroMinimapButton:Show();
    else SuperMacroMinimapButton:Hide(); end
end

-- ==================== 更新动作条挂钩（使超级宏可点击） ====================
function SM_UpdateAction()
    local refreshedMacros = {}
    local function doUpdate(button)
        if ( button ) then
            button:SetScript("OnLeave", SM_ActionButton_OnLeave)
            if ( not button.SM_HookedBySuperMacro ) then
                button.SM_HookedBySuperMacro = 1
                button.SM_OldOnClick = button:GetScript("OnClick")
                button:SetScript("OnClick", function()
                    if ( not SM_ActionButton_OnClick() ) then
                        local oldscript = this.SM_OldOnClick
                        if ( oldscript ) then oldscript() end
                    end
                end)
            end
            local macroName = getglobal(button:GetName().."Name") and getglobal(button:GetName().."Name"):GetText()
            if ( macroName ) then
                local macroID = GetMacroIndexByName(macroName)
                if ( macroID and macroID > 0 and not refreshedMacros[macroID] ) then
                    local name, texture, body, isLocal = GetMacroInfo(macroID)
                    EditMacro(macroID, nil, nil, body, isLocal)
                    refreshedMacros[macroID] = 1
                end
            end
        end
    end
    for i=1,12 do
        doUpdate(getglobal("ActionButton"..i))
        doUpdate(getglobal("BonusActionButton"..i))
        doUpdate(getglobal("MultiBarBottomLeftButton"..i))
        doUpdate(getglobal("MultiBarBottomRightButton"..i))
        doUpdate(getglobal("MultiBarRightButton"..i))
        doUpdate(getglobal("MultiBarLeftButton"..i))
    end
    -- 兼容其他动作条插件
    if ( FUActionButton1 ) then for i=1,72 do doUpdate(getglobal("FUActionButton"..i)) end end
    if ( DAB_ActionButton_1 ) then for i=1, 120 do doUpdate(getglobal("DAB_ActionButton_"..i)) end end
end

-- ==================== 超级宏数据管理 ====================
function GetNumSuperMacros()
    SuperMacroEnsureOrdered();
    return getn(SM_ORDERED);
end

function GetSuperMacroInfo( superName, code)
    if ( not superName or not SM_SUPER_CHAR[superName] ) then return; end
    local a={}; a.name,a.texture,a.body=unpack(SM_SUPER_CHAR[superName]);
    if (not code) then return a.name,a.texture,a.body;
    else return a[code]; end
end

function SortSuperMacroList()
    SuperMacroEnsureSavedTables();
    local a={};
    for n in pairs(SM_SUPER_CHAR) do table.insert(a, n); end
    table.sort(a, SuperMacroSortNames);
    return a;
end

function GetOrderedSuperMacroInfo( id )
    SuperMacroEnsureOrdered();
    if ( not SM_SUPER_CHAR[SM_ORDERED[id] ] ) then return; end
    return unpack(SM_SUPER_CHAR[SM_ORDERED[id] ]);
end

function GetOrderedSuperMacro( name )
    SuperMacroEnsureOrdered();
    for i,v in SM_ORDERED do if ( v==name ) then return i; end end
end

function CreateSuperMacro( name, texture, body )
    SuperMacroEnsureSavedTables();
    if ( not SM_SUPER_CHAR[name] ) then SM_SUPER_CHAR[name]={name, texture, body or ''}; end
    SM_UpdateActionSpell( name, "super", body);
    SuperMacroMarkOrderedDirty();
    SuperMacroEnsureOrdered();
    return GetOrderedSuperMacro(name);
end

function EditSuperMacro( id, name, texture)
    SuperMacroEnsureSavedTables();
    local oldMacro, oldTexture, oldBody=GetOrderedSuperMacroInfo(id);
    if ( oldMacro~=name ) then
        SM_SUPER_CHAR[oldMacro]=nil;
        SM_UpdateActionSpell( oldMacro, "super", nil);
    end
    SM_SUPER_CHAR[name]={ name, texture, oldBody};
    SM_UpdateActionSpell( name, "super", oldBody);
    SuperMacroMarkOrderedDirty();
    SuperMacroEnsureOrdered();
    return GetOrderedSuperMacro(name);
end

function DeleteSuperMacro( macro )
    if ( not macro ) then return; end -- 防止外部传入 nil 时下方 id 比较报错 by 武藤纯子酱 2026.9.10
    SuperMacroEnsureSavedTables();
    local id=macro;
    if ( type(macro)=="number" ) then macro=GetOrderedSuperMacroInfo(macro);
    else id=GetOrderedSuperMacro(macro); end
    -- 删除时清理动作条/法术缓存 by 武藤纯子酱 2026.9.10
    SM_UpdateActionSpell(macro, "super", nil);
    SuperMacro_UpdateAction(macro, nil);
    SM_SUPER_CHAR[macro]=nil;
    SuperMacroMarkOrderedDirty();
    SuperMacroEnsureOrdered();
    if ( GetNumSuperMacros()==0 ) then id=nil;
    else id=id>1 and id-1 or 1; end
    SuperMacroFrame_SelectSuperMacro(id);
end

-- 加载所有可用图标
function SM_LoadMacroIcons()
    local icon={};
    for i=1,GetNumMacroIcons() do
        local texture=GetMacroIconInfo(i);
        icon[texture]=i;
        if ( GetStringAfterLastSlash ) then
            icon[GetStringAfterLastSlash(texture)] = i;
        end
    end
    return icon;
end

-- 更新/缓存动作按钮上的法术/物品信息
function SM_UpdateActionSpell( macroname, macrotype, body)
    if ( not macroname ) then
        -- 清空旧缓存
        SM_ACTION_SPELL.regular = {};
        SM_ACTION_SPELL.super = {};
        -- 重新遍历所有常规宏（逐槽探测，避免 GetNumMacros 求和漏宏/越界） by 武藤纯子酱 2026.9.10
        local slots = SuperMacroScanRegularMacros();
        for i = 1, MAX_MACROS*2 do
            if ( slots[i] ) then
                SM_UpdateActionSpell(slots[i].name, "regular", slots[i].body);
            end
        end
        -- 遍历所有超级宏
        for i = 1, GetNumSuperMacros() do
            local name, _, body = GetOrderedSuperMacroInfo(i);
            SM_UpdateActionSpell(name, "super", body);
        end
        return;
    end
    if ( macrotype~="regular" and macrotype~="super" ) then
        macrotype = "regular";
    end
    SM_ACTION_SPELL[macrotype][macroname] = {};
    local id, book, texture, count, spell = FindFirstSpell(body);
    if ( id ) then
        SM_ACTION_SPELL[macrotype][macroname].type = "spell";
        spell = count;
    else
        id, book, texture, count, spell = FindFirstItem(body);
        if ( id ) then
            SM_ACTION_SPELL[macrotype][macroname].type = "item";
        end
    end
    if ( not id ) then
        SM_ACTION_SPELL[macrotype][macroname] = nil;
        return;
    end
    SM_ACTION_SPELL[macrotype][macroname].spell = spell;
    SM_ACTION_SPELL[macrotype][macroname].texture = texture;
end

-- 获取缓存的宏动作类型
function SM_GetActionSpell(macroname, macrotype)
    if ( macrotype and macrotype~="regular" ) then macrotype="super"; else macrotype="regular"; end
    if ( not SM_ACTION_SPELL[macrotype][macroname] ) then return nil; end
    local actiontype=SM_ACTION_SPELL[macrotype][macroname].type;
    local spell=SM_ACTION_SPELL[macrotype][macroname].spell;
    local texture=SM_ACTION_SPELL[macrotype][macroname].texture;
    return actiontype, spell, texture;
end