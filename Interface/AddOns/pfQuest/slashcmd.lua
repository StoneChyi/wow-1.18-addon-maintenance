-- multi api compat
local compat = pfQuestCompat

SLASH_PFDB1, SLASH_PFDB2, SLASH_PFDB3, SLASH_PFDB4 = "/db", "/shagu", "/pfquest", "/pfdb"
SlashCmdList["PFDB"] = function(input, editbox)
  local params = {}
  local meta = { ["addon"] = "PFDB" }

  if (input == "" or input == nil) then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest (v" .. pfQuestConfig.version .. "):")
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff lock |cffcccccc - " .. pfQuest_Loc["Lock map tracker"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff tracker |cffcccccc - " .. pfQuest_Loc["Show map tracker"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff journal |cffcccccc - " .. pfQuest_Loc["Show quest journal"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff arrow |cffcccccc - " .. pfQuest_Loc["Show quest arrow"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff show |cffcccccc - " .. pfQuest_Loc["Show database interface"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff config |cffcccccc - " .. pfQuest_Loc["Show configuration interface"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff locale |cffcccccc - " .. pfQuest_Loc["Display addon locales"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff track <list>|cffcccccc - " .. pfQuest_Loc["Show available tracking lists"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff unit <unit> |cffcccccc - " .. pfQuest_Loc["Search unit"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff object <gameobject> |cffcccccc - " .. pfQuest_Loc["Search object"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff item <item> |cffcccccc - " .. pfQuest_Loc["Search loot"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff vendor <item> |cffcccccc - " .. pfQuest_Loc["Search item vendors"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff quest <questname> |cffcccccc - " .. pfQuest_Loc["Show specific quest"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff quests |cffcccccc - " .. pfQuest_Loc["Show all quests on map"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff clean |cffcccccc - " .. pfQuest_Loc["Clean Map"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff reset |cffcccccc - " .. pfQuest_Loc["Reset Map"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff scan |cffcccccc - " .. pfQuest_Loc["Scan the server for custom items"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff query |cffcccccc - " .. pfQuest_Loc["Query the server for completed quests"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff 等级 |cffcccccc - 查询当前地图的怪物等级（/db level）")
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff <等级> |cffcccccc - 查询当前地图指定等级的怪物（如 /db 31，范围 30-33 也算 31）")
    return
  end

  local commandlist = { }
  local command

  for command in compat.gfind(input, "[^ ]+") do
    table.insert(commandlist, command)
  end

  local arg1, arg2 = commandlist[1], ""

  -- handle whitespace mob- and item names correctly
  for i in pairs(commandlist) do
    if (i ~= 1) then
      arg2 = arg2 .. commandlist[i]
      if (commandlist[i+1] ~= nil) then
        arg2 = arg2 .. " "
      end
    end
  end

  -- argument: debug
  if (arg1 == "debug") then
    pfQuest_config.debug = not pfQuest_config.debug
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest Debug Mode: " .. ( pfQuest_config.debug and "|cff33ff33ON" or "|cffff3333OFF" ))
    pfQuest:Debug("Debug Mode Changed")
    return
  end

  -- argument: item
  if (arg1 == "item") then
    local maps = pfDatabase:SearchItem(arg2, meta, "LOWER")
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: vendor
  if (arg1 == "vendor") then
    local maps = pfDatabase:SearchVendor(arg2, meta, "LOWER")
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: unit
  if (arg1 == "unit") then
    local maps = pfDatabase:SearchMob(arg2, meta, "LOWER")
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: object
  if (arg1 == "object") then
    local maps = pfDatabase:SearchObject(arg2, meta, "LOWER")
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: quest
  if (arg1 == "quest") then
    local maps = pfDatabase:SearchQuest(arg2, meta, "LOWER")
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: quests
  if (arg1 == "quests") then
    local maps = pfDatabase:SearchQuests(meta)
    pfMap:UpdateNodes()
    return
  end

  -- argument: track
  if (arg1 == "track" or arg1 == "meta") then
    local list = commandlist[2]

    -- show available lists
    if not list or list == "" then
      local available = nil
      for list in pairs(pfDB["meta"]) do
        available = (available and available .. ", " or "") .. "\"|cff33ffcc"..list.."|r\""
      end

      DEFAULT_CHAT_FRAME:AddMessage(string.format(pfQuest_Loc["Available tracking targets are: %s. Or type \"|cff33ffcc/db track clean|r\" to untrack all."], available))
      return
    end

    -- clean all tracking results
    if commandlist[2] == "clean" then
      for list in pairs(pfDB["meta"]) do
        pfDatabase:TrackMeta(list, false)
      end

      return
    end

    -- load arguments into state
    local state = {
      min = commandlist[3],
      max = commandlist[4],
      faction = commandlist[3],
    }

    -- read skill for auto mines
    if (list == "mines" and commandlist[3] == "auto") then
      state.max = pfDatabase:GetPlayerSkill(186) or 0
      state.min = state.max - 100
    end

    -- read skill for auto herbs
    if (list == "herbs" and commandlist[3] == "auto") then
      state.max = pfDatabase:GetPlayerSkill(182) or 0
      state.min = state.max - 100
    end

    -- clean specific list
    if commandlist[3] == "clean" then
      state = nil
    end

    -- perform tracking
    local maps = pfDatabase:TrackMeta(list, state)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- warn about deprecated arguments
  local deprecated = {
    ["chests"] = true, ["taxi"] = true, ["flights"] = true, ["rares"] = true, ["mines"] = true, ["herbs"] = true
  }

  if deprecated[arg1] then
    DEFAULT_CHAT_FRAME:AddMessage(string.format(pfQuest_Loc["|cffffcc00WARNING:|r The command \"|cff33ffcc/db %s|r\" is deprecated and will be removed soon. Please use the \"|cff33ffcc/db track %s|r\" instead to achieve the same functionality."], arg1, arg1))
  end

  -- argument: chests (deprecated)
  if (arg1 == "chests") then
    local state = true

    if commandlist[2] == "clean" then
      state = nil
    end

    local maps = pfDatabase:TrackMeta("chests", state)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: taxi (deprecated)
  if (arg1 == "flights" or arg1 == "taxi") then
    local state = {
      faction = commandlist[2],
    }

    if commandlist[2] == "clean" then
      state = nil
    end

    local maps = pfDatabase:TrackMeta("flight", state)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: rares (deprecated)
  if (arg1 == "rares") then
    local state = {
      min = commandlist[2],
      max = commandlist[3],
    }

    if commandlist[2] == "clean" then
      state = nil
    end

    local maps = pfDatabase:TrackMeta("rares", state)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: mines (deprecated)
  if (arg1 == "mines") then
    local state = {
      min = commandlist[2],
      max = commandlist[3],
    }

    if (arg2 == "auto") then
      state.max = pfDatabase:GetPlayerSkill(186) or 0
      state.min = state.max - 100
    end

    if commandlist[2] == "clean" then
      state = nil
    end

    state = commandlist[2] == "clean" and nil or state
    local maps = pfDatabase:TrackMeta("mines", state)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: herbs (deprecated)
  if (arg1 == "herbs") then
    local state = {
      min = commandlist[2],
      max = commandlist[3],
    }

    if (arg2 == "auto") then
      state.max = pfDatabase:GetPlayerSkill(182) or 0
      state.min = state.max - 100
    end

    if commandlist[2] == "clean" then
      state = nil
    end

    state = commandlist[2] == "clean" and nil or state
    local maps = pfDatabase:TrackMeta("herbs", state)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: clean
  if (arg1 == "clean") then
    pfMap:DeleteNode("PFDB")
    pfMap:UpdateNodes()
    return
  end

  -- argument: reset
  if (arg1 == "reset") then
    pfQuest:ResetAll()
    return
  end

  -- argument: show
  if (arg1 == "show") then
    if pfBrowser then pfBrowser:Show() end
    return
  end

  -- argument: tracker
  if (arg1 == "tracker") then
    if pfQuest.tracker then pfQuest.tracker:Show() end
    return
  end

  -- argument: lock
  if (arg1 == "lock") then
    pfQuest_config.lock = not pfQuest_config.lock
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest Tracker: " .. ( pfQuest_config.lock and "Locked" or "Unlocked" ))
    return
  end

  -- argument: journal
  if (arg1 == "journal") then
    if pfJournal then pfJournal:Show() end
    return
  end

  -- argument: arrow
  if (arg1 == "arrow") then
    if pfQuest_config["arrow"] == "1" then
      pfQuest_config["arrow"] = "0"
      pfQuest.route.arrow:Hide()
    else
      pfQuest_config["arrow"] = "1"
    end
    return
  end

  -- argument: show
  if (arg1 == "config") then
    if pfQuestConfig then pfQuestConfig:Show() end
    return
  end

  -- argument: locale
  if (arg1 == "locale") then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc" .. pfQuest_Loc["Locales"] .. "|r:" .. pfDatabase.dbstring)
    return
  end

  -- argument: scan
  if (arg1 == "scan") then
    pfDatabase:ScanServer()
    return
  end

    -- argument: query
  if (arg1 == "query") then
    pfDatabase:QueryServer()
    return
  end

  -- argument: level query against current map (e.g. /db 31)
  if (tonumber(arg1)) then
    local target = tonumber(arg1)
    local realZone = GetRealZoneText()
    local mapID = pfMap:GetMapIDByName(realZone)

    -- fallback: use the currently opened world map zone
    if not mapID then
      mapID = pfMap:GetMapID(GetCurrentMapContinent(), GetCurrentMapZone())
    end

    if not mapID then
      DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00pfQuest|r: 无法确定当前地图，请确认你位于一张有效地图上。")
      return
    end

    local zoneName = pfMap:GetMapNameByID(mapID) or realZone
    local seen = {}
    local mobs = {}

    for id, unit in pairs(pfDB["units"]["data"]) do
      local coords = unit["coords"]
      if coords then
        for _, coord in pairs(coords) do
          if coord[3] == mapID then
            local lvl = unit["lvl"]
            if lvl then
              local minlvl, maxlvl = string.match(lvl, "^(%d+)%s*-?%s*(%d*)$")
              minlvl = tonumber(minlvl)
              maxlvl = tonumber(maxlvl) or minlvl
              if minlvl and target >= minlvl and target <= maxlvl then
                local name = pfDB["units"]["loc"][id] or UNKNOWN
                local key = id .. "@" .. name
                if not seen[key] then
                  seen[key] = true
                  table.insert(mobs, { id = id, name = name, lvl = lvl })
                end
              end
            end
            break
          end
        end
      end
    end

    table.sort(mobs, function(a, b) return a.name < b.name end)

    if table.getn(mobs) == 0 then
      DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "|cffffcc00pfQuest|r: 当前地图 |cff33ffcc%s|r 没有找到 %d 级的怪物。",
        zoneName, target))
      return
    end

    if pfBrowser then
      DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "|cffffcc00pfQuest|r: 已在浏览器中按 %d 级筛选当前地图 |cff33ffcc%s|r 的怪物（搜索栏输入数字亦可）。",
        target, zoneName))
      -- reuse the browser's own search box, which refreshes reliably
      pfBrowser:Show()
      pfBrowser.input:SetText(tostring(target))
    else
      DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "|cffffcc00pfQuest|r: 当前地图 |cff33ffcc%s|r 的 %d 级怪物（共 %d 种）：",
        zoneName, target, table.getn(mobs)))
      for _, mob in pairs(mobs) do
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s |cff555555等级|r %s", mob.name, mob.lvl))
      end
    end
    return
  end

  -- argument: mob levels of current map
  if (arg1 == "等级" or arg1 == "level") then
    local realZone = GetRealZoneText()
    local mapID = pfMap:GetMapIDByName(realZone)

    -- fallback: use the currently opened world map zone
    if not mapID then
      mapID = pfMap:GetMapID(GetCurrentMapContinent(), GetCurrentMapZone())
    end

    if not mapID then
      DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00pfQuest|r: 无法确定当前地图，请确认你位于一张有效地图上。")
      return
    end

    local zoneName = pfMap:GetMapNameByID(mapID) or realZone
    local seen = {}
    local mobs = {}

    for id, unit in pairs(pfDB["units"]["data"]) do
      local coords = unit["coords"]
      if coords then
        for _, coord in pairs(coords) do
          if coord[3] == mapID then
            local name = pfDB["units"]["loc"][id] or UNKNOWN
            local lvl = unit["lvl"] or UNKNOWN
            local key = id .. "@" .. name
            if not seen[key] then
              seen[key] = true
              table.insert(mobs, { id = id, name = name, lvl = lvl })
            end
            break
          end
        end
      end
    end

    table.sort(mobs, function(a, b)
      local la = tonumber(string.match(a.lvl, "%d+")) or 0
      local lb = tonumber(string.match(b.lvl, "%d+")) or 0
      if la == lb then return a.name < b.name end
      return la < lb
    end)

    if table.getn(mobs) == 0 then
      DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00pfQuest|r: 当前地图 |cff33ffcc" .. zoneName .. "|r 没有找到怪物数据。")
      return
    end

    DEFAULT_CHAT_FRAME:AddMessage(string.format(
      "|cffffcc00pfQuest|r: 已在浏览器中显示当前地图 |cff33ffcc%s|r 的怪物等级（共 %d 种，点击可在地图标记）。",
      zoneName, table.getn(mobs)))

    if pfBrowser and pfBrowser.ShowList then
      pfBrowser:ShowList(mobs, "units", "Units")
    else
      -- fallback: chat list if the browser is not available
      for _, mob in pairs(mobs) do
        local minlvl = tonumber(string.match(mob.lvl, "%d+")) or 0
        local color = minlvl > 0 and pfMap:HexDifficultyColor(minlvl) or "|cffaaaaaa"
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s |cff555555等级|r %s%s|r",
          mob.name, color, mob.lvl))
      end
    end
    return
  end

  -- argument: <text>
  if (type(arg1)=="string") then
    if pfBrowser then
      pfBrowser:Show()
      pfBrowser.input:SetText((string.gsub(string.format("%s %s",arg1,arg2),"^%s*(.-)%s*$", "%1")))
    end
    return
  end
end
