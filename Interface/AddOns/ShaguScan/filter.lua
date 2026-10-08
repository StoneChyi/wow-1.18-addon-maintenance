if ShaguScan.disabled then return end

local filter = { }

filter.player = function(unit)
  return UnitIsPlayer(unit) and true or false
end

filter.npc = function(unit)
  return not UnitIsPlayer(unit) and true or false
end

filter.infight = function(unit)
  return UnitAffectingCombat(unit) and true or false
end

filter.dead = function(unit)
  return UnitIsDead(unit) and true or false
end

filter.alive = function(unit)
  return not UnitIsDead(unit) and true or false
end

filter.horde = function(unit)
  return UnitFactionGroup(unit) == "Horde" and true or false
end

filter.alliance = function(unit)
  return UnitFactionGroup(unit) == "Alliance" and true or false
end

filter.hardcore = function(unit)
  return string.find((UnitPVPName(unit) or ""), "Still Alive") and true or false
end

filter.pve = function(unit)
  return not UnitIsPVP(unit) and true or false
end

filter.pvp = function(unit)
  return UnitIsPVP(unit) and true or false
end

filter.icon = function(unit)
  return GetRaidTargetIndex(unit) and true or false
end

filter.normal = function(unit)
  local elite = UnitClassification(unit)
  return elite == "normal" and true or false
end

filter.elite = function(unit)
  local elite = UnitClassification(unit)
  return (elite == "elite" or elite == "rareelite") and true or false
end

filter.rare = function(unit)
  local elite = UnitClassification(unit)
  return (elite == "rare" or elite == "rareelite") and true or false
end

filter.rareelite = function(unit)
  local elite = UnitClassification(unit)
  return elite == "rareelite" and true or false
end

filter.worldboss = function(unit)
  local elite = UnitClassification(unit)
  return elite == "worldboss" and true or false
end

filter.hostile = function(unit)
  return UnitIsEnemy("player", unit) and true or false
end

filter.neutral = function(unit)
  return not UnitIsEnemy("player", unit) and not UnitIsFriend("player", unit) and true or false
end

filter.friendly = function(unit)
  return UnitIsFriend("player", unit) and true or false
end

filter.attack = function(unit)
  return UnitCanAttack("player", unit) and true or false
end

filter.noattack = function(unit)
  return not UnitCanAttack("player", unit) and true or false
end

filter.pet = function(unit)
  local player = UnitIsPlayer(unit) and true or false
  local controlled = UnitPlayerControlled(unit) and true or false
  local pet = not player and controlled and true or false
  return pet and true or false
end

filter.nopet = function(unit)
  local player = UnitIsPlayer(unit) and true or false
  local controlled = UnitPlayerControlled(unit) and true or false
  local pet = not player and controlled and true or false
  return not pet and true or false
end

filter.human = function(unit)
  local _, race = UnitRace(unit)
  return race == "Human" and true or false
end

filter.orc = function(unit)
  local _, race = UnitRace(unit)
  return race == "Orc" and true or false
end

filter.dwarf = function(unit)
  local _, race = UnitRace(unit)
  return race == "Dwarf" and true or false
end

filter.nightelf = function(unit)
  local _, race = UnitRace(unit)
  return race == "NightElf" and true or false
end

filter.undead = function(unit)
  local _, race = UnitRace(unit)
  return race == "Scourge" and true or false
end

filter.tauren = function(unit)
  local _, race = UnitRace(unit)
  return race == "Tauren" and true or false
end

filter.gnome = function(unit)
  local _, race = UnitRace(unit)
  return race == "Gnome" and true or false
end

filter.troll = function(unit)
  local _, race = UnitRace(unit)
  return race == "Troll" and true or false
end

filter.goblin = function(unit)
  local _, race = UnitRace(unit)
  return race == "Goblin" and true or false
end

filter.highelf = function(unit)
  local _, race = UnitRace(unit)
  return race == "BloodElf" and true or false
end

filter.warlock = function(unit)
  local _, class = UnitClass(unit)
  local player = UnitIsPlayer(unit)

  return player and class == "WARLOCK" and true or false
end

filter.warrior = function(unit)
  local _, class = UnitClass(unit)
  local player = UnitIsPlayer(unit)

  return player and class == "WARRIOR" and true or false
end

filter.hunter = function(unit)
  local _, class = UnitClass(unit)
  local player = UnitIsPlayer(unit)

  return player and class == "HUNTER" and true or false
end

filter.mage = function(unit)
  local _, class = UnitClass(unit)
  local player = UnitIsPlayer(unit)

  return player and class == "MAGE" and true or false
end

filter.priest = function(unit)
  local _, class = UnitClass(unit)
  local player = UnitIsPlayer(unit)

  return player and class == "PRIEST" and true or false
end

filter.druid = function(unit)
  local _, class = UnitClass(unit)
  local player = UnitIsPlayer(unit)

  return player and class == "DRUID" and true or false
end

filter.paladin = function(unit)
  local _, class = UnitClass(unit)
  local player = UnitIsPlayer(unit)

  return player and class == "PALADIN" and true or false
end

filter.shaman = function(unit)
  local _, class = UnitClass(unit)
  local player = UnitIsPlayer(unit)

  return player and class == "SHAMAN" and true or false
end

filter.rogue = function(unit)
  local _, class = UnitClass(unit)
  local player = UnitIsPlayer(unit)

  return player and class == "ROGUE" and true or false
end

filter.aggro = function(unit)
  return UnitExists(unit .. "target") and UnitIsUnit(unit .. "target", "player") and true or false
end

filter.noaggro = function(unit)
  return not UnitExists(unit .. "target") or not UnitIsUnit(unit .. "target", "player") and true or false
end

filter.pfquest = function(unit)
  return pfQuest and pfMap and UnitName(unit) and pfMap.tooltips[UnitName(unit)] and true or false
end

filter.range = function(unit)
  return CheckInteractDistance(unit, 4) and true or false
end

local level = nil
filter.level = function(unit, args)
  level = tonumber(args)
  return level and UnitLevel(unit) == level and true or false
end

local level = nil
filter.minlevel = function(unit, args)
  level = tonumber(args)
  return level and UnitLevel(unit) >= level and true or false
end

local level = nil
filter.maxlevel = function(unit, args)
  level = tonumber(args)
  return level and UnitLevel(unit) <= level and true or false
end

filter.name = function(unit, name)
  name = strlower(name or "")
  unit = strlower(UnitName(unit) or "")
  return string.find(unit, name) and true or false
end

filter.ot = function(unit)
  -- 1. 仅对敌对NPC生效（OT通常发生在怪物身上）
  if not (filter.npc(unit) and filter.hostile(unit)) then
    return false
  end

  -- 2. 获取单位的当前目标
  local targetUnit = unit .. "target" -- 目标单位的标识（如"targettarget"）
  if not UnitExists(targetUnit) then
    return false -- 无目标则不构成OT
  end

  -- 3. 目标必须是玩家（OT通常指怪物攻击玩家）
  if not UnitIsPlayer(targetUnit) then
    return false
  end

  -- 判断目标玩家是否为【坦克职业且最大血量>6500】
  local _, class = UnitClass(targetUnit)
  local maxHealth = UnitHealthMax(targetUnit) or 0 -- 防止获取失败为nil
  local isTankClass = (class == "WARRIOR" or class == "PALADIN" or class == "DRUID") and (maxHealth > 6500) -- 同时满足职业和血量条件

  -- OT条件：目标不是有效坦克（不满足坦克职业+血量条件）
  return not isTankClass and true or false
end
--烟锅巴1008，增加过滤器X码距离
-- 在现有过滤器后添加（例如在filter.range下方）
-- 支持自定义距离过滤，格式为 range:X（X为数字，单位码）
filter.range = function(unit, args)
  -- 解析用户指定的最大距离（默认保留28码兼容旧逻辑）
  local maxDistance = tonumber(args) or 28
  if maxDistance <= 0 then return false end

  -- 若安装了SuperWoW，使用精确距离计算（支持任意X码）
  if pcall(UnitXP, "nop", "nop") then
    local rawDistance = UnitXP("distanceBetween", "player", unit)
    return rawDistance and rawDistance <= maxDistance or false
  else
    -- 未安装SuperWoW时，使用游戏内置接口近似判断
    -- 注意：内置接口仅支持固定范围，>28码无法精确判断
    if maxDistance >= 28 then
      -- 28码内必显示，超出28码无法通过内置接口判断，此处返回true（避免误过滤）
      -- 但实际无法获取>28码的单位信息，需提示用户安装SuperWoW
      return true
    elseif maxDistance >= 11 then
      return CheckInteractDistance(unit, 2) -- 11码内
    elseif maxDistance >= 9.9 then
      return CheckInteractDistance(unit, 3) -- 9.9码内
    else
      return CheckInteractDistance(unit, 1) -- 5码内
    end
  end
end
ShaguScan.filter = filter
