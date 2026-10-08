pfUI.addonskinner:RegisterSkin("PlayTurtle", function()
  -- place main code below
  local penv = pfUI:GetEnvironment()
  local StripTextures, SkinButton, SkinCheckbox, SkinCloseButton, SkinDropDown, CreateBackdrop, CreateBackdropShadow =
  penv.StripTextures, penv.SkinButton, penv.SkinCheckbox, penv.SkinCloseButton, penv.SkinDropDown, penv.CreateBackdrop, penv.CreateBackdropShadow

  -- 面板根帧：Strip + pfUI 背景边框
  local function SkinPanelRoot(f)
    if not f or f.__pf_skinned then return end
    f.__pf_skinned = true

    StripTextures(f)
    CreateBackdrop(f)
    CreateBackdropShadow(f)
  end

  -- 取按钮 NormalTexture 的纹理路径（用于区分模板按钮/关闭按钮/自定义状态按钮）
  local function GetNormalTexturePath(btn)
    if not btn.GetNormalTexture then return nil end
    local tex = btn:GetNormalTexture()
    if tex and tex.GetTexture then
      local path = tex:GetTexture()
      if type(path) == "string" then return path end
    end
    return nil
  end

  -- 递归处理面板内控件（限制深度，避免意外深入动态层）
  local function SkinChildren(f, depth)
    if not f or not f.GetChildren or (depth or 0) > 8 then return end

    for _, child in pairs({ f:GetChildren() }) do
      if child and child.IsObjectType and not child.__pf_skinned then
        child.__pf_skinned = true

        if child:IsObjectType("CheckButton") then
          -- UICheckButtonTemplate 复选框
          SkinCheckbox(child)
        elseif child:IsObjectType("EditBox") then
          -- 自带 tooltip 背景的输入框
          CreateBackdrop(child)
        elseif child:IsObjectType("Button") then
          local path = GetNormalTexturePath(child)
          if path then
            if string.find(path, "MinimizeButton", 1, true) then
              -- UIPanelCloseButton
              SkinCloseButton(child)
            elseif string.find(path, "UI-Panel-Button", 1, true) then
              -- UIPanelButtonTemplate 普通按钮
              SkinButton(child)
            end
            -- 其余带纹理按钮（翻页箭头等图标按钮）保留原样
          end
          -- 无 NormalTexture 的按钮是插件自制"红绿状态"开关/色块按钮，
          -- 依赖 SetBackdropColor 显示状态，绝不能套 SkinButton
          if child.GetChildren then SkinChildren(child, (depth or 0) + 1) end
        else
          -- UIDropDownMenuTemplate 下拉框（如 PlayTurtleSoundDropDown）：
          -- SkinDropDown 一并处理边框纹理、$parentButton 箭头按钮和下拉图标
          -- （GetChildren 返回的必是 Frame，无需再判类型；方法一律用冒号调用）
          local cname = child.GetName and child:GetName()
          if cname and string.find(cname, "DropDown$") then
            SkinDropDown(child)
          end
          -- 布局容器帧：仅递归，不加边框
          SkinChildren(child, (depth or 0) + 1)
        end
      end
    end
  end

  -- 懒创建的命名根帧：主面板 / 文字设置子面板 / 模式选择对话框
  local roots = {
    "PTURTLE_Combat_Panel",
    "PTURTLE_Combat_SubPanel",
    "PT_ModeChoiceDialog",
  }

  -- 轮询兜底：面板在 PLAYER_ENTERING_WORLD 后创建，子面板/对话框按需创建；
  -- 出现即美化，面板内控件只创建一次故每根只需走一遍。
  -- ⚠️ 本客户端 OnUpdate 回调不传 elapsed（全局 arg1 是上个事件的残留值，
  -- 可能是 nil 甚至字符串），节流必须用 GetTime()，绝不能累加 arg1。
  local poll = CreateFrame("Frame", nil, UIParent)
  local last = 0
  poll:SetScript("OnUpdate", function()
    local now = GetTime()
    if now - last < 1 then return end
    last = now

    -- 单个根帧出错不杀死整个轮询
    for _, name in pairs(roots) do
      local root = _G[name]
      if root and not root.__pf_walked then
        local ok, err = pcall(function()
          root.__pf_walked = true
          SkinPanelRoot(root)
          SkinChildren(root, 0)
        end)
        if not ok and not poll.__pf_err_reported then
          poll.__pf_err_reported = true
          DEFAULT_CHAT_FRAME:AddMessage("|cffff0000pfUI-addonskinner (PlayTurtle):|r " .. tostring(err))
        end
      end
    end
  end)

  -- remove from pending list when applied
  pfUI.addonskinner:UnregisterSkin("PlayTurtle")
end)
