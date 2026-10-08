-- pfUI-addonskinner skin for aux-addon (拍卖行助手 /aux)
-- pfUI 美化：主窗口、标签页、按钮、图标按钮、输入框、下拉框、复选框、
-- 滑动条、滚动条、面板背景、AuxTooltip 统一套 pfUI 暗色风格。
--
-- 兼容 aux 的 blizzard / modern 双主题：控件按类型递归识别，两种主题都套 pfUI。
-- aux 界面在 VARIABLES_LOADED 时一次性创建（aux_frame），之后不会重建；
-- /aux theme 切换主题需 ReloadUI，皮肤会随之重新应用。
--
-- 调试：进游戏后执行
--   /run print(FLAG_AUX_RAN, FLAG_AUX_BTN, FLAG_AUX_OK, FLAG_AUX_ERR)
--   RAN>0   皮肤逻辑已执行
--   BTN     被皮肤化的按钮/控件数量
--   OK=true 至少跑过一遍
--   ERR     非空表示执行期报错（发我即可定位）

local addon = "aux-addon"

-- 调试标志（全局，方便 /run print 验证）
_G.FLAG_AUX_RAN = _G.FLAG_AUX_RAN or 0
_G.FLAG_AUX_BTN = _G.FLAG_AUX_BTN or 0
_G.FLAG_AUX_OK  = _G.FLAG_AUX_OK or false
_G.FLAG_AUX_ERR = _G.FLAG_AUX_ERR or nil

-- ============================================================
-- 皮肤主体
-- ============================================================
local function SkinAux()
  _G.FLAG_AUX_RAN = (_G.FLAG_AUX_RAN or 0) + 1

  -- 尊重 GUI「Disable Skin」勾选（与 addonskinner 加载器一致）
  local disabled = false
  pcall(function()
    if C and C.addonskinner and C.addonskinner.disabled and C.addonskinner.disabled[addon] == "1" then
      disabled = true
    end
  end)
  if disabled then return end

  if not pfUI or not pfUI.api then return end
  local api = pfUI.api
  local StripTextures, CreateBackdrop = api.StripTextures, api.CreateBackdrop
  local SkinButton, SkinCheckbox, SkinTab = api.SkinButton, api.SkinCheckbox, api.SkinTab
  local SkinSlider, SkinScrollbar = api.SkinSlider, api.SkinScrollbar
  local GetStringColor, SetAllPointsOffset = api.GetStringColor, api.SetAllPointsOffset

  local main = _G["aux_frame"]
  if not main or main.auxpfSkinned then return end
  main.auxpfSkinned = true

  -- aux 动态控件命名规则：aux.frameN（注意名字里带字面量点号）
  local function IsAuxName(n)
    return type(n) == "string" and string.find(n, "^aux%.frame%d+$") ~= nil
  end

  -- 主窗口：清掉 aux 自带 blizzard 底板，隐藏 blizzard 主题外框，套 pfUI 暗色
  pcall(function()
    local border = _G["aux_frameBorder"]
    if border then border:Hide() end
    main:SetBackdrop(nil)
    StripTextures(main)
    CreateBackdrop(main, nil, nil, .85)
  end)

  -- 标签页（aux_frameTab1..N，CharacterFrameTabButtonTemplate）
  for i = 1, 10 do
    local tab = _G["aux_frameTab" .. i]
    if tab then pcall(SkinTab, tab) end
  end

  -- aux 自带独立 tooltip（util/info.lua 的 AuxTooltip）
  pcall(function()
    local tip = _G["AuxTooltip"]
    if tip and not tip.auxpfSkinned then
      tip.auxpfSkinned = true
      StripTextures(tip)
      CreateBackdrop(tip, nil, nil, 1)
    end
  end)

  -- 递归遍历主窗口子树，按类型皮肤化
  local function Walk(f)
    if not f or not f.GetChildren then return end
    for _, c in ipairs({ f:GetChildren() }) do
      local ok, err = pcall(function()
        if not c.IsObjectType or not c.GetName then return end
        local otype = c:GetObjectType()
        local name = c:GetName()
        _G.FLAG_AUX_BTN = (_G.FLAG_AUX_BTN or 0) + 1

        if otype == "Button" and IsAuxName(name) then
          -- UIPanelButtonTemplate2 的视觉是 $parentLeft/Middle/Right 三块独立命名纹理
          -- （aux 的 Enable/Disable 也是直接对这三块 SetTexture），
          -- SkinButton 的 SetNormalTexture("") 清不掉它们，必须显式隐藏。
          -- 顺带兜底隐藏所有 UI-Panel-Button 系列区域纹理（含 Highlight）。
          for _, reg in ipairs({ c:GetRegions() }) do
            if reg.IsObjectType and reg:IsObjectType("Texture") and reg.GetTexture then
              local t = reg:GetTexture()
              if type(t) == "string" and string.find(t, "UI%-Panel%-Button") then
                reg:Hide()
              end
            end
          end
          for _, part in ipairs({ "Left", "Middle", "Right" }) do
            local tex = _G[name .. part]
            if tex and tex.IsObjectType and tex:IsObjectType("Texture") then
              tex:Hide()
            end
          end

          -- 普通按钮（blizzard 主题为 UIPanelButtonTemplate2，modern 主题为自制暗色按钮）
          SkinButton(c)

        elseif otype == "CheckButton" then
          -- CheckButton 分两种：
          --   有 Icon 子纹理的（有名字）→ 物品图标按钮（ActionButtonTemplate，挂售/背包清单行）
          --   其余（含 aux gui.checkbox 创建的匿名复选框）→ UICheckButtonTemplate 复选框
          -- 注意 GetObjectType() 对 CheckButton 返回 "CheckButton" 而非 "Button"，
          -- 物品图标按钮走不到上面的 Button 分支，必须在这里处理。
          local icon = name and _G[name .. "Icon"] or nil
          if icon then
            StripTextures(c)
            SkinButton(c, nil, nil, nil, icon, true)
          else
            SkinCheckbox(c)
          end

        elseif otype == "EditBox" then
          -- 输入框（InputBoxTemplate / 自制暗色输入框）
          StripTextures(c, true, "BACKGROUND")
          c:SetBackdrop(nil)
          CreateBackdrop(c, nil, true)

        elseif otype == "Slider" and name and not string.find(name, "ScrollBar$") then
          -- 滑动条（OptionsSliderTemplate / 自制暗色滑动条）；ScrollBar 不走这里
          SkinSlider(c)

        elseif otype == "ScrollFrame" and name then
          -- FauxScrollFrameTemplate 列表滚动区：清掉 blizzard 主题的羊皮纸背景，
          -- 滚动条套 pfUI 样式
          StripTextures(c)
          local bar = _G[name .. "ScrollBar"]
          if bar then SkinScrollbar(bar) end

        elseif otype == "Frame" and IsAuxName(name)
            and _G[name .. "Left"] and _G[name .. "Middle"] then
          -- 下拉框（UIDropDownMenuTemplate）：隐藏左中右纹理，套 pfUI 边框
          local l, m, r = _G[name .. "Left"], _G[name .. "Middle"], _G[name .. "Right"]
          if l then l:Hide() end
          if m then m:Hide() end
          if r then r:Hide() end
          StripTextures(c)
          c:SetBackdrop(nil)
          CreateBackdrop(c, nil, nil, .85)

          -- 箭头切换按钮（$parentButton）：清掉原版纹理，套 pfUI 小边框 + 金色下箭头
          local btn = _G[name .. "Button"]
          if btn then
            StripTextures(btn)
            btn:SetNormalTexture("")
            btn:SetPushedTexture("")
            btn:SetHighlightTexture("")
            btn:SetDisabledTexture("")
            CreateBackdrop(btn)
            btn.backdrop:ClearAllPoints()
            btn.backdrop:SetWidth(18)
            btn.backdrop:SetHeight(18)
            btn.backdrop:SetPoint("RIGHT", c.backdrop, "RIGHT", -4, 0)
            if not btn.icon and pfUI.media and pfUI.media["img:down"] then
              btn.icon = btn:CreateTexture(nil, "OVERLAY")
              btn.icon:SetTexture(pfUI.media["img:down"])
              btn.icon:SetVertexColor(1, .9, .1)
              btn.icon:SetAlpha(.8)
              SetAllPointsOffset(btn.icon, btn.backdrop, 5)
            end
          end

        elseif otype == "Frame" or otype == "Button" then
          -- 匿名 Frame：aux 的面板/状态条 blizzard 边框等
          local bd = c.GetBackdrop and c:GetBackdrop()
          if bd then
            local bg = bd.bgFile or ""
            local edge = bd.edgeFile or ""
            if string.find(edge, "DialogBox%-Border") or string.find(edge, "UI%-Tooltip%-Border") then
              c:SetBackdrop(nil)
            elseif string.find(bg, "UI%-Tooltip%-Background") then
              c:SetBackdrop(nil)
              CreateBackdrop(c, nil, nil, .85)
            end
          end
        end
      end)
      if not ok and not _G.FLAG_AUX_ERR then
        _G.FLAG_AUX_ERR = tostring(err)
      end

      -- 继续向下递归（匿名行/格子无纹理，不会误伤）
      if c.GetChildren then Walk(c) end
    end
  end

  Walk(main)

  _G.FLAG_AUX_OK = true
end

-- ============================================================
-- (1) 尝试登记到 addonskinner（GUI 列表 / 统一禁用）
-- ============================================================
local function tryRegister()
  if pfUI and pfUI.addonskinner and type(pfUI.addonskinner.RegisterSkin) == "function" then
    local ok = pcall(pfUI.addonskinner.RegisterSkin, pfUI.addonskinner, addon, SkinAux)
    return ok
  end
  return false
end
tryRegister()

-- ============================================================
-- (2) 自包含触发器：aux 在 VARIABLES_LOADED 时才创建界面，
--     用事件触发保证不依赖 addonskinner 加载器时序
-- ============================================================
local trig = CreateFrame("Frame")
trig:RegisterEvent("ADDON_LOADED")
trig:RegisterEvent("VARIABLES_LOADED")
trig:RegisterEvent("PLAYER_LOGIN")
trig:SetScript("OnEvent", function()
  -- addonskinner 就绪后补登记一次
  if pfUI and pfUI.addonskinner and type(pfUI.addonskinner.RegisterSkin) == "function" then
    tryRegister()
  end

  if _G["aux_frame"] and _G["aux_frame"].auxpfSkinned then
    trig:UnregisterAllEvents()
    return
  end

  local ok, err = pcall(SkinAux)
  if not ok and not _G.FLAG_AUX_ERR then
    _G.FLAG_AUX_ERR = tostring(err)
  end

  -- 皮肤完成（或 aux 未安装）后停止监听
  if (_G["aux_frame"] and _G["aux_frame"].auxpfSkinned) or not IsAddOnLoaded(addon) then
    trig:UnregisterAllEvents()
  end
end)
