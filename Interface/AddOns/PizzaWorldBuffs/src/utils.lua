local PWB = PizzaWorldBuffs
PWB.utils = {}

setfenv(1, PWB:GetEnv())

-- Convert a time (duration) table to a number of minutes.
function PWB.utils.toMinutes(h, m)
  return h * 60 + m
end

-- Convert a number of minutes to a time table representing the same duration.
function PWB.utils.toTime(minutes)
  local m = math.mod(minutes, 60)
  local h = (minutes - m) / 60
  return h, m
end

function PWB.utils.isTipsie()
  local name = UnitName('player')
  local len = string.len(name)
  if len < 8 then return false end
  return string.sub(name, len - 5, len) == 'tipsie'
end

function PWB.utils.toRoughTimeString(seconds)
  if seconds < 60 then return seconds .. 's' end

  local minutes = seconds / 60
  if minutes < 60 then return math.floor(minutes) .. 'm' end

  local hours = minutes / 60
  if hours < 24 then return '~ ' .. math.floor(hours) .. 'h' end

  local days = hours / 24
  return '~ ' .. math.floor(days + 0.5) .. 'd'
end

-- Convert a time table to string in Hh Mm format, e.g. 1h 52m.
function PWB.utils.toString(h, m)
  if not h and not m then return T['N/A'] end
  return (h > 0 and h .. 'h ' or '') .. m .. 'm'
end

-- Get a time table representing a certain number of hours from now (server time).
function PWB.utils.hoursFromNow(hours)
  local h, m = PWB.utils.getServerTime()
  h = math.mod(h + hours, 24)
  return h, m
end

-- Get current server time, normalized by accounting for in-game timezones.
function PWB.utils.getServerTime()
  local h, m = GetGameTime()

  -- Continent timezone normalization
  if PWB.isOnKalimdor then
    h = math.mod(h + 12, 24)
  end

  return h, m
end

-- Get local PizzaWorldBuffs version as a semantic versioning string
function PWB.utils.getVersion()
  return tostring(GetAddOnMetadata(PWB:GetName(), 'Version'))
end

-- Get local PizzaWorldBuffs version as a single number
function PWB.utils.getVersionNumber()
  local major, minor, patch = PWB.utils.strSplit(PWB.utils.getVersion(), '.')
  major = tonumber(major) or 0
  minor = tonumber(minor) or 0
  patch = tonumber(patch) or 0

  return major * 10000 + minor * 100 + patch
end

-- Identity function
function PWB.utils.identity(x)
  return x
end

-- Check if condition applies to any of our timers.
function PWB.utils.someTimer(fn)
  if not PWB_timers then return false end

  for _, timers in pairs(PWB_timers) do
    for _, timer in pairs(timers) do
      if fn(timer) then return true end
    end
  end
  return false
end

-- Invoke fn for each timer we have stored currently.
function PWB.utils.forEachTimer(fn)
  if not PWB_timers then return end

  for _, timers in pairs(PWB_timers) do
    for _, timer in pairs(timers) do
      fn(timer)
    end
  end
end

function PWB.utils.hasDmf()
  return PWB_dmf and PWB_dmf.location and PWB_dmf.seenAt and PWB_dmf.witness
end

-- Check if we currently have any timers stored.
function PWB.utils.hasTimers()
  return PWB.utils.someTimer(PWB.utils.identity)
end

-- Check if we currently have a timer for a specific faction & boss stored.
function PWB.utils.hasTimer(faction, boss)
  if not PWB_timers then return false end
  return PWB_timers[faction][boss] and true or false
end

-- Check if we have any timers stored in a deprecated format (pre-v0.0.15)
function PWB.utils.hasDeprecatedTimerFormat()
  return PWB.utils.someTimer(function(timer)
    return timer.deadline ~= nil
  end)
end

-- Check if I'm the direct witness for any of my timers.
function PWB.utils.isWitness()
  return PWB.utils.someTimer(function(timer)
    return timer.witness == PWB.me
  end)
end

-- Split the provided string by the specified delimiter.
function PWB.utils.strSplit(str, delimiter)
  if not str then return nil end
  local delimiter, fields = delimiter or ':', {}
  local pattern = string.format('([^%s]+)', delimiter)
  string.gsub(str, pattern, function(c) fields[table.getn(fields) + 1] = c end)
  return unpack(fields)
end

function PWB.utils.getId(t)
  return string.gsub(tostring(t), 'table: ', '', 1)
end

-- Get the color that should be used for a timer, based on how confident we are in it.
function PWB.utils.getTimerColor(witness, receivedFrom)
  if witness == PWB.me then return PWB.Colors.green end
  if receivedFrom == witness then return PWB.Colors.orange end
  return PWB.Colors.red
end

function PWB.utils.getTimerConfidence(witness, receivedFrom)
  if witness == PWB.me then return 1 end
  if receivedFrom == witness then return 2 end
  return 3
end

function PWB.utils.contains(table, value)
  for _, val in pairs(table) do
    if val == value then return true end
  end
  return false
end

function PWB.utils.getChannelId(channelName)
  local channels = {}
  local chanList = { GetChannelList() }

  for i = 1, length(chanList), 2 do
    if string.lower(chanList[i + 1]) == channelName then
      return chanList[i]
    end
  end
end

function PWB.utils.isPwbChannel(channelName)
  if type(channelName) ~= 'string' then return false end
  if type(PWB.channelName) ~= 'string' then return false end
  return string.lower(channelName) == string.lower(PWB.channelName)
end

function PWB.utils.getCurrentMapZoneName()
  local cid = GetCurrentMapContinent()
  local mid = GetCurrentMapZone()
  local list = { GetMapZones(cid) }
  return list[mid]
end

function PWB.utils.isWitnessUsing4hTimer(witness)
  if (witness == nil or witness == '') then
    return false
  end
  return string.sub(witness, -1) == PWB.nameSuffix4h
end

-- 获取暗月马戏团当前和下次位置及剩余时间（基于固定时间计算）
function PWB.utils.getDarkmoonFaireInfo()
  local currentTime = time()                          -- 服务器时间戳（UTC）
  local baseTime = 1763251200                         -- 2025-11-16 00:00 UTC（北京时间08:00）
  local cycle = 7 * 24 * 3600                          -- 7天周期

  local timeSinceBase = currentTime - baseTime
  local cyclesSinceBase = math.floor(timeSinceBase / cycle)
  local locationIndex = math.mod(cyclesSinceBase, 2)   -- 0: 艾尔文森林, 1: 雷霆崖

  local currentLoc = locationIndex == 0 and "E" or "M"
  local nextReset = baseTime + (cyclesSinceBase + 1) * cycle
  local timeLeft = nextReset - currentTime              -- 剩余秒数
  local nextLoc = (math.mod(cyclesSinceBase + 1, 2) == 0) and "E" or "M"

  return currentLoc, nextLoc, timeLeft
end

-- 把服务器返回的年月日时分秒转换为与本机时区无关的连续秒数（与 WorldBuffsTracker 的
-- WBT_ServerDateToSerial 完全一致）。新协议只在同一服务器内用这个数值比较先后，不把它
-- 当作本地 Unix 时间，因此跨时区玩家也能正确换算“传输耗时”，不受本机时区影响。
function PWB.utils.serverDateToSerial(year, month, day, hour, minute, second)
  if not year or not month or not day or not hour or not minute or not second then
    return nil
  end
  if year < 2000 or month < 1 or month > 12 or hour < 0 or hour > 23 or minute < 0 or minute > 59 or second < 0 or second > 59 then
    return nil
  end

  local month_days = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
  local function isLeap(y)
    return math.mod(y, 400) == 0 or (math.mod(y, 4) == 0 and math.mod(y, 100) ~= 0)
  end
  if isLeap(year) then
    month_days[2] = 29
  end
  if day < 1 or day > month_days[month] then
    return nil
  end

  local days = 0
  local y
  for y = 2000, year - 1 do
    days = days + (isLeap(y) and 366 or 365)
  end
  local m
  for m = 1, month - 1 do
    days = days + month_days[m]
  end
  days = days + day - 1
  return (((days * 24) + hour) * 60 + minute) * 60 + second
end