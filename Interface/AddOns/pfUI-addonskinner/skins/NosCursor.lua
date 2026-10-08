pfUI.addonskinner:RegisterSkin("NosCursor", function()
  -- place main code below
  local penv = pfUI:GetEnvironment()
  local StripTextures, SkinButton, SkinCheckbox, CreateBackdrop, CreateBackdropShadow =
  penv.StripTextures, penv.SkinButton, penv.SkinCheckbox, penv.CreateBackdrop, penv.CreateBackdropShadow

  -- 主配置窗口（持久帧）：只处理一次
  local function SkinSettingsFrame()
    local settings = _G["NosCursorConfig"]
    if not settings or settings.__pf_skinned then return end
    settings.__pf_skinned = true

    StripTextures(settings)
    CreateBackdrop(settings)
    CreateBackdropShadow(settings)
  end

  -- 分类框（每次 settings:Load() 都会新建，标记防止重复处理）
  local function SkinCategoryFrame(frame)
    if not frame or frame.__pf_skinned then return end
    frame.__pf_skinned = true
    StripTextures(frame)
    CreateBackdrop(frame)
  end

  -- 分类内的动态控件（每次 settings:Load() 都会重建复选框/选择框，需反复补皮）
  local function ReskinDynamic()
    local settings = _G["NosCursorConfig"]
    if not settings or not settings.category then return end

    for _, frame in pairs(settings.category) do
      if frame and frame.GetChildren then
        SkinCategoryFrame(frame)

        for _, child in pairs({ frame:GetChildren() }) do
          if child and child.IsObjectType and not child.__pf_skinned then
            child.__pf_skinned = true
            if child:IsObjectType("CheckButton") then
              -- OptionsCheckButtonTemplate 开关
              SkinCheckbox(child)
            elseif child:IsObjectType("Frame") and child.GetBackdrop and child:GetBackdrop() then
              -- 数值/纹理选择框（自带 tooltip backdrop 的 Frame）
              CreateBackdrop(child)
            end
            -- 其余（颜色按钮、预览框）保留插件自带外观
          end
        end
      end
    end
  end

  -- 轮询兜底：主窗口在加载期即存在，分类框/复选框在 PLAYER_ENTERING_WORLD 与
  -- 每次 OnShow 时由插件重建，需反复补皮。
  -- ⚠️ 本客户端 OnUpdate 回调不传 elapsed（全局 arg1 是上个事件的残留值，
  -- 可能是 nil 甚至字符串），节流必须用 GetTime()，绝不能累加 arg1。
  local poll = CreateFrame("Frame", nil, UIParent)
  local last = 0
  poll:SetScript("OnUpdate", function()
    local now = GetTime()
    if now - last < 0.5 then return end
    last = now

    local settings = _G["NosCursorConfig"]
    if not settings then return end

    -- 单个元素出错不杀死整个补皮循环
    local ok, err = pcall(function()
      SkinSettingsFrame()
      ReskinDynamic()
    end)
    if not ok and not poll.__pf_err_reported then
      poll.__pf_err_reported = true
      DEFAULT_CHAT_FRAME:AddMessage("|cffff0000pfUI-addonskinner (NosCursor):|r " .. tostring(err))
    end
  end)

  -- remove from pending list when applied
  pfUI.addonskinner:UnregisterSkin("NosCursor")
end)
