-- ============================================
--  WushuangLoot 皮肤 (无双交互 / 无双拾取)
--  美化主设置界面 WSLootFrame：
--    - 替换原对话框材质为 pfUI 风格背景
--    - 无名关闭按钮按位置/尺寸自动定位
--    - 3 个分类复选框 + NPC 过滤复选框
--    - NPC 名字过滤输入框
--  小地图按钮保持原样（圆形图标，套背景反而难看）。
-- ============================================

pfUI.addonskinner:RegisterSkin("WushuangLoot", function()
  local penv = pfUI:GetEnvironment()
  local StripTextures   = penv.StripTextures
  local CreateBackdrop  = penv.CreateBackdrop
  local SkinCloseButton = penv.SkinCloseButton
  local SkinCheckbox    = penv.SkinCheckbox

  local frame = _G["WSLootFrame"]
  if not frame then return end
  if frame.pfWSLootSkinned then return end
  frame.pfWSLootSkinned = true

  -- 清除原对话框 SetBackdrop 材质（对话框边框 + 平铺背景），
  -- 改用 pfUI 风格背景，避免两层边框叠加。
  frame:SetBackdrop(nil)
  StripTextures(frame)
  CreateBackdrop(frame, nil, nil, .75)

  -- 关闭按钮：CreateFrame("Button", nil, ...) 无全局名，
  -- 只能在子节点里按 TOPRIGHT + 尺寸(32x32) 定位。
  local closeBtn
  for _, child in ipairs({frame:GetChildren()}) do
    if child:GetObjectType() == "Button" then
      local w, h = child:GetWidth(), child:GetHeight()
      if w and h and w >= 28 and w <= 36 and h >= 28 and h <= 36 then
        local point, relativeTo = child:GetPoint()
        if point == "TOPRIGHT" and relativeTo == frame then
          closeBtn = child
          break
        end
      end
    end
  end
  if closeBtn then
    SkinCloseButton(closeBtn, frame.backdrop, -6, -6)
  end

  -- 标题 / 提示文本：无名 FontString 区域，移到 backdrop 之上，
  -- 否则会被 pfUI 背景盖住（锚点相对 WSLootFrame，位置不变）。
  if frame.backdrop then
    for _, region in ipairs({frame:GetRegions()}) do
      if region:GetObjectType() == "FontString" then
        region:SetParent(frame.backdrop)
      end
    end
  end

  -- 分类复选框：尸体 / 道具 / 商人
  for i = 1, 3 do
    local cb = _G["WSLootCB" .. i]
    if cb then SkinCheckbox(cb) end
  end

  -- NPC 名字过滤复选框
  local filterCB = _G["WSLootFilterCB"]
  if filterCB then SkinCheckbox(filterCB) end

  -- NPC 名字过滤输入框 (InputBoxTemplate)
  local filterEdit = _G["WSLootFilterEdit"]
  if filterEdit then
    StripTextures(filterEdit, true, "BACKGROUND")
    CreateBackdrop(filterEdit, nil, true)
  end
end)
