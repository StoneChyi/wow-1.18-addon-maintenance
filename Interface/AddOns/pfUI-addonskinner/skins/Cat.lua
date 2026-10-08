
-- Cat 皮肤（已修复：扫描 _G 时加 type(v)=="table" 判断，
-- 避免对 CatModVersion 这类数字全局变量取 GetObjectType 导致报错）
pfUI.addonskinner:RegisterSkin("Cat", function()
  local penv = pfUI:GetEnvironment()
  local StripTextures   = penv.StripTextures
  local CreateBackdrop  = penv.CreateBackdrop
  local SkinCloseButton = penv.SkinCloseButton
  local SkinButton      = penv.SkinButton
  local SkinCheckbox    = penv.SkinCheckbox
  local SkinSlider      = penv.SkinSlider

  local function FindCloseButton(frame)
    for _, child in ipairs({frame:GetChildren()}) do
      if child:GetObjectType() == "Button" then
        local w, h = child:GetWidth(), child:GetHeight()
        if w and h and w >= 28 and w <= 36 and h >= 28 and h <= 36 then
          local point, relativeTo = child:GetPoint()
          if point == "TOPRIGHT" and relativeTo == frame then
            return child
          end
        end
      end
    end
    return nil
  end

  local function ApplyCatUISkin(frame)
    if not frame or frame.pfCatSkinned then return end
    frame.pfCatSkinned = true

    StripTextures(frame)
    CreateBackdrop(frame, nil, nil, .75)

    local closeBtn = FindCloseButton(frame)
    for _, child in ipairs({frame:GetChildren()}) do
      local t = child:GetObjectType()
      if t == "Button" and child == closeBtn then
        SkinCloseButton(child, frame.backdrop, -6, -6)
      elseif (t == "Button" or t == "CheckButton") and child.icon
         and child.icon.SetDrawLayer then
        -- 图标按钮：图标必须位于按钮深色底板上方，保留图标本身的颜色。
        -- 审判控制图标保留无边框外观，避免皮肤重新添加底板边框和图标留白。
        if not child.MPCatBorderlessIcon then
          SkinButton(child, nil, nil, nil, child.icon)
        end
        child.icon:SetDrawLayer("ARTWORK")
        child.icon:SetVertexColor(1, 1, 1)
        child.icon:Show()
        -- 保留 Cat 自己的选中/未选亮度，不能一律恢复为白色。
        if type(child.MPCatRefreshAppearance) == "function" then
          child.MPCatRefreshAppearance()
        end
      elseif t == "Button" then
        SkinButton(child)
      elseif t == "CheckButton" then
        SkinCheckbox(child)
      elseif t == "EditBox" then
        StripTextures(child, true, "BACKGROUND")
        CreateBackdrop(child)
      elseif t == "Slider" then
        if SkinSlider then pcall(SkinSlider, child) end
      end
    end
  end

  -- 扫描所有以 "Cat" 开头的全局 Frame（窗口都是 table，数字/字符串会被跳过）
  for k, v in pairs(_G) do
    if type(k) == "string" and string.find(k, "^Cat")
       and type(v) == "table" and v.GetObjectType and v:GetObjectType() == "Frame" then
      pcall(ApplyCatUISkin, v)
    end
  end
  -- pfUI 可能在 Cat 初始化后才创建背景；完整套用皮肤后恢复整体透明度。
  if type(MPCatPaladinSealApplyAppearance) == "function" then
    MPCatPaladinSealApplyAppearance()
  end
end)
