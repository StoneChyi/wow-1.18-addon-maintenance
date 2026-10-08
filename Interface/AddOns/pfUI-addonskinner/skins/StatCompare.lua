pfUI.addonskinner:RegisterSkin("StatCompare", function()

pfUI.api.StripTextures(StatCompareSelfFrame)
pfUI.api.CreateBackdrop(StatCompareSelfFrame,nil, nil, .75)
pfUI.api.StripTextures(StatCompareTargetFrame)
pfUI.api.CreateBackdrop(StatCompareTargetFrame,nil, nil, .75)

-- 关闭按钮美化（自身 vs 目标装备对比窗口）
if StatCompareSelfFrameCloseButton then
  pfUI.api.SkinCloseButton(StatCompareSelfFrameCloseButton, StatCompareSelfFrame.backdrop, -6, -6)
end
if StatCompareTargetFrameCloseButton then
  pfUI.api.SkinCloseButton(StatCompareTargetFrameCloseButton, StatCompareTargetFrame.backdrop, -6, -6)
end

-- 修复重叠：SkinCloseButton 会把 close button 缩到 15x15，原来 XML 里
--   SpellsButton.TOPRIGHT = close button.TOPLEFT + (6, -8)
-- 的锚定让 spells 按钮整体右移 17px（32-15），溢出到 frame 右边缘外、视觉上
-- 紧贴关闭按钮。改为相对 frame 自身定位，与 close button 留出 6px 间距。
local function ReposSpellButton(btn, frame)
  if not btn then return end
  btn:ClearAllPoints()
  btn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -27, -7)
end

ReposSpellButton(StatCompareSelfFrameSpellsButton, StatCompareSelfFrame)
ReposSpellButton(StatCompareTargetFrameSpellsButton, StatCompareTargetFrame)

if SCApplyPanelStyle then
  SCApplyPanelStyle(StatCompareSelfFrame)
  SCApplyPanelStyle(StatCompareTargetFrame)
end
if SCRequestPanelLayout then SCRequestPanelLayout() end

  pfUI.addonskinner:UnregisterSkin("StatCompare")
end)
