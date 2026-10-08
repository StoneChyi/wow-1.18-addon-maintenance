-- pfUI-addonskinner skin for BrainwasherPro (天赋备注图形版 / 地精洗脑装置)
-- 暗黑风格 pfUI 美化：主窗口、编辑窗口、天赋槽、按钮、关闭按钮、图标、输入框统一套 pfUI 暗色。
--
-- 调试：进游戏后执行
--   /run print(FLAG_BWP_RAN, FLAG_BWP_DISABLED, FLAG_BWP_HOOK, FLAG_BWP_MAIN, FLAG_BWP_EDIT, FLAG_BWP_CLOSE, FLAG_BWP_OK, FLAG_BWP_ERR)
--   RAN>0         皮肤逻辑已执行（自包含触发器生效）
--   DISABLED=1    GUI「Disable Skin BrainwasherPro」被勾选 -> 皮肤被跳过，去 GUI 取消勾选
--   HOOK=1        已钩住创建函数（懒加载窗口会自动套皮肤）
--   MAIN/EDIT>0   主/编辑窗口动作按钮被皮肤化数量
--   CLOSE>0       关闭按钮被皮肤化数量
--   OK=true       至少跑过一遍
--   ERR           非空表示执行期报错（发我即可定位）

local addon = "BrainwasherPro"

-- 调试标志（全局，方便 /run print 验证）
_G.FLAG_BWP_RAN      = _G.FLAG_BWP_RAN      or 0
_G.FLAG_BWP_DISABLED = _G.FLAG_BWP_DISABLED or 0
_G.FLAG_BWP_HOOK     = _G.FLAG_BWP_HOOK     or 0
_G.FLAG_BWP_MAIN     = _G.FLAG_BWP_MAIN     or 0
_G.FLAG_BWP_EDIT     = _G.FLAG_BWP_EDIT     or 0
_G.FLAG_BWP_CLOSE    = _G.FLAG_BWP_CLOSE    or 0
_G.FLAG_BWP_OK       = _G.FLAG_BWP_OK       or false
_G.FLAG_BWP_ERR      = _G.FLAG_BWP_ERR      or nil

-- ============================================================
-- 皮肤主体
-- ============================================================
local function SkinBrainwasherPro()
  _G.FLAG_BWP_RAN = (_G.FLAG_BWP_RAN or 0) + 1

  -- 尊重 GUI「Disable Skin」勾选（与 addonskinner 加载器一致）
  local disabled = false
  pcall(function()
    if C and C.addonskinner and C.addonskinner.disabled and C.addonskinner.disabled[addon] == "1" then
      disabled = true
    end
  end)
  if disabled then
    _G.FLAG_BWP_DISABLED = 1
    return
  end

  if not pfUI or not pfUI.api then return end
  local api = pfUI.api
  local StripTextures    = api.StripTextures
  local CreateBackdrop  = api.CreateBackdrop
  local SkinButton      = api.SkinButton
  local hooksecurefunc  = api.hooksecurefunc or _G.hooksecurefunc

  -- 关闭按钮自定义处理：不用 SkinCloseButton，因为它用死全局名 "pfQuestionDialogCloseTex"
  -- 多个按钮同名会冲突，导致 X 不显示。这里直接用 FontString 在按钮上画一个红色 "×"，
  -- 不依赖任何 tga 纹理，保证在本客户端一定能看到。
  local function SkinCustomCloseButton(b)
    if not b or not b.IsObjectType or not b:IsObjectType("Button") then return end
    pcall(function()
      pfUI.api.SkinButton(b, 1, .25, .25)
      b:SetWidth(15)
      b:SetHeight(15)

      -- 清掉模板自带的纹理，避免它盖住文字
      b:SetNormalTexture("")
      b:SetPushedTexture("")
      b:SetHighlightTexture("")
      b:SetDisabledTexture("")

      -- 红色 "×" 文字，居中，大小适配 15x15
      if not b.xtext then
        b.xtext = b:CreateFontString(nil, "OVERLAY")
        b.xtext:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        b.xtext:SetPoint("CENTER", b, "CENTER", 0, 0)
        b.xtext:SetText("×")
        b.xtext:SetTextColor(1, .25, .25, 1)
      end
    end)
  end

  _G.FLAG_BWP_MAIN  = 0
  _G.FLAG_BWP_EDIT  = 0
  _G.FLAG_BWP_CLOSE = 0

  -- 任意 Frame 套 pfUI 暗色背景 + 细边框，并清除插件自带 backdrop
  local function DarkBackdrop(f, alpha)
    if not f or not f.IsObjectType or not f:IsObjectType("Frame") then return end
    pcall(function()
      f:SetBackdrop(nil)
      StripTextures(f)
      CreateBackdrop(f, nil, nil, alpha or .75)
    end)
  end

  -- 普通动作按钮（插件暗色样式的无模板按钮）：清掉自带 backdrop，套 pfUI 暗色按钮。
  -- CreateBackdrop 会把边框画在子 frame b.backdrop 上；插件自带的 OnEnter SetBackdropColor
  -- 作用在父 frame（已是 SetBackdrop(nil)）上，红闪被自动中和，不破坏 pfUI 边框。
  local function SkinActionButton(b, alpha)
    if not b or not b.IsObjectType or not b:IsObjectType("Button") then return end
    pcall(function()
      b:SetBackdrop(nil)
      StripTextures(b, true)
      CreateBackdrop(b, nil, nil, alpha or .8)
    end)
  end

  -- 图标按钮（天赋图标 / 编辑框大图标 / 空槽）：去掉纹理，套 pfUI 边框，保留内部图标
  local function SkinIconButton(b)
    if not b or not b.IsObjectType or not b:IsObjectType("Button") then return end
    pcall(function()
      b:SetNormalTexture("")
      b:SetPushedTexture("")
      b:SetDisabledTexture("")
      CreateBackdrop(b, nil, nil, .9)
    end)
  end

  -- 关闭按钮识别（UIPanelCloseButton 走 MinimizeButton 纹理）
  local function IsCloseButton(b)
    local nt = b.GetNormalTexture and b:GetNormalTexture()
    if nt then
      local t = nt:GetTexture() or ""
      if string.find(t, "MinimizeButton") or string.find(t, "CloseButton") then return true end
    end
    return false
  end

  -- 空槽纹理识别
  local function IsEmptySlot(b)
    local nt = b.GetNormalTexture and b:GetNormalTexture()
    if nt then
      local t = nt:GetTexture() or ""
      if string.find(t, "UI%-EmptySlot") then return true end
    end
    return false
  end

  -- 隐藏插件自带背景/标题纹理（DialogBox 标题条、Tooltip 背景底纹），交给 pfUI 画暗色边框
  local function HideNativeTextures(frame)
    local regions = { frame:GetRegions() }
    for _, r in ipairs(regions) do
      if r.IsObjectType and r:IsObjectType("Texture") then
        local t = r:GetTexture() or ""
        if string.find(t, "UI%-DialogBox%-Header") or string.find(t, "UI%-Tooltip%-Background") then
          r:Hide()
        end
      end
    end
  end

  -- 递归收集某根 frame 下所有 Button（跳过宏图标选择区，避免上千个按钮被处理）
  local collected = {}
  local function CollectButtons(frame)
    if not frame or not frame.IsObjectType or not frame:IsObjectType("Frame") then return end
    local nm = frame:GetName()
    if nm == "BrainwasherProIconContent" or nm == "BrainwasherProIconScrollFrame" then return end
    local kids = { frame:GetChildren() }
    for _, c in ipairs(kids) do
      if c.IsObjectType and c:IsObjectType("Button") then
        table.insert(collected, c)
      elseif c.IsObjectType and c:IsObjectType("Frame") then
        CollectButtons(c)
      end
    end
  end

  -- 在子树里找 EditBox（编辑框名称输入框没有全局名）
  local function FindEditBox(frame)
    if not frame or not frame.IsObjectType or not frame:IsObjectType("Frame") then return nil end
    local kids = { frame:GetChildren() }
    for _, c in ipairs(kids) do
      if c.IsObjectType and c:IsObjectType("EditBox") then
        return c
      elseif c.IsObjectType and c:IsObjectType("Frame") then
        local r = FindEditBox(c)
        if r then return r end
      end
    end
    return nil
  end

  -- 皮肤化一个动作按钮：模板按钮走 SkinButton，无模板暗色按钮走 SkinActionButton
  local function SkinAction(b)
    local nt = b.GetNormalTexture and b:GetNormalTexture()
    local t = nt and (nt:GetTexture() or "") or ""
    if string.find(t, "UI%-Panel%-Button") then
      pcall(SkinButton, b)          -- UIPanelButtonTemplate（风格切换 / 经典样式的底部按钮）
    else
      SkinActionButton(b)           -- 暗色样式的无模板按钮（重置/显示原版/隐藏点数/编辑/保存/确认/取消）
    end
  end

  -- 主窗口皮肤
  local function SkinMain()
    if not BrainwasherProFrame then return end
    HideNativeTextures(BrainwasherProFrame)
    DarkBackdrop(BrainwasherProFrame, .85)

    collected = {}
    CollectButtons(BrainwasherProFrame)
    for _, b in ipairs(collected) do
      local nm = b:GetName() or ""
        if IsCloseButton(b) then
          pcall(SkinCustomCloseButton, b)
          _G.FLAG_BWP_CLOSE = (_G.FLAG_BWP_CLOSE or 0) + 1
      elseif string.find(nm, "^BrainwasherProIcon%d+$") then
        pcall(SkinIconButton, b)    -- 天赋槽图标按钮
      elseif IsEmptySlot(b) then
        pcall(SkinIconButton, b)
      else
        SkinAction(b)
        _G.FLAG_BWP_MAIN = (_G.FLAG_BWP_MAIN or 0) + 1
      end
    end

    -- 4 个天赋槽外框
    for i = 1, 4 do
      local slot = _G["BrainwasherProSlot" .. i]
      if slot then DarkBackdrop(slot, .8) end
    end
  end

  -- 编辑窗口皮肤
  local function SkinEdit()
    if not BrainwasherProEditFrame then return end
    HideNativeTextures(BrainwasherProEditFrame)
    DarkBackdrop(BrainwasherProEditFrame, .85)

    -- 宏图标滚动背景区单独套暗色（内含上千宏图标，不逐个处理）
    if BrainwasherProIconScrollFrame then
      local bg = BrainwasherProIconScrollFrame:GetParent()
      if bg and bg.IsObjectType and bg:IsObjectType("Frame") then DarkBackdrop(bg, .9) end
    end

    collected = {}
    CollectButtons(BrainwasherProEditFrame)
    for _, b in ipairs(collected) do
        if IsCloseButton(b) then
          pcall(SkinCustomCloseButton, b)
          _G.FLAG_BWP_CLOSE = (_G.FLAG_BWP_CLOSE or 0) + 1
      elseif IsEmptySlot(b) then
        pcall(SkinIconButton, b)    -- 编辑框大图标 / 空槽
      else
        SkinAction(b)
        _G.FLAG_BWP_EDIT = (_G.FLAG_BWP_EDIT or 0) + 1
      end
    end

    -- 名称输入框（InputBoxTemplate）
    local editBox = FindEditBox(BrainwasherProEditFrame)
    if editBox then
      pcall(function()
        StripTextures(editBox, true, "BACKGROUND")
        CreateBackdrop(editBox, nil, true)
      end)
    end
  end

  -- 立即尝试（若窗口已存在）
  pcall(SkinMain)
  pcall(SkinEdit)

  -- 插件窗口是懒加载（首次与洗脑装置对话时创建），用 hooksecurefunc 钩住创建函数，
  -- 窗口一建好就套皮肤。同时钩 OnGossipShow，每次打开装置都再套一遍，双保险。
  -- 样式切换（经典 / 暗黑）会 ReloadUI，皮肤会重新注册，无需额外处理。
  if BrainwasherPro and hooksecurefunc and _G.FLAG_BWP_HOOK ~= 1 then
    if BrainwasherPro.CreateMainFrame then
      hooksecurefunc(BrainwasherPro, "CreateMainFrame", function() pcall(SkinMain) end)
    end
    if BrainwasherPro.CreateEditFrame then
      hooksecurefunc(BrainwasherPro, "CreateEditFrame", function() pcall(SkinEdit) end)
    end
    if BrainwasherPro.OnGossipShow then
      hooksecurefunc(BrainwasherPro, "OnGossipShow", function() pcall(SkinMain) end)
    end
    _G.FLAG_BWP_HOOK = 1
  end

  _G.FLAG_BWP_OK = true
end

-- ============================================================
-- (1) 尝试登记到 addonskinner（仅用于 GUI 列表/统一禁用，绝不因此抛错中断）
-- ============================================================
local function tryRegister()
  if pfUI and pfUI.addonskinner and type(pfUI.addonskinner.RegisterSkin) == "function" then
    local ok = pcall(pfUI.addonskinner.RegisterSkin, pfUI.addonskinner, addon, SkinBrainwasherPro)
    return ok
  end
  return false
end
tryRegister()

-- ============================================================
-- (2) 自包含触发器：保证皮肤一定执行，不依赖 addonskinner 加载器的时序
--     （pfUI 在依赖插件加载完成后才 boot，导致皮肤文件解析时
--      pfUI.addonskinner 尚为 nil，旧版 RegisterSkin 直接抛错使整个文件中止。）
-- ============================================================
local trig = CreateFrame("Frame")
trig:RegisterEvent("ADDON_LOADED")
trig:RegisterEvent("VARIABLES_LOADED")
trig:RegisterEvent("PLAYER_LOGIN")
trig:SetScript("OnEvent", function()
  -- addonskinner 就绪后补登记一次（不影响执行）
  if pfUI and pfUI.addonskinner and type(pfUI.addonskinner.RegisterSkin) == "function" then
    tryRegister()
  end

  -- 仅在目标插件已加载（或窗口已存在）时执行皮肤
  if event == "ADDON_LOADED" and arg1 ~= addon then return end
  if IsAddOnLoaded(addon) or _G[addon .. "Frame"] then
    pcall(SkinBrainwasherPro)
    -- 钩子已设好即可停止重复触发
    if _G.FLAG_BWP_HOOK == 1 then
      trig:UnregisterAllEvents()
    end
  end
end)
