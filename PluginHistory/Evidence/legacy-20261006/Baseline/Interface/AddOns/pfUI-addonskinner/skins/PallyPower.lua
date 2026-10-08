-- pfUI-addonskinner skin for PallyPower
-- 覆盖对象（全部为 XML 静态创建，ADDON_LOADED 时已存在）：
--   PallyPowerFrame         主分配面板（XML 自绘 tooltip 底板；ARTWORK 层的职业图标/分隔线
--                           纹理是功能元素，禁止对主面板 StripTextures，仅替换底板）
--   PallyPowerBuffBar       左侧悬浮祝福条（buff 按钮底色由插件扫描逻辑 SetBackdropColor
--                           动态设置状态色：红=无人有 / 黄=有人缺 / 黑=齐全，必须保留该机制）
--   PallyPower_OptionsFrame 设置窗口（2 个数字 EditBox + 3 个 OptionsCheckButtonTemplate）
-- grid 格子与 buff 按钮走 legacy 底板（画在按钮自身，不新增子帧），
-- OVERLAY 层图标与后续 SetBackdropColor 状态色均不受影响。

local addon = "PallyPower"

-- 调试标志（全局，进游戏 /run print(FLAG_RAN, FLAG_OK, FLAG_ERR) 验证）
_G.FLAG_RAN = _G.FLAG_RAN or 0
_G.FLAG_OK  = _G.FLAG_OK  or false
_G.FLAG_ERR = _G.FLAG_ERR or nil

local function SkinAddon()
  _G.FLAG_RAN = _G.FLAG_RAN + 1

  -- 与 GUI 的「Disable Skin XXX」语义保持一致（勾上 = 禁用）
  local disabled = false
  pcall(function()
    if C and C.addonskinner and C.addonskinner.disabled and C.addonskinner.disabled[addon] == "1" then
      disabled = true
    end
  end)
  if disabled then return end

  if not pfUI or not pfUI.api then return end
  local api = pfUI.api
  local CreateBackdrop       = api.CreateBackdrop
  local CreateBackdropShadow = api.CreateBackdropShadow
  local SkinButton           = api.SkinButton
  local SkinCheckbox         = api.SkinCheckbox

  local closeTex = (pfUI.media and pfUI.media["img:close"]) or "Interface\\AddOns\\pfUI\\img\\close"

  -- 标题字体：只换字体族、保留原字号（zhCN 下 font_default 已映射中文字体）
  local function SkinTitle(fs, gold)
    if not fs then return end
    pcall(function()
      local _, size = fs:GetFont()
      fs:SetFont(pfUI.font_default, size or 12, "OUTLINE")
      if gold then fs:SetTextColor(1, 0.82, 0.2, 1) end
    end)
  end

  -- 关闭按钮：复用 NormalTexture 画 pfUI 红色 X，绕开 SkinCloseButton 的全局纹理名冲突
  local function SkinCustomCloseButton(b)
    if not b or b.pfuiCloseSkinned then return end
    pcall(function()
      SkinButton(b, 1, .25, .25)
      b:SetWidth(15)
      b:SetHeight(15)
      b:SetNormalTexture(closeTex)
      local nt = b:GetNormalTexture()
      if nt then
        nt:SetTexture(closeTex)
        nt:SetVertexColor(1, .25, .25, 1)
        nt:SetTexCoord(0, 1, 0, 1)
      end
      b:SetPushedTexture("")
      b:SetHighlightTexture("")
      b:SetDisabledTexture("")
      b.pfuiCloseSkinned = true
    end)
  end

  -- 图标格按钮（grid / buff）：legacy 底板画在按钮自身，图标与状态色不受影响
  local function SkinIconButton(btn)
    if not btn or btn.pfuiSkinned then return end
    pcall(function()
      CreateBackdrop(btn, nil, true)
      btn.pfuiSkinned = true
    end)
  end

  -- 数字输入框：只清 Common-Input-Border 三件套（按命名后缀精确匹配），
  -- 保留 HighlightText 等内部纹理，再套 pfUI legacy 底板
  local function SkinEditBox(eb)
    if not eb or eb.pfuiSkinned then return end
    pcall(function()
      local regions = { eb:GetRegions() }
      for _, r in ipairs(regions) do
        if r and type(r.GetName) == "function" then
          local n = r:GetName()
          if n and (string.find(n, "Left$") or string.find(n, "Right$") or string.find(n, "Middle$")) then
            r:SetTexture("")
          end
        end
      end
      CreateBackdrop(eb, nil, true)
      pcall(function() eb:SetTextInsets(5, 5, 0, 0) end)
      pcall(function() eb:SetTextColor(1, 1, 1, 1) end)
      eb.pfuiSkinned = true
    end)
  end

  -- ============ 主分配面板 PallyPowerFrame ============
  local main = _G["PallyPowerFrame"]
  if main and not main.pfuiSkinned then
    pcall(function()
      main:SetBackdrop(nil)          -- 丢掉 XML 的 tooltip 底板
      CreateBackdrop(main, nil, nil, .75)
      main.pfuiSkinned = true
    end)
    pcall(function() CreateBackdropShadow(main) end)

    SkinTitle(_G["PallyPowerFrameTitleText"], true)

    -- 底部动作按钮（GameMenuButtonTemplate，带文字）
    SkinButton(_G["PallyPowerFrameRefresh"])
    SkinButton(_G["PallyPowerFrameClear"])
    SkinButton(_G["PallyPowerFrameOptions"])

    -- 右上关闭按钮（UIPanelCloseButton）
    SkinCustomCloseButton(_G["PallyPowerFrameCloseButton"])

    -- 12 行 x 10 列祝福分配格（BuffGridButtonTemplate，图标居中 OVERLAY 层）
    for p = 1, 12 do
      for c = 0, 9 do
        SkinIconButton(_G["PallyPowerFramePlayer" .. p .. "Class" .. c])
      end
    end

    -- 左下角「小祝福(10分钟)」勾选框（OptionsCheckButtonTemplate，对勾保留）
    SkinCheckbox(_G["TenMinBlessingMainChk"])
  end

  -- ============ 左侧悬浮祝福条 PallyPowerBuffBar ============
  local bar = _G["PallyPowerBuffBar"]
  if bar and not bar.pfuiSkinned then
    pcall(function()
      bar:SetBackdrop(nil)
      CreateBackdrop(bar, nil, true)   -- legacy：高度动态变化（30+34*n）时底板自动铺满
      bar.pfuiSkinned = true
    end)
    pcall(function() CreateBackdropShadow(bar) end)

    SkinTitle(_G["PallyPowerBuffBarTitleText"])

    -- buff 按钮：替换 XML 的 tooltip 底板为 pfUI 底板，
    -- 插件扫描逻辑后续 SetBackdropColor 状态色（红/黄/黑）继续生效
    for i = 1, 10 do
      SkinIconButton(_G["PallyPowerBuffBarBuff" .. i])
    end
  end

  -- ============ 设置窗口 PallyPower_OptionsFrame ============
  local opt = _G["PallyPower_OptionsFrame"]
  if opt and not opt.pfuiSkinned then
    pcall(function()
      opt:SetBackdrop(nil)
      CreateBackdrop(opt, nil, nil, .9)
      opt.pfuiSkinned = true
    end)
    pcall(function() CreateBackdropShadow(opt) end)

    SkinTitle(_G["PallyPower_OptionsFrameTitle"], true)

    SkinCustomCloseButton(_G["PallyPower_OptionsFrameCloseButton"])

    SkinEditBox(_G["PallyPower_OptionsFrameScan1"])
    SkinEditBox(_G["PallyPower_OptionsFrameScan2"])

    -- 复选框（保持 XML 的 20x20 尺寸，对勾 CheckedTexture 由 pfUI 保留）
    SkinCheckbox(_G["PallyPower_OptionsFrameFeedback"])
    SkinCheckbox(_G["PallyPower_OptionsFrameSmart"])
    SkinCheckbox(_G["TenMinBlessingChk"])
    -- 同批新增的两个勾选框
    SkinCheckbox(_G["PallyPower_OptionsFrameSolo"])
    SkinCheckbox(_G["PallyPower_OptionsFrameSoloForce"])
  end

  _G.FLAG_OK = true
end

-- (1) 尝试登记到 addonskinner（供 GUI 列表/统一禁用），pcall 防止时序 nil
pcall(function()
  if pfUI and pfUI.addonskinner and type(pfUI.addonskinner.RegisterSkin) == "function" then
    pfUI.addonskinner:RegisterSkin(addon, SkinAddon)
  end
end)

-- (2) 自包含触发器：不依赖 addonskinner 加载时序，确保皮肤一定执行
local trig = CreateFrame("Frame")
trig:RegisterEvent("ADDON_LOADED")
trig:RegisterEvent("VARIABLES_LOADED")
trig:RegisterEvent("PLAYER_LOGIN")
trig:SetScript("OnEvent", function()
  -- addonskinner 若此时才就绪，补登记一次
  pcall(function()
    if pfUI and pfUI.addonskinner and type(pfUI.addonskinner.RegisterSkin) == "function" then
      pfUI.addonskinner:RegisterSkin(addon, SkinAddon)
    end
  end)

  if event == "ADDON_LOADED" and arg1 ~= addon then return end
  if IsAddOnLoaded(addon) then
    pcall(SkinAddon)
    trig:UnregisterAllEvents()
  end
end)
