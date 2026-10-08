
-- 定义插件名称
local ADDON_NAME = "CatUI-PaladinHeal"

CatPaladinHeal = CreateFrame("Frame", ADDON_NAME.."Frame", UIParent)
CatPaladinHeal:Hide()

-- 设置窗口基本属性
CatPaladinHeal:SetWidth(225)
CatPaladinHeal:SetHeight(100)
CatPaladinHeal:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
CatPaladinHeal:SetFrameLevel(1)

-- 创建Tooltip风格的背景和边框
CatPaladinHeal:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
CatPaladinHeal:SetBackdropColor(0.1, 0.1, 0.2, 0.7)
--CatPaladinHeal:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.1)
CatPaladinHeal:SetScale(0.8)

-- 使窗口可移动
CatPaladinHeal:EnableMouse(true)
CatPaladinHeal:SetMovable(true)
CatPaladinHeal:RegisterForDrag("LeftButton")
CatPaladinHeal:SetScript("OnDragStart", function()
    CatPaladinHeal:StartMoving()
end)
CatPaladinHeal:SetScript("OnDragStop", function()
    CatPaladinHeal:StopMovingOrSizing()
end)

-- 添加标题文字
local title = CatPaladinHeal:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOPLEFT", CatPaladinHeal, "TOPLEFT", 10, -10)
title:SetText("|cFFF58CBA奶骑宏控制|r")

-- 添加标准关闭按钮（精确对齐标题行）
local closeButton = CreateFrame("Button", nil, CatPaladinHeal, "UIPanelCloseButton")
closeButton:SetWidth(32)
closeButton:SetHeight(32)
closeButton:SetPoint("TOPRIGHT", CatPaladinHeal, "TOPRIGHT", -5, -2)  -- Y坐标调整为-10，与标题完全对齐
-- 设置点击事件
closeButton:SetScript("OnClick", function(self)
    CatPaladinHeal:Hide()
    MPPublicSaved.PaladinHealDisplay = 0
end)

-- 添加分隔线
local divider = CatPaladinHeal:CreateTexture(nil, "ARTWORK")
divider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
divider:SetTexCoord(0.81, 0.94, 0.5, 1)
divider:SetVertexColor(0.5, 0.5, 0.5)
divider:SetWidth(215)
divider:SetHeight(4)
divider:SetPoint("TOP", CatPaladinHeal, "TOP", 0, -30)

local postion_y = -45

local postion_x = 20
local PopColor = 0.3



local ButtonHolyLight = CreateFrame("Button", "MySkillButton", CatPaladinHeal, "ActionButtonTemplate")

-- 设置按钮大小和位置
ButtonHolyLight:SetWidth(36)  -- 标准技能按钮大小
ButtonHolyLight:SetHeight(36)
ButtonHolyLight:SetPoint("TOPLEFT", CatPaladinHeal, "TOPLEFT", postion_x, postion_y)

-- 设置技能图标
ButtonHolyLight.icon = ButtonHolyLight:CreateTexture("MySkillButtonIcon", "BACKGROUND")
ButtonHolyLight.icon:SetAllPoints()
ButtonHolyLight.icon:SetTexture("Interface\\Icons\\Spell_Holy_HolyBolt") -- 替换为你想要的技能图标路径
ButtonHolyLight:SetAlpha(1.0)
-- 添加高亮效果
ButtonHolyLight:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

-- 添加按下效果
ButtonHolyLight:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

-- 添加按钮文本(可选)
ButtonHolyLight.text = ButtonHolyLight:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ButtonHolyLight.text:SetPoint("BOTTOM", ButtonHolyLight, "BOTTOM", 0, 0)
ButtonHolyLight.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
ButtonHolyLight.text:SetTextColor(1, 1, 1)
ButtonHolyLight.text:SetText("圣光术")

ButtonHolyLight:SetScript("OnClick", function()

    if MPPaladinHealSaved[1].HolyLight==1 then
        MPPaladinHealSaved[1].HolyLight = 0
        MPPaladinHealSaved[2].HolyLight = 0
        MPPaladinHealSaved[3].HolyLight = 0
        ButtonHolyLight:SetAlpha(0.3)
    else
        MPPaladinHealSaved[1].HolyLight = 1
        MPPaladinHealSaved[2].HolyLight = 1
        MPPaladinHealSaved[3].HolyLight = 1
        ButtonHolyLight:SetAlpha(1.0)
    end
    MPInitPaladinHealSettings()
end)



postion_x = postion_x + 50 

local ButtonFlashLight = CreateFrame("Button", "MySkillButton", CatPaladinHeal, "ActionButtonTemplate")

-- 设置按钮大小和位置
ButtonFlashLight:SetWidth(36)  -- 标准技能按钮大小
ButtonFlashLight:SetHeight(36)
ButtonFlashLight:SetPoint("TOPLEFT", CatPaladinHeal, "TOPLEFT", postion_x, postion_y)

-- 设置技能图标
ButtonFlashLight.icon = ButtonFlashLight:CreateTexture("MySkillButtonIcon", "BACKGROUND")
ButtonFlashLight.icon:SetAllPoints()
ButtonFlashLight.icon:SetTexture("Interface\\Icons\\Spell_Holy_FlashHeal") -- 替换为你想要的技能图标路径
ButtonFlashLight:SetAlpha(1.0)
-- 添加高亮效果
ButtonFlashLight:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

-- 添加按下效果
ButtonFlashLight:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

-- 添加按钮文本(可选)
ButtonFlashLight.text = ButtonFlashLight:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ButtonFlashLight.text:SetPoint("BOTTOM", ButtonFlashLight, "BOTTOM", 0, 0)
ButtonFlashLight.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
ButtonFlashLight.text:SetTextColor(1, 1, 1)
ButtonFlashLight.text:SetText("圣光闪现")

ButtonFlashLight:SetScript("OnClick", function()

    if MPPaladinHealSaved[1].FlashLight==1 then
        MPPaladinHealSaved[1].FlashLight = 0
        MPPaladinHealSaved[2].FlashLight = 0
        MPPaladinHealSaved[3].FlashLight = 0
        ButtonFlashLight:SetAlpha(0.3)
    else
        MPPaladinHealSaved[1].FlashLight = 1
        MPPaladinHealSaved[2].FlashLight = 0
        MPPaladinHealSaved[3].FlashLight = 0
        ButtonFlashLight:SetAlpha(1.0)
    end
    MPInitPaladinHealSettings()
end)




postion_x = postion_x + 50 

local ButtonHolyShock = CreateFrame("Button", "MySkillButton", CatPaladinHeal, "ActionButtonTemplate")

-- 设置按钮大小和位置
ButtonHolyShock:SetWidth(36)  -- 标准技能按钮大小
ButtonHolyShock:SetHeight(36)
ButtonHolyShock:SetPoint("TOPLEFT", CatPaladinHeal, "TOPLEFT", postion_x, postion_y)

-- 设置技能图标
ButtonHolyShock.icon = ButtonHolyShock:CreateTexture("MySkillButtonIcon", "BACKGROUND")
ButtonHolyShock.icon:SetAllPoints()
ButtonHolyShock.icon:SetTexture("Interface\\Icons\\Spell_Holy_SearingLight") -- 替换为你想要的技能图标路径
ButtonHolyShock:SetAlpha(1.0)
-- 添加高亮效果
ButtonHolyShock:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

-- 添加按下效果
ButtonHolyShock:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

-- 添加按钮文本(可选)
ButtonHolyShock.text = ButtonHolyShock:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ButtonHolyShock.text:SetPoint("BOTTOM", ButtonHolyShock, "BOTTOM", 0, 0)
ButtonHolyShock.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
ButtonHolyShock.text:SetTextColor(1, 1, 1)
ButtonHolyShock.text:SetText("神圣震击")

ButtonHolyShock:SetScript("OnClick", function()

    if MPPaladinHealSaved[1].HolyShock==1 then
        MPPaladinHealSaved[1].HolyShock = 0
        MPPaladinHealSaved[2].HolyShock = 0
        MPPaladinHealSaved[3].HolyShock = 0
        ButtonHolyShock:SetAlpha(0.3)
    else
        MPPaladinHealSaved[1].HolyShock = 1
        MPPaladinHealSaved[2].HolyShock = 1
        MPPaladinHealSaved[3].HolyShock = 1
        ButtonHolyShock:SetAlpha(1.0)
    end
    MPInitPaladinHealSettings()
end)



postion_x = postion_x + 50 

local ButtonSacredStrike = CreateFrame("Button", "MySkillButton", CatPaladinHeal, "ActionButtonTemplate")

-- 设置按钮大小和位置
ButtonSacredStrike:SetWidth(36)  -- 标准技能按钮大小
ButtonSacredStrike:SetHeight(36)
ButtonSacredStrike:SetPoint("TOPLEFT", CatPaladinHeal, "TOPLEFT", postion_x, postion_y)

-- 设置技能图标
ButtonSacredStrike.icon = ButtonSacredStrike:CreateTexture("MySkillButtonIcon", "BACKGROUND")
ButtonSacredStrike.icon:SetAllPoints()
ButtonSacredStrike.icon:SetTexture("Interface\\Icons\\INV_Sword_01") -- 替换为你想要的技能图标路径
ButtonSacredStrike:SetAlpha(1.0)
-- 添加高亮效果
ButtonSacredStrike:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

-- 添加按下效果
ButtonSacredStrike:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

-- 添加按钮文本(可选)
ButtonSacredStrike.text = ButtonSacredStrike:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ButtonSacredStrike.text:SetPoint("BOTTOM", ButtonSacredStrike, "BOTTOM", 0, 0)
ButtonSacredStrike.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
ButtonSacredStrike.text:SetTextColor(1, 1, 1)
ButtonSacredStrike.text:SetText("神圣打击")

ButtonSacredStrike:SetScript("OnClick", function()

    if MPPaladinHealSaved[1].SacredStrike==1 then
        MPPaladinHealSaved[1].SacredStrike = 0
        MPPaladinHealSaved[2].SacredStrike = 0
        MPPaladinHealSaved[3].SacredStrike = 0
        ButtonSacredStrike:SetAlpha(0.3)
    else
        MPPaladinHealSaved[1].SacredStrike = 1
        MPPaladinHealSaved[2].SacredStrike = 1
        MPPaladinHealSaved[3].SacredStrike = 1
        ButtonSacredStrike:SetAlpha(1.0)
    end
    MPInitPaladinHealSettings()
end)




local PaladinHealSettingsUIVersion = 2

function MPCatPaladinHealReset()


end

function MPCatPaladinControlHealInit()

    if not MPPaladinHealSaved then
        return
    end

    if MPPaladinHealSaved[1].HolyLight==1 then
        ButtonHolyLight:SetAlpha(1.0)
    else
        ButtonHolyLight:SetAlpha(0.3)
    end

    if MPPaladinHealSaved[1].FlashLight==1 then
        ButtonFlashLight:SetAlpha(1.0)
    else
        ButtonFlashLight:SetAlpha(0.3)
    end

    if MPPaladinHealSaved[1].HolyShock==1 then
        ButtonHolyShock:SetAlpha(1.0)
    else
        ButtonHolyShock:SetAlpha(0.3)
    end

    if MPPaladinHealSaved[1].SacredStrike==1 then
        ButtonSacredStrike:SetAlpha(1.0)
    else
        ButtonSacredStrike:SetAlpha(0.3)
    end


end


