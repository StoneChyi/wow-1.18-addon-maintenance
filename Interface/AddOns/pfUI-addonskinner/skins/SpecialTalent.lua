pfUI.addonskinner:RegisterSkin("SpecialTalent", function()

  local penv = pfUI:GetEnvironment()
  local StripTextures, CreateBackdrop, SkinCloseButton, SkinButton, SkinCheckbox =
    penv.StripTextures, penv.CreateBackdrop, penv.SkinCloseButton, penv.SkinButton, penv.SkinCheckbox

  -- ===== 主窗口 =====
  if SpecialTalentFrame then
    pfUI.api.StripTextures(SpecialTalentFrame)
    pfUI.api.CreateBackdrop(SpecialTalentFrame, nil, nil, .75)
    if SpecialTalentFrame.backdrop then
      SpecialTalentFrame.backdrop:SetPoint("TOPLEFT", SpecialTalentFrame, "TOPLEFT", 5, 0)
      SpecialTalentFrame.backdrop:SetPoint("BOTTOMRIGHT", SpecialTalentFrame, "BOTTOMRIGHT", -20, 60)
    end
  end

  -- 主窗口按钮（含此前遗漏的 上页/下页 小按钮 与 应用方案 按钮）
  local mainButtons = {
    "SpecialTalentFrameMinimizeButton",
    "SpecialTalentFrameResetButton",
    "SpecialTalentRename",
    "SpecialTalentFrameNextButtonLarge",
    "SpecialTalentFramePreviousButtonLarge",
    "SpecialTalentFrameNextButtonSmall",
    "SpecialTalentFramePreviousButtonSmall",
    "SpecialTalentFrameApplyButton",
  }
  for _, name in ipairs(mainButtons) do
    pfUI.api.SkinButton(_G[name])
  end

  -- 复选框（ForceShift 在当前版本不存在，SkinCheckbox 对 nil 安全，自动跳过）
  pfUI.api.SkinCheckbox(SpecialTalentFrameLearnedCheckButton, 25)
  pfUI.api.SkinCheckbox(SpecialTalentFramePlannedCheckButton, 25)

  -- 关闭按钮
  pfUI.api.SkinCloseButton(SpecialTalentFrameCloseButton)

  -- ===== 弹窗定位：仅放大态往右挪，避开主窗口右缘 =====
  -- 需求：小窗口(345宽)保持插件原始位置不动（用户确认小窗口不重叠、整齐）；
  --       放大态(900宽)插件把 RenamePanel/ResetConfirmationPanel 压在主窗口右缘内(-32/-33)导致重叠，
  --       只需在放大态下把它们挪到主窗口右侧外(+8)即可，不做其它对齐处理。
  -- 用 OnUpdate 每 0.3s 轮询，仅在放大态(主窗口宽度>500)生效；小窗口完全不碰。
  -- 注意：1.12/乌龟服 SetScript 回调不传 self，时间差用 GetTime()。
  local ppLast = 0
  local function PollLargeWindow()
    local t = GetTime()
    if t - ppLast < 0.3 then return end
    ppLast = t
    local frame = SpecialTalentFrame
    if not frame or frame:GetWidth() <= 500 then return end  -- 非放大态：不动
    local rename = _G["SpecialTalentUI_RenamePanel"]
    if rename and rename:IsObjectType("Frame") then
      rename:ClearAllPoints()
      rename:SetPoint("TOPLEFT", frame, "TOPRIGHT", -19, 0)
    end
    local reset = _G["SpecialTalentUI_ResetConfirmationPanel"]
    if reset and reset:IsObjectType("Frame") then
      reset:ClearAllPoints()
      reset:SetPoint("TOPLEFT", frame, "TOPRIGHT", -19, 0)
    end
  end
  if SpecialTalentUI_RenamePanel then
    SpecialTalentUI_RenamePanel:SetScript("OnUpdate", PollLargeWindow)
  end
  if SpecialTalentUI_ResetConfirmationPanel then
    SpecialTalentUI_ResetConfirmationPanel:SetScript("OnUpdate", PollLargeWindow)
  end

  -- ===== 重命名弹窗外观 (SpecialTalentUI_RenamePanel) =====
  -- 弹窗自带 <Backdrop>，CreateBackdrop 检测到已有 backdrop 会自动清除并换成 pfUI 边框
  if SpecialTalentUI_RenamePanel then
    pfUI.api.CreateBackdrop(SpecialTalentUI_RenamePanel, nil, nil, .9)
  end

  -- 输入框（InputBoxTemplate）
  if SpecialTalentUI_RenameEditBox then
    pfUI.api.StripTextures(SpecialTalentUI_RenameEditBox, true, "BACKGROUND")
    pfUI.api.CreateBackdrop(SpecialTalentUI_RenameEditBox, nil, true)
  end

  -- 确定 / 取消 按钮
  pfUI.api.SkinButton(SpecialTalentUI_Rename)
  pfUI.api.SkinButton(SpecialTalentUI_RenameCancel)

  -- ===== 重置确认弹窗外观 (SpecialTalentUI_ResetConfirmationPanel) =====
  if SpecialTalentUI_ResetConfirmationPanel then
    pfUI.api.CreateBackdrop(SpecialTalentUI_ResetConfirmationPanel, nil, nil, .9)
  end
  local resetButtons = {
    "SpecialTalentUI_ResetOneButton",
    "SpecialTalentUI_ResetTwoButton",
    "SpecialTalentUI_ResetThreeButton",
    "SpecialTalentUI_ResetAllButton",
    "SpecialTalentUI_ResetCancel",
  }
  for _, name in ipairs(resetButtons) do
    pfUI.api.SkinButton(_G[name])
  end

  -- 天赋树内容框 (SpecialTalentFrameTabFrame*) 与 左侧职业标签 (SpecialTalentFrameTab*)
  -- 内含天赋图标/连线/职业图标等必要美术，刻意不 StripTextures，仅保留原生外观。

  pfUI.addonskinner:UnregisterSkin("SpecialTalentUI")

end)
