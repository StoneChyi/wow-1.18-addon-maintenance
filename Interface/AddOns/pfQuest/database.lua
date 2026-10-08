-- multi api compat
local compat = pfQuestCompat

pfDatabase = { icons = {} }

local loc = GetLocale()
local dbs = { "items", "quests", "quests-itemreq", "objects", "units", "zones", "professions", "areatrigger", "refloot", "objtext" }
-- objtext 的键要和客户端吐出来的字对齐，所以和 items/quests 一样跟着客户端语言走
local noloc = { items = true, quests = true, objects = true, units = true, objtext = true }

pfDB.locales = {
  ["enUS"] = "English",
  ["koKR"] = "Korean",
  ["frFR"] = "French",
  ["deDE"] = "German",
  ["zhCN"] = "Chinese (Simplified)",
  ["zhTW"] = "Chinese (Traditional)",
  ["esES"] = "Spanish",
  ["ruRU"] = "Russian",
  ["ptBR"] = "Portuguese",
}

-- Patch databases to further expansions
local function patchtable(base, diff)
  for k, v in pairs(diff) do
    if type(v) == "string" and v == "_" then
      base[k] = nil
    else
      base[k] = v
    end
  end
end

-- Return the best cluster point for a coordiante table
local best, neighbors = { index = 1, neighbors = 0 }, 0
local cache, cacheindex = {}
local ymin, ymax, xmin, ymax
local function getcluster(tbl, name)
  local count = 0
  best.index, best.neighbors = 1, 0
  cacheindex = string.format("%s:%s", name, table.getn(tbl))

  -- calculate new cluster if nothing is cached
  if not cache[cacheindex] then
    for index, data in pairs(tbl) do
      -- precalculate the limits, and compare directly.
      -- This way is much faster than the math.abs function.
      xmin, xmax = data[1] - 5, data[1] + 5
      ymin, ymax = data[2] - 5, data[2] + 5
      neighbors = 0
      count = count + 1

      for _, compare in pairs(tbl) do
        if compare[1] > xmin and compare[1] < xmax and compare[2] > ymin and compare[2] < ymax then
          neighbors = neighbors + 1
        end
      end

      if neighbors > best.neighbors then
        best.neighbors = neighbors
        best.index = index
      end
    end

    cache[cacheindex] = { tbl[best.index][1] + .001, tbl[best.index][2] + .001, count }
  end

  return cache[cacheindex][1], cache[cacheindex][2], cache[cacheindex][3]
end

-- Detects if a non indexed table is empty
local function isempty(tbl)
  for _ in pairs(tbl) do return end
  return true
end

-- Returns the levenshtein distance between two strings
-- based on: https://gist.github.com/Badgerati/3261142
local len1, len2, cost, best
local levcache = {}
local function lev(str1, str2, limit)
  if levcache[str1..":"..str2] then
    return levcache[str1..":"..str2]
  end

  len1, len2, cost = string.len(str1), string.len(str2), 0

  -- abort early on empty strings
  if len1 == 0 then
    return len2
  elseif len2 == 0 then
    return len1
  elseif str1 == str2 then
    return 0
  end

  -- initialise the base matrix
  local matrix = {}
  for i = 0, len1, 1 do
    matrix[i] = { [0] = i }
  end

  for j = 0, len2, 1 do
    matrix[0][j] = j
  end

  -- levenshtein algorithm
  for i = 1, len1, 1 do
    best = limit

    for j = 1, len2, 1 do
      cost = string.byte(str1,i) == string.byte(str2,j) and 0 or 1
      matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)

      if limit and matrix[i][j] < limit then
        best = matrix[i][j]
      end
    end

    if limit and best >= limit then
      levcache[str1..":"..str2] = limit
      return limit
    end
  end

  -- return the levenshtein distance
  levcache[str1..":"..str2] = matrix[len1][len2]
  return matrix[len1][len2]
end

local loc_core, loc_update
for _, exp in pairs({ "-tbc", "-wotlk" }) do
  for _, db in pairs(dbs) do
    if pfDB[db]["data"..exp] then
      patchtable(pfDB[db]["data"], pfDB[db]["data"..exp])
    end

    for loc, _ in pairs(pfDB.locales) do
      if pfDB[db][loc] and pfDB[db][loc..exp] then
        loc_update = pfDB[db][loc..exp] or pfDB[db]["enUS"..exp]
        patchtable(pfDB[db][loc], loc_update)
      end
    end
  end

  loc_core = pfDB["professions"][loc] or pfDB["professions"]["enUS"]
  loc_update = pfDB["professions"][loc..exp] or pfDB["professions"]["enUS"..exp]
  if loc_update then patchtable(loc_core, loc_update) end

  if pfDB["minimap"..exp] then patchtable(pfDB["minimap"], pfDB["minimap"..exp]) end
  if pfDB["meta"..exp] then patchtable(pfDB["meta"], pfDB["meta"..exp]) end
end

-- detect installed locales
for key, name in pairs(pfDB.locales) do
  if not pfDB["quests"][key] then pfDB.locales[key] = nil end
end

-- detect localized databases
pfDatabase.dbstring = ""
for id, db in pairs(dbs) do
  -- assign existing locale
  pfDB[db]["loc"] = pfDB[db][loc] or pfDB[db]["enUS"] or {}
  pfDatabase.dbstring = pfDatabase.dbstring .. " |cffcccccc[|cffffffff" .. db .. "|cffcccccc:|cff33ffcc" .. ( pfDB[db][loc] and loc or "enUS" ) .. "|cffcccccc]"
end

-- track all previous meta selections on login
pfDatabase.tracking = CreateFrame("Frame", "pfDatabaseMetaTracking", UIParent)
pfDatabase.tracking:RegisterEvent("PLAYER_ENTERING_WORLD")
pfDatabase.tracking:SetScript("OnEvent", function()
  -- break on empty config
  if not pfQuest_track then return end

  -- enable all tracked
  for name, data in pairs(pfQuest_track) do
    pfDatabase:SearchMetaRelation(data[1], data[2])
  end

  -- remove events
  this:UnregisterAllEvents()
end)

-- track questitems to maintain object requirements
pfDatabase.itemlist = CreateFrame("Frame", "pfDatabaseQuestItemTracker", UIParent)
pfDatabase.itemlist.update = 0
pfDatabase.itemlist.db = {}
pfDatabase.itemlist.db_tmp = {}
pfDatabase.itemlist.registry = {}
pfDatabase.TrackQuestItemDependency = function(self, item, qid)
  self.itemlist.registry[item] = qid
  self.itemlist.update = GetTime() + .5
  self.itemlist:Show()
end

pfDatabase.itemlist:RegisterEvent("BAG_UPDATE")
pfDatabase.itemlist:SetScript("OnEvent", function()
  this.update = GetTime() + .5
  this:Show()
end)

pfDatabase.itemlist:SetScript("OnUpdate", function()
  if GetTime() < this.update then return end

  -- remove obsolete registry entries
  for item, qid in pairs(this.registry) do
    if not pfQuest.questlog[qid] then
      this.registry[item] = nil
    end
  end

  -- save and clean previous items
  local previous = this.db
  this.db = {}

  -- fill new item db with bag items
  for bag = 4, 0, -1 do
    for slot = 1, GetContainerNumSlots(bag) do
      local link = GetContainerItemLink(bag,slot)
      local _, _, parse = strfind((link or ""), "(%d+):")
      if parse then
        -- Some custom quest items crash the 1.12 client when queried before their template is cached.
        if not (pfQuest and pfQuest.TurtleUnsafeItem and pfQuest:TurtleUnsafeItem(parse)) then
          local item = GetItemInfo(parse)
          if item then this.db[item] = true end
        end
      end
    end
  end

  -- fill new item db with equipped items
  for i=1,19 do
    if GetInventoryItemLink("player", i) then
      local _, _, link = string.find(GetInventoryItemLink("player", i), "(item:%d+:%d+:%d+:%d+)");
      local item = GetItemInfo(link)
      if item then this.db[item] = true end
    end
  end

  -- find new items
  for item in pairs(this.db) do
    if not previous[item] and this.registry[item] then
      pfQuest.questlog[this.registry[item]] = nil
      pfQuest:UpdateQuestlog()
    end
  end

  -- find removed items
  for item in pairs(previous) do
    if not this.db[item] and this.registry[item] then
      pfQuest.questlog[this.registry[item]] = nil
      pfQuest:UpdateQuestlog()
    end
  end

  this:Hide()
end)

-- check for unlocalized servers and fallback to enUS databases when the server
-- returns item names that are different to the database ones. (check via. Hearthstone)
CreateFrame("Frame", "pfQuestLocaleCheck", UIParent):SetScript("OnUpdate", function()
  -- throttle to to one item per second
  if ( this.tick or 0) > GetTime() then return else this.tick = GetTime() + .1 end

  if not this.dryrun then
    -- give the server one iteration to return the itemname.
    -- this is required for clients that use a clean wdb folder.
    ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
    ItemRefTooltip:SetHyperlink("item:6948:0:0:0")
    ItemRefTooltip:Hide()
    this.dryrun = true
    return
  end

  -- try to load hearthstone into tooltip
  ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
  ItemRefTooltip:SetHyperlink("item:6948:0:0:0")

  -- check tooltip for results
  if ItemRefTooltip:IsShown() and ItemRefTooltipTextLeft1 and ItemRefTooltipTextLeft1:IsVisible() then
    -- once the tooltip shows up, read the name and hide it
    local name = ItemRefTooltipTextLeft1:GetText()
    ItemRefTooltip:Hide()

    -- check for noloc
    if name and name ~= "" and pfDB["items"][loc] and pfDB["items"][loc][6948] then
      if not strfind(name, pfDB["items"][loc][6948], 1) then
        pfDatabase.dbstring = ""
        for id, db in pairs(dbs) do
          -- assign existing locale and update dbstring
          pfDB[db]["loc"] = noloc[db] and pfDB[db]["enUS"] or pfDB[db][loc] or {}
          pfDatabase.dbstring = pfDatabase.dbstring .. " |cffcccccc[|cffffffff" .. db .. "|cffcccccc:|cff33ffcc" .. ( noloc[db] and "enUS" or loc ) .. "|cffcccccc]"
        end
      end

      pfDatabase.localized = true
      this:Hide()
    end
  end

  -- set a detection timeout to 15 seconds
  if GetTime() > 15 then
    pfDatabase.localized = true
    this:Hide()
  end
end)

-- sanity check the databases
if isempty(pfDB["quests"]["loc"]) then
  CreateFrame("Frame"):SetScript("OnUpdate", function()
    if GetTime() < 3 then return end
    DEFAULT_CHAT_FRAME:AddMessage("|cffff5555 !! |cffffaaaaWrong version of |cff33ffccpf|cffffffffQuest|cffffaaaa detected.|cffff5555 !!")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffccccThe language pack does not match the gameclient's language.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffccccYou'd either need to pick the complete or the " .. GetLocale().."-version.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffccccFor more details, see: https://shagu.org/pfQuest")
    this:Hide()
  end)
end

-- add database shortcuts
local items, units, objects, quests, zones, refloot, itemreq, areatrigger, professions
pfDatabase.Reload = function()
  items = pfDB["items"]["data"]
  units = pfDB["units"]["data"]
  objects = pfDB["objects"]["data"]
  quests = pfDB["quests"]["data"]
  zones = pfDB["zones"]["data"]
  refloot = pfDB["refloot"]["data"]
  itemreq = pfDB["quests-itemreq"]["data"]
  areatrigger = pfDB["areatrigger"]["data"]
  professions = pfDB["professions"]["loc"]
end

pfDatabase.Reload()

local bitraces = {
  [1] = "Human",
  [2] = "Orc",
  [4] = "Dwarf",
  [8] = "NightElf",
  [16] = "Scourge",
  [32] = "Tauren",
  [64] = "Gnome",
  [128] = "Troll"
}

-- append with playable races by expansion
if pfQuestCompat.client > 11200 then
  bitraces[512] = "BloodElf"
  bitraces[1024] = "Draenei"
end

-- make it public for extensions
pfDB.bitraces = bitraces

local bitclasses = {
  [1] = "WARRIOR",
  [2] = "PALADIN",
  [4] = "HUNTER",
  [8] = "ROGUE",
  [16] = "PRIEST",
  [32] = "DEATHKNIGHT",
  [64] = "SHAMAN",
  [128] = "MAGE",
  [256] = "WARLOCK",
  [1024] = "DRUID"
}

-- make it public for extensions
pfDB.bitclasses = bitclasses

function pfDatabase:IsFriendly(id)
  if id and units[id] and units[id].fac then
    local faction = string.lower(UnitFactionGroup("player") or "")
    faction = faction == "horde" and "H" or faction == "alliance" and "A" or "UNKNOWN"

    if string.find(units[id].fac, faction) then
      return true
    end
  end

  return false
end

-- ParseObjectiveCounter
-- 拆出目标行尾部的「当前/需求」计数。中文客户端的冒号是全角，先归一成半角。
-- 返回整段前缀（做显示标签）、当前数、需求数。
function pfDatabase:ParseObjectiveCounter(text)
  local _, _, prefix, num, needed =
    strfind(string.gsub(text, "\239\188\154", ":"), "(.*):%s*(%d+)%s*/%s*(%d+)")
  return prefix, num, needed
end

-- ObjtextTargets
-- objtext 的一个槽位可以写一个 id，也可以写成一列，统一成表返回，没有则返回 nil。
function pfDatabase:ObjtextTargets(override, slot)
  local targets = override and override[slot]
  if tonumber(targets) then return { tonumber(targets) } end
  return targets
end

-- ParseTalkObjective
-- 对话类目标的日志文本由服务端自定义，客户端没有对应的格式串，只能按已知措辞识别。
-- 只认「听」「询问」紧跟名字（后面任意内容）和「与」名字「交谈」三种，用 plain 查找拼
-- 字面量，这样名字里的 · < - 不会被当成模式。「倾听」已被「听」覆盖，不必单列。
-- 返回整段前缀（做显示标签）、当前数、需求数。
function pfDatabase:ParseTalkObjective(text, name)
  local prefix, num, needed = pfDatabase:ParseObjectiveCounter(text)
  if not prefix or not name then return end

  if strfind(prefix, "听" .. name, 1, true)
  or strfind(prefix, "询问" .. name, 1, true)
  or strfind(prefix, "与" .. name .. "交谈", 1, true) then
    return prefix, num, needed
  end
end

function pfDatabase:BuildQuestDescription(meta)
  if not meta.title or not meta.quest or not meta.QTYPE then return meta.description end

  -- 召唤类目标的箭头说召唤源那句话：目标怪还没被召唤出来，说"击杀它"玩家没法照做
  local summonhint = pfDatabase:SummonHint(meta)
  if summonhint then return summonhint end

  if meta.QTYPE == "NPC_START" then
    return string.format(pfQuest_Loc["Speak with |cff33ffcc%s|r to obtain |cffffcc00[!]|cff33ffcc %s|r"], (meta.spawn or UNKNOWN), (meta.quest or UNKNOWN))
  elseif meta.QTYPE == "OBJECT_START" then
    return string.format(pfQuest_Loc["Interact with |cff33ffcc%s|r to obtain |cffffcc00[!]|cff33ffcc %s|r"], (meta.spawn or UNKNOWN), (meta.quest or UNKNOWN))
  elseif meta.QTYPE == "NPC_END" then
    return string.format(pfQuest_Loc["Speak with |cff33ffcc%s|r to complete |cffffcc00[?]|cff33ffcc %s|r"], (meta.spawn or UNKNOWN), (meta.quest or UNKNOWN))
  elseif meta.QTYPE == "OBJECT_END" then
    return string.format(pfQuest_Loc["Interact with |cff33ffcc%s|r to complete |cffffcc00[?]|cff33ffcc %s|r"], (meta.spawn or UNKNOWN), (meta.quest or UNKNOWN))
  elseif meta.QTYPE == "UNIT_OBJECTIVE" then
    -- 不再按阵营友好度猜是杀还是谈，对话目标一律靠 obj.T 显式标出
    return string.format(pfQuest_Loc["Kill |cff33ffcc%s|r"], (meta.spawn or UNKNOWN))
  elseif meta.QTYPE == "TALK_OBJECTIVE" then
    return string.format(pfQuest_Loc["Talk to |cff33ffcc%s|r"], (meta.spawn or UNKNOWN))
  elseif meta.QTYPE == "UNIT_OBJECTIVE_ITEMREQ" then
    return string.format(pfQuest_Loc["On |cff33ffcc%s|r use |cff33ffcc%s|r"], (meta.spawn or UNKNOWN), (meta.itemreq or UNKNOWN))
  elseif meta.QTYPE == "OBJECT_OBJECTIVE" then
    return string.format(pfQuest_Loc["Interact with |cff33ffcc%s|r"], (meta.spawn or UNKNOWN))
  elseif meta.QTYPE == "OBJECT_OBJECTIVE_ITEMREQ" then
    return string.format(pfQuest_Loc["On |cff33ffcc%s|r use |cff33ffcc%s|r"], (meta.spawn or UNKNOWN), (meta.itemreq or UNKNOWN))
  elseif meta.QTYPE == "ITEM_OBJECTIVE_LOOT" then
    return string.format(pfQuest_Loc["Loot |cff33ffcc[%s]|r from |cff33ffcc%s|r"], (meta.item or UNKNOWN), (meta.spawn or UNKNOWN))
  elseif meta.QTYPE == "ITEM_OBJECTIVE_USE" then
    return string.format(pfQuest_Loc["Loot and/or Use |cff33ffcc[%s]|r from |cff33ffcc%s|r"], (meta.item or UNKNOWN), (meta.spawn or UNKNOWN))
  elseif meta.QTYPE == "AREATRIGGER_OBJECTIVE" then
    return string.format(pfQuest_Loc["Explore |cff33ffcc%s|r"], (meta.spawn or UNKNOWN))
  elseif meta.QTYPE == "ZONE_OBJECTIVE" then
    return string.format(pfQuest_Loc["Use Quest Item at |cff33ffcc%s|r"], (meta.spawn or UNKNOWN))
  end
end

-- ShowExtendedTooltip
-- Draws quest informations into a tooltip
function pfDatabase:ShowExtendedTooltip(id, tooltip, parent, anchor, offx, offy)
  local tooltip = tooltip or GameTooltip
  local parent = parent or this
  local anchor = anchor or "ANCHOR_LEFT"

  tooltip:SetOwner(parent, anchor, offx, offy)

  local locales = pfDB["quests"]["loc"][id]
  local data = pfDB["quests"]["data"][id]

  if locales then
    tooltip:SetText((locales["T"] or UNKNOWN), .3, 1, .8)
    tooltip:AddLine(" ")
  else
    tooltip:SetText(UNKNOWN, .3, 1, .8)
  end

  if data then
    -- scan for active quests
    local queststate = pfQuest_history[id] and 2 or 0
    queststate = pfQuest.questlog[id] and 1 or queststate

    if queststate == 0 then
      tooltip:AddLine(pfQuest_Loc["You don't have this quest."] .. "\n\n", 1, .5, .5)
    elseif queststate == 1 then
      tooltip:AddLine(pfQuest_Loc["You are on this quest."] .. "\n\n", 1, 1, .5)
    elseif queststate == 2 then
      tooltip:AddLine(pfQuest_Loc["You already did this quest."] .. "\n\n", .5, 1, .5)
    end

    -- quest start
    if data["start"] then
      for key, db in pairs({["U"]="units", ["O"]="objects", ["I"]="items"}) do
        if data["start"][key] then
          local entries = ""
          for _, id in pairs(data["start"][key]) do
            entries = entries .. (entries == "" and "" or ", ") .. ( pfDB[db]["loc"][id] or UNKNOWN )
          end

          tooltip:AddDoubleLine(pfQuest_Loc["Quest Start"]..":", entries, 1,1,1, 1,1,.8)
        end
      end
    end

    -- quest end
    if data["end"] then
      for key, db in pairs({["U"]="units", ["O"]="objects"}) do
        if data["end"][key] then
          local entries = ""
          for _, id in ipairs(data["end"][key]) do
            entries = entries .. (entries == "" and "" or ", ") .. ( pfDB[db]["loc"][id] or UNKNOWN )
          end

          tooltip:AddDoubleLine(pfQuest_Loc["Quest End"]..":", entries, 1,1,1, 1,1,.8)
        end
      end
    end
  end

  if locales then
    -- obectives
    if locales["O"] and locales["O"] ~= "" then
      tooltip:AddLine(" ")
      tooltip:AddLine(pfDatabase:FormatQuestText(locales["O"]),1,1,1,true)
    end

    -- details
    if locales["D"] and locales["D"] ~= "" then
      tooltip:AddLine(" ")
      tooltip:AddLine(pfDatabase:FormatQuestText(locales["D"]),.6,.6,.6,true)
    end
  end

  -- add levels
  if data then
    if data["lvl"] or data["min"] then
      tooltip:AddLine(" ")
    end
    if data["lvl"] then
      local questlevel = tonumber(data["lvl"])
      local color = pfQuestCompat.GetDifficultyColor(questlevel)
      tooltip:AddLine("|cffffffff" .. pfQuest_Loc["Quest Level"] .. ": |r" .. questlevel, color.r, color.g, color.b)
    end
    if data["min"] then
      local questlevel = tonumber(data["min"])
      local color = pfQuestCompat.GetDifficultyColor(questlevel)
      tooltip:AddLine("|cffffffff" .. pfQuest_Loc["Required Level"] .. ": |r" .. questlevel, color.r, color.g, color.b)
    end
  end

  tooltip:Show()
end

-- GetPlayerSkill
-- Returns false if the player doesn't have the required skill, or their rank if they do
function pfDatabase:GetPlayerSkill(skill)
  if not professions[skill] then return false end

  for i=0,GetNumSkillLines() do
    local skillName, _, _, skillRank = GetSkillLineInfo(i)
    if skillName == professions[skill] then
      return skillRank
    end
  end

  return false
end

-- GetBitByRace
-- Returns bit of the current race
function pfDatabase:GetBitByRace(model)
  -- scan for regular bitmasks
  for bit, v in pairs(bitraces) do
    if model == v then return bit end
  end

  -- return alliance/horde racemask as fallback for unknown races
  return UnitFactionGroup("player") == "Alliance" and 77 or 178
end

-- GetBitByClass
-- Returns bit of the current class
function pfDatabase:GetBitByClass(class)
  for bit, v in pairs(bitclasses) do
    if class == v then return bit end
  end
end

-- GetHexDifficultyColor
-- Returns a string with the difficulty color of the given level
function pfDatabase:GetHexDifficultyColor(level, force)
  if force and UnitLevel("player") < level then
    return "|cffff5555"
  else
    local c = pfQuestCompat.GetDifficultyColor(level)
    return string.format("|cff%02x%02x%02x", c.r*255, c.g*255, c.b*255)
  end
end

-- GetRaceMaskByID
function pfDatabase:GetRaceMaskByID(id, db)
  -- 64 + 8 + 4 + 1 = 77 = Alliance
  -- 128 + 32 + 16 + 2 = 178 = Horde
  local factionMap = {["A"]=77, ["H"]=178, ["AH"]=255, ["HA"]=255}
  local raceMask = 0

  if db == "quests" then
    raceMask = quests[id]["race"] or raceMask

    if (quests[id]["start"]) then
      local questStartRaceMask = 0

      -- get quest starter faction
      if (quests[id]["start"]["U"]) then
        for _, startUnitId in ipairs(quests[id]["start"]["U"]) do
          if units[startUnitId] and units[startUnitId]["fac"] and factionMap[units[startUnitId]["fac"]] then
            questStartRaceMask = bit.bor(factionMap[units[startUnitId]["fac"]])
          end
        end
      end

      -- get quest object starter faction
      if (quests[id]["start"]["O"]) then
        for _, startObjectId in ipairs(quests[id]["start"]["O"]) do
          if objects[startObjectId] and objects[startObjectId]["fac"] and factionMap[objects[startObjectId]["fac"]] then
            questStartRaceMask = bit.bor(factionMap[objects[startObjectId]["fac"]])
          end
        end
      end

      -- apply starter faction as racemask
      if raceMask == 0 and questStartRaceMask > 0 and questStartRaceMask ~= raceMask then
        raceMask = questStartRaceMask
      end
    end
  elseif pfDB[db] and pfDB[db]["data"] and pfDB[db]["data"]["fac"] then
    raceMask = factionMap[pfDB[db]["data"]["fac"]]
  end

  return raceMask
end

-- GetIDByName
-- Scans localization tables for matching IDs
-- Returns table with all IDs
function pfDatabase:GetIDByName(name, db, partial, server)
  if not pfDB[db] then return nil end
  local ret = {}

  for id, loc in pairs(pfDB[db]["loc"]) do
    if db == "quests" then loc = loc["T"] end

    local custom = server and pfQuest_server[db] and pfQuest_server[db][id] or not server
    if loc and name then
      if partial == true and strfind(strlower(loc), strlower(name), 1, true) and custom then
        ret[id] = loc
      elseif partial == "LOWER" and strlower(loc) == strlower(name) and custom then
        ret[id] = loc
      elseif loc == name and custom then
        ret[id] = loc
      end
    end
  end
  return ret
end

-- GetIDByIDPart
-- Scans localization tables for matching IDs
-- Returns table with all IDs
function pfDatabase:GetIDByIDPart(idPart, db)
  if not pfDB[db] then return nil end
  local ret = {}

  for id, loc in pairs(pfDB[db]["loc"]) do
    if db == "quests" then loc = loc["T"] end

    if idPart and loc and strfind(tostring(id), idPart) then
      ret[id] = loc
    end
  end
  return ret
end

-- GetBestMap
-- Scans a map table for all spawns
-- Returns the map with most spawns
function pfDatabase:GetBestMap(maps)
  local bestmap, bestscore = nil, 0

  -- calculate best map results
  for map, count in pairs(maps or {}) do
    if count > bestscore or ( count == 0 and bestscore == 0 ) then
      bestscore = count
      bestmap   = map
    end
  end

  return bestmap or nil, bestscore or nil
end

-- SearchAreaTriggerID
-- Scans for all mobs with a specified ID
-- Adds map nodes for each and returns its map table
function pfDatabase:SearchAreaTriggerID(id, meta, maps, prio)
  if not areatrigger[id] or not areatrigger[id]["coords"] then return maps end

  local maps = maps or {}
  local prio = prio or 1

  for _, data in pairs(areatrigger[id]["coords"]) do
    local x, y, zone = unpack(data)

    if zone and zone > 0 then
      -- add all gathered data
      meta = meta or {}
      meta["spawn"] = pfQuest_Loc["Exploration Mark"]
      meta["spawnid"] = id
      meta["spawnalias"] = nil
      meta["summonsrc"] = nil
      meta["item"] = nil

      meta["title"] = meta["quest"] or meta["item"] or meta["spawn"]
      meta["zone"]  = zone
      meta["x"]     = x
      meta["y"]     = y

      meta["level"] = pfQuest_Loc["N/A"]
      meta["spawntype"] = pfQuest_Loc["Trigger"]
      meta["respawn"] = pfQuest_Loc["N/A"]

      maps[zone] = maps[zone] and maps[zone] + prio or prio
      pfMap:AddNode(meta)
    end
  end

  return maps
end

-- SummonHint
-- 召唤源那句话的唯一出处，世界提示、图钉提示、导航箭头三处共用。
-- summon 的四种形态各对应一句：
--   { U }        与某人交谈        { U, I }  对某人使用某物
--   { O }        使用某物件        { O, I }  对某物件使用某物
-- 条件复杂到四句都套不上的，数据里写 hint 给整句。hint 是**语言表的键**，不是成品文本：
-- 取到译文后替换三个占位符，缺译文时回落成键本身（英文），所以数据层不写死中文。
--   $source 召唤源名   $item 召唤道具名   $target 被召唤者名
-- 三者都会自动套上与内置四句一致的青色，模板里不必自己写颜色码。
function pfDatabase:SummonHint(meta)
  local src = meta and meta["summonsrc"]
  if not src then return nil end

  if src.hint then
    local text = pfQuest_Loc[src.hint]
    local function teal(v) return function() return "|cff33ffcc" .. v .. "|r" end end
    if src.name then text = string.gsub(text, "%$source", teal(src.name)) end
    if src.item then text = string.gsub(text, "%$item", teal(src.item)) end
    if meta["spawn"] then text = string.gsub(text, "%$target", teal(meta["spawn"])) end
    return text
  end

  if not src.name then return nil end

  if src.item then
    return string.format(pfQuest_Loc["On |cff33ffcc%s|r use |cff33ffcc%s|r"], src.name, src.item)
  elseif src.kind == "U" then
    return string.format(pfQuest_Loc["Talk to |cff33ffcc%s|r"], src.name)
  else
    return string.format(pfQuest_Loc["Use |cff33ffcc%s|r"], src.name)
  end
end

-- GetSummonCoords
-- 被召唤出来的单位在服务端没有 spawn_points，coords 是空表。units[id].summon
-- 声明召唤来源，这里解析成与 coords 同构的落点表。
-- O = 场景物，U = 单位。区域标记不单独支持：库里的惯例是虚构一个游戏内不存在的
-- 场景物来占位，写 O 即可，不必再多一条分支。
-- O 与 U 都可以写成一个 id，也可以写成 id 列表（同一只怪由好几种源变出来时）。
-- 返回的坐标是 5 元素 { x, y, zone, respawn, 源id }，第 5 位供逐点认领各自的源。
-- 第二个返回值描述召唤源：{ id, kind, name, lvl, item, hint, byid }，byid 按源 id 索引，
-- 每项都是一份完整的源描述。四种固定措辞见 SummonHint，写了 hint 就整句照搬。
function pfDatabase:GetSummonCoords(summon)
  if not summon then return nil end

  local item = summon["I"] and pfDB.items.loc[summon["I"]] or nil

  -- 单位召唤源与场景物不同：它有几十个会移动的落点，等于把整片同类怪都标成目标。
  -- 只在「哪一只都行」时才写 summon.U；若只有特定一只能召唤，这里会标出一片。
  for _, kind in ipairs({ "O", "U" }) do
    local decl = summon[kind]
    if decl then
      local list = type(decl) == "table" and decl or { decl }
      local coords, byid, first = {}, {}, nil

      for _, id in ipairs(list) do
        local entry = kind == "O" and objects[id] or units[id]
        if entry and entry["coords"] and not isempty(entry["coords"]) then
          byid[id] = { id = id, kind = kind, item = item, hint = summon["hint"],
            name = kind == "O" and pfDB.objects.loc[id] or pfDB.units.loc[id],
            lvl = kind == "U" and entry["lvl"] or nil }
          first = first or byid[id]
          for _, c in pairs(entry["coords"]) do
            table.insert(coords, { c[1], c[2], c[3], c[4], id })
          end
        end
      end

      if first then
        return coords, { id = first.id, kind = kind, name = first.name, lvl = first.lvl,
          item = item, hint = summon["hint"], byid = byid }
      end
    end
  end

  return nil
end

-- 无坐标也无 summon 落点的目标：画不了图钉，但鼠标提示照样要认识它。
-- 库里 0 刷点不等于游戏里没有（上游导出会丢刷点），玩家指到实体时至少
-- 要能看到任务归属，否则整条任务四处静默。
-- meta 是跨函数复用的共享表，这里写到的字段必须全量赋值或显式清 nil，
-- 防止上一个目标的 spawnalias/summonsrc/respawn 漏进来（:845 的老坑）。
local unpinned_skip = { "dummy", "trigger", "triger", "credit marker", "^quest[%s_]" }

-- 名字命中内部触发器模式就跳过。库是 zhCN 本地化的，触发器多半被译成
--「…触发器」之类，模式却是英文的——所以 enUS 原名也要过一遍筛。
local function IsUnpinnedSkipName(name)
  if not name then return nil end
  local lower = strlower(name)
  for _, pat in pairs(unpinned_skip) do
    if strfind(lower, pat) then return true end
  end
  return nil
end

local function RegisterUnpinnedTooltip(kind, id, meta)
  -- texture 非空是任务给予者/商贩节点，不属于目标类，不走这条路
  if not meta or meta["texture"] then return end
  -- 没有任务也没有物品上下文时无话可说，不登记空条目
  if not meta["quest"] and not meta["item"] then return end

  local name = kind == "U" and pfDB.units.loc[id] or pfDB.objects.loc[id]
  if not name then return end

  -- 服务端内部触发器（约 91 条）玩家永远指不到，名字不会出现在 GameTooltip 里。
  -- loc 是 zhCN，模式是英文，所以 enUS 原名也要单独过一遍——不能拼接后一起测，
  -- 否则 "^quest[%s_]" 的行首锚点永远锚在 zhCN 名字上，锚不到 enUS 名字开头。
  local enus
  if kind == "U" then
    enus = pfDB.units.enUS and pfDB.units.enUS[id]
  else
    enus = pfDB.objects.enUS and pfDB.objects.enUS[id]
  end
  if IsUnpinnedSkipName(name) or IsUnpinnedSkipName(enus) then return end

  meta["spawn"] = name
  meta["spawnid"] = id
  meta["spawnalias"] = nil
  meta["summonsrc"] = nil
  meta["title"] = meta["quest"] or meta["item"] or meta["spawn"]
  meta["zone"], meta["x"], meta["y"] = nil, nil, nil
  meta["respawn"] = nil

  if kind == "U" then
    meta["level"] = units[id]["lvl"] or UNKNOWN
    meta["spawntype"] = pfQuest_Loc["Unit"]
  else
    local skill, caption = pfDatabase:SearchObjectSkill(id)
    meta["level"] = skill and string.format("%s [%s]", skill, caption) or nil
    meta["spawntype"] = pfQuest_Loc["Object"]
  end

  pfMap:AddTooltipEntry(meta)
end

-- SearchMobID
-- Scans for all mobs with a specified ID
-- Adds map nodes for each and returns its map table
function pfDatabase:SearchMobID(id, meta, maps, prio)
  if not units[id] then return maps end

  -- 无落点的单位（被召唤出来的）按 summon 声明解析坐标。
  -- 保留 nil 检查：patchtable 对乌龟层是整条替换，将来上游若出现不带 coords
  -- 的条目，pairs(nil) 会打断整条 SearchQuestID 调用链。
  local coords, summonsrc = units[id]["coords"], nil
  if units[id]["summon"] and (not coords or isempty(coords)) then
    coords, summonsrc = pfDatabase:GetSummonCoords(units[id]["summon"])
  end
  if not coords or isempty(coords) then
    RegisterUnpinnedTooltip("U", id, meta)
    return maps or {}
  end

  local maps = maps or {}
  local prio = prio or 1

  for _, data in pairs(coords) do
    local x, y, zone, respawn, srcid = unpack(data)

    -- 多个召唤源时每个落点认领自己那个，图钉抬头与提示键各归各的怪
    local nodesrc = summonsrc
    if srcid and summonsrc and summonsrc.byid and summonsrc.byid[srcid] then
      nodesrc = summonsrc.byid[srcid]
    end

    if zone > 0 then
      -- add all gathered data
      meta = meta or {}
      meta["spawn"] = pfDB.units.loc[id]
      meta["spawnid"] = id
      -- spawnalias 是召唤源的名字，供 AddNode 额外注册一个鼠标提示键；非召唤单位为 nil。
      -- summonsrc 带着措辞需要的其余信息（id / U 还是 O / 等级 / 道具），见 SummonHint。
      -- meta 在 SearchQuestID 内跨函数复用，所以这两个每次都赋值，
      -- 且 SearchObjectID / SearchAreaTriggerID / SearchZoneID 也各自清空它们
      meta["spawnalias"] = nodesrc and nodesrc.name or nil
      meta["summonsrc"] = nodesrc

      meta["title"] = meta["quest"] or meta["item"] or meta["spawn"]
      meta["zone"]  = zone
      meta["x"]     = x
      meta["y"]     = y

      meta["level"] = units[id]["lvl"] or UNKNOWN
      meta["spawntype"] = pfQuest_Loc["Unit"]
      meta["respawn"] = respawn and respawn > 0 and SecondsToTime(respawn)

      maps[zone] = maps[zone] and maps[zone] + prio or prio
      pfMap:AddNode(meta)
    end
  end

  return maps
end

-- Search MetaRelation
-- Scans for all entries within the specified meta name
-- Adds map nodes for each and returns its map table
-- query = { relation-name, relation-min, relation-max }
local alias = {
  ["flightmaster"] = "flight",
  ["taxi"] = "flight",
  ["flights"] = "flight",
  ["raremobs"] = "rares",
}

local skill = {
  ["herbs"] = true,
  ["mines"] = true,
  ["rares"] = true,
  ["chests"] = true,
}

function pfDatabase:SearchMetaRelation(query, meta, show)
  local maps = {}

  -- abort on invalid queries
  if not query.name then return end

  -- convert track name aliases
  local track = alias[query.name] or query.name

  if pfDB["meta"] and pfDB["meta"][track] then
    -- check which faction should be searched
    local faction = query.faction and string.lower(query.faction) or (UnitFactionGroup("player") and string.lower(UnitFactionGroup("player")))
    faction = faction == "horde" and "H" or faction == "alliance" and "A" or ""

    -- iterate over all tracking entries
    for entry, value in pairs(pfDB["meta"][track]) do
      if skill[track] and tonumber(query.min) and tonumber(value) < tonumber(query.min) then
        -- required skill is lower than the queried one
      elseif skill[track] and tonumber(query.max) and tonumber(value) > tonumber(query.max) then
        -- required skill is lower than the queried one
      elseif not skill[track] and not string.find(value, faction) then
        -- faction is different from the queried one
      else
        local prev_icon = meta.icon
        local object = pfDB["objects"]["loc"][math.abs(entry)]
        local unit = pfDB["units"]["loc"][entry]

        -- set node as tracking result
        meta.tracking = true

        -- handle custom tracking icons
        if pfQuest_config.trackingicons == "0" then
          meta.icon = nil
        elseif entry < 0 and object and pfDatabase.icons[object] then
          meta.icon = pfDatabase.icons[object]
        elseif entry > 0 and unit and pfDatabase.icons[unit] then
          meta.icon = pfDatabase.icons[unit]
        end

        -- set custom fade range for skill-trackables
        if meta.icon and skill[track] then
          meta.fade_range = 85
        elseif meta.icon then
          meta.fade_range = 10
        else
          meta.fade_range = nil
        end

        if entry < 0 then
          pfDatabase:SearchObjectID(math.abs(entry), meta, maps)
        else
          pfDatabase:SearchMobID(entry, meta, maps)
        end

        -- reset meta table
        meta.icon = prev_icon
        meta.tracking = false
      end
    end
  end

  return maps
end

-- Search TrackMeta
-- Scans for all entries within the specified list
-- Adds map nodes for each, saves it to the persistent
-- tracking variable per character and returns a map table
function pfDatabase:TrackMeta(list, state)
  local list = alias[list] and alias[list] or list
  local identifier = "TRACK_"..string.upper(list)

  local meta = {
    ["addon"] = identifier,
    ["icon"] = pfQuestConfig.path.."\\img\\tracking\\"..list,
  }

  local query = {
    name = list
  }

  local maps = nil

  -- hide previous tracks
  pfQuest_track[list] = nil
  pfMap:DeleteNode(identifier)
  pfMap:UpdateNodes()

  -- break here if nothing should be tracked
  if not state then return end

  -- add extended state values to query
  -- this is used for min/max values
  if type(state) == "table" then
    for k, v in pairs(state) do
      query[k] = v
    end
  end

  -- save and perform the actual meta tracking
  pfQuest_track[list] = { query, meta }
  local maps = pfDatabase:SearchMetaRelation(query, meta)

  -- remove invalid results
  if not maps then pfQuest_track[list] = nil end

  -- return map results
  return maps
end

-- SearchMob
-- Scans for all mobs with a specified name
-- Adds map nodes for each and returns its map table
function pfDatabase:SearchMob(mob, meta, partial)
  local maps = {}

  for id in pairs(pfDatabase:GetIDByName(mob, "units", partial)) do
    if units[id] and units[id]["coords"] then
      maps = pfDatabase:SearchMobID(id, meta, maps)
    end
  end

  return maps
end

-- SearchZoneID
-- Scans for all zones with a specific ID
-- Add nodes to the center of that location
function pfDatabase:SearchZoneID(id, meta, maps, prio)
  if not zones[id] then return maps end

  local maps = maps or {}
  local prio = prio or 1

  local zone, width, height, x, y, ex, ey = unpack(zones[id])

  if zone > 0 then
    maps[zone] = maps[zone] and maps[zone] + prio or prio

    meta = meta or {}
    meta["spawn"] = pfDB.zones.loc[id] or UNKNOWN
    meta["spawnid"] = id
    meta["spawnalias"] = nil
    meta["summonsrc"] = nil

    meta["title"] = meta["quest"] or meta["item"] or meta["spawn"]
    meta["zone"]  = zone
    meta["level"] = "N/A"
    meta["spawntype"] = pfQuest_Loc["Area/Zone"]
    meta["respawn"] = "N/A"
    meta["x"]     = x
    meta["y"]     = y

    pfMap:AddNode(meta)
    return maps
  end

  return maps
end

-- SearchZone
-- Scans for all zones with a specified name
-- Adds map nodes for each and returns its map table
function pfDatabase:SearchZone(obj, meta, partial)
  local maps = {}

  for id in pairs(pfDatabase:GetIDByName(obj, "zones", partial)) do
    if zones[id] then
      maps = pfDatabase:SearchZoneID(id, meta, maps)
    end
  end

  return maps
end

function pfDatabase:SearchObjectSkill(id)
  if not id or not tonumber(id) then return end
  local skill, caption = nil, nil

  if (pfDB["meta"]["herbs"][-id]) then
    skill = pfDB["meta"]["herbs"][-id]
    caption = pfQuest_Loc["Herbalism"]
  elseif (pfDB["meta"]["mines"][-id]) then
    skill = pfDB["meta"]["mines"][-id]
    caption = pfQuest_Loc["Mining"]
  end

  return skill, caption
end

-- Scans for all objects with a specified ID
-- Adds map nodes for each and returns its map table
function pfDatabase:SearchObjectID(id, meta, maps, prio)
  if not objects[id] then return maps end
  if not objects[id]["coords"] or isempty(objects[id]["coords"]) then
    RegisterUnpinnedTooltip("O", id, meta)
    return maps or {}
  end

  local skill, caption = pfDatabase:SearchObjectSkill(id)
  local maps = maps or {}
  local prio = prio or 1

  for _, data in pairs(objects[id]["coords"]) do
    local x, y, zone, respawn = unpack(data)

    if zone > 0 then
      -- add all gathered data
      meta = meta or {}
      meta["spawn"] = pfDB.objects.loc[id]
      meta["spawnid"] = id
      meta["spawnalias"] = nil
      meta["summonsrc"] = nil

      meta["title"] = meta["quest"] or meta["item"] or meta["spawn"]
      meta["zone"]  = zone
      meta["x"]     = x
      meta["y"]     = y

      meta["level"] = skill and string.format("%s [%s]", skill, caption) or nil
      meta["spawntype"] = pfQuest_Loc["Object"]
      meta["respawn"] = respawn and SecondsToTime(respawn)

      maps[zone] = maps[zone] and maps[zone] + prio or prio
      pfMap:AddNode(meta)
    end
  end

  return maps
end

-- SearchObject
-- Scans for all objects with a specified name
-- Adds map nodes for each and returns its map table
function pfDatabase:SearchObject(obj, meta, partial)
  local maps = {}

  for id in pairs(pfDatabase:GetIDByName(obj, "objects", partial)) do
    if objects[id] and objects[id]["coords"] then
      maps = pfDatabase:SearchObjectID(id, meta, maps)
    end
  end

  return maps
end

-- SearchItemID
-- Scans for all items with a specified ID
-- Adds map nodes for each drop and vendor
-- Returns its map table
function pfDatabase:SearchItemID(id, meta, maps, allowedTypes)
  if not items[id] then return maps end

  local maps = maps or {}
  local meta = meta or {}

  meta["itemid"] = id
  meta["item"] = pfDB.items.loc[id]

  local minChance = tonumber(pfQuest_config.mindropchance)
  if not minChance then minChance = 0 end

  -- search unit drops
  if items[id]["U"] and ((not allowedTypes) or allowedTypes["U"]) then
    for unit, chance in pairs(items[id]["U"]) do
      if chance >= minChance then
        meta["texture"] = nil
        meta["droprate"] = chance
        meta["sellcount"] = nil
        maps = pfDatabase:SearchMobID(unit, meta, maps)
      end
    end
  end

  -- search object loot (veins, chests, ..)
  if items[id]["O"] and ((not allowedTypes) or allowedTypes["O"]) then
    for object, chance in pairs(items[id]["O"]) do
      if chance >= minChance and chance > 0 then
        meta["texture"] = nil
        meta["droprate"] = chance
        meta["sellcount"] = nil
        maps = pfDatabase:SearchObjectID(object, meta, maps)
      end
    end
  end

  -- search reference loot (objects, creatures)
  if items[id]["R"] then
    for ref, chance in pairs(items[id]["R"]) do
      if chance >= minChance and refloot[ref] then
        -- ref creatures
        if refloot[ref]["U"] and ((not allowedTypes) or allowedTypes["U"]) then
          for unit in pairs(refloot[ref]["U"]) do
            meta["texture"] = nil
            meta["droprate"] = chance
            meta["sellcount"] = nil
            maps = pfDatabase:SearchMobID(unit, meta, maps)
          end
        end

        -- ref objects
        if refloot[ref]["O"] and ((not allowedTypes) or allowedTypes["O"]) then
          for object in pairs(refloot[ref]["O"]) do
            meta["texture"] = nil
            meta["droprate"] = chance
            meta["sellcount"] = nil
            maps = pfDatabase:SearchObjectID(object, meta, maps)
          end
        end
      end
    end
  end

  -- search vendor goods
  if items[id]["V"] and ((not allowedTypes) or allowedTypes["V"]) then
    for unit, chance in pairs(items[id]["V"]) do
      meta["texture"] = pfQuestConfig.path.."\\img\\icon_vendor"
      meta["droprate"] = nil
      meta["sellcount"] = chance
      maps = pfDatabase:SearchMobID(unit, meta, maps)
    end
  end

  return maps
end

-- SearchItem
-- Scans for all items with a specified name
-- Adds map nodes for each drop and vendor
-- Returns its map table
function pfDatabase:SearchItem(item, meta, partial)
  local maps = {}
  local bestmap, bestscore = nil, 0

  for id in pairs(pfDatabase:GetIDByName(item, "items", partial)) do
    maps = pfDatabase:SearchItemID(id, meta, maps)
  end

  return maps
end

-- SearchVendor
-- Scans for all items with a specified name
-- Adds map nodes for each vendor
-- Returns its map table
function pfDatabase:SearchVendor(item, meta)
  local maps = {}
  local meta = meta or {}
  local bestmap, bestscore = nil, 0

  for id in pairs(pfDatabase:GetIDByName(item, "items")) do
    meta["itemid"] = id
    meta["item"] = pfDB.items.loc[id]

    -- search vendor goods
    if items[id] and items[id]["V"] then
      for unit, chance in pairs(items[id]["V"]) do
        meta["texture"] = pfQuestConfig.path.."\\img\\icon_vendor"
        meta["droprate"] = nil
        meta["sellcount"] = chance
        maps = pfDatabase:SearchMobID(unit, meta, maps)
      end
    end
  end

  return maps
end

-- SearchQuestID
-- Scans for all quests with a specified ID
-- Adds map nodes for each objective and involved units
-- Returns its map table
function pfDatabase:SearchQuestID(id, meta, maps)
  if not quests[id] then return end
  local maps = maps or {}
  local meta = meta or {}

  meta["questid"] = id
  meta["quest"] = pfDB.quests.loc[id] and pfDB.quests.loc[id].T
  meta["qlvl"] = quests[id]["lvl"]
  meta["qmin"] = quests[id]["min"]

  -- clear previous unified quest nodes
  if meta.quest then
    pfMap.unifiedcache[meta.quest] = {}
  end

  if pfQuest_config["currentquestgivers"] == "1" then
    -- search quest-starter
    if quests[id]["start"] and not meta["qlogid"] then
      -- units
      if quests[id]["start"]["U"] then
        for _, unit in pairs(quests[id]["start"]["U"]) do
          meta = meta or {}
          meta["QTYPE"] = "NPC_START"
          meta["layer"] = meta["layer"] or 4
          meta["texture"] = pfQuestConfig.path.."\\img\\available_c"
          maps = pfDatabase:SearchMobID(unit, meta, maps, 0)
        end
      end

      -- objects
      if quests[id]["start"]["O"] then
        for _, object in pairs(quests[id]["start"]["O"]) do
          meta = meta or {}
          meta["QTYPE"] = "OBJECT_START"
          meta["texture"] = pfQuestConfig.path.."\\img\\available_c"
          maps = pfDatabase:SearchObjectID(object, meta, maps, 0)
        end
      end
    end

    -- search quest-ender
    if quests[id]["end"] then
      -- units
      if quests[id]["end"]["U"] then
        for _, unit in pairs(quests[id]["end"]["U"]) do
          meta = meta or {}

          if meta["qlogid"] then
            local _, _, _, _, _, complete = compat.GetQuestLogTitle(meta["qlogid"])
            if not (pfQuest and pfQuest.TurtleUnsafeQuest and pfQuest:TurtleUnsafeQuest(id, meta["quest"])) then
              complete = complete or GetNumQuestLeaderBoards(meta["qlogid"]) == 0 and true or nil
            end
            if complete == true or complete == 1 then
              meta["texture"] = pfQuestConfig.path.."\\img\\complete_c"
            else
              meta["texture"] = pfQuestConfig.path.."\\img\\complete"
            end
          else
            meta["texture"] = pfQuestConfig.path.."\\img\\complete_c"
          end
          meta["QTYPE"] = "NPC_END"

          maps = pfDatabase:SearchMobID(unit, meta, maps, 0)
        end
      end

      -- objects
      if quests[id]["end"]["O"] then
        for _, object in pairs(quests[id]["end"]["O"]) do
          meta = meta or {}

          if meta["qlogid"] then
            local _, _, _, _, _, complete = compat.GetQuestLogTitle(meta["qlogid"])
            if not (pfQuest and pfQuest.TurtleUnsafeQuest and pfQuest:TurtleUnsafeQuest(id, meta["quest"])) then
              complete = complete or GetNumQuestLeaderBoards(meta["qlogid"]) == 0 and true or nil
            end
            if complete then
              meta["texture"] = pfQuestConfig.path.."\\img\\complete_c"
            else
              meta["texture"] = pfQuestConfig.path.."\\img\\complete"
            end
          else
            meta["texture"] = pfQuestConfig.path.."\\img\\complete_c"
          end

          meta["QTYPE"] = "OBJECT_END"

          maps = pfDatabase:SearchObjectID(object, meta, maps, 0)
        end
      end
    end
  end

  local parse_obj = {
    ["U"] = {},
    ["O"] = {},
    ["I"] = {},
  }

  -- 整条任务已完成就不必再画目标。判据只取 GetQuestLogTitle 的完成位，不碰会
  -- 返回任务文本的目标行接口，所以放在黑名单判据外面也不会踩崩溃那条路。
  if meta["qlogid"] then
    local _, _, _, _, _, complete = compat.GetQuestLogTitle(meta["qlogid"])
    if complete then return maps end
  end

  -- If QuestLogID is given, scan and add all finished objectives to blacklist
  if meta["qlogid"] and not (pfQuest and pfQuest.TurtleUnsafeQuest and pfQuest:TurtleUnsafeQuest(id, meta["quest"])) then
    local objectives = GetNumQuestLeaderBoards(meta["qlogid"])

    if objectives then
      -- 认不出归属的目标行，先攒着，扫完全部目标行后只在能唯一归属时才认。
      local orphan, orphans = nil, 0

      local objtext = pfDB["objtext"] and pfDB["objtext"]["loc"][id]

      for i=1, objectives, 1 do
        local text, type, done = GetQuestLogLeaderBoard(i, meta["qlogid"])

        -- 手工映射的目标文本。服务端会给目标行写自定义文案（2681「解放拉瑟莱克的仆从」），
        -- 也会把名字译得和 NPC 对不上（40285），两种都只能按整段文本查表。
        -- 查到就以配置为准，本行不再走后面任何一种匹配。
        local prefix, num, needed = pfDatabase:ParseObjectiveCounter(text)
        local override = prefix and objtext and objtext[prefix]

        if override then
          local state = ( done or ( num and num + 0 >= needed + 0 ) ) and "DONE" or "PROG"
          for _, slot in pairs({ "U", "O", "I" }) do
            local targets = pfDatabase:ObjtextTargets(override, slot)
            if targets then
              for _, target in pairs(targets) do parse_obj[slot][target] = state end
            end
          end
        end

        -- spawn data
        if not override and type == "monster" then
          local i, j, monsterName, objNum, objNeeded = strfind(text, pfUI.api.SanitizePattern(QUEST_MONSTERS_KILLED))

          -- 杀怪式匹配不上时，拿本任务自己的目标名去认对话类措辞，范围不外扩
          if not monsterName and quests[id]["obj"] then
            local named
            for _, class in pairs({ "T", "U" }) do
              if quests[id]["obj"][class] then
                for _, target in pairs(quests[id]["obj"][class]) do
                  local db = target > 0 and "units" or "objects"
                  local _, num, needed =
                    pfDatabase:ParseTalkObjective(text, pfDB[db]["loc"][math.abs(target)])
                  if num then
                    named = true
                    local slot = target > 0 and "U" or "O"
                    parse_obj[slot][math.abs(target)] =
                      ( num + 0 >= needed + 0 or done ) and "DONE" or "PROG"
                  end
                end
              end
            end

            if not named then
              orphan, orphans = { text = text, done = done }, orphans + 1
            end
          end

          for id in pairs(pfDatabase:GetIDByName(monsterName, "units")) do
            parse_obj["U"][id] = ( objNum + 0 >= objNeeded + 0 or done ) and "DONE" or "PROG"
          end

          for id in pairs(pfDatabase:GetIDByName(monsterName, "objects")) do
            parse_obj["O"][id] = ( objNum + 0 >= objNeeded + 0 or done ) and "DONE" or "PROG"
          end
        end

        -- item data
        if not override and type == "item" then
          local i, j, itemName, objNum, objNeeded = strfind(text, pfUI.api.SanitizePattern(QUEST_OBJECTS_FOUND))
          for id in pairs(pfDatabase:GetIDByName(itemName, "items")) do
            parse_obj["I"][id] = ( objNum + 0 >= objNeeded + 0 or done ) and "DONE" or "PROG"
          end
        end
      end

      -- 只剩一行没归属、且本任务只有一个对话目标时，这行只能是它，按它记进度。
      -- 多于一个就不猜：认错会让还没做完的目标提前从地图上消失。
      local talk = quests[id]["obj"] and quests[id]["obj"]["T"]
      if orphans == 1 and talk and table.getn(talk) == 1 then
        local target = talk[1]
        local slot, key = ( target > 0 and "U" or "O" ), math.abs(target)
        if not parse_obj[slot][key] then
          local _, num, needed = pfDatabase:ParseObjectiveCounter(orphan.text)
          local finished = orphan.done or ( num and num + 0 >= needed + 0 )
          parse_obj[slot][key] = finished and "DONE" or "PROG"
        end
      end
    end
  end

  -- search quest-objectives
  if quests[id]["obj"] then
    local skip_objects
    local skip_creatures

    -- item requirements
    if quests[id]["obj"]["IR"] then
      local requirement

      for _, item in pairs(quests[id]["obj"]["IR"]) do
        if itemreq[item] then
          requirement = pfDB["items"]["loc"][item] or UNKNOWN

          for object, spell in pairs(itemreq[item]) do
            if object < 0 then
              -- gameobject
              meta["texture"] = nil
              meta["layer"] = 2
              meta["QTYPE"] = "OBJECT_OBJECTIVE_ITEMREQ"
              meta.itemreq = requirement

              skip_objects = skip_objects or {}
              skip_objects[math.abs(object)] = true

              pfDatabase:TrackQuestItemDependency(requirement, id)
              if pfDatabase.itemlist.db[requirement] then
                maps = pfDatabase:SearchObjectID(math.abs(object), meta, maps)
              end
            elseif object > 0 then
              -- creature
              meta["texture"] = nil
              meta["layer"] = 2
              meta["QTYPE"] = "UNIT_OBJECTIVE_ITEMREQ"
              meta.itemreq = requirement

              skip_creatures = skip_creatures or {}
              skip_creatures[math.abs(object)] = true

              pfDatabase:TrackQuestItemDependency(requirement, id)
              if pfDatabase.itemlist.db[requirement] then
                maps = pfDatabase:SearchMobID(math.abs(object), meta, maps)
              end
            end
          end
        end
      end
    end

    -- talk objectives
    -- 正数是单位、负数是游戏物件，与 obj.IR 的约定一致。
    -- 这里会把 ID 登记进 skip 集合，所以同一个 ID 继续留在 obj.U / obj.O 里也不会被重复画。
    if quests[id]["obj"]["T"] then
      for _, target in pairs(quests[id]["obj"]["T"]) do
        meta["texture"] = nil
        meta["QTYPE"] = "TALK_OBJECTIVE"

        if target > 0 then
          -- 先判后记：obj.IR 也登记同一批集合且优先级更高，已被它画过的不再画一遍
          local drawn = skip_creatures and skip_creatures[target]
          skip_creatures = skip_creatures or {}
          skip_creatures[target] = true

          if not drawn and parse_obj["U"][target] ~= "DONE" then
            maps = pfDatabase:SearchMobID(target, meta, maps)
          end
        elseif target < 0 then
          local object = math.abs(target)
          local drawn = skip_objects and skip_objects[object]
          skip_objects = skip_objects or {}
          skip_objects[object] = true

          if not drawn and parse_obj["O"][object] ~= "DONE" then
            meta["layer"] = 2
            maps = pfDatabase:SearchObjectID(object, meta, maps)
          end
        end
      end
    end

    -- units
    if quests[id]["obj"]["U"] then
      for _, unit in pairs(quests[id]["obj"]["U"]) do
        if not parse_obj["U"][unit] or parse_obj["U"][unit] ~= "DONE" then
          if not skip_creatures or not skip_creatures[unit] then
            meta = meta or {}
            meta["texture"] = nil
            meta["QTYPE"] = "UNIT_OBJECTIVE"
            maps = pfDatabase:SearchMobID(unit, meta, maps)
          end
        end
      end
    end

    -- objects
    if quests[id]["obj"]["O"] then
      for _, object in pairs(quests[id]["obj"]["O"]) do
        if not parse_obj["O"][object] or parse_obj["O"][object] ~= "DONE" then
          if not skip_objects or not skip_objects[object] then
            meta = meta or {}
            meta["texture"] = nil
            meta["layer"] = 2
            meta["QTYPE"] = "OBJECT_OBJECTIVE"
            maps = pfDatabase:SearchObjectID(object, meta, maps)
          end
        end
      end
    end

    -- items
    if quests[id]["obj"]["I"] then
      for _, item in pairs(quests[id]["obj"]["I"]) do
        if not parse_obj["I"][item] or parse_obj["I"][item] ~= "DONE" then
          meta = meta or {}
          meta["texture"] = nil
          meta["layer"] = 2
          if parse_obj["I"][item] then
            meta["QTYPE"] = "ITEM_OBJECTIVE_LOOT"
          else
            meta["QTYPE"] = "ITEM_OBJECTIVE_USE"
          end
          maps = pfDatabase:SearchItemID(item, meta, maps)
        end
      end
    end

    -- areatrigger
    if quests[id]["obj"]["A"] then
      for _, areatrigger in pairs(quests[id]["obj"]["A"]) do
        meta = meta or {}
        meta["texture"] = nil
        meta["layer"] = 2
        meta["QTYPE"] = "AREATRIGGER_OBJECTIVE"
        maps = pfDatabase:SearchAreaTriggerID(areatrigger, meta, maps)
      end
    end

    -- zones
    if quests[id]["obj"]["Z"] then
      for _, zone in pairs(quests[id]["obj"]["Z"]) do
        meta = meta or {}
        meta["texture"] = nil
        meta["layer"] = 2
        meta["QTYPE"] = "ZONE_OBJECTIVE"
        maps = pfDatabase:SearchZoneID(zone, meta, maps)
      end
    end
  end

  -- prepare unified quest location markers
  local addon = meta["addon"] or "PFDB"
  if pfMap.nodes[addon] then
    for map in pairs(pfMap.nodes[addon]) do
      if meta.quest and pfMap.unifiedcache[meta.quest] and pfMap.unifiedcache[meta.quest][map] then
        for hash, data in pairs(pfMap.unifiedcache[meta.quest][map]) do
          meta = data.meta
          meta["title"] = meta["quest"]
          meta["cluster"] = true
          meta["zone"]  = map

          local icon = pfQuest_config["clustermono"] == "1" and "_mono" or ""

          -- 每个目标分支都会重设 QTYPE，所以直接拿它派发，不需要额外的状态清理
          local kindtex = meta.QTYPE == "TALK_OBJECTIVE" and "cluster_talk"
                       or meta.QTYPE == "AREATRIGGER_OBJECTIVE" and "cluster_explore" or nil

          if kindtex then
            meta["x"], meta["y"], meta["priority"] = getcluster(data.coords, meta["quest"]..hash..map)
            meta["texture"] = pfQuestConfig.path.."\\img\\" .. kindtex .. icon
            pfMap:AddNode(meta, true)
          elseif meta.item then
            meta["x"], meta["y"], meta["priority"] = getcluster(data.coords, meta["quest"]..hash..map)
            meta["texture"] = pfQuestConfig.path.."\\img\\cluster_item" .. icon
            pfMap:AddNode(meta, true)
          elseif meta.spawntype and meta.spawntype == pfQuest_Loc["Unit"] and meta.spawn and not meta.itemreq then
            meta["x"], meta["y"], meta["priority"] = getcluster(data.coords, meta["quest"]..hash..map)
            meta["texture"] = pfQuestConfig.path.."\\img\\cluster_mob" .. icon
            pfMap:AddNode(meta, true)
          else
            meta["x"], meta["y"], meta["priority"] = getcluster(data.coords, meta["quest"]..hash..map)
            meta["texture"] = pfQuestConfig.path.."\\img\\cluster_misc" .. icon
            pfMap:AddNode(meta, true)
          end
        end
      end
    end
  end

  return maps
end

-- SearchQuest
-- Scans for all quests with a specified name
-- Adds map nodes for each objective and involved unit
-- Returns its map table
function pfDatabase:SearchQuest(quest, meta, partial)
  local maps = {}

  for id in pairs(pfDatabase:GetIDByName(quest, "quests", partial)) do
    maps = pfDatabase:SearchQuestID(id, meta, maps)
  end

  return maps
end

function pfDatabase:QuestFilter(id, plevel, pclass, prace)
  -- hide active quest
  if pfQuest.questlog[id] then return end

  -- hide completed quests
  if pfQuest_history[id] then return end

  -- hide broken quests without names
  if not pfDB.quests.loc[id] or not pfDB.quests.loc[id].T then return end

  -- hide missing pre-quests
  if quests[id]["pre"] then
    -- check all pre-quests for one to be completed
    local one_complete = nil
    for _, prequest in pairs(quests[id]["pre"]) do
      if pfQuest_history[prequest] then
        one_complete = true
      end
    end

    -- hide if none of the pre-quests has been completed
    if not one_complete then return end
  end

  -- hide non-available quests for your race
  if quests[id]["race"] and not ( bit.band(quests[id]["race"], prace) == prace ) then return end

  -- hide non-available quests for your class
  if quests[id]["class"] and not ( bit.band(quests[id]["class"], pclass) == pclass ) then return end

  -- hide non-available quests for your profession
  if quests[id]["skill"] and not pfDatabase:GetPlayerSkill(quests[id]["skill"]) then return end

  -- hide lowlevel quests
  if quests[id]["lvl"] and quests[id]["lvl"] < plevel - 4 and pfQuest_config["showlowlevel"] == "0" then return end

  -- hide highlevel quests (or show those that are 3 levels above)
  if quests[id]["min"] and quests[id]["min"] > plevel + ( pfQuest_config["showhighlevel"] == "1" and 3 or 0 ) then return end

  -- hide event quests
  if quests[id]["event"] and pfQuest_config["showfestival"] == "0" then return end

  return true
end

-- SearchQuests
-- Scans for all available quests
-- Adds map nodes for each quest starter and ender
-- Returns its map table
function pfDatabase:SearchQuests(meta, maps)
  local level, minlvl, maxlvl, race, class, prof, festival
  local maps = maps or {}
  local meta = meta or {}

  local plevel = UnitLevel("player")
  local pfaction = UnitFactionGroup("player")
  if pfaction == "Horde" then
    pfaction = "H"
  elseif pfaction == "Alliance" then
    pfaction = "A"
  else
    pfaction = "GM"
  end

  local _, race = UnitRace("player")
  local prace = pfDatabase:GetBitByRace(race)
  local _, class = UnitClass("player")
  local pclass = pfDatabase:GetBitByClass(class)

  for id in pairs(quests) do
    if pfDatabase:QuestFilter(id, plevel, pclass, prace) then
      -- set metadata
      meta["quest"] = ( pfDB.quests.loc[id] and pfDB.quests.loc[id].T ) or UNKNOWN
      meta["questid"] = id
      meta["texture"] = pfQuestConfig.path.."\\img\\available_c"

      meta["qlvl"] = quests[id]["lvl"]
      meta["qmin"] = quests[id]["min"]

      meta["vertex"] = { 0, 0, 0 }
      meta["layer"] = 3

      -- tint high level quests red
      if quests[id]["min"] and quests[id]["min"] > plevel then
        meta["texture"] = pfQuestConfig.path.."\\img\\available"
        meta["vertex"] = { 1, .6, .6 }
        meta["layer"] = 2
      end

      -- tint low level quests grey
      if quests[id]["lvl"] and quests[id]["lvl"] + 10 < plevel then
        meta["texture"] = pfQuestConfig.path.."\\img\\available"
        meta["vertex"] = { 1, 1, 1 }
        meta["layer"] = 2
      end

      -- tint event quests as blue
      if quests[id]["event"] then
        meta["texture"] = pfQuestConfig.path.."\\img\\available"
        meta["vertex"] = { .2, .8, 1 }
        meta["layer"] = 2
      end

      -- iterate over all questgivers
      if quests[id]["start"] then
        -- units
        if quests[id]["start"]["U"] then
          meta["QTYPE"] = "NPC_START"
          for _, unit in pairs(quests[id]["start"]["U"]) do
            if units[unit] and strfind(units[unit]["fac"] or pfaction, pfaction) then
              maps = pfDatabase:SearchMobID(unit, meta, maps)
            end
          end
        end

        -- objects
        if quests[id]["start"]["O"] then
          meta["QTYPE"] = "OBJECT_START"
          for _, object in pairs(quests[id]["start"]["O"]) do
            if objects[object] and strfind(objects[object]["fac"] or pfaction, pfaction) then
              maps = pfDatabase:SearchObjectID(object, meta, maps)
            end
          end
        end
      end
    end
  end
end

-- AddCustomIcon
-- Helper function to add custom tracking node icons
--   id: negative for objects, positive for units
--   img: path to the image that is appended to root
--   root: optional, default: "Interface\\AddOns\\pfQuest"
function pfDatabase:AddCustomIcon(id, img, root)
  if not id or not img then return end

  root = root and root .. "\\" or pfQuestConfig.path .. "\\"

  local object = pfDB["objects"]["loc"][math.abs(id)]
  local unit = pfDB["units"]["loc"][math.abs(id)]

  if id < 0 and object then
    pfDatabase.icons[object] = root .. img
  elseif id > 0 and unit then
    pfDatabase.icons[unit] = root .. img
  end
end

function pfDatabase:FormatQuestText(questText)
  questText = string.gsub(questText, "$[Nn]", UnitName("player"))
  questText = string.gsub(questText, "$[Cc]", strlower(UnitClass("player")))
  questText = string.gsub(questText, "$[Rr]", strlower(UnitRace("player")))
  questText = string.gsub(questText, "$[Bb]", "\n")
  -- UnitSex("player") returns 2 for male and 3 for female
  -- that's why there is an unused capture group around the $[Gg]
  return string.gsub(questText, "($[Gg])([^:]+):([^;]+);", "%"..UnitSex("player"))
end

-- GetQuestIDs
-- Try to guess the quest ID based on the questlog ID
-- Returns possible quest IDs
function pfDatabase:GetQuestIDs(qid)
  local safe_title = compat.GetQuestLogTitle(qid)
  local safe_quest_id = pfQuest and pfQuest.TurtleSafeQuestID and pfQuest:TurtleSafeQuestID(nil, safe_title)
  if safe_quest_id then
    return { [1] = safe_quest_id }
  end

  if GetQuestLink then
    local questLink = GetQuestLink(qid)
      if questLink then
      local _, _, id = strfind(questLink, "|c.*|Hquest:([%d]+):([-]?[%d]+)|h%[(.*)%]|h|r")
      if id then return { [1] = tonumber(id) } end
    end
  end

  local oldID = GetQuestLogSelection()
  SelectQuestLogEntry(qid)
  local text, objective = GetQuestLogQuestText()
  local title, level, _, header = compat.GetQuestLogTitle(qid)
  SelectQuestLogEntry(oldID)

  if header or not title then return end
  local identifier = title .. ":" .. ( level or "") .. ":" .. ( objective or "") .. ":" .. ( text or "")

  -- always make sure the quest-cache exists
  pfQuest_questcache = pfQuest_questcache or {}

  if pfQuest_questcache[identifier] and pfQuest_questcache[identifier][1] then
    return pfQuest_questcache[identifier]
  end

  local _, race = UnitRace("player")
  local prace = pfDatabase:GetBitByRace(race)
  local _, class = UnitClass("player")
  local pclass = pfDatabase:GetBitByClass(class)

  local best = 0
  local results = {}

  local tcount = 0
  -- check if multiple quests share the same name
  for id, data in pairs(pfDB["quests"]["loc"]) do
    if quests[id] and data.T == title then tcount = tcount + 1 end
  end

  -- no title was found, run levenshtein on titles
  if tcount == 0 and title then
    local tlen = string.len(title)
    local tscore, tbest, ttitle = nil, math.min(tlen/2, 5), nil
    for id, data in pairs(pfDB["quests"]["loc"]) do
      if quests[id] and data.T then
        tscore = lev(data.T, title, tbest)
        if tscore < tbest then
          tbest = tscore
          ttitle = data.T
        end
      end
    end

    if not ttitle then
      -- return early on unknown quests.
      if not pfDatabase.localized then
        -- skip cache if locale-checks are still running
        return { title }
      else
        -- flag quest as unknown and return
        pfQuest_questcache[identifier] = { title }
        return pfQuest_questcache[identifier]
      end
    else
      -- set title to best result
      title = ttitle
    end
  end

  for id, data in pairs(pfDB["quests"]["loc"]) do
    local score = 0

    if quests[id] and data.T and data.T == title then
      -- low score for same name
      score = 1

      -- check level and set score
      if quests[id]["lvl"] == level then
        score = score + 8
      end

      -- check race and set score
      if quests[id]["race"] and ( bit.band(quests[id]["race"], prace) == prace ) then
        score = score + 8
      end

      -- check class and set score
      if quests[id]["class"] and ( bit.band(quests[id]["class"], pclass) == pclass ) then
        score = score + 8
      end

      -- if multiple quests share the same name, use levenshtein algorithm,
      -- to compare quest text distances in order to estimate the best quest id
      if tcount > 1 then
        -- check objective and calculate score
        score = score + max(24 - lev(pfDatabase:FormatQuestText(pfDB.quests.loc[id]["O"]), objective, 24),0)

        -- check description and calculate score
        score = score + max(24 - lev(pfDatabase:FormatQuestText(pfDB.quests.loc[id]["D"]), text, 24),0)
      end

      if score > best then best = score end
      results[score] = results[score] or {}
      if score > 0 then table.insert(results[score], id) end
    end
  end

  -- cache for next time
  pfQuest_questcache[identifier] = results[best]
  return results[best]
end

-- browser search related defaults and values
pfDatabase.lastSearchQuery = ""
pfDatabase.lastSearchResults = {["items"] = {}, ["quests"] = {}, ["objects"] = {}, ["units"] = {}}

-- BrowserSearch
-- Search for a list of IDs of the specified `searchType` based on if `query` is
-- part of the name or ID of the database entry it is compared against.
--
-- `query` must be a string. If the string represents a number, the search is
-- based on IDs, otherwise it compares names.
--
-- `searchType` must be one of these strings: "items", "quests", "objects" or
-- "units"
--
-- Returns a table and an integer, the latter being the element count of the
-- former. The table contains the ID as keys for the name of the search result.
-- E.g.: {{[5] = "Some Name", [231] = "Another Name"}, 2}
-- If the query doesn't satisfy the minimum search length requiered for its
-- type (number/string), the favourites for the `searchType` are returned.
function pfDatabase:BrowserSearch(query, searchType)
  local queryLength = strlen(query) -- needed for some checks
  local queryNumber = tonumber(query) -- if nil, the query is NOT a number
  local results = {} -- save results
  local resultCount = 0; -- count results

  -- Set the DB to be searched
  local minChars = 3
  local minInts = 1
  if (queryLength >= minChars) or (queryNumber and (queryLength >= minInts)) then -- make sure this is no fav display
    if ((queryLength > minChars) or (queryNumber and (queryLength > minInts)))
       and (pfDatabase.lastSearchQuery ~= "" and queryLength > strlen(pfDatabase.lastSearchQuery))
    then
      -- there are previous search results to use
      local searchDatabase = pfDatabase.lastSearchResults[searchType]
      -- iterate the last search
      for id, _ in pairs(searchDatabase) do
        local dbLocale = pfDB[searchType]["loc"][id]
        if (dbLocale) then
          local compare
          local search = query
          if (queryNumber) then
            -- do number search
            compare = tostring(id)
          else
            -- do name search
            search = strlower(query)
            if (searchType == "quests") then
              compare = strlower(dbLocale["T"])
            else
              compare = strlower(dbLocale)
            end
          end
          -- search and save on match
          if (strfind(compare, search)) then
            results[id] = dbLocale
            resultCount = resultCount + 1
          end
        end
      end
      return results, resultCount
    else
      -- no previous results, search whole DB
      if (queryNumber) then
        results = pfDatabase:GetIDByIDPart(query, searchType)
      else
        results = pfDatabase:GetIDByName(query, searchType, true)
      end
      local resultCount = 0
      for _,_ in pairs(results) do
        resultCount = resultCount + 1
      end
      return results, resultCount
    end
  else
    -- minimal search length not satisfied, reset search results and return favourites
    return pfBrowser_fav[searchType], -1
  end
end

local function LoadCustomData(always)
  -- table.getn doesn't work here :/
  local icount = 0
  for _,_ in pairs(pfQuest_server["items"]) do
    icount = icount + 1
  end

  if icount > 0 or always then
    for id, name in pairs(pfQuest_server["items"]) do
      pfDB["items"]["loc"][id] = name
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest: |cff33ffcc" .. icount .. "|cffffffff " .. pfQuest_Loc["custom items loaded."])
  end
end

local pfServerScan = CreateFrame("Frame", "pfServerItemScan", UIParent)
pfServerScan:SetWidth(200)
pfServerScan:SetHeight(100)
pfServerScan:SetPoint("TOP", 0, 0)
pfServerScan:Hide()

pfServerScan.scanID = 1
pfServerScan.max = 100000
pfServerScan.perloop = 100

pfServerScan.header = pfServerScan:CreateFontString("Caption", "LOW", "GameFontWhite")
pfServerScan.header:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
pfServerScan.header:SetJustifyH("CENTER")
pfServerScan.header:SetPoint("CENTER", 0, 0)

pfServerScan:RegisterEvent("VARIABLES_LOADED")
pfServerScan:SetScript("OnEvent", function()
  pfQuest_server = pfQuest_server or { }
  pfQuest_server["items"] = pfQuest_server["items"] or {}
  LoadCustomData()
end)

pfServerScan:SetScript("OnHide", function()
  ItemRefTooltip:Show()
  LoadCustomData(true)
end)

pfServerScan:SetScript("OnShow", function()
  this.scanID = 1
  pfQuest_server["items"] = {}
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest: " .. pfQuest_Loc["Server scan started..."])
end)

local ignore, custom_id, custom_skip = {}, nil, nil
pfServerScan:SetScript("OnUpdate", function()
  if this.scanID >= this.max then
    this:Hide()
    return
  end

  -- scan X items per update
  for i=this.scanID,this.scanID+this.perloop do
    pfServerScan.header:SetText(pfQuest_Loc["Scanning server for items..."] .. " " .. string.format("%.1f",100*i/this.max) .. "%")
    local link = "item:" .. i .. ":0:0:0"

    ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
    ItemRefTooltip:SetHyperlink(link)

    if ItemRefTooltipTextLeft1 and ItemRefTooltipTextLeft1:IsVisible() then
      local name = ItemRefTooltipTextLeft1:GetText()
      ItemRefTooltip:Hide()

      -- skip-wait for item retrieval
      if name == (RETRIEVING_ITEM_INFO or "") then

        if not ignore[i] then
          if custom_id == i and custom_skip >= 3 then
            -- ignore item and proceed
            ignore[i] = true
          elseif custom_id == i then
            -- try again up to 3 times
            custom_skip = custom_skip + 1
            return
          elseif custom_id ~= i then
            -- give it another try
            custom_id = i
            custom_skip = 0
            return
          end
        end
      end

      -- assign item to custom server table
      if not pfDB["items"]["loc"][i] and not ignore[i] then
        pfQuest_server["items"][i] = name
      end
    end
  end

  this.scanID = this.scanID+this.perloop
end)

function pfDatabase:ScanServer()
  pfServerScan:Show()
end

function pfDatabase:QueryServer()
  -- break here on incompatible versions
  if not QueryQuestsCompleted then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest: Option is not available on your server.")
    return
  end

  QueryQuestsCompleted()  -- Send the request to the server

  local frame = CreateFrame("Frame")  -- Create a new frame
  frame:RegisterEvent("QUEST_QUERY_COMPLETE")  -- Register the event on the frame

  local function OnQuestQueryComplete()
    frame:UnregisterEvent("QUEST_QUERY_COMPLETE")  -- Unregister the event once it's triggered

    -- Retrieve completed quests after the QUEST_QUERY_COMPLETE event
    local completedQuests = GetQuestsCompleted()

    if type(completedQuests) == "table" then
      for questID, _ in pairs(completedQuests) do
        pfQuest_history[questID] = { time(), UnitLevel("player") }
      end

      -- Reset all quest markers after processing completed quests
      pfQuest:ResetAll()
    elseif completedQuests == nil then
      -- Handle the case where GetQuestsCompleted() returned nil
      print("Error: GetQuestsCompleted() returned nil.")
    else
      -- Handle the case where GetQuestsCompleted() did not return a valid table
      print("Error: GetQuestsCompleted() did not return a valid table. Value: ", completedQuests)
    end
  end

  frame:SetScript("OnEvent", OnQuestQueryComplete)  -- Set the event handler
end
