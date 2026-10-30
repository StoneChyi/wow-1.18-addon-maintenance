PizzaWorldBuffs = CreateFrame('Frame', 'PizzaWorldBuffsTime', UIParent)
local PWB = PizzaWorldBuffsTime
PWB.abbrev = 'PWB'
PWB.abbrevDmf = 'PWB_DMF'

PWB.nameSuffix4h = '*'

PWB.Colors = {
  primary = '|cffa050ff',
  secondary = '|cffffffff',

  alliance = '|cff0070dd',
  horde = '|cffc41e3a',
  white = '|cffffffff',
  grey = '|cffaaaaaa',
  green = '|cff00ff98',
  orange = '|cffff7c0a',
  red = '|cffc41e3a',
}

local dmfNpcNames = {
  'Flik',
  'Sayge',
  'Burth',
  'Lhara',
  'Morja',
  'Jubjub',
  'Chronos',
  'Felinni',
  'Rinling',
  'Sylannia',
  'Hornsley',
  'Kerri Hicks',
  'Flik\'s Frog',
  'Yebb Neblegear',
  'Silas Darkmoon',
  'Selina Dourman',
  'Khaz Modan Ram',
  'Pygmy Cockatrice',
  'Gelvas Grimegate',
  'Stamp Thunderhorn',
  'Maxima Blastenheimer',
  'Professor Thaddeus Paleo',
}

PWB.env = {}
setmetatable(PWB.env, {
  __index = function(self, key)
    if key == 'T' then return end
    return getfenv(0)[key]
  end
})
function PWB:GetEnv()
  if not PWB.env.T then
    local locale = GetLocale() or 'enUS'
    PWB.env.T = setmetatable((PWB_translations or {})[locale] or {}, {
      __index = function(tbl, key)
        local value = tostring(key)
        rawset(tbl, key, value)
        return value
      end
    })
  end
  PWB.env._G = getfenv(0)
  return PWB.env
end

setfenv(1, PWB:GetEnv())

PWB.Bosses = {
  O = T['Onyxia'],
  N = T['Nefarian'],
  Z = T['Spirit of Zandalar'],
  R = T['Warchief\'s Blessing'],
}

PWB.DmfLocations = {
  E = T['Elwynn Forest'],
  M = T['Mulgore'],
}

function PWB:Print(msg, withPrefix)
  local prefix = withPrefix == false and '' or PWB.Colors.primary .. 'Pizza' .. PWB.Colors.secondary .. 'WorldBuffs:|r '
  DEFAULT_CHAT_FRAME:AddMessage(prefix .. msg)
end

function PWB:PrintClean(msg)
  PWB:Print(msg, false)
end

-- Turtle's '.server info' reply looks like "Server Time: 27.10.2026 20:33:14" (often followed by a
-- "Server Uptime: ..." line) and we only need the time line to calibrate PWB.serverTime -- but the
-- client also prints the whole reply into the chat frame. Wrap ChatFrameN:AddMessage (same approach
-- pfUI / CleanChat use on this client) and swallow those lines right after the calibration command
-- is sent, so the chat stays clean. Everything else is passed straight through to whatever
-- AddMessage implementation was installed before us.
local function hookServerTimeFilter(frame)
  if not frame or type(frame.AddMessage) ~= 'function' then return end
  -- Already wrapped (and nobody replaced our wrapper since) -- nothing to do.
  if frame.pwbAddMessageWrapper and frame.AddMessage == frame.pwbAddMessageWrapper then return end

  local origAddMessage = frame.AddMessage
  local wrapper = function(self, msg, r, g, b, id)
    if PWB_config.hideServerTime and PWB.serverTimeFilterUntil and PWB.serverTimeFilterUntil > GetTime()
      and type(msg) == 'string' then
      local plain = string.gsub(string.gsub(msg, '|c%x%x%x%x%x%x%x%x', ''), '|r', '')
      if string.find(plain, '^%s*Server [Tt]ime%s*:')
        or string.find(plain, '^%s*Server [Uu]ptime%s*:')
        or string.find(plain, '^%s*服务器时间%s*[:：]')
        or string.find(plain, '^%s*服务器运行时间%s*[:：]') then
        return
      end
    end
    return origAddMessage(self, msg, r, g, b, id)
  end
  frame.AddMessage = wrapper
  frame.pwbAddMessageWrapper = wrapper
end

function PWB.hookServerTimeFilter()
  hookServerTimeFilter(DEFAULT_CHAT_FRAME)
  for i = 1, (NUM_CHAT_WINDOWS or 7) do
    hookServerTimeFilter(_G['ChatFrame' .. i])
  end
end

local timerStrs = {}
PWB:RegisterEvent('ADDON_LOADED')
PWB:RegisterEvent('PLAYER_ENTERING_WORLD')
PWB:RegisterEvent('CHAT_MSG_ADDON')
PWB:RegisterEvent('CHAT_MSG_CHANNEL')
PWB:RegisterEvent('CHAT_MSG_MONSTER_YELL')
PWB:RegisterEvent('CHAT_MSG_WHISPER')
PWB:RegisterEvent('CHAT_MSG_SYSTEM')
PWB:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
PWB:SetScript('OnEvent', function()
  if event == 'ADDON_LOADED' and arg1 == 'PizzaWorldBuffs' then
    -- Initialize config with default values if necessary
    PWB.config.init()

    if PWB_config.autoLogout then
      PWB_config.autoLogout = false
      PWB:Print(T['Auto-logout disabled automatically. To enable it again, use /wb logout 1'])
    end

    if PWB_config.autoExit then
      PWB_config.autoExit = false
      PWB:Print(T['Auto-exit disabled automatically. To enable it again, use /wb exit 1'])
    end
  end

  if event == 'CHAT_MSG_SYSTEM' then
    if string.find(arg1, 'Server Time:') then
      local dd, mm, yyyy, hh, minute, second = string.match(arg1,
        'Server Time:%s[^,]+,%s(%d+)%.(%d+)%.(%d+)%s(%d+):(%d+):(%d+)')
      if dd and mm and yyyy and hh and minute and second then
        -- Encode the server's wall-clock as a local-time epoch. From then on PWB.serverTime
        -- is advanced by real elapsed seconds, so all countdowns stay on the server scale.
        PWB.serverTime = time({
          year = tonumber(yyyy),
          month = tonumber(mm),
          day = tonumber(dd),
          hour = tonumber(hh),
          min = tonumber(minute),
          sec = tonumber(second)
        })
        -- Timezone-independent serial (mirrors WorldBuffsTracker's WBT_Server_Serial) so we can
        -- convert WBT's Sync2 serial-based expiries without being thrown off by the local timezone.
        PWB.serverSerial = PWB.utils.serverDateToSerial(tonumber(yyyy), tonumber(mm), tonumber(dd),
          tonumber(hh), tonumber(minute), tonumber(second))
        PWB.serverTimeCounter = GetTime()
      end
    end
  end

  if event == 'PLAYER_ENTERING_WORLD' then
    -- Calibrate the server clock so world-buff countdowns are accurate regardless of the
    -- in-game clock speed or the player's local timezone. Mirrors WorldBuffsTracker.
    -- The reply line itself is only useful to us, so hide it from chat (config: hideServerTime).
    if PWB_config.hideServerTime then
      PWB.hookServerTimeFilter()
      PWB.serverTimeFilterUntil = GetTime() + 20
    end
    SendChatMessage('.server info')

    -- Store player's name & faction ('A' or 'H') for future use
    PWB.me = UnitName('player')
    PWB.myFaction = string.sub(UnitFactionGroup('player'), 1, 1)
    -- Workaround for Spanish localization
    if PWB.myFaction ~= "A" and PWB.myFaction ~= "H" then
      local _, raceEn = UnitRace('player')
      local hordeRaces = {
        Orc = true,
        Scourge = true,
        Troll = true,
        Tauren = true,
        Goblin = true,
      }
      PWB.myFaction = hordeRaces[raceEn] and "H" or "A"
    end
    PWB.isOnKalimdor = GetCurrentMapContinent() == 1

    -- If we don't have any timers or we still have timers in a deprecated format, clear/initialize them first.
    if not PWB.utils.hasTimers() or PWB.utils.hasDeprecatedTimerFormat() then
      PWB.core.clearAllTimers()
    end
    -- Ensure faction tables exist (older saved variables lack 'N' for neutral Zandalar)
    PWB.core.ensureFactions()

    -- Trigger delayed joining of the PWB chat channel
    PWB.channelJoinDelay:Show()

    -- Trigger delayed joining of WorldBuffsTracker's TWB channel so we can import its accurate,
    -- absolutely-timestamped timers (sync with WBT v1.8+). PWB only reads TWB; it never writes.
    if PWB_config.wbtSync then
      PWB.wbtChannelJoinDelay:Show()
    end

    -- Set an initial publish delay
    PWB.core.resetPublishDelay()
  end

  if event == 'CHAT_MSG_MONSTER_YELL' then
    local boss, faction = PWB.core.parseMonsterYell(arg1)
    -- PWB:Print("found NPC yell")
    if boss and faction then
      -- PWB:Print("found NPC yell for: " .. boss .. ", faction: " .. faction)
      local h, m = PWB.utils.hoursFromNow(4)
      -- Absolute expiry on the calibrated server-time scale (2h buff) for accurate self-tracking.
      local expiresAt = PWB.serverTime and (PWB.serverTime + PWB.core.BUFF_DURATION_SECONDS) or nil
      PWB.core.setTimer(faction, boss, h, m, PWB.me, PWB.me, expiresAt)

      if PWB_config.autoLogout or PWB_config.autoExit then
        local message = PWB_config.autoExit and
            T['About to receive buff and auto-exit is enabled. Will exit game in 1 minute.'] or
            T['About to receive buff and auto-logout is enabled. Will log out in 1 minute.']
        PWB:Print(message)
        PWB.logoutAt = time() + 60
      end
    end
  end

  if event == 'CHAT_MSG_CHANNEL' and arg2 ~= UnitName('player') then
    -- Resolve the channel name once (arg9 is the name when available; otherwise look it up from arg4).
    -- Used by both the WorldBuffsTracker bridge and the PWB channel check below, so we only parse it once.
    local channelName = arg9
    if not channelName and arg4 then
      local _, _, source = string.find(arg4, '(%d+)%.')
      if source then
        _, channelName = GetChannelName(tonumber(source))
      end
    end

    -- WorldBuffsTracker bridge: import accurate timers off the TWB channel. PWB only reads it.
    if channelName == 'TWB' then
      if PWB_config.wbtSync then
        PWB.core.importWbtMessage(arg1, arg2)
      end
      return
    end

    if PWB.utils.isPwbChannel(channelName) then
      local _, _, addonName, remoteVersion, msg = string.find(arg1, '(.*)%:(.*)%:(.*)')


      if addonName == PWB.abbrev then
        local v = PWB.utils.getVersionNumber()
        if remoteVersion == nil then remoteVersion = "nil" end

        -- Ignore timers from players with pre-1.1.4 versions that contain a bug where it sometimes
        -- shares invalid/expired timers with everyone.
        if tonumber(remoteVersion) < 10104 or tonumber(remoteVersion) >= 20000 then
          return
        end

        PWB.core.resetPublishDelay()

        timerStrs[1], timerStrs[2], timerStrs[3], timerStrs[4] = PWB.utils.strSplit(msg, ';')
        for _, timerStr in next, timerStrs do
          local faction, boss, h, m, witness, decodedExpiresAt = PWB.core.decode(timerStr)
          if not faction or not boss or not h or not m or not witness then return end

          -- convert timers from previous versions with slower server time to the double speed time
          if not decodedExpiresAt and tonumber(remoteVersion) < 10700 then
            -- avoid adding the offset when the witness already did (using fixed version)
            local offset = PWB.utils.isWitnessUsing4hTimer(witness) and 0 or 2
            h = math.mod(h + offset, 24)
          end

          -- Resolve an absolute real-server-clock expiry so the countdown is accurate regardless of
          -- the in-game clock rate (Turtle WoW reverted server time to 1x in 2026).
          --   * New-format peers send the absolute epoch directly (preferred, continent-independent).
          --   * Legacy peers send in-game HH:MM = drop + 4 in-game hours. On the current 1x server
          --     that is 4 real hours (2 real hours beyond the true 2h buff), so reconstruct and
          --     correct it to the real expiry.
          local expiresAt
          if decodedExpiresAt then
            local remaining = decodedExpiresAt - time()
            if remaining > 0 and remaining <= (PWB.core.BUFF_DURATION_SECONDS + 300) then
              expiresAt = decodedExpiresAt
            end
          elseif PWB.serverTime then
            local sh, sm = PWB.utils.getServerTime()
            local hh, mm = h, m
            -- midnight wrap: deadline crossed into the next day
            if sh > hh and hh < 4 then hh = hh + 24 end
            local realDeadline = PWB.serverTime + (PWB.utils.toMinutes(hh, mm) - PWB.utils.toMinutes(sh, sm)) * 60
            expiresAt = realDeadline - PWB.core.BUFF_DURATION_SECONDS
          end

          local receivedFrom = arg2
          if PWB.core.shouldAcceptNewTimer(faction, boss, h, m, witness, receivedFrom, expiresAt) then
            PWB.core.setTimer(faction, boss, h, m, witness, receivedFrom, expiresAt)
          end
        end

      elseif addonName == PWB.abbrevDmf then
        PWB.core.resetPublishDelay()
        local location, seenAt, witness = PWB.core.decodeDmf(msg)
        if PWB.core.shouldAcceptDmfLocation(seenAt, tonumber(remoteVersion)) then
          PWB.core.setDmfLocation(location, seenAt, witness)
        end
      end
    end
  end

  if event == 'CHAT_MSG_ADDON' and arg1 == 'TWB_MSG' and arg4 ~= UnitName('player') then
    -- WorldBuffsTracker bridge: import accurate timers from its guild/party/raid addon messages.
    if PWB_config.wbtSync then
      PWB.core.importWbtMessage(arg2, arg4)
    end
  end

  if event == 'CHAT_MSG_WHISPER' and string.find(UnitName('player'), 'Pizza') then
    local msg, from = string.lower(string.gsub(string.gsub(arg1, '?', ''), '!', '')), arg2
    if msg == 'ony when' or msg == 'nef when' or msg == 'buff when' or msg == 'buf when' or msg == 'head when' then
      local aOnyText = PWB.share.getText('timer', { faction = 'A', boss = 'O' })
      local aNefText = PWB.share.getText('timer', { faction = 'A', boss = 'N' })
      local hOnyText = PWB.share.getText('timer', { faction = 'H', boss = 'O' })
      local hNefText = PWB.share.getText('timer', { faction = 'H', boss = 'N' })
      local hRendText = PWB.share.getText('timer', { faction = 'H', boss = 'R' })
      local zanText = PWB.share.getText('timer', { faction = 'N', boss = 'Z' })
      SendChatMessage(aOnyText, 'WHISPER', nil, from)
      SendChatMessage(aNefText, 'WHISPER', nil, from)
      SendChatMessage(hOnyText, 'WHISPER', nil, from)
      SendChatMessage(hNefText, 'WHISPER', nil, from)
      SendChatMessage(hRendText, 'WHISPER', nil, from)
      SendChatMessage(zanText, 'WHISPER', nil, from)
    elseif msg == 'dmf where' or msg == 'dmf' or msg == 'dmf loc' or msg == 'dmf location' then
      local dmfText = PWB.share.getText('dmf')
      SendChatMessage(dmfText, 'WHISPER', nil, from)
    end
  end

  if event == 'UPDATE_MOUSEOVER_UNIT' and not UnitIsPlayer('mouseover') and PWB.utils.contains(dmfNpcNames, UnitName('mouseover')) then
    local zone = GetZoneText()
    if zone == T['Elwynn Forest'] or zone == T['Mulgore'] then
      PWB.core.setDmfLocation(string.sub(zone, 1, 1), time(), PWB.me)
    end
  end
end)

PWB:SetScript('OnUpdate', function()
  -- Throttle this function so it doesn't run on every frame render
  if (this.tick or 1) > GetTime() then return else this.tick = GetTime() + 2 end

  PWB.core.updateServerTime()
  PWB.core.clearExpiredTimers()

  -- Keep the TWB channel joined so WorldBuffsTracker timer imports keep flowing (mirrors WBT's
  -- 30-second rejoin cadence). PWB only reads TWB; it never broadcasts to it.
  if PWB_config.wbtSync and (not PWB.wbtRejoinAt or time() > PWB.wbtRejoinAt) then
    local inTwb = false
    local chanList = { GetChannelList() }
    for _, v in next, chanList do
      if v == 'TWB' then inTwb = true; break end
    end
    if not inTwb then JoinChannelByName('TWB') end
    PWB.wbtRejoinAt = time() + 30
  end

  if (PWB_config.autoLogout or PWB_config.autoExit) and PWB.logoutAt and time() >= PWB.logoutAt then
    PWB.logoutAt = nil
    if PWB_config.autoLogout then
      PWB:Print(T['Logging out...'])
      Logout()
    else
      PWB:Print(T['Exiting game...'])
      Quit()
    end
  elseif PWB.core.shouldPublish() then
    PWB.core.publishAll()
  end
end)
