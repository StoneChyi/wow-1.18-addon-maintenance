pfUI.addonskinner:RegisterSkin("Capslock", function()
  -- 获取 pfUI 环境方法
  local penv = pfUI:GetEnvironment()
  local StripTextures, CreateBackdrop, SkinButton, SkinCheckbox, SkinScrollbar =
    penv.StripTextures, penv.CreateBackdrop, penv.SkinButton, penv.SkinCheckbox, penv.SkinScrollbar

  -- ===== 主配置窗口 CapslockFrame =====
  -- 自带 <Backdrop>(DialogBox 边框) + 标题美术，CreateBackdrop 检测到已有 backdrop 会自动清除并换成 pfUI 边框。
  -- StripTextures 只会处理 Texture 区域，标题 FontString("拉人助手") 保留不动。
  if CapslockFrame then
    StripTextures(CapslockFrame)
    CreateBackdrop(CapslockFrame, nil, nil, .75)
  end

  -- ===== 三个按钮（拉下一个 / 拉人通告 / 退出）=====
  local mainButtons = {
    "SummonButton",
    "AnnounceButton",
    "CloseButton",
  }
  for _, name in ipairs(mainButtons) do
    SkinButton(_G[name])
  end

  -- ===== 关键字输入框 Capslock_KeyWordEditBox =====
  -- 去掉原生 Common-Input-Border 三段纹理(BACKGROUND 层)，换成 pfUI 输入框边框
  if Capslock_KeyWordEditBox then
    StripTextures(Capslock_KeyWordEditBox, true, "BACKGROUND")
    CreateBackdrop(Capslock_KeyWordEditBox, nil, true)
  end

  -- ===== 复选框（只在密语频道生效）=====
  if Capslock_CheckButton then
    SkinCheckbox(Capslock_CheckButton, 20)
  end

  -- ===== 队列滚动列表 CapslockFrameSummonQueue (FauxScrollFrameTemplate) =====
  if CapslockFrameSummonQueue then
    StripTextures(CapslockFrameSummonQueue) -- 去掉原 Tooltip 边框
    if CapslockFrameSummonQueueScrollBar then
      SkinScrollbar(CapslockFrameSummonQueueScrollBar)
    end
  end

  -- ===== 列表条目 CapslockFrameSummonQueueEntry1..40（CAPSLOCK_InitializeListElements 动态创建）=====
  -- 保留原生 BG 高亮(悬停变色)，仅补 pfUI 边框，nil 安全。
  for i = 1, 40 do
    local entry = _G["CapslockFrameSummonQueueEntry" .. i]
    if entry and entry:IsObjectType("Button") then
      CreateBackdrop(entry, nil, true)
    end
  end
end)
