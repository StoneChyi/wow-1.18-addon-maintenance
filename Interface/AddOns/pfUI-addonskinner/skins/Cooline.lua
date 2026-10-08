-- Cooline 主冷却条皮肤（仅外观，不改动逻辑）
-- 配置面板 CoolineConfigPanel 的关闭按钮由 Cooline 自身 settings.lua 在创建时直接调用 pfUI 的 SkinCloseButton 美化，
-- 因为面板是懒加载的，无法依赖此处的 RegisterSkin 时机。
pfUI.addonskinner:RegisterSkin("cooline", function()
  local frame = getglobal("cooline")
  if not frame or frame.pfUISkinned then return end
  frame.pfUISkinned = true

  -- 主冷却条背景（cooline 自带 statusbar 填充，这里补 pfUI 边框）
  pfUI.api.CreateBackdrop(frame)

  pfUI.addonskinner:UnregisterSkin("cooline")
end)
