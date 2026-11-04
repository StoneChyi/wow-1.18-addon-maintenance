-- ============================================
--  ActionBarProfiles（ABP · 动作条布局保存）皮肤
--  ABP 的「设置界面」其实只有两块：
--    1. 小地图图标点出来的 UIDropDownMenu 菜单（加载 / 保存子菜单 / 删除子菜单）
--    2. ABP_ExportFrame —— 导出 / 导入文本窗口
--  菜单列表的底板 pfUI 本体已经统一处理了（modules/skin.lua 给 DropDownList1..N
--  的 MenuBackdrop / Backdrop 都套了 CreateBackdrop），所以这里只用补 pfUI 没管的部分：
--    1. 导出窗口：暴雪 DialogBox 金边 + 平铺底 → pfUI 底板
--       必须先 SetBackdrop(nil)，否则两层边框（pfUI 底板 + 暴雪金边）叠在一起
--    2. 顶部 40px 空档补一个 pfUI 标题，并补一个真正的关闭叉
--       （原来只有底部「关闭」按钮，没有右上角的 X）
--    3. 三个 UIPanelButtonTemplate 按钮 → SkinButton（字体也一起换成 pfUI 字体）
--    4. 多行编辑框的滚动条 → SkinScrollbar；编辑框背后单独垫一块底板当输入区
--       （底板不能挂在 ScrollFrame 自己或 ScrollChild 上：挂 ScrollChild 会跟着文字滚走，
--         挂 ScrollFrame 会被 createBackdrop 的 hit rect 撑大，独立子帧最稳）
--    5. 补进 UISpecialFrames，ESC 可关
--  刻意不动的地方：
--    · 编辑框字体。导出内容全是中文法术名 / 装备名，pfUI.font_default 在别人机器上
--      可能是 Myriad Pro（无中日韩字形），强改会整片变方块。
--    · 小地图图标（ActionBarProfiles_IconFrame）。自带 26x26 图标 + 暴雪缩放高亮环，
--      再套一层底板反而更花，且位置靠 ABPButton_UpdatePosition 用角度计算，别碰。
-- ============================================

pfUI.addonskinner:RegisterSkin("ActionBarProfiles", function()

  local penv = pfUI:GetEnvironment()
  local StripTextures        = penv.StripTextures
  local CreateBackdrop       = penv.CreateBackdrop
  local CreateBackdropShadow = penv.CreateBackdropShadow
  local SkinButton           = penv.SkinButton
  local SkinCloseButton      = penv.SkinCloseButton
  local SkinScrollbar        = penv.SkinScrollbar

  local frame = _G["ABP_ExportFrame"]
  if not frame then return end
  if frame.pfABPSkinned then return end
  frame.pfABPSkinned = true

  local font = pfUI.font_default or STANDARD_TEXT_FONT
  local font_size = tonumber(pfUI_config.global.font_size) or 12

  -- ---------- 1. 主窗口 ----------
  if frame.SetBackdrop then frame:SetBackdrop(nil) end
  StripTextures(frame)
  CreateBackdrop(frame, nil, nil, .75)
  CreateBackdropShadow(frame)

  -- ---------- 2. 标题 + 关闭叉 ----------
  if frame.backdrop then
    if not frame.pfTitle then
      local title = frame.backdrop:CreateFontString("ABP_PfTitle", "OVERLAY", "GameFontNormal")
      title:SetFont(font, font_size + 1, "OUTLINE")
      title:SetPoint("TOPLEFT", frame.backdrop, "TOPLEFT", 10, -8)
      -- 不能用 appearance.border.color：那是描边色，pfUI 默认 "0.2,0.2,0.2,1"(深灰)，
      -- 描在深色底板上就是纯黑看不见。这里跟 pfUI 自己的窗口标题一致，用青绿 .2,1,.8
      title:SetTextColor(.2, 1, .8, 1)
      title:SetText("动作条布局")
      frame.pfTitle = title
    end

    if not frame.pfCloseButton then
      local close = CreateFrame("Button", "ABP_PfCloseButton", frame, "UIPanelCloseButton")
      if close then
        close:SetFrameLevel(frame:GetFrameLevel() + 3)
        SkinCloseButton(close, frame.backdrop, -6, -6)
        -- 模板自带的 HideParentPanel 在 1.12 上行为不完全一致，直接写死最稳
        close:SetScript("OnClick", function() frame:Hide() end)
        frame.pfCloseButton = close
      end
    end
  end

  -- ---------- 3. 按钮 ----------
  local function SkinABPButton(button)
    if not button or button.pfABPButtonSkinned then return end
    button.pfABPButtonSkinned = true
    StripTextures(button, true)
    SkinButton(button)
  end
  SkinABPButton(_G["ABP_ExportDoButton"])
  SkinABPButton(_G["ABP_ImportDoButton"])
  SkinABPButton(_G["ABP_ExportCloseButton"])

  -- ---------- 4. 输入区底板 + 滚动条 ----------
  local scroll = _G["ABP_ExportScrollFrame"]
  if scroll then
    if not frame.pfInputBg then
      local bg = CreateFrame("Frame", nil, frame)
      bg:SetPoint("TOPLEFT", scroll, "TOPLEFT", -6, 6)
      bg:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 6, -6)
      local level = scroll:GetFrameLevel()
      bg:SetFrameLevel(level > 0 and level - 1 or 0)
      CreateBackdrop(bg, nil, true)
      frame.pfInputBg = bg
    end

    local bar = _G["ABP_ExportScrollFrameScrollBar"]
    if bar then SkinScrollbar(bar) end
  end

  -- ---------- 5. ESC 关闭 ----------
  local found = false
  for i = 1, table.getn(UISpecialFrames) do
    if UISpecialFrames[i] == "ABP_ExportFrame" then
      found = true
      break
    end
  end
  if not found then table.insert(UISpecialFrames, "ABP_ExportFrame") end

end)
