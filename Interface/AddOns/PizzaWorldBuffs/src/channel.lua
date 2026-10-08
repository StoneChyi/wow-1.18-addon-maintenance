local PWB = PizzaWorldBuffs

PWB.channelName = 'LFT'

-- Frame to delay joining PWB channel
PWB.channelJoinDelay = CreateFrame('Frame', 'PizzaWorldBuffsChannelJoinDelay', UIParent)
PWB.channelJoinDelay:Hide()

PWB.channelJoinDelay:SetScript('OnShow', function ()
  this.startTime = GetTime()
end)

PWB.channelJoinDelay:SetScript('OnHide', function ()
  local isInChannel = false
  local channels = { GetChannelList() }

  for _, channel in next, channels do
    if PWB.utils.isPwbChannel(channel) then
      isInChannel = true
      break
    end
  end

  if not isInChannel then
    JoinChannelByName(PWB.channelName)
  end
end)

PWB.channelJoinDelay:SetScript('OnUpdate', function ()
  local delay = 15
  local gt = GetTime() * 1000
  local st = (this.startTime + delay) * 1000
  if gt >= st then
    PWB.channelJoinDelay:Hide()
  end
end)

-- Frame to delay joining the WorldBuffsTracker (TWB) channel so PizzaWorldBuffs can import
-- its accurate, absolutely-timestamped buff timers (sync with WorldBuffsTracker v1.8+).
-- PWB only READS the TWB channel; it never broadcasts to it, so it won't pollute WBT's network.
PWB.wbtChannelJoinDelay = CreateFrame('Frame', 'PizzaWorldBuffsWbtChannelJoinDelay', UIParent)
PWB.wbtChannelJoinDelay:Hide()

PWB.wbtChannelJoinDelay:SetScript('OnShow', function ()
  this.startTime = GetTime()
end)

PWB.wbtChannelJoinDelay:SetScript('OnHide', function ()
  if PWB_config.wbtSync then
    JoinChannelByName('TWB')
  end
end)

PWB.wbtChannelJoinDelay:SetScript('OnUpdate', function ()
  local delay = 15
  if (GetTime() * 1000) >= ((this.startTime + delay) * 1000) then
    PWB.wbtChannelJoinDelay:Hide()
  end
end)
