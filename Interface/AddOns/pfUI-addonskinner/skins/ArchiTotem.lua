pfUI.addonskinner:RegisterSkin("ArchiTotem", function()
  if not pfUI or not pfUI.api then
    pfUI.addonskinner:UnregisterSkin("ArchiTotem")
    return
  end

  local api = pfUI.api
  local noop = function() end

  -- 参照 totems 模块的颜色映射
  local elementColors = {
    Earth = { r = 0.2, g = 0.4, b = 0.1 },  -- 地
    Fire  = { r = 0.5, g = 0.2, b = 0.1 },  -- 火
    Water = { r = 0.1, g = 0.4, b = 0.6 },  -- 水
    Air   = { r = 0.4, g = 0.1, b = 0.7 },  -- 风
    Totemic = { r = 0.8, g = 0.8, b = 0.2 }, -- 杂项（亮黄）
  }

  local function skinButton(button)
    if not button then return end
    local name = button:GetName()
    if not name then return end

    -- 1. 隐藏标准纹理
    local normalTexture = _G[name .. "NormalTexture"]
    if normalTexture then
      normalTexture:SetTexture(nil)
      normalTexture:Hide()
    end

    -- 2. 创建 pfUI 背景（沿用原逻辑）
    api.CreateBackdrop(button, nil, nil, 0.9)

    -- 3. 根据按钮名称提取元素类型并设置边框颜色
    for element, color in pairs(elementColors) do
      if string.find(name, element) then
        button:SetBackdropBorderColor(color.r, color.g, color.b)
        break
      end
    end

    -- 4. 添加标准高亮
    api.SetHighlight(button)

    -- 5. 禁用按下纹理
    button:SetPushedTexture(nil)
    button.SetPushedTexture = noop

    -- 6. 隐藏自定义冷却背景（如有）
    local cooldownBg = _G[name .. "CooldownBg"]
    if cooldownBg then
      cooldownBg:SetTexture(nil)
      cooldownBg:Hide()
    end
  end

  -- 普通元素按钮
  local totemElements = {"Earth", "Fire", "Water", "Air", "Totemic"}
  local totemMaxCounts = {
    Ear = 5,
    Fir = 5,
    Wat = 5,
    Air = 7,
    Tot = 1
  }

  for _, element in ipairs(totemElements) do
    local elementKey = string.sub(element, 1, 3)
    local maxButtons = totemMaxCounts[elementKey]
    if maxButtons then
      for i = 1, maxButtons do
        local buttonName = "ArchiTotemButton_" .. element .. i
        local button = _G[buttonName]
        skinButton(button)
      end
    end
  end

  -- 特殊功能按钮（全图腾、召回、预设管理）
  local specialButtons = {"AllTotems", "Recall", "PresetManager"}
  for _, suffix in ipairs(specialButtons) do
    local buttonName = "ArchiTotemButton_" .. suffix
    local button = _G[buttonName]
    skinButton(button)
    -- 特殊按钮额外给予一个中性边框颜色（白色偏灰）
    if button then
      button:SetBackdropBorderColor(0.7, 0.7, 0.7)
    end
  end

  pfUI.addonskinner:UnregisterSkin("ArchiTotem")
end)