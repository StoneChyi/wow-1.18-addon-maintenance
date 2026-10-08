local PWB = PizzaWorldBuffs
PWB.core = {}

setfenv(1, PWB:GetEnv())

local BUFF_CD_HOURS = 4                 -- buff window in in-game hours (wrap/cap in in-game units)
PWB.core.BUFF_DURATION_SECONDS = 7200  -- real seconds the world buff lasts (2h); matches WorldBuffsTracker's 7200s
local IN_GAME_RATE = 2                  -- in-game clock runs 2x real time on this server
local MAX_REMAINING_SECONDS = PWB.core.BUFF_DURATION_SECONDS + 5 * 60

-- Encode the provided timer as a string that can be shared with other addon users.
--
-- Encoded timer format (new):
--   FACTION-BOSS-HH-MM-WITNESS|EXPIRY
--
--   FACTION    'A' for Alliance or 'H' for Horde
--   BOSS       'O' for Onyxia or 'N' for Nefarian
--   TIME       The server time at which the head will go down again, in HH-MM format (legacy, kept for old clients)
--   WITNESS    Name of the player who originally witnessed the buff
--   EXPIRY     Absolute real-server-clock epoch (seconds) when the buff expires. This is what
--              makes the countdown accurate regardless of the in-game clock rate (Turtle WoW
--              reverted server time to 1x in 2026). Old clients ignore everything after '|'.
--
-- Example:
--   A-O-16-37-Pizzahawaii*|1768900000
function PWB.core.encode(faction, boss, h, m, witness, expiresAt)
  if not faction or not boss or not h or not m or not witness then return end
  local base = string.format('%s-%s-%.2d-%.2d-%s', faction, boss, h, m, witness .. PWB.nameSuffix4h)
  if expiresAt then
    return base .. '|' .. tostring(math.floor(expiresAt))
  end
  return base
end

-- Encode all of our timers as strings, separated by semicolon.
function PWB.core.encodeAll()
  local timersStr
  for _, timers in pairs(PWB_timers) do
    for _, timer in pairs(timers) do
      local faction, boss, h, m, witness = timer.faction, timer.boss, timer.h, timer.m, timer.witness
      timersStr = (timersStr and timersStr .. ';' or '') .. PWB.core.encode(faction, boss, h, m, witness, timer.expiresAt)
    end
  end
  return timersStr
end

-- Decode the provided timer string into a timer table.
-- Returns faction, boss, h, m, witness and (if present) the absolute expiry epoch.
function PWB.core.decode(timerStr)
  -- New format appends the absolute real expiry after a '|'. Old format has none.
  local base, expiryStr = string.match(timerStr, '^(.-)|(.+)$')
  if not base then base = timerStr end
  local _, _, faction, boss, hStr, mStr, witness = string.find(base, '(.*)%-(.*)%-(.*)%-(.*)%-(.*)')
  local expiresAt
  if expiryStr then
    expiresAt = tonumber(expiryStr)
  end
  return faction, boss, tonumber(hStr), tonumber(mStr), witness, expiresAt
end

-- LOCATION-SECONDSAGO-WITNESS
function PWB.core.encodeDmf()
  if not PWB_dmf or not PWB_dmf.location or not PWB_dmf.seenAt or not PWB_dmf.witness then
    return
  end

  local secondsAgo = math.floor(time() - PWB_dmf.seenAt)
  return string.format('%s-%d-%s', PWB_dmf.location, secondsAgo, PWB_dmf.witness)
end

function PWB.core.decodeDmf(dmfStr)
  local _, _, location, secondsAgoStr, witness = string.find(dmfStr, '(.*)%-(.*)%-(.*)')
  local seenAt = time() - tonumber(secondsAgoStr)
  return location, seenAt, witness
end

-- Advance the calibrated server time by the real seconds that have elapsed. Called every
-- frame; it accumulates elapsed time so lag/stutter never makes the countdown fall behind.
-- This mirrors the WorldBuffsTracker approach (real server clock + drift-free progression)
-- instead of sampling the in-game clock, which is affected by its 2x speed and continent offsets.
function PWB.core.updateServerTime()
  if not PWB.serverTime then return end

  local now = GetTime()
  if not PWB.serverTimeCounter then
    PWB.serverTimeCounter = now
    return
  end

  local elapsed = math.floor(now - PWB.serverTimeCounter)
  if elapsed >= 1 then
    PWB.serverTime = PWB.serverTime + elapsed
    -- Keep the timezone-independent serial in lockstep with the server clock so we can convert
    -- WorldBuffsTracker's Sync2 serial-based expiries into our own expiry epoch.
    if PWB.serverSerial then
      PWB.serverSerial = PWB.serverSerial + elapsed
    end
    PWB.serverTimeCounter = PWB.serverTimeCounter + elapsed
  end
end

-- Generate a time table representing the duration from now until the provided
-- timer will run out.
function PWB.core.getTimeLeft(timer)
  -- Self-witnessed timers carry an absolute expiry on the calibrated server-time scale.
  -- This is timezone-independent and immune to the in-game clock speed / continent offsets.
  if timer.expiresAt and PWB.serverTime then
    local remaining = timer.expiresAt - PWB.serverTime   -- real seconds
    if remaining < 0 or remaining > MAX_REMAINING_SECONDS then
      return nil
    end
    return PWB.utils.toTime(math.floor(remaining / 60))
  end

  -- Legacy path (received timers / before server time is calibrated): compute directly
  -- from the in-game clock. Kept for backward compatibility with shared timers.
  local sh, sm = PWB.utils.getServerTime()
  local h, m = timer.h, timer.m
  if sh > h and h < BUFF_CD_HOURS then
    h = h + 24
  end

  local diff = PWB.utils.toMinutes(h, m) - PWB.utils.toMinutes(sh, sm)
  if diff < 0 or diff > BUFF_CD_HOURS * 60 then
    return nil
  end

  return PWB.utils.toTime(math.floor(diff / IN_GAME_RATE))
end

-- Check if the provided timer is valid. A timer is only valid if all of the following
-- conditions apply:
--
--   1. The timer is less than 4 hours in the future.
--   2. The timer has not expired, i.e. it's not in the past.
--   3. We received/stored the timer no more than 4 hours ago.
function PWB.core.isValid(timer)
  local now = time()
  local fourHours = 4 * 60 * 60

  -- Mark timer as invalid if we accepted/stored it more than 4 hours ago. This prevents an
  -- issue that's due to the timers containing only the time, not the date. Without this, if
  -- you log off at e.g. 7 pm with 1 hour left on Ony buff and then log back in the next day
  -- at 7 pm, the addon will just resume the old timer because it doesn't know it's from
  -- the day before.
  if not timer.acceptedAt or timer.acceptedAt > now or timer.acceptedAt < now - fourHours then
    return false
  end

  return PWB.core.getTimeLeft(timer) ~= nil
end

-- These are the NPC yell triggers we use to detect that one of the buffs has dropped.
local yellTriggers = {
  A = {
    O = T['YELL_TRIGGER_ALLIANCE_ONYXIA'],
    N = T['YELL_TRIGGER_ALLIANCE_NEFARIAN'],
  },
  H = {
    O = T['YELL_TRIGGER_HORDE_ONYXIA'],
    N = T['YELL_TRIGGER_HORDE_NEFARIAN'],
    R = T['YELL_TRIGGER_HORDE_REND'],          -- 酋长的祝福（雷德之首）
  },
  N = {                                        -- faction 'N' = 中立
    Z = T['YELL_TRIGGER_NEUTRAL_ZANDALAR'],    -- 赞达拉之魂（哈卡之心）
  },
}

-- Given an NPC's yell message, check if it's one of the triggers for a buff being dropped.
-- If yes, return the boss and faction. Otherwise, return nil.
function PWB.core.parseMonsterYell(yellMsg)
  for faction, bossTriggers in pairs(yellTriggers) do
    for boss, yellTrigger in pairs(bossTriggers) do
										  
											   
      local found = string.find(yellMsg, yellTrigger)
      if found then
								
			 
		   
											   
													   
					 
        return boss, faction
		   
      end
    end
  end
end

function PWB.core.setDmfLocation(location, seenAt, witness)
  _G.PWB_dmf = {
    location = location,
    seenAt = seenAt,
    witness = witness,
  }
end

-- Get our current timer for the provided faction and boss.
function PWB.core.getTimer(faction, boss)
  return PWB_timers[faction][boss]
end

-- Store the provided timer locally.
-- expiresAt (optional) is the absolute expiry on the calibrated server-time scale; it is set
-- for self-witnessed timers so their countdown is accurate regardless of the in-game clock.
function PWB.core.setTimer(faction, boss, h, m, witness, receivedFrom, expiresAt)
  _G.PWB_timers[faction][boss] = {
    faction = faction,
    boss = boss,
    h = h,
    m = m,
    expiresAt = expiresAt or nil,
    witness = witness,
    receivedFrom = receivedFrom,
    acceptedAt = time(),
  }
  -- PWB:Print("setTimer to " .. h .. ":" .. m .. " from " .. receivedFrom .. " witness " .. witness)
end

-- Remove the provided timer from our local timer store.
function PWB.core.clearTimer(timer)
  -- PWB:Print("core.clearTimer()")
  _G.PWB_timers[timer.faction][timer.boss] = nil
end

-- Clear all invalid timers from our local timer store.
function PWB.core.clearExpiredTimers()
  -- PWB:Print("core.clearExpiredTimers()")
  -- Initialize timers if they somehow haven't been initialized yet
  if not PWB_timers then PWB.core.clearAllTimers() end

  PWB.utils.forEachTimer(function(timer)
    if not PWB.core.isValid(timer) then
      PWB.core.clearTimer(timer)
    end
  end)
end

-- Clear all local timers, even valid ones.
function PWB.core.clearAllTimers()
  -- PWB:Print("core.clearAllTimers()")
  _G.PWB_timers = {
    A = {},
    H = {},
    N = {}, -- 中立（赞达拉之魂）
  }
end

-- Make sure all faction tables exist. Older saved variables only contained 'A'/'H';
-- v1.7+ adds 'N' (neutral, used by the Spirit of Zandalar timer).
function PWB.core.ensureFactions()
  _G.PWB_timers = _G.PWB_timers or {}
  if not _G.PWB_timers.A then _G.PWB_timers.A = {} end
  if not _G.PWB_timers.H then _G.PWB_timers.H = {} end
  if not _G.PWB_timers.N then _G.PWB_timers.N = {} end
end

-- Check if the provided timer should be accepted and stored locally.
function PWB.core.shouldAcceptNewTimer(faction, boss, h, m, witness, receivedFrom, expiresAt)
  local currentTimer = PWB.core.getTimer(faction, boss)

  -- Never accept invalid or expired timers
  if not PWB.core.isValid({ h = h, m = m, acceptedAt = time(), expiresAt = expiresAt }) then return false end

  -- Always accept if we currently don't have a timer for this buff
  if not currentTimer then return true end

  -- Always accept if current timer is expired or invalid
  if not PWB.core.isValid(currentTimer) then return true end

  -- Always accept new timers that we witnessed ourselves
  if witness == PWB.me then return true end

  -- Never accept other peoples' timers if we currently have a timer that we witnessed ourselves
  if currentTimer.witness == PWB.me then return false end

  -- Otherwise, only accept if the new timer came from a direct witness and our current one didn't
  return receivedFrom == witness and currentTimer.receivedFrom ~= currentTimer.witness
end

-- Import a single timer coming from WorldBuffsTracker's network (the TWB channel or TWB_MSG
-- addon messages). WBT broadcasts the absolute expiry (SyncS) or a serial-based expiry (Sync2),
-- both on a server-time scale. We store the absolute expiry so PizzaWorldBuffs' countdown matches
-- WBT exactly.
--
-- Acceptance rules (mirrors WBT's source-priority and range validation):
--   * Reject anything outside (0, BUFF_DURATION_SECONDS] remaining — this is what prevents
--     "abnormal future times forming hundreds-of-minutes countdowns" from surviving a reload.
--   * Never override a timer we witnessed ourselves (equally accurate, and ours).
--   * Prefer a newer (later-expiring) WBT timer over a stale/legacy one so the display refreshes.
function PWB.core.importWbtTimer(faction, boss, expiresAt, source)
  if not expiresAt or expiresAt <= 0 then return end

  local now = PWB.serverTime or time()
  local remaining = expiresAt - now
  if remaining <= 0 or remaining > PWB.core.BUFF_DURATION_SECONDS + 5 then
    return
  end

  local current = PWB.core.getTimer(faction, boss)
  -- Never clobber our own self-witnessed timer.
  if current and current.witness == PWB.me then return end
  -- Keep the later-expiring (more current) timer; refresh stale/legacy entries.
  if current and current.expiresAt and current.expiresAt >= expiresAt then return end

  local t = date('*t', expiresAt)
  local witness = 'WBT:' .. source
  PWB.core.setTimer(faction, boss, t.hour, t.min, witness, witness, expiresAt)
end

-- Parse a raw WorldBuffsTracker sync message and import every valid timer in it.
-- Supported formats (both still broadcast by WBT v1.8+):
--   Sync2:<FACTION><serial.float><BOSS>...   -- serial-based, timezone-independent (preferred)
--   SyncS:<FACTION><epoch><BOSS>...          -- absolute expiry epoch (legacy, still sent)
function PWB.core.importWbtMessage(msg, sender)
  if not msg or msg == '' then return end

  PWB.core.ensureFactions()

  local sync2 = string.match(msg, '^Sync2:(.+)$')
  if sync2 and PWB.serverSerial then
    for item in string.gmatch(sync2, '[AHNT][%d%.]+[ONRZ]') do
      local f, serialText, d = string.match(item, '([AHNT])([%d%.]+)([ONRZ])')
      if f == 'T' then f = 'N' end -- WBT 用 'T' 表示中立；但部分版本发送 'N'（string.sub('Neutral',0,1)），两者都映射为 PWB 的中立 'N'
      local serial = tonumber(serialText)
      if serial then
        local remaining = serial - PWB.serverSerial
        if remaining > 0 and remaining <= PWB.core.BUFF_DURATION_SECONDS + 5 then
          local expiresAt = (PWB.serverTime or time()) + remaining
          PWB.core.importWbtTimer(f, d, expiresAt, sender)
        end
      end
    end
    return
  end

  local syncS = string.match(msg, '^SyncS:(.+)$')
  if syncS then
    for item in string.gmatch(syncS, '[AHNT]%d+[ONRZ]') do
      local f, epochStr, d = string.match(item, '([AHNT])(%d+)([ONRZ])')
      if f == 'T' then f = 'N' end -- WBT 用 'T' 表示中立；但部分版本发送 'N'，两者都映射为 PWB 的中立 'N'
      local expiresAt = tonumber(epochStr)
      PWB.core.importWbtTimer(f, d, expiresAt, sender)
    end
    return
  end
end

local sevenDays = 7 * 24 * 60 * 60
function PWB.core.shouldAcceptDmfLocation(seenAt, remoteVersion)
  -- Don't accept any DMF locations from pre-1.4.1 versions. Version 1.4.0 had a bug because it
  -- also detected DMF when mouseover target was Darkmoon Faire Carnie. These are there even on
  -- Wednesdays when DMF is paused.
  if remoteVersion and remoteVersion < 10401 then return false end

  -- Don't accept any DMF locations older than 7 days.
  if seenAt < (time() - sevenDays) then return false end

  -- Accept any reasonably up-to-date DMF location if we don't have any.
  if not PWB.utils.hasDmf() then return true end

  -- Always accept the most recent DMF location.
  return seenAt > PWB_dmf.seenAt
end

-- Reset the publish delay that we will count down from before we publish our local timers.
function PWB.core.resetPublishDelay()
  local min, max = 10, 60

  -- (Re)set our own publish delay to a random number of seconds.
  local delay = math.random(min, max)
  PWB.nextPublishAt = time() + delay
end

-- Check if we should publish our local data.
function PWB.core.shouldPublish()
  return PWB.nextPublishAt and time() > PWB.nextPublishAt
end

function PWB.core.publishAll()
  PWB.core.publishDmfLocation()
  PWB.core.publishTimers()

  PWB.core.resetPublishDelay()
end

-- Publish our local timers by sending them to the hidden PWB chat channel.
--
-- Message format:
--   PizzaWorldBuffs:VERSION:TIMER;TIMER;TIMER;...
--
--   VERSION    Our own version of the addon as a single number
--   TIMER      A single encoded timer; see PWB.core.encode() for details
--
-- Example:
--   PizzaWorldBuffs:1337:A-O-13-37-Pizzahawaii;H-N-14-44-Someotherdude
function PWB.core.publishTimers()
  -- Always clear all expired timers (again) right before publishing to make sure we never share
  -- outdated timers.
  PWB.core.clearExpiredTimers()

  if not PWB.utils.hasTimers() or UnitLevel('player') < 5 then
    return
  end

  local pwbChannel = GetChannelName(PWB.channelName)
  if pwbChannel ~= 0 then
    SendChatMessage(PWB.abbrev .. ':' .. PWB.utils.getVersionNumber() .. ':' .. PWB.core.encodeAll(), 'CHANNEL', nil,
      pwbChannel)
  end
end

function PWB.core.publishDmfLocation()
  if PWB_dmf == nil then
    return
  end
  
  if not PWB.utils.hasDmf() or UnitLevel('player') < 5 then
    return
  end

  local pwbChannel = GetChannelName(PWB.channelName)
  if pwbChannel ~= 0 then
    SendChatMessage(PWB.abbrevDmf .. ':' .. PWB.utils.getVersionNumber() .. ':' .. PWB.core.encodeDmf(), 'CHANNEL', nil,
      pwbChannel)
  end
end
