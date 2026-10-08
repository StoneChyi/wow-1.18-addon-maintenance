
-- 定义插件名称
local ADDON_NAME = "CatUI-PaladinSeal"

CatPaladinSeal = CreateFrame("Frame", ADDON_NAME.."Frame", UIParent)
CatPaladinSeal:Hide()

-- 设置窗口基本属性
CatPaladinSeal:SetWidth(330)
CatPaladinSeal:SetHeight(140)
CatPaladinSeal:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
CatPaladinSeal:SetFrameLevel(1)

-- 创建Tooltip风格的背景和边框
CatPaladinSeal:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
CatPaladinSeal:SetBackdropColor(0.1, 0.1, 0.2, 0.7)
--CatPaladinSeal:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.1)
CatPaladinSeal:SetScale(0.8)

-- 使窗口可移动
CatPaladinSeal:EnableMouse(true)
CatPaladinSeal:SetMovable(true)
CatPaladinSeal:RegisterForDrag("LeftButton")
CatPaladinSeal:SetScript("OnDragStart", function()
    CatPaladinSeal:StartMoving()
end)
CatPaladinSeal:SetScript("OnDragStop", function()
    CatPaladinSeal:StopMovingOrSizing()
end)

-- 添加标题文字
local title = CatPaladinSeal:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOPLEFT", CatPaladinSeal, "TOPLEFT", 10, -10)
title:SetText("|cFFF58CBA圣骑士 - 审判控制|r")

-- 添加标准关闭按钮（精确对齐标题行）
local closeButton = CreateFrame("Button", nil, CatPaladinSeal, "UIPanelCloseButton")
closeButton:SetWidth(32)
closeButton:SetHeight(32)
closeButton:SetPoint("TOPRIGHT", CatPaladinSeal, "TOPRIGHT", -5, -2)  -- Y坐标调整为-10，与标题完全对齐
-- 设置点击事件
closeButton:SetScript("OnClick", function(self)
    CatPaladinSeal:Hide()
    MPPublicSaved.PaladinSealDisplay = 0
end)

-- 添加分隔线
local divider = CatPaladinSeal:CreateTexture(nil, "ARTWORK")
divider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
divider:SetTexCoord(0.81, 0.94, 0.5, 1)
divider:SetVertexColor(0.5, 0.5, 0.5)
divider:SetWidth(320)
divider:SetHeight(4)
divider:SetPoint("TOP", CatPaladinSeal, "TOP", 0, -30)





local JusticeText = CatPaladinSeal:CreateFontString(nil, "OVERLAY", "GameFontNormal")
JusticeText:SetPoint("TOPLEFT", CatPaladinSeal, "TOPLEFT", 10, -50)
JusticeText:SetText("审判")

local postion_y = -40

local postion_x = 50
local PopColor = 0.3

local JusticeButtonNormal = CreateFrame("Button", "MySkillButton", CatPaladinSeal, "ActionButtonTemplate")

-- 设置按钮大小和位置
JusticeButtonNormal:SetWidth(36)  -- 标准技能按钮大小
JusticeButtonNormal:SetHeight(36)
JusticeButtonNormal:SetPoint("TOPLEFT", CatPaladinSeal, "TOPLEFT", postion_x, postion_y)

-- 设置技能图标
JusticeButtonNormal.icon = JusticeButtonNormal:CreateTexture("MySkillButtonIcon", "BACKGROUND")
JusticeButtonNormal.icon:SetAllPoints()
JusticeButtonNormal.icon:SetTexture("Interface\\Icons\\Spell_Nature_WispSplode") -- 替换为你想要的技能图标路径
JusticeButtonNormal:SetAlpha(1.0)
-- 添加高亮效果
JusticeButtonNormal:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

-- 添加按下效果
JusticeButtonNormal:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

-- 添加按钮文本(可选)
JusticeButtonNormal.text = JusticeButtonNormal:CreateFontString(nil, "OVERLAY", "GameFontNormal")
JusticeButtonNormal.text:SetPoint("BOTTOM", JusticeButtonNormal, "BOTTOM", 0, 5)
JusticeButtonNormal.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
JusticeButtonNormal.text:SetTextColor(1, 1, 1)
JusticeButtonNormal.text:SetText("配置")



postion_x = postion_x + 45 

local JusticeButtonWisdom = CreateFrame("Button", "MySkillButton", CatPaladinSeal, "ActionButtonTemplate")

-- 设置按钮大小和位置
JusticeButtonWisdom:SetWidth(36)  -- 标准技能按钮大小
JusticeButtonWisdom:SetHeight(36)
JusticeButtonWisdom:SetPoint("TOPLEFT", CatPaladinSeal, "TOPLEFT", postion_x, postion_y)

-- 设置技能图标
JusticeButtonWisdom.icon = JusticeButtonWisdom:CreateTexture("MySkillButtonIcon", "BACKGROUND")
JusticeButtonWisdom.icon:SetAllPoints()
JusticeButtonWisdom.icon:SetTexture("Interface\\Icons\\Spell_Holy_RighteousnessAura") -- 替换为你想要的技能图标路径
JusticeButtonWisdom:SetAlpha(PopColor)
-- 添加高亮效果
JusticeButtonWisdom:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

-- 添加按下效果
JusticeButtonWisdom:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

-- 添加按钮文本(可选)
JusticeButtonWisdom.text = JusticeButtonWisdom:CreateFontString(nil, "OVERLAY", "GameFontNormal")
JusticeButtonWisdom.text:SetPoint("BOTTOM", JusticeButtonWisdom, "BOTTOM", 0, 5)
JusticeButtonWisdom.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
JusticeButtonWisdom.text:SetTextColor(1, 1, 1)
JusticeButtonWisdom.text:SetText("智慧")




postion_x = postion_x + 45 

local JusticeButtonRight = CreateFrame("Button", "MySkillButton", CatPaladinSeal, "ActionButtonTemplate")

-- 设置按钮大小和位置
JusticeButtonRight:SetWidth(36)  -- 标准技能按钮大小
JusticeButtonRight:SetHeight(36)
JusticeButtonRight:SetPoint("TOPLEFT", CatPaladinSeal, "TOPLEFT", postion_x, postion_y)

-- 设置技能图标
JusticeButtonRight.icon = JusticeButtonRight:CreateTexture("MySkillButtonIcon", "BACKGROUND")
JusticeButtonRight.icon:SetAllPoints()
JusticeButtonRight.icon:SetTexture("Interface\\Icons\\Spell_Holy_HealingAura") -- 替换为你想要的技能图标路径
JusticeButtonRight:SetAlpha(PopColor)
-- 添加高亮效果
JusticeButtonRight:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

-- 添加按下效果
JusticeButtonRight:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

-- 添加按钮文本(可选)
JusticeButtonRight.text = JusticeButtonRight:CreateFontString(nil, "OVERLAY", "GameFontNormal")
JusticeButtonRight.text:SetPoint("BOTTOM", JusticeButtonRight, "BOTTOM", 0, 5)
JusticeButtonRight.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
JusticeButtonRight.text:SetTextColor(1, 1, 1)
JusticeButtonRight.text:SetText("光明")



postion_x = postion_x + 45 

local JusticeButtonCrusader = CreateFrame("Button", "MySkillButton", CatPaladinSeal, "ActionButtonTemplate")

-- 设置按钮大小和位置
JusticeButtonCrusader:SetWidth(36)  -- 标准技能按钮大小
JusticeButtonCrusader:SetHeight(36)
JusticeButtonCrusader:SetPoint("TOPLEFT", CatPaladinSeal, "TOPLEFT", postion_x, postion_y)

-- 设置技能图标
JusticeButtonCrusader.icon = JusticeButtonCrusader:CreateTexture("MySkillButtonIcon", "BACKGROUND")
JusticeButtonCrusader.icon:SetAllPoints()
JusticeButtonCrusader.icon:SetTexture("Interface\\Icons\\Spell_Holy_HolySmite") -- 替换为你想要的技能图标路径
JusticeButtonCrusader:SetAlpha(PopColor)
-- 添加高亮效果
JusticeButtonCrusader:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

-- 添加按下效果
JusticeButtonCrusader:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

-- 添加按钮文本(可选)
JusticeButtonCrusader.text = JusticeButtonCrusader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
JusticeButtonCrusader.text:SetPoint("BOTTOM", JusticeButtonCrusader, "BOTTOM", 0, 5)
JusticeButtonCrusader.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
JusticeButtonCrusader.text:SetTextColor(1, 1, 1)
JusticeButtonCrusader.text:SetText("十字军")



postion_x = postion_x + 45 
postion_x = postion_x + 45 

local ButtonConsecration = CreateFrame("Button", "MySkillButton", CatPaladinSeal, "ActionButtonTemplate")

-- 设置按钮大小和位置
ButtonConsecration:SetWidth(36)  -- 标准技能按钮大小
ButtonConsecration:SetHeight(36)
ButtonConsecration:SetPoint("TOPLEFT", CatPaladinSeal, "TOPLEFT", postion_x, postion_y)

-- 设置技能图标
ButtonConsecration.icon = ButtonConsecration:CreateTexture("MySkillButtonIcon", "BACKGROUND")
ButtonConsecration.icon:SetAllPoints()
ButtonConsecration.icon:SetTexture("Interface\\Icons\\Spell_Holy_InnerFire") -- 替换为你想要的技能图标路径
ButtonConsecration:SetAlpha(PopColor)
-- 添加高亮效果
ButtonConsecration:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

-- 添加按下效果
ButtonConsecration:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

-- 添加按钮文本(可选)
ButtonConsecration.text = ButtonConsecration:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ButtonConsecration.text:SetPoint("BOTTOM", ButtonConsecration, "BOTTOM", 0, 5)
ButtonConsecration.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
ButtonConsecration.text:SetTextColor(1, 1, 1)
ButtonConsecration.text:SetText("奉献\n开")


-- 添加点击事件
JusticeButtonNormal:SetScript("OnClick", function()
    JusticeButtonNormal:SetAlpha(1.0)
    JusticeButtonWisdom:SetAlpha(PopColor)
    JusticeButtonRight:SetAlpha(PopColor)
    JusticeButtonCrusader:SetAlpha(PopColor)
    MPPaladinSealSaved.Justice = 0
end)

JusticeButtonWisdom:SetScript("OnClick", function()
    JusticeButtonNormal:SetAlpha(PopColor)
    JusticeButtonWisdom:SetAlpha(1.0)
    JusticeButtonRight:SetAlpha(PopColor)
    JusticeButtonCrusader:SetAlpha(PopColor)
    MPPaladinSealSaved.Justice = 1
end)

JusticeButtonRight:SetScript("OnClick", function()
    JusticeButtonNormal:SetAlpha(PopColor)
    JusticeButtonWisdom:SetAlpha(PopColor)
    JusticeButtonRight:SetAlpha(1.0)
    JusticeButtonCrusader:SetAlpha(PopColor)
    MPPaladinSealSaved.Justice = 2
end)

JusticeButtonCrusader:SetScript("OnClick", function()
    JusticeButtonNormal:SetAlpha(PopColor)
    JusticeButtonWisdom:SetAlpha(PopColor)
    JusticeButtonRight:SetAlpha(PopColor)
    JusticeButtonCrusader:SetAlpha(1.0)
    MPPaladinSealSaved.Justice = 3
end)

ButtonConsecration:SetScript("OnClick", function()
    if MPPaladinSealSaved.Consecration==0 then
        ButtonConsecration:SetAlpha(1.0)
        MPPaladinSealSaved.Consecration=2
        ButtonConsecration.text:SetText("奉献\n配置")
        ButtonConsecration.icon:SetTexture("Interface\\Icons\\Spell_Nature_WispSplode")
    elseif MPPaladinSealSaved.Consecration==1 then
        ButtonConsecration:SetAlpha(PopColor)
        MPPaladinSealSaved.Consecration=0
        ButtonConsecration.text:SetText("奉献\n关")
        ButtonConsecration.icon:SetTexture("Interface\\Icons\\Spell_Holy_InnerFire")
    elseif MPPaladinSealSaved.Consecration==2 then
        ButtonConsecration:SetAlpha(1.0)
        MPPaladinSealSaved.Consecration=1
        ButtonConsecration.text:SetText("奉献\n开")
        ButtonConsecration.icon:SetTexture("Interface\\Icons\\Spell_Holy_InnerFire")
    end
end)







postion_y = postion_y - 50

local SealText = CatPaladinSeal:CreateFontString(nil, "OVERLAY", "GameFontNormal")
SealText:SetPoint("TOPLEFT", CatPaladinSeal, "TOPLEFT", 10, -100)
SealText:SetText("圣印")


local postion_x = 50
local PopColor = 0.3

local SealButtonNormal = CreateFrame("Button", "MySkillButton", CatPaladinSeal, "ActionButtonTemplate")

-- 设置按钮大小和位置
SealButtonNormal:SetWidth(36)  -- 标准技能按钮大小
SealButtonNormal:SetHeight(36)
SealButtonNormal:SetPoint("TOPLEFT", CatPaladinSeal, "TOPLEFT", postion_x, postion_y)

-- 设置技能图标
SealButtonNormal.icon = SealButtonNormal:CreateTexture("MySkillButtonIcon", "BACKGROUND")
SealButtonNormal.icon:SetAllPoints()
SealButtonNormal.icon:SetTexture("Interface\\Icons\\INV_Sword_08") -- 替换为你想要的技能图标路径
SealButtonNormal:SetAlpha(1.0)
-- 添加高亮效果
SealButtonNormal:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

-- 添加按下效果
SealButtonNormal:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

-- 添加按钮文本(可选)
SealButtonNormal.text = SealButtonNormal:CreateFontString(nil, "OVERLAY", "GameFontNormal")
SealButtonNormal.text:SetPoint("BOTTOM", SealButtonNormal, "BOTTOM", 0, 5)
SealButtonNormal.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
SealButtonNormal.text:SetTextColor(1, 1, 1)
SealButtonNormal.text:SetText("自动")



postion_x = postion_x + 45 

local SealButtonWisdom = CreateFrame("Button", "MySkillButton", CatPaladinSeal, "ActionButtonTemplate")

-- 设置按钮大小和位置
SealButtonWisdom:SetWidth(36)  -- 标准技能按钮大小
SealButtonWisdom:SetHeight(36)
SealButtonWisdom:SetPoint("TOPLEFT", CatPaladinSeal, "TOPLEFT", postion_x, postion_y)

-- 设置技能图标
SealButtonWisdom.icon = SealButtonWisdom:CreateTexture("MySkillButtonIcon", "BACKGROUND")
SealButtonWisdom.icon:SetAllPoints()
SealButtonWisdom.icon:SetTexture("Interface\\Icons\\Spell_Holy_RighteousnessAura") -- 替换为你想要的技能图标路径
SealButtonWisdom:SetAlpha(PopColor)
-- 添加高亮效果
SealButtonWisdom:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

-- 添加按下效果
SealButtonWisdom:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

-- 添加按钮文本(可选)
SealButtonWisdom.text = SealButtonWisdom:CreateFontString(nil, "OVERLAY", "GameFontNormal")
SealButtonWisdom.text:SetPoint("BOTTOM", SealButtonWisdom, "BOTTOM", 0, 5)
SealButtonWisdom.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
SealButtonWisdom.text:SetTextColor(1, 1, 1)
SealButtonWisdom.text:SetText("智慧")




postion_x = postion_x + 45 

local SealButtonRight = CreateFrame("Button", "MySkillButton", CatPaladinSeal, "ActionButtonTemplate")

-- 设置按钮大小和位置
SealButtonRight:SetWidth(36)  -- 标准技能按钮大小
SealButtonRight:SetHeight(36)
SealButtonRight:SetPoint("TOPLEFT", CatPaladinSeal, "TOPLEFT", postion_x, postion_y)

-- 设置技能图标
SealButtonRight.icon = SealButtonRight:CreateTexture("MySkillButtonIcon", "BACKGROUND")
SealButtonRight.icon:SetAllPoints()
SealButtonRight.icon:SetTexture("Interface\\Icons\\Spell_Holy_HealingAura") -- 替换为你想要的技能图标路径
SealButtonRight:SetAlpha(PopColor)
-- 添加高亮效果
SealButtonRight:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

-- 添加按下效果
SealButtonRight:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

-- 添加按钮文本(可选)
SealButtonRight.text = SealButtonRight:CreateFontString(nil, "OVERLAY", "GameFontNormal")
SealButtonRight.text:SetPoint("BOTTOM", SealButtonRight, "BOTTOM", 0, 5)
SealButtonRight.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
SealButtonRight.text:SetTextColor(1, 1, 1)
SealButtonRight.text:SetText("光明")



postion_x = postion_x + 45 

local SealButtonCrusader = CreateFrame("Button", "MySkillButton", CatPaladinSeal, "ActionButtonTemplate")

-- 设置按钮大小和位置
SealButtonCrusader:SetWidth(36)  -- 标准技能按钮大小
SealButtonCrusader:SetHeight(36)
SealButtonCrusader:SetPoint("TOPLEFT", CatPaladinSeal, "TOPLEFT", postion_x, postion_y)

-- 设置技能图标
SealButtonCrusader.icon = SealButtonCrusader:CreateTexture("MySkillButtonIcon", "BACKGROUND")
SealButtonCrusader.icon:SetAllPoints()
SealButtonCrusader.icon:SetTexture("Interface\\Icons\\Spell_Holy_HolySmite") -- 替换为你想要的技能图标路径
SealButtonCrusader:SetAlpha(PopColor)
-- 添加高亮效果
SealButtonCrusader:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

-- 添加按下效果
SealButtonCrusader:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

-- 添加按钮文本(可选)
SealButtonCrusader.text = SealButtonCrusader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
SealButtonCrusader.text:SetPoint("BOTTOM", SealButtonCrusader, "BOTTOM", 0, 5)
SealButtonCrusader.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
SealButtonCrusader.text:SetTextColor(1, 1, 1)
SealButtonCrusader.text:SetText("十字军")


postion_x = postion_x + 45 

local SealButtonJustice = CreateFrame("Button", "MySkillButton", CatPaladinSeal, "ActionButtonTemplate")

-- 设置按钮大小和位置
SealButtonJustice:SetWidth(36)  -- 标准技能按钮大小
SealButtonJustice:SetHeight(36)
SealButtonJustice:SetPoint("TOPLEFT", CatPaladinSeal, "TOPLEFT", postion_x, postion_y)

-- 设置技能图标
SealButtonJustice.icon = SealButtonJustice:CreateTexture("MySkillButtonIcon", "BACKGROUND")
SealButtonJustice.icon:SetAllPoints()
SealButtonJustice.icon:SetTexture("Interface\\Icons\\Ability_ThunderBolt") -- 替换为你想要的技能图标路径
SealButtonJustice:SetAlpha(PopColor)
-- 添加高亮效果
SealButtonJustice:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

-- 添加按下效果
SealButtonJustice:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

-- 添加按钮文本(可选)
SealButtonJustice.text = SealButtonJustice:CreateFontString(nil, "OVERLAY", "GameFontNormal")
SealButtonJustice.text:SetPoint("BOTTOM", SealButtonJustice, "BOTTOM", 0, 5)
SealButtonJustice.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
SealButtonJustice.text:SetTextColor(1, 1, 1)
SealButtonJustice.text:SetText("正义")



postion_x = postion_x + 45 

local SealButtonCommand = CreateFrame("Button", "MySkillButton", CatPaladinSeal, "ActionButtonTemplate")

-- 设置按钮大小和位置
SealButtonCommand:SetWidth(36)  -- 标准技能按钮大小
SealButtonCommand:SetHeight(36)
SealButtonCommand:SetPoint("TOPLEFT", CatPaladinSeal, "TOPLEFT", postion_x, postion_y)

-- 设置技能图标
SealButtonCommand.icon = SealButtonCommand:CreateTexture("MySkillButtonIcon", "BACKGROUND")
SealButtonCommand.icon:SetAllPoints()
SealButtonCommand.icon:SetTexture("Interface\\Icons\\Ability_Warrior_InnerRage") -- 替换为你想要的技能图标路径
SealButtonCommand:SetAlpha(PopColor)
-- 添加高亮效果
SealButtonCommand:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

-- 添加按下效果
SealButtonCommand:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

-- 添加按钮文本(可选)
SealButtonCommand.text = SealButtonCommand:CreateFontString(nil, "OVERLAY", "GameFontNormal")
SealButtonCommand.text:SetPoint("BOTTOM", SealButtonCommand, "BOTTOM", 0, 5)
SealButtonCommand.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
SealButtonCommand.text:SetTextColor(1, 1, 1)
SealButtonCommand.text:SetText("命令")


-- 添加点击事件
SealButtonNormal:SetScript("OnClick", function()
    SealButtonNormal:SetAlpha(1.0)
    SealButtonWisdom:SetAlpha(PopColor)
    SealButtonRight:SetAlpha(PopColor)
    SealButtonCrusader:SetAlpha(PopColor)
    SealButtonJustice:SetAlpha(PopColor)
    SealButtonCommand:SetAlpha(PopColor)
    MPPaladinSealSaved.Seal = 0
end)

SealButtonWisdom:SetScript("OnClick", function()
    SealButtonNormal:SetAlpha(PopColor)
    SealButtonWisdom:SetAlpha(1.0)
    SealButtonRight:SetAlpha(PopColor)
    SealButtonCrusader:SetAlpha(PopColor)
    SealButtonJustice:SetAlpha(PopColor)
    SealButtonCommand:SetAlpha(PopColor)
    MPPaladinSealSaved.Seal = 1
end)

SealButtonRight:SetScript("OnClick", function()
    SealButtonNormal:SetAlpha(PopColor)
    SealButtonWisdom:SetAlpha(PopColor)
    SealButtonRight:SetAlpha(1.0)
    SealButtonCrusader:SetAlpha(PopColor)
    SealButtonJustice:SetAlpha(PopColor)
    SealButtonCommand:SetAlpha(PopColor)
    MPPaladinSealSaved.Seal = 2
end)

SealButtonCrusader:SetScript("OnClick", function()
    SealButtonNormal:SetAlpha(PopColor)
    SealButtonWisdom:SetAlpha(PopColor)
    SealButtonRight:SetAlpha(PopColor)
    SealButtonCrusader:SetAlpha(1.0)
    SealButtonJustice:SetAlpha(PopColor)
    SealButtonCommand:SetAlpha(PopColor)
    MPPaladinSealSaved.Seal = 3
end)

SealButtonJustice:SetScript("OnClick", function()
    SealButtonNormal:SetAlpha(PopColor)
    SealButtonWisdom:SetAlpha(PopColor)
    SealButtonRight:SetAlpha(PopColor)
    SealButtonCrusader:SetAlpha(PopColor)
    SealButtonJustice:SetAlpha(1.0)
    SealButtonCommand:SetAlpha(PopColor)
    MPPaladinSealSaved.Seal = 4
end)

SealButtonCommand:SetScript("OnClick", function()
    SealButtonNormal:SetAlpha(PopColor)
    SealButtonWisdom:SetAlpha(PopColor)
    SealButtonRight:SetAlpha(PopColor)
    SealButtonCrusader:SetAlpha(PopColor)
    SealButtonJustice:SetAlpha(PopColor)
    SealButtonCommand:SetAlpha(1.0)
    MPPaladinSealSaved.Seal = 5
end)








local PaladinSealSettingsUIVersion = 2

function MPCatPaladinSealReset()

    MPPaladinSealSaved.Version = PaladinSealSettingsUIVersion

    MPPaladinSealSaved.Seal = 0
    MPPaladinSealSaved.Justice = 1
    MPPaladinSealSaved.Consecration = 1

end


function MPCatPaladinSealInit()

    if not MPPaladinSealSaved then
        MPPaladinSealSaved = {}
        MPCatPaladinSealReset()
    end

    if MPPaladinSealSaved.Version ~= PaladinSealSettingsUIVersion then
        MPCatPaladinSealReset()
    end

    JusticeButtonNormal:SetAlpha(PopColor)
    JusticeButtonWisdom:SetAlpha(PopColor)
    JusticeButtonRight:SetAlpha(PopColor)
    JusticeButtonCrusader:SetAlpha(PopColor)

    SealButtonNormal:SetAlpha(PopColor)
    SealButtonWisdom:SetAlpha(PopColor)
    SealButtonRight:SetAlpha(PopColor)
    SealButtonCrusader:SetAlpha(PopColor)
    SealButtonJustice:SetAlpha(PopColor)
    SealButtonCommand:SetAlpha(PopColor)

    if MPPaladinSealSaved.Justice==0 then
        JusticeButtonNormal:SetAlpha(1.0)
    elseif MPPaladinSealSaved.Justice==1 then
        JusticeButtonWisdom:SetAlpha(1.0)
    elseif MPPaladinSealSaved.Justice==2 then
        JusticeButtonRight:SetAlpha(1.0)
    elseif MPPaladinSealSaved.Justice==3 then
        JusticeButtonCrusader:SetAlpha(1.0)
    end

    if MPPaladinSealSaved.Seal==0 then
        SealButtonNormal:SetAlpha(1.0)
    elseif MPPaladinSealSaved.Seal==1 then
        SealButtonWisdom:SetAlpha(1.0)
    elseif MPPaladinSealSaved.Seal==2 then
        SealButtonRight:SetAlpha(1.0)
    elseif MPPaladinSealSaved.Seal==3 then
        SealButtonCrusader:SetAlpha(1.0)
    elseif MPPaladinSealSaved.Seal==4 then
        SealButtonJustice:SetAlpha(1.0)
    elseif MPPaladinSealSaved.Seal==5 then
        SealButtonCommand:SetAlpha(1.0)
    end

    if MPPaladinSealSaved.Consecration==2 then
        ButtonConsecration:SetAlpha(1.0)
        ButtonConsecration.text:SetText("奉献\n配置")
        ButtonConsecration.icon:SetTexture("Interface\\Icons\\Spell_Nature_WispSplode")
    elseif MPPaladinSealSaved.Consecration==0 then
        ButtonConsecration:SetAlpha(PopColor)
        ButtonConsecration.text:SetText("奉献\n关")
        ButtonConsecration.icon:SetTexture("Interface\\Icons\\Spell_Holy_InnerFire")
    elseif MPPaladinSealSaved.Consecration==1 then
        ButtonConsecration:SetAlpha(1.0)
        ButtonConsecration.text:SetText("奉献\n开")
        ButtonConsecration.icon:SetTexture("Interface\\Icons\\Spell_Holy_InnerFire")
    end

end



