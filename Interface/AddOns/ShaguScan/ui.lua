if ShaguScan.disabled then return end

local utils = ShaguScan.utils
local filter = ShaguScan.filter
local settings = ShaguScan.settings





local ui = CreateFrame("Frame", nil, UIParent)

ui.border = {
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

ui.background = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  tile = true, tileSize = 16, edgeSize = 8,
  insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

ui.frames = {}
-- 新增：防重复喊话缓存（key: GUID, value: 上次喊话时间）
ui.otAnnounceCache = {}

ui.CreateRoot = function(parent, caption)
  local frame = CreateFrame("Frame", "ShaguScan"..caption, parent)
  frame.id = caption
  -- 新增锁定状态标志
  frame.locked = true -- 默认已锁定

  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetMovable(true)

  -- 修改拖拽逻辑，添加锁定判断
  frame:SetScript("OnDragStart", function()
    if this.locked then return end -- 锁定状态下不允许拖拽
    this.lock = true
    this:StartMoving()
  end)

  frame:SetScript("OnDragStop", function()
    -- load current window config
    local config = ShaguScan_db.config[this.id]

    -- convert to best anchor depending on position
    local new_anchor = utils.GetBestAnchor(this)
    local anchor, x, y = utils.ConvertFrameAnchor(this, new_anchor)
    this:ClearAllPoints()
    this:SetPoint(anchor, UIParent, anchor, x, y)

    -- save new position
    local anchor, _, _, x, y = this:GetPoint()
    config.anchor, config.x, config.y = anchor, x, y

    -- stop drag
    this:StopMovingOrSizing()
    this.lock = false
  end)

  -- assign/initialize elements
  frame.CreateBar = ui.CreateBar
  frame.frames = {}
  


  

  -- create title text
  frame.caption = frame:CreateFontString(nil, "HIGH", "GameFontWhite")
  frame.caption:SetFont(STANDARD_TEXT_FONT, 9, "THINOUTLINE")
  frame.caption:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
  frame.caption:SetTextColor(1, 1, 1, 1)
  -- 修改后（添加颜色代码）
frame.caption:SetText("|cff00ffff[表名]：|r" .. caption .. 
  " |cffaaaaaa(喊:" .. 
  (ShaguScan_db.otAnnounce 
    and "|cff00ff00开|r"  -- 开启时绿色
    or "|cffff0000关|r"   -- 关闭时红色
  ) .. ")|r")

  
  

  -- create option button设置按钮
  frame.settings = CreateFrame("Button", nil, frame)
  frame.settings:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 12)
  frame.settings:SetWidth(8)
  frame.settings:SetHeight(8)

  frame.settings:SetScript("OnEnter", function()
    frame.settings.tex:SetAlpha(1)
  end)

  frame.settings:SetScript("OnLeave", function()
    frame.settings.tex:SetAlpha(.5)
  end)

  frame.settings.tex = frame.settings:CreateTexture(nil, 'OVERLAY')
  frame.settings.tex:SetTexture("Interface\\AddOns\\ShaguScan\\img\\config")
  frame.settings.tex:SetAllPoints()
  frame.settings.tex:SetAlpha(.5)

  frame.settings:SetScript("OnClick", function()
    PlaySound("igCharacterInfoTab")
    settings.OpenConfig(this:GetParent().id)
  end)


  -- 【显示】按钮（文字按钮）
  frame.showBtn = CreateFrame("Button", nil, frame)
  frame.showBtn:SetPoint("RIGHT", frame.settings, "RIGHT", 14, 0) -- 标题右侧
  frame.showBtn:SetWidth(14) -- 文字按钮宽度
  frame.showBtn:SetHeight(14) -- 文字按钮高度=
  
  -- 按钮背景
  frame.showBtn:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  })
  frame.showBtn:SetBackdropColor(0.1, 0.1, 0.1, 1) -- 深色背景
  frame.showBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1) -- 灰色边框

  -- 按钮文字
  frame.showBtn.text = frame.showBtn:CreateFontString(nil, "HIGH", "GameFontWhite")
  frame.showBtn.text:SetFont(STANDARD_TEXT_FONT, 8, "THINOUTLINE")
  frame.showBtn.text:SetAllPoints()
  frame.showBtn.text:SetText("显")

  -- 悬停效果
  frame.showBtn:SetScript("OnEnter", function()
    this:SetBackdropBorderColor(1, 1, 1, 1) -- 白色边框
    this.text:SetTextColor(1, 1, 0, 1) -- 黄色文字
  end)
  frame.showBtn:SetScript("OnLeave", function()
    this:SetBackdropBorderColor(0.5, 0.5, 0.5, 1) -- 恢复灰色边框
    -- 根据文字内容设置颜色：隐字红色，其他绿色
    if this.text:GetText() == "隐" then
      this.text:SetTextColor(1, 0, 0, 1) -- 红色文字
    else
      this.text:SetTextColor(0, 1, 0, 1) -- 绿色文字
    end
  end)

  -- 点击事件
  frame.showBtn:SetScript("OnClick", function()
    PlaySound("igCharacterInfoTab")
    frame.hiddenBars = false
    -- 显示所有已存在的血条
    if frame.frames then
      for _, bar in pairs(frame.frames) do
        bar:Show()
      end
    end
    -- 强制触发一次UI更新，确保重新生成血条
    ui:GetScript("OnUpdate")()
  end)

  -- 【隐藏】按钮（文字按钮）
  frame.hideBtn = CreateFrame("Button", nil, frame)
  frame.hideBtn:SetPoint("RIGHT", frame.showBtn, "RIGHT", 13, 0) -- 显示按钮左侧
  frame.hideBtn:SetWidth(14)
  frame.hideBtn:SetHeight(14)
  
  -- 按钮背景（与显示按钮一致）
  frame.hideBtn:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  })
  frame.hideBtn:SetBackdropColor(0.1, 0.1, 0.1, 1)
  frame.hideBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

  -- 按钮文字
  frame.hideBtn.text = frame.hideBtn:CreateFontString(nil, "HIGH", "GameFontWhite")
  frame.hideBtn.text:SetFont(STANDARD_TEXT_FONT, 8, "THINOUTLINE")
  frame.hideBtn.text:SetAllPoints()
  frame.hideBtn.text:SetText("隐")

  -- 悬停效果
  frame.hideBtn:SetScript("OnEnter", function()
    this:SetBackdropBorderColor(1, 1, 1, 1)
    this.text:SetTextColor(1, 1, 0, 1)
  end)
  frame.hideBtn:SetScript("OnLeave", function()
    this:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    -- 根据文字内容设置颜色：隐字红色，其他绿色
    if this.text:GetText() == "隐" then
      this.text:SetTextColor(1, 0, 0, 1) -- 红色文字
    else
      this.text:SetTextColor(0, 1, 0, 1) -- 绿色文字
    end
  end)

  -- 【隐藏按钮逻辑修改】
  frame.hideBtn:SetScript("OnClick", function()
    PlaySound("igCharacterInfoTab")
    frame.hiddenBars = true
    -- 隐藏所有血条
    if frame.frames then
      for _, bar in pairs(frame.frames) do
        bar:Hide()
      end
    end
  end)

  -- 【锁定】按钮（文字按钮）
frame.lockBtn = CreateFrame("Button", nil, frame)
frame.lockBtn:SetPoint("RIGHT", frame.hideBtn, "RIGHT", 13, 0) -- 隐藏按钮左侧
frame.lockBtn:SetWidth(14)
frame.lockBtn:SetHeight(14)

-- 按钮背景（与其他按钮一致）
frame.lockBtn:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
frame.lockBtn:SetBackdropColor(0.1, 0.1, 0.1, 1)
frame.lockBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

-- 按钮文字
frame.lockBtn.text = frame.lockBtn:CreateFontString(nil, "HIGH", "GameFontWhite")
frame.lockBtn.text:SetFont(STANDARD_TEXT_FONT, 8, "THINOUTLINE")
frame.lockBtn.text:SetAllPoints()
frame.lockBtn.text:SetText("锁") -- 初始显示"锁"
frame.lockBtn.text:SetTextColor(1, 0, 0, 1) -- 初始文字颜色设为红色

-- 悬停效果
frame.lockBtn:SetScript("OnEnter", function()
  this:SetBackdropBorderColor(1, 1, 1, 1)
  this.text:SetTextColor(1, 1, 0, 1)
end)
frame.lockBtn:SetScript("OnLeave", function()
  this:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
  -- 根据文字内容设置颜色：隐字或锁字红色，其他绿色
  if this.text:GetText() == "隐" or this.text:GetText() == "锁" then
    this.text:SetTextColor(1, 0, 0, 1) -- 红色文字
  else
    this.text:SetTextColor(0, 1, 0, 1) -- 绿色文字
  end
end)

-- 点击事件：切换锁定状态
frame.lockBtn:SetScript("OnClick", function()
  PlaySound("igCharacterInfoTab")
  local parentFrame = this:GetParent()
  -- 切换锁定状态
  parentFrame.locked = not parentFrame.locked
  -- 更新按钮文字和颜色
  if parentFrame.locked then
    this.text:SetText("锁") -- 锁定时显示"锁"
    this.text:SetTextColor(1, 0, 0, 1) -- 红色文字
  else
    this.text:SetText("解") -- 解锁时显示"解"
    this.text:SetTextColor(0, 1, 0, 1) -- 绿色文字
  end
end)
-- 【距离】按钮（控制距离文本显示）
frame.distanceBtn = CreateFrame("Button", nil, frame)
-- 定位在锁按钮右侧，间距与其他按钮保持一致
frame.distanceBtn:SetPoint("RIGHT", frame.lockBtn, "RIGHT", 13, 0)
frame.distanceBtn:SetWidth(14)
frame.distanceBtn:SetHeight(14)

-- 按钮背景（与其他按钮样式统一）
frame.distanceBtn:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
frame.distanceBtn:SetBackdropColor(0.1, 0.1, 0.1, 1)
frame.distanceBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

-- 按钮文字
frame.distanceBtn.text = frame.distanceBtn:CreateFontString(nil, "HIGH", "GameFontWhite")
frame.distanceBtn.text:SetFont(STANDARD_TEXT_FONT, 8, "THINOUTLINE")
frame.distanceBtn.text:SetAllPoints()
frame.distanceBtn.text:SetText("距") -- 按钮文字为"距"

-- 初始化距离显示状态（默认显示）
frame.showDistance = true

-- 悬停效果
frame.distanceBtn:SetScript("OnEnter", function()
  this:SetBackdropBorderColor(1, 1, 1, 1)
  this.text:SetTextColor(1, 1, 0, 1)
end)
frame.distanceBtn:SetScript("OnLeave", function()
  this:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
  -- 根据文字内容设置颜色：隐字红色，其他绿色
  if this.text:GetText() == "隐" then
    this.text:SetTextColor(1, 0, 0, 1) -- 红色文字
  else
    this.text:SetTextColor(0, 1, 0, 1) -- 绿色文字
  end
end)

-- 点击事件：切换距离显示状态
frame.distanceBtn:SetScript("OnClick", function()
  PlaySound("igCharacterInfoTab")
  local parentFrame = this:GetParent()
  local config = ShaguScan_db.config[parentFrame.id]
  
  -- 安全检查：确保配置存在
  if not config then return end
  
  -- 切换状态（默认显示）
  config.showDistance = not config.showDistance
  
  -- 同步距离按钮文字与配置状态
local config = ShaguScan_db.config[caption]
-- 更新按钮文字和颜色
if config.showDistance then
  frame.distanceBtn.text:SetText("距")
  frame.distanceBtn.text:SetTextColor(0, 1, 0, 1) -- 绿色文字
else
  frame.distanceBtn.text:SetText("隐")
  frame.distanceBtn.text:SetTextColor(1, 0, 0, 1) -- 红色文字
end
  
  -- 立即更新所有血条的距离文本显示
  if parentFrame.frames then
    for _, bar in pairs(parentFrame.frames) do
      if bar.distanceText then
        if config.showDistance then
          bar.distanceText:Show() -- 显示
        else
          bar.distanceText:Hide() -- 隐藏
        end
      end
    end
  end
end)

-- 在距离按钮（distanceBtn）创建代码后添加（约 ui.CreateRoot 函数内）
-- 【目标显示切换按钮】
frame.targetBtn = CreateFrame("Button", nil, frame)
frame.targetBtn:SetPoint("RIGHT", frame.distanceBtn, "RIGHT", 13, 0) -- 位于距离按钮右侧
frame.targetBtn:SetWidth(14)
frame.targetBtn:SetHeight(14)

-- 按钮样式（与其他按钮统一）
frame.targetBtn:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
frame.targetBtn:SetBackdropColor(0.1, 0.1, 0.1, 1)
frame.targetBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

-- 按钮文字（初始显示“目”表示显示目标文本）
frame.targetBtn.text = frame.targetBtn:CreateFontString(nil, "HIGH", "GameFontWhite")
frame.targetBtn.text:SetFont(STANDARD_TEXT_FONT, 8, "THINOUTLINE")
frame.targetBtn.text:SetAllPoints()
frame.targetBtn.text:SetText("目")

-- 悬停效果
frame.targetBtn:SetScript("OnEnter", function()
  this:SetBackdropBorderColor(1, 1, 1, 1)
  this.text:SetTextColor(1, 1, 0, 1) -- 黄色高亮
end)
frame.targetBtn:SetScript("OnLeave", function()
  this:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
  -- 根据文字内容设置颜色：隐字红色，其他绿色
  if this.text:GetText() == "隐" then
    this.text:SetTextColor(1, 0, 0, 1) -- 红色文字
  else
    this.text:SetTextColor(0, 1, 0, 1) -- 绿色文字
  end
end)

-- 点击事件：切换目标文本显示状态
frame.targetBtn:SetScript("OnClick", function()
  PlaySound("igCharacterInfoTab")
  local parentFrame = this:GetParent()
  local config = ShaguScan_db.config[parentFrame.id]
  
  -- 安全检查：确保配置存在
  if not config then return end
  
  -- 切换状态（默认显示）
  config.showTargetText = not config.showTargetText
  
  -- 更新按钮文字和颜色（显示时为"目"绿色，隐藏时为"隐"红色）
  if config.showTargetText then
    this.text:SetText("目")
    this.text:SetTextColor(0, 1, 0, 1) -- 绿色文字
  else
    this.text:SetText("隐")
    this.text:SetTextColor(1, 0, 0, 1) -- 红色文字
  end
  
  -- 立即更新所有血条的目标文本显示
  if parentFrame.frames then
    for _, bar in pairs(parentFrame.frames) do
      if bar.targetText then
        if config.showTargetText then
          bar.targetText:Show()
          -- 恢复文本内容（如果之前有值）
          if bar.lastTargetText then
            bar.targetText:SetText(bar.lastTargetText)
          end
        else
          -- 保存当前文本以便恢复
          bar.lastTargetText = bar.targetText:GetText()
          bar.targetText:Hide()
        end
      end
    end
  end
end)

-- 在目标显示按钮（targetBtn）创建代码后添加（约 ui.CreateRoot 函数内）
-- 【伤害显示切换按钮】
frame.damageBtn = CreateFrame("Button", nil, frame)
frame.damageBtn:SetPoint("RIGHT", frame.targetBtn, "RIGHT", 13, 0) -- 位于目标按钮右侧
frame.damageBtn:SetWidth(14)
frame.damageBtn:SetHeight(14)

-- 按钮样式（与其他按钮统一）
frame.damageBtn:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
frame.damageBtn:SetBackdropColor(0.1, 0.1, 0.1, 1)
frame.damageBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

-- 按钮文字（初始显示“伤”表示显示伤害数据）
frame.damageBtn.text = frame.damageBtn:CreateFontString(nil, "HIGH", "GameFontWhite")
frame.damageBtn.text:SetFont(STANDARD_TEXT_FONT, 8, "THINOUTLINE")
frame.damageBtn.text:SetAllPoints()
frame.damageBtn.text:SetText("伤")

-- 悬停效果
frame.damageBtn:SetScript("OnEnter", function()
  this:SetBackdropBorderColor(1, 1, 1, 1)
  this.text:SetTextColor(1, 1, 0, 1) -- 黄色高亮
end)
frame.damageBtn:SetScript("OnLeave", function()
  this:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
  -- 根据文字内容设置颜色：隐字红色，其他绿色
  if this.text:GetText() == "隐" then
    this.text:SetTextColor(1, 0, 0, 1) -- 红色文字
  else
    this.text:SetTextColor(0, 1, 0, 1) -- 绿色文字
  end
end)

-- 点击事件：切换伤害文本显示状态
frame.damageBtn:SetScript("OnClick", function()
  PlaySound("igCharacterInfoTab")
  local parentFrame = this:GetParent()
  local config = ShaguScan_db.config[parentFrame.id]
  
  -- 安全检查：确保配置存在
  if not config then return end
  
  -- 切换状态（默认显示）
  config.showDamageText = not config.showDamageText
  
  -- 更新按钮文字和颜色（显示时为"伤"绿色，隐藏时为"隐"红色）
  if config.showDamageText then
    this.text:SetText("伤")
    this.text:SetTextColor(0, 1, 0, 1) -- 绿色文字
  else
    this.text:SetText("隐")
    this.text:SetTextColor(1, 0, 0, 1) -- 红色文字
  end
  
  -- 立即更新所有血条的伤害文本显示
  if parentFrame.frames then
    for _, bar in pairs(parentFrame.frames) do
      if bar.feedbackText then -- 伤害文本通常通过 feedbackText 引用
        if config.showDamageText then
          bar.feedbackText:Show()
        else
          bar.feedbackText:Hide()
        end
      end
    end
  end
end)

-- 【仇恨显示切换按钮】
frame.threatBtn = CreateFrame("Button", nil, frame)
frame.threatBtn:SetPoint("RIGHT", frame.damageBtn, "RIGHT", 13, 0) -- 位于伤害按钮右侧
frame.threatBtn:SetWidth(14)
frame.threatBtn:SetHeight(14)

-- 按钮样式
frame.threatBtn:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
frame.threatBtn:SetBackdropColor(0.1, 0.1, 0.1, 1)
frame.threatBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

-- 按钮文字
frame.threatBtn.text = frame.threatBtn:CreateFontString(nil, "HIGH", "GameFontWhite")
frame.threatBtn.text:SetFont(STANDARD_TEXT_FONT, 8, "THINOUTLINE")
frame.threatBtn.text:SetAllPoints()
frame.threatBtn.text:SetText("仇") -- 初始显示"仇"

-- 悬停效果
frame.threatBtn:SetScript("OnEnter", function()
  this:SetBackdropBorderColor(1, 1, 1, 1)
  this.text:SetTextColor(1, 1, 0, 1)
end)
frame.threatBtn:SetScript("OnLeave", function()
  this:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
  -- 根据文字内容设置颜色：隐字红色，其他绿色
  if this.text:GetText() == "隐" then
    this.text:SetTextColor(1, 0, 0, 1) -- 红色文字
  else
    this.text:SetTextColor(0, 1, 0, 1) -- 绿色文字
  end
end)

-- 点击事件：切换仇恨条显示
   frame.threatBtn:SetScript("OnClick", function()
     PlaySound("igCharacterInfoTab")
     local parentFrame = this:GetParent()
  local config = ShaguScan_db.config[parentFrame.id]
  
  -- 安全检查：确保配置存在
  if not config then return end
  
  config.showThreatBar = not config.showThreatBar -- 切换状态
  -- 更新按钮文字和颜色（显示时为"仇"绿色，隐藏时为"隐"红色）
  if config.showThreatBar then
    this.text:SetText("仇")
    this.text:SetTextColor(0, 1, 0, 1) -- 绿色文字
  else
    this.text:SetText("隐")
    this.text:SetTextColor(1, 0, 0, 1) -- 红色文字
  end
  -- 未检查配置，强制显示/隐藏
-- 立即更新所有血条的仇恨条显示
  
end)

-- 初始化按钮状态并设置初始颜色
local config = ShaguScan_db.config[caption]

-- 初始化仇恨按钮
config.showThreatBar = config.showThreatBar ~= nil and config.showThreatBar or false -- 默认为false（不显示）
if config.showThreatBar then
  frame.threatBtn.text:SetText("仇")
  frame.threatBtn.text:SetTextColor(0, 1, 0, 1) -- 绿色文字
else
  frame.threatBtn.text:SetText("隐")
  frame.threatBtn.text:SetTextColor(1, 0, 0, 1) -- 红色文字
end

-- 初始化时确保血条的仇恨百分比不显示
if frame.frames then
  for _, bar in pairs(frame.frames) do
    if bar.threatBar then
      bar.threatBar:Hide()
    end
  end
end

-- 初始化目标按钮
config.showTargetText = config.showTargetText ~= nil and config.showTargetText or true -- 默认为true
if config.showTargetText then
  frame.targetBtn.text:SetText("目")
  frame.targetBtn.text:SetTextColor(0, 1, 0, 1) -- 绿色文字
else
  frame.targetBtn.text:SetText("隐")
  frame.targetBtn.text:SetTextColor(1, 0, 0, 1) -- 红色文字
end

-- 初始化伤害按钮
config.showDamageText = config.showDamageText ~= nil and config.showDamageText or true -- 默认为true
if config.showDamageText then
  frame.damageBtn.text:SetText("伤")
  frame.damageBtn.text:SetTextColor(0, 1, 0, 1) -- 绿色文字
else
  frame.damageBtn.text:SetText("隐")
  frame.damageBtn.text:SetTextColor(1, 0, 0, 1) -- 红色文字
end

-- 初始化距离按钮
config.showDistance = config.showDistance ~= nil and config.showDistance or true -- 默认为true
if config.showDistance then
  frame.distanceBtn.text:SetText("距")
  frame.distanceBtn.text:SetTextColor(0, 1, 0, 1) -- 绿色文字
else
  frame.distanceBtn.text:SetText("隐")
  frame.distanceBtn.text:SetTextColor(1, 0, 0, 1) -- 红色文字
end

-- 根据锁定状态设置初始锁定按钮文字
if frame.locked then
  frame.lockBtn.text:SetText("锁")
  frame.lockBtn.text:SetTextColor(1, 0, 0, 1) -- 锁定状态为红色
else
  frame.lockBtn.text:SetText("解")
  frame.lockBtn.text:SetTextColor(0, 1, 0, 1) -- 解锁状态为绿色
end

-- 设置初始显示和隐藏按钮文字颜色
frame.showBtn.text:SetTextColor(0, 1, 0, 1) -- 绿色文字
frame.hideBtn.text:SetTextColor(1, 0, 0, 1) -- 隐藏按钮默认红色
  return frame

end

-- 仇恨值颜色映射（0%绿色 → 100%红色）
local function GetThreatColor(threatPerc)
  threatPerc = math.max(0, math.min(100, tonumber(threatPerc) or 0))
  local r, g = 1, 1

   if threatPerc < 50 then
    -- 绿色到黄色（0-50%）
    r = threatPerc / 50
    g = 1
  else
    -- 黄色到红色（50-100%）
    r = 1
    g = 1 - (threatPerc - 50) / 50
  end
  return r, g, 0, 0.6 -- 蓝色固定为0，透明度0.6
end

-- 初始化OT喊话全局开关（默认关闭）
if ShaguScan_db.otAnnounce == nil then
  ShaguScan_db.otAnnounce = false
end



--此行上面为框架的按钮部分内容。--------------------------------------------------------------------------

ui.BarEnter = function()
  this.border:SetBackdropBorderColor(1, 1, 1, 1)
  this.hover = true

  GameTooltip_SetDefaultAnchor(GameTooltip, this)
  GameTooltip:SetUnit(this.guid)
  GameTooltip:Show()
end

ui.BarLeave = function()
  this.hover = false
  GameTooltip:Hide()
end

ui.BarUpdate = function()
  -- animate combat text
  if this.feedbackText and ShaguScan_db.config[this:GetParent().id] and ShaguScan_db.config[this:GetParent().id].showDamageText then
    CombatFeedback_OnUpdate(arg1) -- 仅在启用时更新动画
  end

  -- update statusbar values
  this.bar:SetMinMaxValues(0, UnitHealthMax(this.guid))
  this.bar:SetValue(UnitHealth(this.guid))

  -- update health bar color
  local hex, r, g, b, a = utils.GetUnitColor(this.guid)
  this.bar:SetStatusBarColor(r, g, b, a)

  -- update caption text
  local level = utils.GetLevelString(this.guid)
  local level_color = utils.GetLevelColor(this.guid)
  local name = UnitName(this.guid)
  this.text:SetText(level_color..level.."|r "..name)

  local function TruncateTo6Chars(str)
    if not str then return "" end
    local len = string.len(str)
    local result = ""
    local count = 0
    local i = 1
    while i <= len and count < 6 do
        local byte = string.byte(str, i)
        if byte > 127 then -- 汉字占2字节
            result = result .. string.sub(str, i, i+1)
            i = i + 2
            count = count + 1
        else -- 非汉字占1字节，不计数（确保只限制汉字数量）
            result = result .. string.sub(str, i, i)
            i = i + 1
        end
    end
    return result
end

local function TruncateTo8Chars(str)
    if not str then return "" end
    local len = string.len(str)
    local result = ""
    local count = 0
    local i = 1
    while i <= len and count < 8 do
        local byte = string.byte(str, i)
        if byte > 127 then -- 汉字占2字节
            result = result .. string.sub(str, i, i+1)
            i = i + 2
            count = count + 1
        else -- 非汉字占1字节，不计数（确保只限制汉字数量）
            result = result .. string.sub(str, i, i)
            i = i + 1
        end
    end
    return result
end

-- 修改名称获取部分
local name = UnitName(this.guid)
--name = TruncateTo8Chars(name) -- 截断名称为6个汉字


-- 新增：获取攻击目标信息
  local targetInfo = ">无目标" -- 默认显示
  if UnitAffectingCombat(this.guid) then -- 检查是否在战斗中
     -- 怀旧服中通过 "单位令牌+target" 获取目标（如"targettarget"）
  local targetUnit = this.guid .. "target" -- 拼接目标单位的令牌
  if UnitExists(targetUnit) then
        local targetName = UnitName(targetUnit) or "未知目标"
        --targetName = TruncateTo8Chars(targetName) -- 截断目标名称为6个汉字
        targetInfo = ">" .. targetName
    else
        targetInfo = ">无目标"
    end
end-- 新增：获取攻击目标信息
  
  

  -- 新增：计算当前血条的序号
  local root = this:GetParent()            -- 获取父框架（窗口）
  local sortedBars = root.sortedBars or {} -- 获取排序后的血条列表
  local index = nil

  -- 查找当前血条在sortedBars中的位置
  for i, guid in ipairs(sortedBars) do
    if guid == this.guid then
      index = i
      break
    end
  end
  -- 计算序号：最下方为1（反向索引）
  local sequence = index and "[" .. index .. "] " or ""



  -- 组合文本：等级 + 名称 + 攻击目标（新增部分）
  -- 用灰色显示目标信息，与主文本区分
--烟锅巴1007，添加距离信息
 local distance = nil
local distanceColor = "|cffffffff" -- 默认白色
local distanceValue = 0 -- 用于范围判断的数值

-- 计算距离值
if pcall(UnitXP, "nop", "nop") then
    if not UnitXP("distanceBetween", "player", this.guid) then
        distance = "∞" -- 无法计算时显示无限远
        distanceValue = math.huge -- 无限大值用于判断
    else
        local rawDistance = UnitXP("distanceBetween", "player", this.guid)
        distance = string.format("%.1f", rawDistance)
        distanceValue = rawDistance -- 保存原始数值用于判断
    end
-- 范围判断模式
elseif CheckInteractDistance(this.guid, 3) then -- 9.9码（决斗范围）
    distance = "<9.9"
    distanceValue = 9.9
elseif CheckInteractDistance(this.guid, 2) then -- 11.11码（交易范围）
    distance = "<11"
    distanceValue = 11
elseif CheckInteractDistance(this.guid, 4) or CheckInteractDistance(this.guid, 1) then -- 28码（跟随/查看范围）
    distance = "≤28"
    distanceValue = 28
else
    distance = ">28"
    distanceValue = 29 -- 用29代表超出28码的起始值
end

-- 根据距离值设置颜色
if distance == "∞" then
    distanceColor = "|cff888888" -- 无限远显示灰色
elseif distanceValue > 40 then
    distanceColor = "|cffff0000" -- 红色：>40码
elseif distanceValue > 30 then
    distanceColor = "|cffff9900" -- 橙色：30<距离≤40
elseif distanceValue > 10 then
    distanceColor = "|cffffff00" -- 黄色：10<距离≤30
elseif distanceValue > 5 then
    distanceColor = "|cff00ffff" -- 青色：5<距离≤10
else
    distanceColor = "|cff00ff00" -- 蓝色：≤5码
end
-- 【1. 距离文本框（血条外左侧）：仅显示距离】

  -- 原距离文本更新代码处（约 #startLine: 400）
local config = ShaguScan_db.config[this:GetParent().id]
if config and config.showDistance then
  this.distanceText:SetText(string.format("%s（%s）|r", distanceColor, distance))
  this.distanceText:Show()
else
  this.distanceText:Hide()
end

-- 【关键：每次更新文本前重新计算序列号】
local root = this:GetParent()
local sortedBars = root.sortedBars or {}
local index = nil
for i, guid in ipairs(sortedBars) do
  if guid == this.guid then
    index = i
    break
  end
end
local sequence = index and "[" .. index .. "] " or ""


-- 拼接最终文本（确保颜色正确闭合）
-- 【2. 血条内左侧文本框：序号+等级+名称】
  this.text:SetText(string.format(
    "|cffff9900%s|r%s%s|r %s",
    sequence, -- 序号（橙色）
    level_color, -- 等级颜色
    level, -- 等级
    name -- 名称
  ))
-- 【3. 血条内右侧文本框：目标信息（固定靠右）】
  -- 原目标文本更新代码处（约 #startLine: 410）
local config = ShaguScan_db.config[this:GetParent().id]
local targetTextStr = string.format("|cffffffff%s|r", targetInfo)
-- 保存文本到lastTargetText以便后续恢复
this.lastTargetText = targetTextStr
if config and config.showTargetText then
  this.targetText:SetText(targetTextStr)
  this.targetText:Show()
else
  this.targetText:Hide()
end

-- 新增：仇恨条更新逻辑
local guid = this.guid
-- 在计算threatPerc前添加战斗状态检查
local inCombat = UnitAffectingCombat(this.guid)
local threatData = pfUI and pfUI.threatData and pfUI.threatData[guid] or {}
local threatPerc = nil

-- 若脱离战斗，清除缓存并不显示仇恨值
if not inCombat then
  -- 清除该单位的仇恨数据缓存
  if pfUI and pfUI.threatData then
    pfUI.threatData[guid] = nil
  end
  threatPerc = nil
else
  -- 原有逻辑：从缓存读取仇恨值
  if threatData.int_my_threat then
    threatPerc = threatData.int_my_threat
  elseif threatData.int_second_threat then
    threatPerc = threatData.int_second_threat
  end
end

  
  -- 更新仇恨百分比文本
if this.threatText then -- 先检查 threatText 是否存在
  -- 获取当前窗口的配置
  local config = ShaguScan_db.config[this:GetParent().id]
  -- 根据配置决定是否显示仇恨文本
  if not config or not config.showThreatBar then
    this.threatText:Hide() -- 不显示时直接隐藏
  else
    -- 显示状态下，按原有逻辑更新文本
    if threatPerc then
      local r, g, b = GetThreatColor(threatPerc)
      local text = string.format("|cff%02x%02x%02x%d%%|r", r*255, g*255, b*255, threatPerc)
      this.threatText:SetText(text)
      this.threatText:Show()
    else
      this.threatText:SetText("|cff888888无仇恨|r")
      this.threatText:Show()
    end
  end
end

  -- update health bar border
  -- 优先判断是否为当前目标，设置白色边框
  if UnitIsUnit("target", this.guid) then
    this.border:SetBackdropBorderColor(1, 1, 1, 1) -- 白色边框（选中目标）
  elseif this.hover then
    this.border:SetBackdropBorderColor(0, 1, 1, 1) -- 鼠标悬停时白色边框
  elseif UnitAffectingCombat(this.guid) then
    this.border:SetBackdropBorderColor(.8, .2, .2, 1) -- 战斗中红色边框
  else
    this.border:SetBackdropBorderColor(.2, .2, .2, 1) -- 默认灰色边框
  end

  -- show raid icon if existing
  if GetRaidTargetIndex(this.guid) then
    SetRaidTargetIconTexture(this.icon, GetRaidTargetIndex(this.guid))
    this.icon:Show()
  else
    this.icon:Hide()
  end

  -- update target indicator
  if UnitIsUnit("target", this.guid) then
    this.target_left:Show()
    this.target_right:Show()
  else
    this.target_left:Hide()
    this.target_right:Hide()
  end
end

ui.BarClick = function()
  TargetUnit(this.guid)
end

ui.BarEvent = function()
  if arg1 ~= this.guid then return end
  local config = ShaguScan_db.config[this:GetParent().id]
  if config and config.showDamageText then
    CombatFeedback_OnCombatEvent(arg2, arg3, arg4, arg5) -- 仅在启用时显示伤害
  end
end

ui.BarCycler = function(win, direction, num)
  local windowName = win or "ot"
  direction = direction or "up" -- 默认为up
  local root = ui.frames[windowName]
  if not root then return end

  -- 初始化循环状态（保持原有逻辑）
  ui.cycleStates = ui.cycleStates or {}
  local stateKey = windowName
  ui.cycleStates[stateKey] = ui.cycleStates[stateKey] or {
    upIndex = 0,
    downIndex = 0
  }
  local state = ui.cycleStates[stateKey]

  local bars = root.sortedBars or {}
  local total = table.getn(bars)
  if total == 0 then return end -- 无血条时退出

  -- 【新增：处理num参数（直接选择指定序号的血条）】
  if num ~= nil then
    -- 将num转换为数字并取整
    local targetNum = math.floor(tonumber(num) or 0)
    -- 校验num有效性：必须是1到血条总数之间的整数（最多5个，符合需求）
    if targetNum >= 1 and targetNum <= total and targetNum <= 5 then
      local targetGuid = bars[targetNum]
      if targetGuid and select(1, UnitExists(targetGuid)) then
        TargetUnit(targetGuid)
        -- 同步索引状态（让后续方向循环从当前序号开始）
        state.upIndex = targetNum
        state.downIndex = targetNum
        return -- 执行后退出，不触发原有循环逻辑
      end
    end
    -- 若num无效，不执行操作（可根据需求改为默认选第一个）
    return
  end

  -- 【原有逻辑：方向循环（当num不存在时执行）】
  local currentIndex = direction == "up" and state.upIndex or state.downIndex
  if currentIndex == 0 then -- 首次使用时初始化
    local targetExists, currentTargetGuid = UnitExists("target")
    if targetExists and currentTargetGuid then
      for i, guid in ipairs(bars) do
        if guid == currentTargetGuid then
          currentIndex = i
          break
        end
      end
    end
    currentIndex = currentIndex == 0 and (direction == "up" and 1 or total) or currentIndex
  end

  -- 计算下一个索引
  local nextIndex
  if direction == "up" then
    nextIndex = currentIndex >= total and 1 or currentIndex + 1
    state.upIndex = nextIndex
  else
    nextIndex = currentIndex <= 1 and total or currentIndex - 1
    state.downIndex = nextIndex
  end

  -- 同步方向索引
  if direction == "up" then
    state.downIndex = nextIndex
  else
    state.upIndex = nextIndex
  end

  -- 选择目标
  local targetGuid = bars[nextIndex]
  if targetGuid and select(1, UnitExists(targetGuid)) then
    TargetUnit(targetGuid)
  else
    ui.BarCycler(win, direction) -- 目标无效时重试
  end
end


ui.CreateBar = function(parent, guid)
  local frame = CreateFrame("Button", nil, parent)
  frame.guid = guid

  -- assign required events and scripts
  frame:RegisterEvent("UNIT_COMBAT")
  frame:SetScript("OnEvent", ui.BarEvent)
  frame:SetScript("OnClick", ui.BarClick)
  frame:SetScript("OnEnter", ui.BarEnter)
  frame:SetScript("OnLeave", ui.BarLeave)
  frame:SetScript("OnUpdate", ui.BarUpdate)

  -- create health bar
  local bar = CreateFrame("StatusBar", nil, frame)
  bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  bar:SetStatusBarColor(1, .8, .2, 1)
  bar:SetMinMaxValues(0, 100)
  bar:SetValue(20)
  bar:SetAllPoints()
  frame.bar = bar

-- -- 【新增：距离文本框（血条外左侧，仅显示距离）】
--   local distanceText = frame:CreateFontString(nil, "HIGH", "GameFontWhite")
--   distanceText:SetFont(STANDARD_TEXT_FONT, 9, "THINOUTLINE")
--   distanceText:SetJustifyH("RIGHT") -- 右对齐，贴近血条左侧
--   distanceText:SetPoint("TOPRIGHT", frame, "TOPLEFT", -4, -2) -- 位于血条左侧外部（左移3px留白）
--   distanceText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", -3, 2)
--   frame.distanceText = distanceText

-- 【修改：距离文本框（血条下方左侧）】
local distanceText = frame:CreateFontString(nil, "HIGH", "GameFontWhite")
distanceText:SetFont(STANDARD_TEXT_FONT, 9, "THINOUTLINE")
distanceText:SetJustifyH("LEFT") -- 左对齐
-- 定位在血条底部左侧，向下偏移2像素，右侧预留目标文本空间
distanceText:SetPoint("TOPLEFT", frame.bar, "TOPLEFT", -6, 14)
distanceText:SetPoint("TOPRIGHT", frame.bar, "TOPRIGHT", -6, 20) -- 预留60像素给右侧目标文本
frame.distanceText = distanceText
  -- 根据配置初始化显示状态
local config = ShaguScan_db.config[parent.id]
if config and not config.showDistance then
  distanceText:Hide()
end
  -- 【修改：血条内左侧文本框（序号+等级+名称）】
  local text = frame.bar:CreateFontString(nil, "HIGH", "GameFontWhite")
  text:SetPoint("TOPLEFT", bar, "TOPLEFT", 6, -1)
  -- 右侧预留目标信息空间（例如右移80px，避免重叠）
  text:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -4, 3) 
  text:SetFont(STANDARD_TEXT_FONT, 9, "THINOUTLINE")
  text:SetJustifyH("LEFT") -- 左对齐
  frame.text = text


  --   -- 【修改：目标文本框（血条外部右侧，显示目标信息）】
  -- local targetText = frame:CreateFontString(nil, "HIGH", "GameFontWhite") -- 父容器改为 frame（血条的父级）
  -- targetText:SetFont(STANDARD_TEXT_FONT, 9, "THINOUTLINE")
  -- targetText:SetJustifyH("LEFT") -- 左对齐，贴近血条右侧
  -- -- 定位在血条右侧外部（右移3px留白，与血条顶部对齐）
  -- targetText:SetPoint("TOPLEFT", frame.bar, "TOPRIGHT", 3, -1)
  -- targetText:SetPoint("BOTTOMLEFT", frame.bar, "BOTTOMRIGHT", 4, 2)
  -- frame.targetText = targetText
  
  -- 【修改：目标文本框（血条下方右侧）】
local targetText = frame:CreateFontString(nil, "HIGH", "GameFontWhite")
targetText:SetFont(STANDARD_TEXT_FONT, 9, "THINOUTLINE")
targetText:SetJustifyH("RIGHT") -- 右对齐（与距离文本区分）
-- 定位在血条底部右侧，与左侧距离文本保持间距
targetText:SetPoint("TOPLEFT", frame.bar, "TOPLEFT", 30, 14) -- 与距离文本左侧错开60像素
--targetText:SetPoint("TOPRIGHT", frame.bar, "BOTTOMRIGHT", -30, -2)
frame.targetText = targetText
-- 初始化显示状态
local config = ShaguScan_db.config[parent.id]
if config and not config.showTargetText then
  targetText:Hide()
end

  -- create combat feedback text
  local feedback = bar:CreateFontString(guid.."feedback"..GetTime(), "OVERLAY", "NumberFontNormalHuge")
  feedback:SetAlpha(.8)
  feedback:SetFont(DAMAGE_TEXT_FONT, 12, "OUTLINE")
  feedback:SetParent(bar)
  feedback:ClearAllPoints()
  feedback:SetPoint("RIGHT", bar, "RIGHT", -2, 0)

  frame.feedbackFontHeight = 14
  frame.feedbackStartTime = GetTime()
  frame.feedbackText = feedback
  -- 初始化伤害文本显示状态
local config = ShaguScan_db.config[parent.id]
if config and not config.showDamageText then
  feedback:Hide()
end

  -- create raid icon textures
  local icon = bar:CreateTexture(nil, "OVERLAY")
  icon:SetWidth(10)
  icon:SetHeight(10)
  icon:SetPoint("LEFT", frame, "LEFT", 1, 0)
  icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
  icon:Hide()
  frame.icon = icon

  -- create target indicator
  -- 修改目标左侧纹理（变大并调整位置）
  local target_left = bar:CreateTexture(nil, "OVERLAY")
  target_left:SetWidth(8) -- 原8，改为12（可根据需要调整）
  target_left:SetHeight(8) -- 原8，改为12
  -- 向左偏移量增加（避免遮挡血条），原-4，改为-6
  target_left:SetPoint("LEFT", frame, "LEFT", 2, 0)
  target_left:SetTexture("Interface\\AddOns\\ShaguScan\\img\\target-left")
  target_left:Hide()
  frame.target_left = target_left

  local target_right = bar:CreateTexture(nil, "OVERLAY")
  target_right:SetWidth(8)
  target_right:SetHeight(8)
  target_right:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
  target_right:SetTexture("Interface\\AddOns\\ShaguScan\\img\\target-right")
  target_right:Hide()
  frame.target_right = target_right
  




  -- create frame backdrops
  if pfUI and pfUI.uf then
    pfUI.api.CreateBackdrop(frame)
    frame.border = frame.backdrop
  else
    frame:SetBackdrop(ui.background)
    frame:SetBackdropColor(0, 0, 0, 1)

    local border = CreateFrame("Frame", nil, frame.bar)
    border:SetBackdrop(ui.border)
    border:SetBackdropColor(.2, .2, .2, 1)
    border:SetPoint("TOPLEFT", frame.bar, "TOPLEFT", -2,2)
    border:SetPoint("BOTTOMRIGHT", frame.bar, "BOTTOMRIGHT", 2,-2)
    frame.border = border
  end

  -- 【新增：仇恨百分比文本框（血条右侧）】
local threatText = frame.bar:CreateFontString(nil, "HIGH", "GameFontWhite")
threatText:SetFont(STANDARD_TEXT_FONT, 9, "THINOUTLINE")
threatText:SetJustifyH("RIGHT") -- 右对齐
-- 定位在血条右侧，与边缘保持间距
threatText:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 32, -1)
threatText:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 32, 2)
frame.threatText = threatText -- 保存引用

-- 初始化仇恨文本显示状态（根据配置）
local config = ShaguScan_db.config[parent.id]
if config and not config.showThreatBar then
  threatText:Hide()
end




  return frame
end

-- 新增：实时排序函数
ui.UpdateSorting = function(root)
  local tempBars = {}
  for guid, bar in pairs(root.frames) do
    -- 直接使用OnUpdate中已排序的validGuids，避免重复计算
  return root.sortedBars or {}
  end

  -- 优先按y值排序，y值相同则按guid哈希排序（避免随机顺序）
  table.sort(tempBars, function(a, b)
    if a.y ~= b.y then
      return a.y > b.y  -- y越大越靠下（序号越前）
    else
      return a.guidHash < b.guidHash  -- 同y值时按guid稳定排序
    end
  end)

  root.sortedBars = {}
  for i = 1, table.getn(tempBars) do
    table.insert(root.sortedBars, tempBars[i].guid)
  end
end

--优化：降低更新频率至1秒，减轻CPU负担
ui:SetAllPoints()
ui:SetScript("OnUpdate", function()
  if (this.tick or 1) > GetTime() then return else this.tick = GetTime() + 1 end

  -- 移除无效的旧框架
  for caption, root in pairs(ui.frames) do
    if not ShaguScan_db.config[caption] then
      ui.frames[caption]:Hide()
      ui.frames[caption] = nil
    end
  end

  -- 基于配置创建UI框架
  for caption, config in pairs(ShaguScan_db.config) do
    ui.frames[caption] = ui.frames[caption] or ui:CreateRoot(caption)
    local root = ui.frames[caption]

    if root.lock then return end

    -- 更新位置和缩放
    if not root.pos or root.pos ~= config.anchor..config.x..config.y..config.scale then
      root.pos = config.anchor..config.x..config.y..config.scale
      root:ClearAllPoints()
      root:SetPoint(config.anchor, config.x, config.y)
      root:SetScale(config.scale)
    end

    -- 更新过滤器
    if not root.filter_conf or root.filter_conf ~= config.filter then
      root.filter = {}
      local filter_texts = { utils.strsplit(',', config.filter) }
      for id, filter_text in pairs(filter_texts) do
        local name, args = utils.strsplit(':', filter_text)
        root.filter[name] = args or true
      end
      root.filter_conf = config.filter
    end

    -- 初始化变量
    local title_size = 12 + config.spacing
    local width, height = config.width, config.height + title_size
    local max_display_rows = config.max_display_rows or 5
    local visibleCount = 0  -- 用于计算可见血条的位置

    -- 先隐藏所有血条，准备重新排列
    for guid, bar in pairs(root.frames) do
      bar:Hide()
    end

    -- 收集所有符合条件的血条GUID（基础创建逻辑）
    local validGuids = {}
    -- 优化：缓存过滤结果，避免重复过滤
    local filteredGuids = {}
    
    for guid, _ in pairs(ShaguScan.core.guids) do
      if UnitExists(guid) then  -- 确保单位存在
        -- 优化：使用缓存减少重复计算
        if filteredGuids[guid] == nil then
          local visible = true
          -- 应用过滤条件
          for name, args in pairs(root.filter) do
            if filter[name] then
              visible = visible and filter[name](guid, args)
            end
          end
          filteredGuids[guid] = visible
        end
        
        if filteredGuids[guid] then
          table.insert(validGuids, guid)
        end
      else
        -- 如果单位不再存在，从core.guids中移除（帮助core.add逻辑更好地管理数量）
        ShaguScan.core.guids[guid] = nil
      end
    end

    -- 优化：批量获取单位属性并缓存，减少API调用次数
    local unitProperties = {}
    local classification_values = {
      worldboss = 5,
      rareelite = 4,
      rare = 3,
      elite = 2,
      normal = 1
    }
    
    -- 先批量获取所有单位属性
    for _, guid in ipairs(validGuids) do
      unitProperties[guid] = {
        infight = UnitAffectingCombat(guid) and 1 or 0,
        aggro = UnitExists(guid.."target") and UnitIsUnit(guid.."target", "player") and 1 or 0,
        classification = classification_values[UnitClassification(guid)] or 0,
        updatetime = ShaguScan.core.guids[guid] or 0
      }
    end
    
    -- 对有效血条排序（按照重要性从高到低排序）
    table.sort(validGuids, function(a, b)
      -- 优先级排序规则：
      -- 1. 处于战斗中的单位优先
      -- 2. 对玩家有仇恨的单位优先
      -- 3. 稀有精英 > 精英 > 普通单位
      -- 4. 最近更新的单位优先
      
      -- 使用缓存的属性数据
      local a_props = unitProperties[a]
      local b_props = unitProperties[b]
      
      -- 战斗状态优先级
      if a_props.infight ~= b_props.infight then
        return a_props.infight > b_props.infight
      end
      
      -- 仇恨优先级（攻击玩家的单位）
      if a_props.aggro ~= b_props.aggro then
        return a_props.aggro > b_props.aggro
      end
      
      -- 单位类型优先级
      if a_props.classification ~= b_props.classification then
        return a_props.classification > b_props.classification
      end
      
      -- 更新时间优先级（最近更新的优先）
      if a_props.updatetime ~= b_props.updatetime then
        return a_props.updatetime > b_props.updatetime
      end
      
      -- 最后按GUID哈希值排序（确保稳定）
      return tonumber(string.sub(a, -6), 16) < tonumber(string.sub(b, -6), 16)
    end)

    -- 限制显示数量并计算位置
    for i, guid in ipairs(validGuids) do
      if visibleCount < max_display_rows then
        visibleCount = visibleCount + 1
        -- 计算垂直位置（从上到下排列）
        local y = (visibleCount - 1) * (config.height + config.spacing) + title_size
        height = math.max(y + config.height + config.spacing, height)

        -- 创建或获取血条
        root.frames[guid] = root.frames[guid] or root:CreateBar(guid)
        local bar = root.frames[guid]

        -- 设置位置（强制更新，避免缓存问题）
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", root, "TOPLEFT", 0, -y)
        bar.pos = "0" .. -y  -- 更新位置缓存

        -- 设置尺寸
        if not bar.sizes or bar.sizes ~= config.width .. config.height then
          bar:SetWidth(config.width)
          bar:SetHeight(config.height)
          bar.sizes = config.width .. config.height
        end

        -- 根据隐藏状态显示
        if not root.hiddenBars then
          bar:Show()
        end
      end
    end

  -- 优化：降低OT喊话频率，减少字符串操作和SendChatMessage调用
  if ShaguScan_db.otAnnounce and caption == "ot" then
    -- 只在有效GUID数量变化或间隔足够长时检查
    local validGuids = root.sortedBars or {}
    local guidCount = 0
    for _, _ in pairs(validGuids) do guidCount = guidCount + 1 end
    
    -- 只有当有GUID或间隔超过3秒时才处理
    local now = GetTime()
    if (guidCount > 0) and (not ui.lastOTCheck or (now - ui.lastOTCheck > 3)) then
      ui.lastOTCheck = now
      
      -- 优化：减少单位API调用
      local announceNeeded = false
      local unitsToAnnounce = {}
      
      -- 先检查是否有需要喊话的单位
      for _, guid in ipairs(validGuids) do
        local targetUnit = guid .. "target"
        if UnitExists(targetUnit) then
          local targetName = UnitName(targetUnit) or "未知目标"
          local cacheKey = guid .. "_" .. targetName
          
          if not ui.otAnnounceCache[cacheKey] or (now - ui.otAnnounceCache[cacheKey] > 30) then
            table.insert(unitsToAnnounce, {guid = guid, targetName = targetName})
            announceNeeded = true
          end
        end
      end
      
      -- 只在有需要时才执行喊话
      if announceNeeded then
        -- 限制一次最多只喊一个单位，避免刷屏
        local unitInfo = unitsToAnnounce[1]
        if unitInfo then
          SendChatMessage("[OT监控] " .. UnitName(unitInfo.guid) .. " 换目标攻击: " .. unitInfo.targetName .. " <--大家鄙视ta！", "RAID")
          ui.otAnnounceCache[unitInfo.guid .. "_" .. unitInfo.targetName] = now
        end
      end
    end
  end
    --要添加ui要素在这行之前----------------------------------------------------------------------------------------------




    -- 更新窗口尺寸
    root:SetWidth(width)
    root:SetHeight(height)

    -- 更新排序缓存（供其他功能使用，如序号显示）
    root.sortedBars = validGuids
  end
end)

-- 注册OT喊话控制命令
SLASH_OTANNOUNCE1 = "/otannounce"
SlashCmdList["OTANNOUNCE"] = function(msg)
  -- 切换开关状态
  ShaguScan_db.otAnnounce = not ShaguScan_db.otAnnounce
  
  -- 发送状态提示
  local status = ShaguScan_db.otAnnounce and "|cff00ff00开启|r" or "|cffff0000关闭|r"
  DEFAULT_CHAT_FRAME:AddMessage("OT喊话功能已" .. status)
  -- 新增：强制刷新所有框架的标题文本，显示最新状态
  for caption, root in pairs(ui.frames) do
    if root.caption then -- 确保标题控件存在
      root.caption:SetText(
      "|cff00ffff[表名]：|r" .. caption .. 
      " |cffaaaaaa(喊:" .. 
      (ShaguScan_db.otAnnounce 
        and "|cff00ff00开|r"  -- 绿色开
        or "|cffff0000关|r"   -- 红色关
      ) .. ")|r"
    )
    end
  end
end

-- 优化：使用节流机制处理TWT消息，避免频繁处理
local twtFrame = CreateFrame("Frame")
twtFrame:RegisterEvent("CHAT_MSG_ADDON")
twtFrame.lastProcessTime = 0
local twtProcessInterval = 0.5 -- 至少间隔0.5秒处理一次TWT消息

twtFrame:SetScript("OnEvent", function()
  -- 节流处理，避免过于频繁地处理TWT消息
  local now = GetTime()
  if now - this.lastProcessTime < twtProcessInterval then
    return
  end
  
  if arg1 == "TWT" and (string.find(arg2, "TWTv4=") or string.find(arg2, "TMTv1=")) then
    this.lastProcessTime = now
    
    -- 只处理当前显示的单位GUID，避免不必要的计算
    local guidToProcess = {}
    for _, root in pairs(ui.frames) do
      for guid, bar in pairs(root.frames) do
        if bar:IsShown() then
          guidToProcess[guid] = true
        end
      end
    end
    
    -- 批量处理相关GUID的数据
    for guid in pairs(guidToProcess) do
      ProcessTWTData(guid)
    end
    
    -- 延迟更新显示，避免在同一帧内多次更新UI
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function()
      -- 只更新一次就隐藏
      for _, root in pairs(ui.frames) do
        for guid, bar in pairs(root.frames) do
          if bar:IsShown() then
            bar:GetScript("OnUpdate")()
          end
        end
      end
      this:Hide()
    end)
  end
end)

local function ProcessTWTData(guid)
  -- 优化：先检查GUID是否有效，无效直接返回
  if not UnitExists(guid) then
    -- 清理无效GUID的数据
    if pfUI and pfUI.threatData and pfUI.threatData[guid] then
      pfUI.threatData[guid] = nil
    end
    return
  end
  
  -- 初始化变量，避免多次创建
  local my_threat_perc = nil  -- 玩家自身仇恨百分比
  local second_threat_name = nil  -- 第二仇恨目标名称
  local second_threat_perc = nil  -- 第二仇恨百分比
  
  -- 检查TWT是否存在，避免全局变量nil访问
  if not TWT then
    return
  end
  
  -- 1. 从TWT.tankModeThreats获取多目标仇恨数据
  if TWT.tankModeThreats then
    for k, v in pairs(TWT.tankModeThreats) do
      if v and v.guid == guid then  -- 匹配当前单位的GUID
        -- 提取第二仇恨信息（多目标场景）
        second_threat_name = v.name
        second_threat_perc = v.perc
        break
      end
    end
  end

  -- 2. 从TWT.threats获取玩家自身仇恨数据
  if TWT.threats then
    local player_name = UnitName("player")  -- 当前玩家名称
    for k, v in pairs(TWT.threats) do
      if k == player_name and v and v.perc then  -- 匹配当前玩家
        my_threat_perc = v.perc  -- 记录玩家仇恨百分比
        break  -- 找到后立即退出循环
      end
    end
  end

  -- 3. 处理单体目标仇恨（当前目标时）
  local is_current_target = UnitIsUnit("target", guid)  -- 是否为当前目标
  if is_current_target and TWT.threats then
    local player_name = UnitName("player")  -- 当前玩家名称
    
    -- 优化：合并循环，一次遍历完成多项任务
    local top_threat_perc = 0
    local top_threat_name = nil
    local threats_to_sort = {}
    local found_player = false
    
    for k, v in pairs(TWT.threats) do
      if v and v.perc and k ~= "-Pull Aggro at-" then
        local perc = tonumber(v.perc)
        
        -- 查找最高仇恨
        if perc > top_threat_perc then
          top_threat_perc = perc
          top_threat_name = k
        end
        
        -- 同时收集玩家以外的威胁数据，避免二次遍历
        if k ~= player_name then
          table.insert(threats_to_sort, {name = k, perc = perc})
        else
          found_player = true
        end
      end
    end

    -- 若玩家是最高仇恨，查找第二仇恨
    if top_threat_name == player_name then
      -- 直接使用已收集的数据，无需重新遍历
      if table.getn(threats_to_sort) > 0 then
        -- 按仇恨值降序排序，取第一个作为第二仇恨
        table.sort(threats_to_sort, function(a, b) return a.perc > b.perc end)
        if threats_to_sort[1] then
          second_threat_name = threats_to_sort[1].name
          second_threat_perc = threats_to_sort[1].perc
        end
      end
    end
  end
  
  -- 调试日志（仅在开发模式下启用）
  if ShaguScan_db and ShaguScan_db.debug and pfUI and pfUI.threatData and pfUI.threatData[guid] then
    print(string.format(
      "仇恨数据[GUID:%s]：玩家仇恨=%d%%，第二仇恨=%s(%d%%)",
      guid,
      pfUI.threatData[guid].int_my_threat or 0,
      pfUI.threatData[guid].second_threat_name or "未知",
      pfUI.threatData[guid].int_second_threat or 0
    ))
  end

  -- 缓存数据到pfUI.threatData，确保安全访问
  if not pfUI then pfUI = {} end
  if not pfUI.threatData then pfUI.threatData = {} end
  if not pfUI.threatData[guid] then pfUI.threatData[guid] = {} end
  
  pfUI.threatData[guid].int_second_threat = math.floor(second_threat_perc or 0)  -- 整数化
  pfUI.threatData[guid].second_threat_name = second_threat_name
  pfUI.threatData[guid].int_my_threat = math.floor(my_threat_perc or 0)
end

ShaguScan.ui = ui
