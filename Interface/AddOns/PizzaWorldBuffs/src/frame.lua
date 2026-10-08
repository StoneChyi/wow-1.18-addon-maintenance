-- frame.lua
local PWB = PizzaWorldBuffs

setfenv(1, PWB:GetEnv())

-- Main container frame
PWB.frame = CreateFrame('Frame', 'PizzaWorldBuffsFrame', UIParent)
PWB.frame:ClearAllPoints()
PWB.frame:SetPoint('TOP', 0, -50)
PWB.frame:SetFrameStrata('LOW')
PWB.frame:SetWidth(1)
PWB.frame:SetHeight(1)

-- Initialize a single frame
local function initFrame(f, anchor)
  f.frame = CreateFrame('Frame', f.name, PWB.frame)
  f.anchor = anchor
  f.frame:EnableMouse(true)
  f.frame:SetScript('OnMouseDown', function ()
    if IsShiftKeyDown() then
      if arg1 ~= 'LeftButton' and arg1 ~= 'RightButton' and arg1 ~= 'MiddleButton' and arg1 ~= 'Button4' then return end
      if f.timer then
        PWB.share.share(arg1, 'timer', f.timer)
      elseif f.name == 'PizzaWorldBuffsDmf' then 
        PWB.share.share(arg1, 'dmf')
      else
        PWB.share.share(arg1, 'link')
      end
    else
      if not PWB_config.lock then
        PWB.frame:StartMoving()
      end
    end
  end)
  f.frame:SetScript('OnMouseUp', function ()
    PWB.frame:StopMovingOrSizing()
  end)

  if f.name == 'PizzaWorldBuffsDmf' then
    f.frame:SetScript('OnEnter', function ()
      local currentLoc, nextLoc, timeLeft = PWB.utils.getDarkmoonFaireInfo()
      local currentLocFull = PWB.DmfLocations[currentLoc]
      local nextLocFull = PWB.DmfLocations[nextLoc]
      local timeLeftStr = PWB.utils.toRoughTimeString(timeLeft)

      GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
      GameTooltip:SetText(PWB.Colors.primary .. '暗月马戏团')
      GameTooltip:AddLine(PWB.Colors.secondary .. '\n当前位置: ' .. (currentLoc == 'E' and PWB.Colors.alliance or PWB.Colors.horde) .. currentLocFull)
      GameTooltip:AddLine(PWB.Colors.secondary .. '下次轮换: ' .. timeLeftStr .. ' 后到 ' .. (nextLoc == 'E' and PWB.Colors.alliance or PWB.Colors.horde) .. nextLocFull)
      GameTooltip:AddLine(PWB.Colors.grey .. T['\nThe Faire shuts down on Wednesdays and\nmoves between Elwynn Forest and Mulgore\nevery Sunday at midnight (server time).'])
      GameTooltip:AddLine(PWB.Colors.primary .. '\n/wb dmfbuffs' .. PWB.Colors.grey .. T['shows all available buffs.'])
      GameTooltip:AddLine(PWB.Colors.primary .. '\n/wb dmf 0' .. PWB.Colors.grey .. T['hides DMF location.'])
      GameTooltip:Show()
    end)
    f.frame:SetScript('OnLeave', function ()
      GameTooltip:Hide()
    end)
  end

  f.frame.text = f.frame:CreateFontString(f.name .. 'Text', 'DIALOG', 'GameFontWhite')
  f.frame.text:SetFont(STANDARD_TEXT_FONT, PWB_config.fontSize, 'OUTLINE')
  f.frame.text:SetJustifyH('LEFT')
  local point = PWB_config.align == 'left' and 'TOPLEFT' or PWB_config.align == 'right' and 'TOPRIGHT' or 'TOP'
  f.frame.text:SetPoint(point, 0, 0)
  f.frame.text:SetText(f.text)
end

-- Initialize all frames
local function initFrames()
  if PWB.frames then return end

  local otherFaction = PWB.myFaction == 'A' and 'H' or 'A'

  PWB.frames = {
    {
      name = 'PizzaWorldBuffsHeader',
      text = PWB.Colors.primary .. 'Pizza' .. PWB.Colors.secondary .. 'WorldBuffs',
      shouldShow = function() 
        return PWB_config.header == true
      end,
    },
    {
      name = 'PizzaWorldBuffsTimer1',
      timer = {
        faction = PWB.myFaction,
        boss = 'O',
      },
    },
    {
      name = 'PizzaWorldBuffsTimer2',
      timer = {
        faction = PWB.myFaction,
        boss = 'N',
      },
    },
    {
      name = 'PizzaWorldBuffsTimer3',
      timer = {
        faction = otherFaction,
        boss = 'O',
      },
    },
    {
      name = 'PizzaWorldBuffsTimer4',
      timer = {
        faction = otherFaction,
        boss = 'N',
      },
    },
    {
      name = 'PizzaWorldBuffsTimer5',
      timer = {
        faction = 'H',
        boss = 'R', -- 酋长的祝福（部落雷德）
      },
    },
    {
      name = 'PizzaWorldBuffsTimer6',
      timer = {
        faction = 'N',
        boss = 'Z', -- 赞达拉之魂（中立）
      },
    },
    {
      name = 'PizzaWorldBuffsDmf',
      shouldShow = function() 
        return PWB_config.dmf == true
      end,
    },
  }

  local previous
  for _, frame in ipairs(PWB.frames) do
    initFrame(frame, previous)
    previous = frame
  end
end

-- Mouse Drag
PWB.frame:SetMovable(true)

-- Apply saved variables
PWB.frame:RegisterEvent('PLAYER_ENTERING_WORLD')
PWB.frame:SetScript('OnEvent', function ()
  if event == 'PLAYER_ENTERING_WORLD' then
    initFrames()
    if PWB_config.show then
      PWB.frame:Show()
    else
      PWB.frame:Hide()
    end
  end
end)

function PWB.frame.updateFrames()
  local spacing = 10 -- Space between frames in horizontal mode
  local xOffset = 0
  local yOffset = 0
  local maxWidth = 0
  local totalHeight = 0

  for i, frame in ipairs(PWB.frames) do
    frame.frame.text:SetFont(STANDARD_TEXT_FONT, PWB_config.fontSize, 'OUTLINE')

    -- Update text content
    if frame.timer then
      local timer = PWB_timers and PWB_timers[frame.timer.faction] and PWB_timers[frame.timer.faction][frame.timer.boss]
      local timeStr = PWB.Colors.grey .. T['N/A']
      if timer then
        local h, m = PWB.core.getTimeLeft(timer)
        timeStr = PWB.utils.getTimerColor(timer.witness, timer.receivedFrom) .. PWB.utils.toString(h, m)
      end
      local bossColor = frame.timer.faction == 'A' and PWB.Colors.alliance or frame.timer.faction == 'H' and PWB.Colors.horde or PWB.Colors.primary
      frame.frame.text:SetText(bossColor .. T[PWB.Bosses[frame.timer.boss]] .. ': ' .. timeStr)

      -- 'N'（中立，赞达拉之魂）对所有玩家可见；其他阵营的计时器仅在开启 allFactions 时显示
      if not PWB_config.allFactions and frame.timer.faction ~= PWB.myFaction and frame.timer.faction ~= 'N' then
        frame.frame:Hide()
      else
        frame.frame:Show()
      end
    elseif frame.name == 'PizzaWorldBuffsDmf' then
    local currentLoc, nextLoc, timeLeft = PWB.utils.getDarkmoonFaireInfo()
    local shortLoc = PWB.utils.strSplit(PWB.DmfLocations[currentLoc], ' ')
    local color = currentLoc == 'E' and PWB.Colors.alliance or PWB.Colors.horde
    local location = color .. (shortLoc or PWB.DmfLocations[currentLoc])
    frame.frame.text:SetText(PWB.Colors.primary .. '马戏团: ' .. location)
    end

    -- Handle visibility for optional frames
    if frame.shouldShow then
      if frame.shouldShow() then
        frame.frame:Show()
      else
        frame.frame:Hide()
      end
    end

    -- Position frames based on orientation
    frame.frame:ClearAllPoints()
    local point = PWB_config.orientation == 'horizontal' and 'TOPLEFT' or (PWB_config.align == 'left' and 'TOPLEFT' or PWB_config.align == 'right' and 'TOPRIGHT' or 'TOP')

    if PWB_config.orientation == 'horizontal' then
      if frame.frame:IsShown() then
        frame.frame:SetPoint(point, PWB.frame, point, xOffset, 0)
        xOffset = xOffset + frame.frame.text:GetWidth() + spacing
        totalHeight = math.max(totalHeight, frame.frame.text:GetHeight())
      end
    else -- vertical (default)
      if frame.frame:IsShown() then
        frame.frame:SetPoint(point, PWB.frame, point, 0, yOffset)
        yOffset = yOffset - frame.frame.text:GetHeight()
        maxWidth = math.max(maxWidth, frame.frame.text:GetWidth())
        totalHeight = totalHeight + frame.frame.text:GetHeight()
      end
    end

    frame.frame:SetWidth(frame.frame.text:GetWidth())
    frame.frame:SetHeight(frame.frame.text:GetHeight())
  end

  -- Set parent frame size
  if PWB_config.orientation == 'horizontal' then
    PWB.frame:SetWidth(xOffset - spacing) -- Subtract last spacing
    PWB.frame:SetHeight(totalHeight)
  else
    PWB.frame:SetWidth(maxWidth)
    PWB.frame:SetHeight(totalHeight)
  end
end

-- Update
PWB.frame:SetScript('OnUpdate', function ()
  if (this.tick or 1) > GetTime() then return else this.tick = GetTime() + 1 end
  PWB.frame.updateFrames()
end)