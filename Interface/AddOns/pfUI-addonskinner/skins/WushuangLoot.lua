-- ============================================
--  WushuangLoot 皮肤（无双交互 / 无双拾取）
--  完整覆盖 WSLootFrame 设置面板：
--    1. 主面板：暴雪 DialogBox 边框 + 平铺底 → pfUI 底板
--    2. 关闭按钮（无名 UIPanelCloseButton，按锚点 + 尺寸定位）
--    3. 全部复选框（尸体 / 剥皮 / 道具 / 商人 / 交互指定NPC），数量自适应
--    4. 勾选标记：插件用 SetScript 覆盖了模板 OnClick，暴雪「勾上换成对勾贴图」的
--       逻辑不再执行；SkinCheckbox 又把 normal/pushed/highlight 三态贴图清空
--       → 勾与不勾外观完全一样。客户端没有常驻对勾贴图时这里自绘一枚 pfUI 对勾。
--    5. NPC 过滤输入框（InputBoxTemplate 左/中/右三块贴图）
--    6. 标题 / 提示 / 复选框标签统一 pfUI 字体
--    7. 速度滑块（若存在，只有 WSLMain 版本才有）
--  小地图按钮保持原样（自带金环 + 圆底，再套一层背景反而难看）。
-- ============================================

pfUI.addonskinner:RegisterSkin("WushuangLoot", function()
  local penv = pfUI:GetEnvironment()
  local StripTextures   = penv.StripTextures
  local CreateBackdrop  = penv.CreateBackdrop
  local SkinCloseButton = penv.SkinCloseButton
  local SkinCheckbox    = penv.SkinCheckbox
  local SkinSlider      = penv.SkinSlider
  local SetHighlight    = penv.SetHighlight
  local HookScript      = penv.HookScript

  local frame = _G["WSLootFrame"]
  if not frame then return end
  if frame.pfWSLootSkinned then return end
  frame.pfWSLootSkinned = true

  local font = pfUI.font_default or STANDARD_TEXT_FONT

  local function RestyleFont(region)
    if not region or not region.SetFont or not font then return end
    local size
    if region.GetFont then
      local _, s = region:GetFont()
      size = s
    end
    region:SetFont(font, size or 12, "OUTLINE")
  end

  -- ---------- 1. 主面板 ----------
  -- 先摘掉暴雪的 SetBackdrop 材质（对话框边框 + 平铺背景），再铺 pfUI 底板，
  -- 否则两层边框叠在一起。
  frame:SetBackdrop(nil)
  StripTextures(frame)
  CreateBackdrop(frame, nil, nil, .75)

  -- ---------- 2. 关闭按钮 ----------
  -- CreateFrame("Button", nil, ...) 无全局名，只能按 TOPRIGHT 锚点 + 尺寸定位。
  local closeBtn
  for _, child in ipairs({frame:GetChildren()}) do
    if child.GetObjectType and child:GetObjectType() == "Button" then
      local point, relativeTo = child:GetPoint()
      local w, h = child:GetWidth(), child:GetHeight()
      if point == "TOPRIGHT" and (relativeTo == frame or relativeTo == nil)
         and w and h and w >= 16 and w <= 40 and h >= 16 and h <= 40 then
        closeBtn = child
        break
      end
    end
  end
  if closeBtn then
    SkinCloseButton(closeBtn, frame.backdrop, -6, -6)
  end

  -- ---------- 3./4. 复选框 + 勾选标记 ----------
  -- 常驻对勾贴图检测：Turtle 1.17 这类把 checkedtexture 回填进来的客户端，
  -- 勾选状态由客户端自己画，重复自绘会叠出两层对勾。
  local function HasCheckedTexture(cb)
    for _, region in ipairs({cb:GetRegions()}) do
      if region.GetObjectType and region:GetObjectType() == "Texture"
         and region.GetTexture and region:GetTexture() == "Interface\\Buttons\\UI-CheckBox-Check" then
        return true
      end
    end
    return false
  end

  local syncers = {}

  local function SkinWSCheckbox(cb)
    if not cb or cb.pfWSCBSkinned then return end
    cb.pfWSCBSkinned = true

    -- 20px：与仓库内 Atlas / AtlasLoot 皮肤取值一致；28px 行距放得下 28px 底板。
    SkinCheckbox(cb, 20)

    -- 标签挂到 pfUI 底板右侧：底板比按钮外扩 4px，仍按按钮 RIGHT +5 会顶到边框上。
    for _, region in ipairs({cb:GetRegions()}) do
      if region.GetObjectType and region:GetObjectType() == "FontString" then
        RestyleFont(region)
        if cb.backdrop then
          region:ClearAllPoints()
          region:SetPoint("LEFT", cb.backdrop, "RIGHT", 5, 0)
        end
      end
    end

    if cb.backdrop and not HasCheckedTexture(cb) then
      local check = cb:CreateTexture(nil, "OVERLAY")
      check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
      check:SetPoint("TOPLEFT", cb.backdrop, "TOPLEFT", 3, -3)
      check:SetPoint("BOTTOMRIGHT", cb.backdrop, "BOTTOMRIGHT", -3, 3)
      check:SetVertexColor(0, 1, .4)
      check:Hide()

      local state
      local function Sync()
        local on = cb:GetChecked() and true or false
        if state == on then return end
        state = on
        if on then check:Show() else check:Hide() end
      end
      Sync()
      table.insert(syncers, Sync)
      HookScript(cb, "OnClick", Sync)
      HookScript(cb, "OnShow", Sync)
    end

    -- 悬停时底板边框变职业色（tooltip 脚本已存在，HookScript 会保留）
    if SetHighlight then SetHighlight(cb) end
  end

  -- 扫全部子复选框，而不是写死名字区间：
  -- 插件从 3 类扩到 4 类（新增「剥皮」「商人」）时不会漏掉（旧皮肤写死 1..3）。
  for _, child in ipairs({frame:GetChildren()}) do
    if child.GetObjectType and child:GetObjectType() == "CheckButton" then
      SkinWSCheckbox(child)
    end
  end

  -- 程序化改勾选（「商人」与「交互指定NPC」互斥时会 SetChecked）不会触发 OnClick，
  -- 面板显示期间用一次 OnUpdate 轮询同步对勾；隐藏时不跑，开销可忽略。
  if table.getn(syncers) > 0 then
    local sync = CreateFrame("Frame")
    sync:SetScript("OnUpdate", function()
      if not frame:IsShown() then return end
      for i = 1, table.getn(syncers) do
        syncers[i]()
      end
    end)
  end

  -- ---------- 5. NPC 过滤输入框 ----------
  local edit = _G["WSLootFilterEdit"]
  if edit then
    -- InputBoxTemplate 的 左/中/右 三块底图，不限定层全部清掉（原皮肤只清 BACKGROUND）
    StripTextures(edit, true)
    CreateBackdrop(edit, nil, true)
    if edit.SetTextInsets then
      edit:SetTextInsets(5, 5, 5, 5)
    end
    RestyleFont(edit)
  end

  -- ---------- 6. 标题 / 提示 ----------
  -- pfUI 底板是独立子帧，文字必须挪到它下面才不会被背景盖住（锚点不变，位置不动）。
  if frame.backdrop then
    for _, region in ipairs({frame:GetRegions()}) do
      if region.GetObjectType and region:GetObjectType() == "FontString" then
        RestyleFont(region)
        region:SetParent(frame.backdrop)
      end
    end
  end

  -- ---------- 7. 速度滑块（可选） ----------
  -- SkinSlider 内部用 GetOrientation（3.0+ API），1.12 上可能不存在，用 pcall 兜底。
  local slider = _G["WSLootSpeedSlider"]
  if slider then
    local ok = SkinSlider and pcall(SkinSlider, slider)
    if not ok then
      StripTextures(slider)
      CreateBackdrop(slider, nil, true)
      local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
      if thumb then thumb:SetTexture(1, .82, 0) end
    end
    for _, region in ipairs({slider:GetRegions()}) do
      if region.GetObjectType and region:GetObjectType() == "FontString" then
        RestyleFont(region)
      end
    end
  end
end)
