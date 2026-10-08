-- Tmog 幻化试衣间 (Otari98) pfUI 皮肤
-- 20260928 可可慕斯
local addon = "Tmog"

-- 调试标记（进游戏 /run print(TMOG_SKIN_RAN, TMOG_SKIN_OK, TMOG_SKIN_ERR)）
_G.TMOG_SKIN_RAN = _G.TMOG_SKIN_RAN or 0
_G.TMOG_SKIN_OK  = _G.TMOG_SKIN_OK or false
_G.TMOG_SKIN_ERR = _G.TMOG_SKIN_ERR or nil

local function SkinTmog()
  _G.TMOG_SKIN_RAN = _G.TMOG_SKIN_RAN + 1

  -- 与 GUI 的「Disable Skin Tmog」语义保持一致
  local disabled = false
  pcall(function()
    if C and C.addonskinner and C.addonskinner.disabled and C.addonskinner.disabled[addon] == "1" then
      disabled = true
    end
  end)
  if disabled then return end

  if not pfUI or not pfUI.api then return end
  local T = Tmog
  if not T then return end

  local api = pfUI.api
  local er, eg, eb, ea = api.GetStringColor(pfUI_config.appearance.border.color)
  local rawborder, border = api.GetBorderSize()

  -- 主窗口只处理一次
  if not _G.PF_TMOG_SKINNED then
    _G.PF_TMOG_SKINNED = true

    ---------------------------------------------------------------
    -- 关闭按钮（匿名纹理，避开 SkinCloseButton 的全局纹理名冲突）
    ---------------------------------------------------------------
    local function SkinTmogCloseButton(b, parent, offX, offY)
      if not b or b.pfTmogClose then return end
      b.pfTmogClose = true
      pcall(function()
        api.SkinButton(b, 1, .25, .25)
        b:SetWidth(15)
        b:SetHeight(15)
        if parent then
          b:ClearAllPoints()
          b:SetPoint("TOPRIGHT", parent, "TOPRIGHT", offX or -4, offY or -4)
        end
        local tex = pfUI.media and pfUI.media["img:close"] or "Interface\\AddOns\\pfUI\\img\\close"
        b:SetNormalTexture(tex)
        local nt = b:GetNormalTexture()
        if nt then
          nt:SetTexture(tex)
          nt:SetVertexColor(1, .25, .25, 1)
          nt:SetTexCoord(0, 1, 0, 1)
        end
        b:SetPushedTexture("")
        b:SetHighlightTexture("")
        b:SetDisabledTexture("")
      end)
    end

    ---------------------------------------------------------------
    -- 主窗口 TmogFrame
    ---------------------------------------------------------------
    local tf = _G.TmogFrame
    if tf then
      -- 清掉自绘的 ui1/ui2 双贴图背景、种族背景、头像
      pcall(api.StripTextures, tf)
      api.CreateBackdrop(tf, nil, nil, .75)
      pcall(api.CreateBackdropShadow, tf)

      SkinTmogCloseButton(_G.TmogFrameCloseButton, tf.backdrop, -4, -4)
    end

    ---------------------------------------------------------------
    -- 玩家装备槽（TmogPlayerSlot 模板 x14）
    -- 隐藏装饰边框，pfUI 底板；BorderFull 的 Show/Hide 映射为白色选中边
    ---------------------------------------------------------------
    local function SkinPlayerSlot(name)
      local slot = _G[name]
      if not slot or slot.pfTmogSlot then return end
      slot.pfTmogSlot = true

      for _, suffix in pairs({ "Border", "BorderFull", "BorderHighlight" }) do
        local t = _G[name .. suffix]
        if t and t.SetTexture then t:SetTexture("") end
      end

      api.CreateBackdrop(slot, nil, true)

      -- BorderFull 被插件当作选中/收藏指示器，Show/Hide 时联动边框颜色
      local full = _G[name .. "BorderFull"]
      if full and not full.pfTmogWrap then
        full.pfTmogWrap = true
        local oShow, oHide = full.Show, full.Hide
        full.Show = function(self)
          oShow(self)
          if slot.SetBackdropBorderColor then slot:SetBackdropBorderColor(1, 1, 1, 1) end
        end
        full.Hide = function(self)
          oHide(self)
          if slot.SetBackdropBorderColor then slot:SetBackdropBorderColor(er, eg, eb, ea) end
        end
        if full.IsShown and full:IsShown() then
          slot:SetBackdropBorderColor(1, 1, 1, 1)
        end
      end

      -- 悬停反馈（保留插件自己的 OnEnter/OnLeave tooltip）
      slot.pfEnterLeave = false
      pcall(api.SetHighlight, slot, 1, 1, 1)
    end

    local slots = {
      "TmogFrameHeadSlot", "TmogFrameShoulderSlot", "TmogFrameBackSlot",
      "TmogFrameChestSlot", "TmogFrameShirtSlot", "TmogFrameTabardSlot",
      "TmogFrameWristSlot", "TmogFrameHandsSlot", "TmogFrameWaistSlot",
      "TmogFrameLegsSlot", "TmogFrameFeetSlot", "TmogFrameMainHandSlot",
      "TmogFrameSecondaryHandSlot", "TmogFrameRangedSlot",
    }
    for _, name in pairs(slots) do pcall(SkinPlayerSlot, name) end

    ---------------------------------------------------------------
    -- 分页按钮（翻页箭头）
    ---------------------------------------------------------------
    pcall(function() api.SkinArrowButton(_G.TmogFrameLeftArrow, "left", 20) end)
    pcall(function() api.SkinArrowButton(_G.TmogFrameRightArrow, "right", 20) end)

    ---------------------------------------------------------------
    -- 搜索框（InputBoxTemplate）
    ---------------------------------------------------------------
    local function SkinSearchBox(eb)
      if not eb or eb.pfTmogBox then return end
      eb.pfTmogBox = true
      local regions = { eb:GetRegions() }
      for _, r in pairs(regions) do
        if r and r.GetObjectType and r:GetObjectType() == "Texture" and r.GetTexture then
          local t = tostring(r:GetTexture() or "")
          if string.find(t, "Common-Input-Border", 1, true) then
            r:SetTexture("")
          end
        end
      end
      api.CreateBackdrop(eb, nil, true)
    end
    pcall(SkinSearchBox, _G.TmogFrameSearchBox)

    ---------------------------------------------------------------
    -- 下拉框 / 勾选框 / 普通按钮
    ---------------------------------------------------------------
    pcall(api.SkinDropDown, _G.TmogFrameOutfitsDropDown)
    pcall(api.SkinDropDown, _G.TmogFrameTypeDropDown)

    pcall(api.SkinCheckbox, _G.TmogFrameCollected)
    pcall(api.SkinCheckbox, _G.TmogFrameNotCollected)
    pcall(api.SkinCheckbox, _G.TmogFrameUsable)
    pcall(api.SkinCheckbox, _G.TmogFrameIgnoreLevel)

    pcall(api.SkinButton, _G.TmogFrameSaveOutfit)
    pcall(api.SkinButton, _G.TmogFrameHideUI)
    pcall(api.SkinButton, _G.TmogFrameUndress)
    pcall(api.SkinButton, _G.TmogFrameResetPosition)
    pcall(api.SkinButton, _G.TmogFrameShareOutfit)
    pcall(api.SkinButton, _G.TmogFrameImportOutfit)

    -- 删除套装：红色 X 小按钮，重锚到保存按钮右侧
    pcall(function()
      local del = _G.TmogFrameDeleteOutfit
      local save = _G.TmogFrameSaveOutfit
      if del then
        SkinTmogCloseButton(del)
        if save then
          del:ClearAllPoints()
          del:SetPoint("LEFT", save, "RIGHT", border * 2 + 1, 0)
        end
      end
    end)

    ---------------------------------------------------------------
    -- 标签页（Items / Outfits）
    -- 原 OnClick 靠 NormalTexture 路径判断激活态，清除贴图后会失效，
    -- 改为按 Tmog.currentTab 判断；贴图清除后用文字亮/暗区分激活态
    ---------------------------------------------------------------
    local tabs = { ITEMS = _G.TmogFrameItemsButton, OUTFITS = _G.TmogFrameOutfitsButton }
    for _, btn in pairs(tabs) do
      if btn and not btn.pfTmogTab then
        btn.pfTmogTab = true
        pcall(api.SkinButton, btn)
      end
    end

    local function ApplyTabState()
      for name, btn in pairs(tabs) do
        if btn and btn.pfTmogTab then
          local active = (T.currentTab or "ITEMS") == name
          pcall(function()
            local fs = btn:GetFontString()
            if fs then
              if active then
                fs:SetTextColor(1, 1, 1, 1)
              else
                fs:SetTextColor(.6, .6, .6, 1)
              end
            end
          end)
        end
      end
    end

    pcall(function()
      local itemsBtn = _G.TmogFrameItemsButton
      local outfitsBtn = _G.TmogFrameOutfitsButton
      if itemsBtn then
        itemsBtn:SetScript("OnClick", function()
          if (T.currentTab or "ITEMS") ~= "ITEMS" then
            T.SwitchTab("ITEMS")
            T.Search()
            PlaySound("igCharacterInfoTab")
          end
        end)
      end
      if outfitsBtn then
        outfitsBtn:SetScript("OnClick", function()
          if (T.currentTab or "ITEMS") ~= "OUTFITS" then
            T.SwitchTab("OUTFITS")
            PlaySound("igCharacterInfoTab")
          end
        end)
      end
      -- 每次切换标签后刷新激活态视觉
      if not T.pfSwitchWrapped then
        T.pfSwitchWrapped = true
        local origSwitch = T.SwitchTab
        T.SwitchTab = function(which)
          origSwitch(which)
          pcall(ApplyTabState)
        end
      end
      ApplyTabState()
    end)

    ---------------------------------------------------------------
    -- 共享物品浮层（SharedItems）
    ---------------------------------------------------------------
    pcall(function()
      local si = _G.TmogFrameSharedItems
      if si then
        api.CreateBackdrop(si)
        pcall(api.CreateBackdropShadow, si)
      end
    end)

    ---------------------------------------------------------------
    -- 分享/导入对话框
    ---------------------------------------------------------------
    pcall(function()
      local dlg = _G.TmogFrameShareDialog
      if dlg then
        api.CreateBackdrop(dlg, nil, nil, .9)
        pcall(api.CreateBackdropShadow, dlg)
        SkinTmogCloseButton(_G.TmogFrameShareDialogCloseButton, dlg.backdrop, -4, -4)

        -- 单行输入框：清掉 InputBoxTemplate 边框三件套
        local eb = _G.TmogFrameShareDialogEditBox
        if eb then
          local regions = { eb:GetRegions() }
          for _, r in pairs(regions) do
            if r and r.GetObjectType and r:GetObjectType() == "Texture" and r.GetTexture then
              local t = tostring(r:GetTexture() or "")
              if string.find(t, "Common-Input-Border", 1, true) then
                r:SetTexture("")
              end
            end
          end
          api.CreateBackdrop(eb, nil, true)
        end

        -- 多行文本外框
        local bf = _G.TmogFrameShareDialogBorderFrame
        if bf then
          api.CreateBackdrop(bf, nil, true)
        end
      end
    end)
  end

  ---------------------------------------------------------------
  -- 预览按钮（TmogFramePreviewN，DrawPreviews 动态创建/刷新）
  -- 每次重绘都会重设 item_bg 贴图，包装 SetNormalTexture 拦截：
  -- selected -> 白色边框，normal -> 默认边框，贴图一律清空
  ---------------------------------------------------------------
  local function ReskinPreviews()
    if not T.PreviewButtons then return end
    for _, pframe in pairs(T.PreviewButtons) do
      if type(pframe) == "table" and pframe.GetObjectType then
        local pname = pframe.GetName and pframe:GetName()
        local btn = pname and _G[pname .. "Button"]
        if btn then
          if not pframe.pfTmogBg then
            pframe.pfTmogBg = true
            api.CreateBackdrop(pframe, nil, true)
          end
          if not btn.pfTmogWrapped then
            btn.pfTmogWrapped = true
            local orig = btn.SetNormalTexture
            btn.SetNormalTexture = function(self, tex)
              local t = tostring(tex or "")
              if string.find(t, "item_bg_selected", 1, true) then
                orig(self, "")
                pcall(function() pframe:SetBackdropBorderColor(1, 1, 1, 1) end)
              elseif string.find(t, "item_bg_normal", 1, true) then
                orig(self, "")
                pcall(function() pframe:SetBackdropBorderColor(er, eg, eb, ea) end)
              else
                orig(self, tex)
              end
            end
            -- 预览细边框贴图
            local btex = _G[pname .. "ButtonBorder"]
            if btex and btex.SetTexture then btex:SetTexture("") end
            -- 当前状态重新走一遍包装器
            local nt = btn.GetNormalTexture and btn:GetNormalTexture()
            local curt = (nt and nt.GetTexture and nt:GetTexture()) or "Interface\\AddOns\\Tmog\\Textures\\item_bg_normal"
            btn:SetNormalTexture(curt)
            pcall(function()
              btn:SetPushedTexture("")
              btn:SetHighlightTexture("")
              btn:SetDisabledTexture("")
            end)
          end
        end
      end
    end
  end

  if not T.pfDrawWrapped and type(T.DrawPreviews) == "function" then
    T.pfDrawWrapped = true
    local origDraw = T.DrawPreviews
    T.DrawPreviews = function(noDraw)
      origDraw(noDraw)
      pcall(ReskinPreviews)
    end
  end
  -- 已存在的预览按钮立即补一遍
  pcall(ReskinPreviews)

  _G.TMOG_SKIN_OK = true
end

-- (1) 尝试登记到 addonskinner（供 GUI 列表/统一禁用）
pcall(function()
  if pfUI and pfUI.addonskinner and type(pfUI.addonskinner.RegisterSkin) == "function" then
    pfUI.addonskinner:RegisterSkin(addon, SkinTmog)
  end
end)

-- (2) 自包含触发器：不依赖 addonskinner 加载器时序
local trig = CreateFrame("Frame")
trig:RegisterEvent("ADDON_LOADED")
trig:RegisterEvent("VARIABLES_LOADED")
trig:RegisterEvent("PLAYER_LOGIN")
trig:SetScript("OnEvent", function()
  pcall(function()
    if pfUI and pfUI.addonskinner and type(pfUI.addonskinner.RegisterSkin) == "function" then
      pfUI.addonskinner:RegisterSkin(addon, SkinTmog)
    end
  end)

  if event == "ADDON_LOADED" and arg1 ~= addon then return end
  if IsAddOnLoaded(addon) then
    local ok, err = pcall(SkinTmog)
    if not ok then _G.TMOG_SKIN_ERR = tostring(err) end
    trig:UnregisterAllEvents()
  end
end)
