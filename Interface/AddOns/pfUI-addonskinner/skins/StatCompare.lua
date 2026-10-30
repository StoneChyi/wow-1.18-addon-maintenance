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

-- =====================================================================
-- 设置窗口（小地图图标左键 / /statc 打开）
-- 结构来自 StatCompareUI\SCOptions.xml：StatCompareOptFrame 下挂两个标签页、
-- 关闭按钮、确定按钮，以及 SubFrame1（46 个勾选项）和 SubFrame2（3 个勾选 + 1 个滑块）。
-- 窗口常驻内存，皮肤只做一次。
-- =====================================================================
local api = pfUI.api
local FS = 13
if C and C.global and tonumber(C.global.font_size) then FS = tonumber(C.global.font_size) end

local function SetFontString(fs)
  if fs and fs.SetFont and pfUI.font_default then
    pcall(fs.SetFont, fs, pfUI.font_default, FS, "OUTLINE")
  end
end

-- 勾选框：pfUI 底板默认外扩 4px，而原生勾选贴图（$parentCheck）固定 32x32、不随框体缩放，
-- 20px 的框会出现「深色大框 + 黄色勾顶到框外压住右侧文字」。统一缩到 16px 并把勾塞进框内。
local CHECK_SIZE = 16

local function FitCheckTexture(cb)
  local name = cb.GetName and cb:GetName()
  local chk = name and getglobal(name .. "Check")
  if not chk and cb.GetCheckedTexture then
    chk = cb:GetCheckedTexture()
  end
  if chk and chk.SetAllPoints then
    chk:ClearAllPoints()
    chk:SetAllPoints(cb)
  end
end

local function SkinOptCheckbox(cb)
  if not cb or cb.pfStatCompareCheck then return end
  cb.pfStatCompareCheck = true

  pcall(api.SkinCheckbox, cb, CHECK_SIZE)
  FitCheckTexture(cb)

  if cb.backdrop then
    cb.backdrop:ClearAllPoints()
    cb.backdrop:SetPoint("TOPLEFT", cb, "TOPLEFT", -1, 1)
    cb.backdrop:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", 1, -1)
  end

  -- 基础页的勾选框是 TOPRIGHT 贴到标签 TOPLEFT+1 的，框缩到 16 之后往左挪 3px，
  -- 让方框和文字之间留出空隙，不再压住第一个字。
  local point, rel, relPoint, x, y = cb:GetPoint()
  if point == "TOPRIGHT" and relPoint == "TOPLEFT" and rel then
    cb:ClearAllPoints()
    cb:SetPoint(point, rel, relPoint, (x or 0) - 3, y or 0)
  end
  -- 文字沿用插件原字号：46 个勾选项的列排版按暴雪字号算的，换字体会串行
end

local of = getglobal("StatCompareOptFrame")
if of and not of.pfStatCompare then
  of.pfStatCompare = true

  -- 主窗口：清掉 XML 里的 DialogBox 底板 + 贴图，换成 pfUI 面板。
  -- 用 legacy 模式（底板直接画在窗框上）：StatCompareOptFrame 是 XML 顶层 frameLevel=0 的框，
  -- pfUI 的独立 backdrop 子框在这种框上会被压到看不见，窗口会变成全透明、只看得见游戏画面。
  if of.SetBackdrop then of:SetBackdrop(nil) end
  pcall(api.StripTextures, of)
  pcall(api.CreateBackdrop, of, nil, true)

  -- 关闭按钮（SCButtons-Up/Down 两张贴图）
  local close = getglobal("StatCompareOptCloseButton")
  if close then
    pcall(api.SkinCloseButton, close, of, -6, -6)
  end

  -- 窗口左下角的标题文字
  SetFontString(getglobal("SCOptTitle"))

  -- 两个标签页：UIPanelButtonGrayTemplate，文字原本偏灰
  for i = 1, 2 do
    local tab = getglobal("StatCompareOptTab" .. i)
    if tab then
      pcall(api.SkinButton, tab)
      if tab.SetTextColor then tab:SetTextColor(1, 1, 1, 1) end
      if tab.GetFontString then SetFontString(tab:GetFontString()) end
    end
  end

  -- 确定按钮
  local ok = getglobal("StatCompareOkButton")
  if ok then
    pcall(api.SkinButton, ok)
    if ok.SetTextColor then ok:SetTextColor(1, 1, 1, 1) end
    ok:SetHeight(20)
  end

  -- 基础配置页：46 个 ShowXXX 勾选框
  local sub1 = getglobal("StatCompareOptSubFrame1")
  if sub1 then
    for _, c in ipairs({sub1:GetChildren()}) do
      if c.GetObjectType and c:GetObjectType() == "CheckButton" then
        SkinOptCheckbox(c)
      end
    end
  end

  -- 高级配置页：3 个 OptionsCheckButtonTemplate 勾选框 + 小地图角度滑块
  local sub2 = getglobal("StatCompareOptSubFrame2")
  if sub2 then
    for _, c in ipairs({sub2:GetChildren()}) do
      local ot = c.GetObjectType and c:GetObjectType()
      if ot == "CheckButton" then
        SkinOptCheckbox(c)
      elseif ot == "Slider" and not c.pfStatCompareSlider then
        -- SkinSlider 会挪动 Low/High/Text 这三个 FontString，重复调用会越挪越偏
        c.pfStatCompareSlider = true
        pcall(api.SkinSlider, c)
      end
    end
  end

  -- 这三行的文字原本紧贴着 pfUI 方框的右边缘（会压住第一个字），统一右移 6px。
  -- 用「原始 x + 偏移」的绝对值写法，以后这类皮肤重复执行也不会累积漂移。
  local function NudgeLabel(name, dx)
    local fs = getglobal(name .. "Text")
    if not fs or not fs.GetPoint then return end
    local p, rel, rp, x, y = fs:GetPoint()
    if not p then return end
    if fs.pfSCX == nil then fs.pfSCX = x or 0 end
    fs:ClearAllPoints()
    if rel then
      fs:SetPoint(p, rel, rp, fs.pfSCX + dx, y or 0)
    else
      fs:SetPoint(p, fs.pfSCX + dx, y or 0)
    end
  end

  NudgeLabel("StatCompareShowMinimapOpt", 6)    -- 显示/隐藏小地图按钮
  NudgeLabel("StatCompareShowSelfFrameOpt", 6)  -- 察看对方玩家信息时显示自己的属性比较窗口
  NudgeLabel("StatCompareShowBuffBonusOpt", 6)  -- 统计装备属性时加入Buf加成统计信息
end

  pfUI.addonskinner:UnregisterSkin("StatCompare")
end)
