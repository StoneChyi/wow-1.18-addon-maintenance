-- multi api compat
local compat = pfQuestCompat

-- fake the pfQuest minimap node names to Gatherer names,
-- if any minimap-breaking addon collector is found.
local nodename = "pfMiniMapPin"
local minimapbreakers = {
  ["ElvUI_MinimapButtons"] = true,
  ["MBB"] = true,
}

local compatnamefake = CreateFrame("Frame")
compatnamefake:RegisterEvent("PLAYER_ENTERING_WORLD")
compatnamefake:SetScript("OnEvent", function()
  -- only run once on login
  this:UnregisterAllEvents()

  -- scan through all addons to identify button collectors
  for i=1, GetNumAddOns() do
    local name, title, notes, enabled = GetAddOnInfo(i)
    if enabled and minimapbreakers[name] then
      nodename = "GatherNoteCompatFake"
    end
  end
end)

-- checking for control key is very time expensive in 1.12
-- this loop puts it into one place and only updates it every .2 seconds
-- it also only updates the key if the mouse is over a relevant frame
local controlkey = CreateFrame("Frame", "pfQuestControlKey", UIParent)
controlkey:SetScript("OnUpdate", function()
  if ( this.throttle or .2) > GetTime() then return else this.throttle = GetTime() + .2 end
  if WorldMapFrame:IsShown() and MouseIsOver(WorldMapFrame) or MouseIsOver(pfMap.drawlayer) then
    controlkey.pressed = IsControlKeyDown()
  end
end)

local validmaps = setmetatable({},{__mode="kv"})
local rgbcache = setmetatable({},{__mode="kv"})
local minimap_sizes = pfDB["minimap"]
local minimap_zoom = {
  [0] = { [0] = 300,
          [1] = 240,
          [2] = 180,
          [3] = 120,
          [4] = 80,
          [5] = 50,
         },

  [1] = { [0] = 466 + 2/3,
          [1] = 400,
          [2] = 333 + 1/3,
          [3] = 266 + 2/6,
          [4] = 200,
          [5] = 133 + 1/3,
        },
}

local unifiedcache = {}

-- used to store/cache combined meta data across nodes of
-- the same kind to avoid duplicating data for each pin
-- the objects here get directly attached to the pfMap nodes
-- 按 addon/标题分桶，键法与 pfMap.nodes 一致，DeleteNode 才能连它一起清掉。
-- 摊平成一张表时它清不掉：目标一变就重建节点，AddNode 命中旧条目会原样复用旧对象，
-- 新算出的 item/droprate 全被丢弃，图钉标签停在上一次那件物品上。
local similar_nodes = {}

local function IsEmpty(tabl)
  for k,v in pairs(tabl) do
    return false
  end
  return true
end

local layers = {
  -- regular icons
  [pfQuestConfig.path.."\\img\\available"]          = 1,
  [pfQuestConfig.path.."\\img\\available_c"]        = 2,
  [pfQuestConfig.path.."\\img\\complete"]           = 3,
  [pfQuestConfig.path.."\\img\\complete_c"]         = 4,
  [pfQuestConfig.path.."\\img\\icon_vendor"]        = 5,
  [pfQuestConfig.path.."\\img\\fav"]                = 6,

  -- cluster textures
  [pfQuestConfig.path.."\\img\\cluster_item"]       = 9,
  [pfQuestConfig.path.."\\img\\cluster_mob"]        = 9,
  [pfQuestConfig.path.."\\img\\cluster_misc"]       = 9,
  [pfQuestConfig.path.."\\img\\cluster_mob_mono"]   = 9,
  [pfQuestConfig.path.."\\img\\cluster_item_mono"]  = 9,
  [pfQuestConfig.path.."\\img\\cluster_misc_mono"]  = 9,

  -- obj.T 对话、obj.A 探索
  [pfQuestConfig.path.."\\img\\cluster_talk"]         = 9,
  [pfQuestConfig.path.."\\img\\cluster_talk_mono"]    = 9,
  [pfQuestConfig.path.."\\img\\cluster_explore"]      = 9,
  [pfQuestConfig.path.."\\img\\cluster_explore_mono"] = 9,
}

-- 同一个 (名字, 任务, 地图) 只有一个鼠标提示键，这里定优先级，越小越先。
-- 目标节点压过任务给予/交付标记：接了任务之后玩家要看的是"现在该做什么"，
-- 不是那个还不能交的感叹号。同为目标节点时，本体压过借坐标的召唤节点。
local function TooltipRank(node)
  if node["texture"] then return 2 end
  return node["spawnalias"] and 1 or 0
end

local function GetLayerByTexture(tex)
  if layers[tex] then return layers[tex] else return 1 end
end

local function minimap_indoor()
  local tempzoom = 0
	local state = 1
	if GetCVar("minimapZoom") == GetCVar("minimapInsideZoom") then
		if GetCVar("minimapInsideZoom")+0 >= 3 then
			pfMap.drawlayer:SetZoom(pfMap.drawlayer:GetZoom() - 1)
			tempzoom = 1
		else
			pfMap.drawlayer:SetZoom(pfMap.drawlayer:GetZoom() + 1)
			tempzoom = -1
		end
	end

	if GetCVar("minimapInsideZoom")+0 == pfMap.drawlayer:GetZoom() then
    state = 0
  end

  pfMap.drawlayer:SetZoom(pfMap.drawlayer:GetZoom() + tempzoom)
	return state
end

local function str2rgb(text)
  if not text then return 1, 1, 1 end
  if pfQuest_colors[text] then return unpack(pfQuest_colors[text]) end
  if rgbcache[text] then return unpack(rgbcache[text]) end
  local counter = 1
  local l = string.len(text)
  for i = 1, l, 3 do
    counter = compat.mod(counter*8161, 4294967279) +
        (string.byte(text,i)*16776193) +
        ((string.byte(text,i+1) or (l-i+256))*8372226) +
        ((string.byte(text,i+2) or (l-i+256))*3932164)
  end
  local hash = compat.mod(compat.mod(counter, 4294967291),16777216)
  local r = (hash - (compat.mod(hash,65536))) / 65536
  local g = ((hash - r*65536) - ( compat.mod((hash - r*65536),256)) ) / 256
  local b = hash - r*65536 - g*256
  rgbcache[text] = { r / 255, g / 255, b / 255 }
  return unpack(rgbcache[text])
end

local fpsmod, step
local function NodeAnimate(self, zoom, alpha, fps)
  local cur_zoom = self:GetWidth()
  local cur_alpha = self:GetAlpha()
  local change = nil
  self:EnableMouse(true)
  fpsmod = math.min(2/fps, 2)
  step = fpsmod/10

  -- update size
  if math.abs(cur_zoom - zoom) < 3 then
    self:SetWidth(zoom)
    self:SetHeight(zoom)
  elseif cur_zoom < zoom then
    self:SetWidth(cur_zoom + fpsmod)
    self:SetHeight(cur_zoom + fpsmod)
    change = true
  elseif cur_zoom > zoom then
    self:SetWidth(cur_zoom - fpsmod)
    self:SetHeight(cur_zoom - fpsmod)
    change = true
  end

  -- update alpha
  if math.abs(cur_alpha - alpha) < step then
    self:SetAlpha(alpha)

    -- disable mouse on hidden
    if alpha < .1 then
      self:EnableMouse(nil)
    end
  elseif cur_alpha < alpha then
    self:SetAlpha(cur_alpha + step)
    change = true
  elseif cur_alpha > alpha then
    self:SetAlpha(cur_alpha - step)
    change = true
  end

  return change
end

-- put player position above everything on worldmap
for k, v in pairs({WorldMapFrame:GetChildren()}) do
  if v:IsObjectType("Model") and not v:GetName() then
    if string.find(strlower(v:GetModel()), "interface\\minimap\\minimaparrow") then
      v:SetFrameLevel(255)
      break
    end
  end
end

pfMap = CreateFrame("Frame", "pfQuestMap", WorldFrame)
pfMap.str2rgb = str2rgb
pfMap.tooltips = {}
pfMap.nodes = {}
pfMap.pins = {}
pfMap.mpins = {}
pfMap.drawlayer = Minimap
pfMap.unifiedcache = unifiedcache

pfMap.minimap_indoor = minimap_indoor
pfMap.minimap_zoom = minimap_zoom
pfMap.minimap_sizes = minimap_sizes

-- 无坐标目标的提示登记：只进 pfMap.tooltips，不建图钉、不进 unifiedcache、
-- 不碰 queue_update。zone 键用 "*"，展示端在当前地图没有同名真节点时回退到它。
-- 库里 0 刷点不等于游戏里没有（上游导出会丢刷点），这批实体玩家指得到，
-- 指到就该有话说。
function pfMap:AddTooltipEntry(meta)
  if not meta or not meta["title"] or not meta["spawn"] then return end

  local name, title = meta["spawn"], meta["title"]
  pfMap.tooltips[name] = pfMap.tooltips[name] or {}
  pfMap.tooltips[name][title] = pfMap.tooltips[name][title] or {}

  local held = pfMap.tooltips[name][title]["*"]
  if held and held.spawnid == meta["spawnid"] then
    -- 同一目标再次登记：只可能是同任务的另一件掉落物，并进 item 表
    --（与 AddNode 的同坐标并单逻辑对齐；droprate 保留首件的，同样与图钉一致）
    if meta["item"] then
      for _, have in pairs(held.item) do
        if have == meta["item"] then return end
      end
      table.insert(held.item, meta["item"])
    end
    return
  end

  local node = {}
  for k, v in pairs(meta) do node[k] = v end
  node.item = { [1] = meta["item"] }  -- ShowTooltip 期望 item 恒为表，同 AddNode
  pfMap.tooltips[name][title]["*"] = node
end

pfMap.tooltip = CreateFrame("Frame" , "pfMapTooltip", GameTooltip)
pfMap.tooltip:SetScript("OnShow", function()
  if pfMap.tooltip_lock then return end
  pfMap.tooltip_lock = true

  local focus = GetMouseFocus()
  -- abort on pfQuest nodes
  if focus and focus.title then pfMap.tooltip_lock = nil return end
  -- abort on quest timers
  if focus and focus.GetName and strsub((focus:GetName() or ""),0,10) == "QuestTimer" then pfMap.tooltip_lock = nil return end
  -- abort if tooltips are disabled
  if pfQuest_config.showtooltips == "0" then pfMap.tooltip_lock = nil return end

  local name = getglobal("GameTooltipTextLeft1") and getglobal("GameTooltipTextLeft1"):GetText() or "__NONE__"
  local zone = pfMap:GetMapID(GetCurrentMapContinent(), GetCurrentMapZone())

  -- remove all colors from received tooltip text
  name = string.gsub(name, "|c%x%x%x%x%x%x%x%x", "")
  name = string.gsub(name, "|r", "")

  -- 鼠标指的是单位还是场景物。1.12 原生：mouseover 令牌与 UnitExists 都不依赖
  -- 任何 DLL（SuperWoWhook / nampower 只补了写入侧的 SetMouseoverUnit）。
  -- 场景物不是单位，指向它时为 nil——召唤源与被召唤者同名时只能靠这个分开。
  local isunit = UnitExists("mouseover") and 1 or nil

  if pfMap.tooltips[name] then
    for title, obj in pairs(pfMap.tooltips[name]) do
      -- 当前地图有真节点用真节点；没有时回退到无坐标目标的通配条目。
      -- 开关只拦回退这一步，真节点提示不受影响，切开关即时生效无需重查。
      local node = obj[zone]
      if not node and pfQuest_config["tooltipnocoord"] ~= "0" then
        node = obj["*"]
      end
      if node then
        pfMap:ShowTooltip(node, GameTooltip, name, isunit)
        GameTooltip:Show()
      end
    end
  end

  pfMap.tooltip_lock = nil
end)

-- dummy function that can be used by extensions
-- to avoid drawing the minimap at some locations
function pfMap:HasMinimap()
  return true
end

function pfMap.tooltip:GetColor(min, max)
  local max = max or 1
  local min = min or max or 1

  local perc = min / max
  local r1, g1, b1, r2, g2, b2
  if perc <= 0.5 then
    perc = perc * 2
    r1, g1, b1 = 1, 0, 0
    r2, g2, b2 = 1, 1, 0
  else
    perc = perc * 2 - 1
    r1, g1, b1 = 1, 1, 0
    r2, g2, b2 = 0, 1, 0
  end
  r = r1 + (r2 - r1)*perc
  g = g1 + (g2 - g1)*perc
  b = b1 + (b2 - b1)*perc

  return r, g, b
end

function pfMap:HexDifficultyColor(level, force)
  if force and UnitLevel("player") < level then
    return "|cffff5555"
  else
    local c = pfQuestCompat.GetDifficultyColor(level)
    return string.format("|cff%02x%02x%02x", c.r*255, c.g*255, c.b*255)
  end
end

-- objtext 的一条映射是不是落在当前节点上。单位/场景物按 id 认（比名字准），
-- 物品按本地化名字认——节点上挂的是名字，没有 id。
local function ObjtextHitsNode(override, meta)
  local slot = meta["spawntype"] == pfQuest_Loc["Unit"] and "U"
            or meta["spawntype"] == pfQuest_Loc["Object"] and "O" or nil
  local targets = slot and meta["spawnid"] and pfDatabase:ObjtextTargets(override, slot)

  if targets then
    for _, target in pairs(targets) do
      if target == meta["spawnid"] then return true end
    end
  end

  return nil
end

local function ObjtextHitsItem(override, item)
  local targets = item and pfDatabase:ObjtextTargets(override, "I")

  if targets then
    for _, target in pairs(targets) do
      if pfDB["items"]["loc"][target] == item then return true end
    end
  end

  return nil
end

function pfMap:ShowTooltip(meta, tooltip, hovered, isunit)
  local catch = nil
  local catch_obj = nil
  local tooltip = tooltip or GameTooltip

  -- 召唤源与被召唤单位共用同一个节点，meta 分不出鼠标指的是哪一个。
  -- 指向召唤源本体时先说清它能召唤出谁，否则玩家只看到一条够不着的目标进度。
  -- 名字不同时靠名字就能分开。名字相同（41742 的火盆与怪都叫「达格诺斯之焰」）时
  -- 名字失效，改问 isunit：场景物不是单位，所以「同名且不是单位」即召唤源本体。
  -- isunit 只在同名这一种情况下当裁判——summon.U 的召唤源自己也是单位，它分不开，
  -- 那种形态必须继续走名字判据；放宽了反而会误伤本已正确的路径。
  local summonline = hovered and meta["spawnalias"] and meta["spawn"]
    and ( hovered ~= meta["spawn"]
       or ( meta["spawnalias"] == meta["spawn"] and not isunit ) )

  -- 四种召唤形态各说一句，措辞由 SummonHint 统一派发（箭头、图钉提示共用同一句）
  local summontext = summonline and pfDatabase:SummonHint(meta)

  -- add quest data
  if meta["quest"] then
    -- scan all quest entries for matches
    for qid=1, GetNumQuestLogEntries() do
      local qtitle, _, _, _, _, complete = compat.GetQuestLogTitle(qid)

      if meta["quest"] == qtitle then
        -- handle active quests
        local objectives = nil
        catch = true

        if not (pfQuest and pfQuest.TurtleUnsafeQuest and pfQuest:TurtleUnsafeQuest(meta["questid"], meta["quest"])) then
          objectives = GetNumQuestLeaderBoards(qid)
        end

        local symbol = ( complete or objectives == 0 ) and "|cff555555[|cffffcc00?|cff555555]|r " or "|cff555555[|cffffcc00!|cff555555]|r "
        tooltip:AddLine(symbol .. meta["quest"], 1, 1, 0)

        if summonline then
          tooltip:AddLine("|cffaaaaaa- |r" .. summontext, .7, .7, .7)
        end

        -- 召唤源身上不挂目标进度：它不掉那件东西、也不是要杀的那只，
        -- 进度归被召唤者与地图图钉。这里指路到此为止，只说"召唤谁"。
        -- 手工映射的目标文本，与 SearchQuestID 查的是同一张表
        local objtext = pfDB["objtext"] and pfDB["objtext"]["loc"][meta["questid"]]

        if objectives and not summonline then
          for i=1, objectives, 1 do
            local text, type, finished = GetQuestLogLeaderBoard(i, qid)

            -- 配了 objtext 的行，归谁由配置说了算，标签用服务端原文
            local prefix, num, needed = pfDatabase:ParseObjectiveCounter(text)
            local override = prefix and objtext and objtext[prefix]

            if type == "monster" then
              -- kill
              local i, j, monsterName, objNum, objNeeded = strfind(text, pfUI.api.SanitizePattern(QUEST_MONSTERS_KILLED))
              local label

              if override then
                -- 命中就顶替掉名字匹配；没命中说明这行归别的节点，不再按名字硬凑
                if ObjtextHitsNode(override, meta) then
                  label, monsterName, objNum, objNeeded = prefix, meta["spawn"], num, needed
                else
                  monsterName = nil
                end
              elseif not monsterName then
                -- 杀怪式匹配不上时按对话措辞认，整段前缀当标签，显示服务端原文
                local tnum, tneeded
                label, tnum, tneeded = pfDatabase:ParseTalkObjective(text, meta["spawn"])
                if label then monsterName, objNum, objNeeded = meta["spawn"], tnum, tneeded end
              end

              if monsterName and meta["spawn"] == monsterName then
                catch_obj = true
                local r,g,b = pfMap.tooltip:GetColor(objNum, objNeeded)
                tooltip:AddLine("|cffaaaaaa- |r" .. (label or monsterName) .. ": " .. objNum .. "/" .. objNeeded, r, g, b)
              end
            elseif meta["item"] and table.getn(meta["item"]) > 0 and type == "item" and meta["droprate"] then
              -- loot
              local i, j, itemName, objNum, objNeeded = strfind(text, pfUI.api.SanitizePattern(QUEST_OBJECTS_FOUND))

              for mid, item in pairs(meta["item"]) do
                if item == itemName or ObjtextHitsItem(override, item) then
                  catch_obj = true
                  objNum, objNeeded = objNum or num, objNeeded or needed
                  local r,g,b = pfMap.tooltip:GetColor(objNum, objNeeded)
                  local dr,dg,db = pfMap.tooltip:GetColor(tonumber(meta["droprate"]), 100)
                  local lootcolor = string.format("%02x%02x%02x", dr * 255,dg * 255, db * 255)
                  tooltip:AddLine("|cffaaaaaa- |r" .. (override and prefix or itemName) .. ": " .. objNum .. "/" .. objNeeded .. " |cff555555[|cff" .. lootcolor .. meta["droprate"] .. "%|cff555555]", r, g, b)
                end
              end
            elseif meta["item"] and table.getn(meta["item"]) > 0 and type == "item" and meta["sellcount"] then
              -- vendor
              local i, j, itemName, objNum, objNeeded = strfind(text, pfUI.api.SanitizePattern(QUEST_OBJECTS_FOUND))

              for mid, item in pairs(meta["item"]) do
                if item == itemName or ObjtextHitsItem(override, item) then
                  catch_obj = true
                  objNum, objNeeded = objNum or num, objNeeded or needed
                  local r,g,b = pfMap.tooltip:GetColor(objNum, objNeeded)
                  local sellcount = tonumber(meta["sellcount"]) > 0 and " |cff555555[|cffcccccc" .. meta["sellcount"] .. "x" .. "|cff555555]" or ""
                  tooltip:AddLine("|cffaaaaaa- |r" .. pfQuest_Loc["Buy"] .. ": " .. (override and prefix or itemName) .. ": " .. objNum .. "/" .. objNeeded .. sellcount, r, g, b)
                end
              end
            end
          end
        end
      end
    end

    if not catch then
      tooltip:AddLine("|cff555555[|cffffcc00!|cff555555]|r " .. meta["quest"], 1, 1, .7)
      if summonline then
        tooltip:AddLine("|cffaaaaaa- |r" .. summontext, .7, .7, .7)
      end
    end

    -- summonline 时目标循环被跳过，catch_obj 必然为空，这里同样得让开
    if not catch_obj and not summonline then
      -- handle inactive quests
      local catchFallback = nil

      if meta["item"] and meta["item"][1] and meta["droprate"] then
        for mid, item in pairs(meta["item"]) do
          catchFallback = true
          local dr, dg, db = pfMap.tooltip:GetColor(tonumber(meta["droprate"]), 100)
          local lootcolor = string.format("%02x%02x%02x", dr * 255, dg * 255, db * 255)
          tooltip:AddLine("|cffaaaaaa- |r" .. item .. " |cff555555[|cff" .. lootcolor .. meta["droprate"] .. "%|cff555555]", .7, .7, .7)
        end
      end

      if meta["item"] and meta["item"][1] and meta["sellcount"] then
        for mid, item in pairs(meta["item"]) do
          catchFallback = true
          local sellcount = tonumber(meta["sellcount"]) > 0 and " |cff555555[|cffcccccc" .. meta["sellcount"] .. "x" .. "|cff555555]" or ""
          tooltip:AddLine("|cffaaaaaa- |r" .. pfQuest_Loc["Buy"] .. ": " .. item .. sellcount, .7, .7, .7)
        end
      end

      -- obj.IR 的节点没有目标物品，兜底本来只报一遍鼠标底下这只怪的名字。
      -- 它手上有真正要说的话：对着它用哪件道具。
      -- 判据用 QTYPE 不用 itemreq：后者从不清空、会残留到同一任务的后续目标节点上。
      if not catchFallback and meta["itemreq"]
       and ( meta["QTYPE"] == "UNIT_OBJECTIVE_ITEMREQ" or meta["QTYPE"] == "OBJECT_OBJECTIVE_ITEMREQ" ) then
        catchFallback = true
        tooltip:AddLine("|cffaaaaaa- |r" .. string.format(pfQuest_Loc["Use |cff33ffcc%s|r"], meta["itemreq"]), .7, .7, .7)
      end

      if not catchFallback and meta["spawn"] and not meta["texture"] then
        catchFallback = true
        tooltip:AddLine("|cffaaaaaa- |r" .. (meta["spawntype"] and meta["spawntype"] == "Trigger" and pfQuest_Loc["Explore"] or meta["spawn"]), .7,.7,.7)
      end

      if not catchFallback and meta["texture"] and meta["qlvl"] then
        local texts = meta["questid"] and pfDB["quests"]["loc"][meta["questid"]] or nil

        if texts and texts["O"] and texts["O"] ~= "" then
          tooltip:AddLine(pfDatabase:FormatQuestText(texts["O"]),1,1,.9,true)
        end

        local qlvlstr = pfQuest_Loc["Level"] .. ": " .. pfMap:HexDifficultyColor(meta["qlvl"]) .. meta["qlvl"] .. "|r"
        local qminstr = meta["qmin"] and " / " .. pfQuest_Loc["Required"] .. ": " .. pfMap:HexDifficultyColor(meta["qmin"], true) .. meta["qmin"] .. "|r"  or ""
        tooltip:AddLine("|cffaaaaaa- |r" .. qlvlstr .. qminstr , .8,.8,.8)
      end
    end
  else
    -- handle non-quest objects
    if meta["item"][1] and meta["itemid"] and not meta["itemlink"] and not (pfQuest and pfQuest.TurtleUnsafeItem and pfQuest:TurtleUnsafeItem(meta["itemid"])) then
      local _, _, itemQuality = GetItemInfo(meta["itemid"])
      if itemQuality then
        local itemColor = "|c" .. string.format("%02x%02x%02x%02x", 255,
            ITEM_QUALITY_COLORS[itemQuality].r * 255,
            ITEM_QUALITY_COLORS[itemQuality].g * 255,
            ITEM_QUALITY_COLORS[itemQuality].b * 255)

        meta["itemlink"] = itemColor .."|Hitem:".. meta["itemid"] ..":0:0:0|h[".. meta["item"][1] .."]|h|r"
      end
    end

    if meta["sellcount"] then
      local item = meta["itemlink"] or "[" .. meta["item"][1] .. "]"
      local sellcount = tonumber(meta["sellcount"]) > 0 and " |cff555555[|cffcccccc" .. meta["sellcount"] .. "x" .. "|cff555555]" or ""
      tooltip:AddLine(pfQuest_Loc["Vendor"] .. ": " .. item .. sellcount, 1,1,1)
    elseif meta["item"][1] then
      local item = meta["itemlink"] or "[" .. meta["item"][1] .. "]"
      local r,g,b = pfMap.tooltip:GetColor(tonumber(meta["droprate"]), 100)
      tooltip:AddLine("|cffffffff" .. pfQuest_Loc["Loot"] .. ": " .. item ..  " |cff555555[|r" .. meta["droprate"] .. "%|cff555555]", r,g,b)
    end
  end

  tooltip:Show()
end

function pfMap:GetMapNameByID(id)
  id = tonumber(id)
  return pfDB["zones"]["loc"][id] or nil
end

function pfMap:GetMapIDByName(search)
  -- search 为 nil 时直接返回，省掉一次注定不命中的全表扫描（合并乌龟服数据后约 1520 条）。
  -- 大陆视图与地图初始化期 GetCurrentMapZone() 返回 0，GetMapID 里 list[0] 取不到名字，
  -- 正好每次都落到这个最贵的分支上。行为完全等价：表里不存在值为 nil 的条目。
  if not search then return nil end

  for id, name in pairs(pfDB["zones"]["loc"]) do
    if name == search then
      return id
    end
  end
end

function pfMap:ShowMapID(map)
  if map then
    if ToggleWorldMap then
      -- vanilla & tbc
      if not WorldMapFrame:IsShown() then
        ToggleWorldMap()
      end
    else
      -- wotlk
      WorldMapFrame:Show()
    end

    pfMap:SetMapByID(map)
    pfMap:UpdateNodes()
    return true
  end

  return nil
end

function pfMap:SetMapByID(id)
  local search = pfDB["zones"]["loc"][id]

  for cid, cname in pairs({GetMapContinents()}) do
    for mid, mname in pairs({GetMapZones(cid)}) do
      if mname == search then
        SetMapZoom(cid, mid)
        return
      end
    end
  end
end

-- 按地图【文件名】直接定 zone id。名字反查（GetMapIDByName）在同名地图上分不开，
-- 而文件名是唯一的，所以这张表优先于名字反查——见下面 GetMapID 里的取值顺序。
local customids = {
  ["AlteracValley"] = 2597,

  -- 手改 2026-09-06：木喉要塞的两张图在客户端大区列表里【同名】，都叫「木喉要塞」
  -- （中文客户端实测：GetMapZones(1) 的 17 与 18 两格都是「木喉要塞」），
  -- 靠 GetMapIDByName 无法区分，两张图会解析成同一个 id，落点互相画到对方图上。
  -- 上游 spawn_points 是分开的：zone 5640 "Timbermaw Hold" 251 个刷点、
  -- zone 1769 "Timbermaw Tunnels" 1 个（15395 纳菲恩）。实测站在纳菲恩旁边
  -- GetMapInfo() = "TimbermawTunnels"，与上游 1769 对上，故：
  ["TimbermawTunnels"] = 1769,
  ["TimbermawEntrance"] = 5640,
}

local map_zone_cache = { }
function pfMap:GetMapID(cid, mid)
  cid = cid or GetCurrentMapContinent()
  mid = mid or GetCurrentMapZone()

  -- GetMapZones() should always return the same amount
  -- of zones for each continent, so we can cache it to
  -- avoid further creations of the same table.
  if not map_zone_cache[cid] then
    map_zone_cache[cid] = { GetMapZones(cid) }
  end

  -- 手改 2026-09-06：customids 提到名字反查【之前】。原来是
  --   local id = pfMap:GetMapIDByName(name); id = id or customids[GetMapInfo()]
  -- 即只在名字查不到时才兜底。但同名地图的问题恰恰是名字【查得到、只是查错了】，
  -- 兜底轮不上。文件名唯一，所以登记过的图一律以 customids 为准。
  -- 对 AlteracValley 无影响：它本来就不在大区列表里，名字反查一直是 nil。
  local id = customids[GetMapInfo()]

  if not id then
    local list = map_zone_cache[cid]
    local name = list[mid]
    id = pfMap:GetMapIDByName(name)
  end

  return id
end

function pfMap:AddNode(meta)
  if not meta then return end
  if not meta["zone"] then return end
  if not meta["title"] then return end

  meta["description"] = pfDatabase:BuildQuestDescription(meta)

  local addon = meta["addon"] or "PFDB"
  local map = meta["zone"]
  local coords = meta["x"] .. "|" .. meta["y"]
  local title = meta["title"]
  local layer = GetLayerByTexture(meta["texture"])
  local spawn = meta["spawn"]
  local alias = meta["spawnalias"]
  local item = meta["item"]

  -- item 不进键：同坐标同任务的多件物品要并进同一个节点，见下面的合并分支
  local sindex = string.format("%s:%s:%s:%s",
    (map or ""), (coords or ""), (layer or ""), (spawn or ""))

  similar_nodes[addon] = similar_nodes[addon] or {}
  similar_nodes[addon][title] = similar_nodes[addon][title] or {}
  local bucket = similar_nodes[addon][title]

  -- use prioritized clusters
  if layer >= 9 and meta["priority"] then
    layer = layer + (10 - min(meta["priority"], 10))
  end

  if not pfMap.nodes[addon] then pfMap.nodes[addon] = {} end
  if not pfMap.nodes[addon][map] then pfMap.nodes[addon][map] = {} end
  if not pfMap.nodes[addon][map][coords] then pfMap.nodes[addon][map][coords] = {} end

  -- 召唤类目标把召唤源的名字也注册一份，指向召唤源本体同样显示任务信息
  local function register(name)
    pfMap.tooltips[name] = pfMap.tooltips[name] or {}
    pfMap.tooltips[name][title] = pfMap.tooltips[name][title] or {}
    local held = pfMap.tooltips[name][title][map]
    if not held or TooltipRank(bucket[sindex]) < TooltipRank(held) then
      pfMap.tooltips[name][title][map] = bucket[sindex]
    end
  end

  local occupied = pfMap.nodes[addon][map][coords][title]

  -- 借坐标的召唤节点让位给本体节点：两者都掉同一件任务物品时会落在同一个槽位，
  -- 谁先建谁赢的话，SearchItemID 遍历掉落来源的 pairs 顺序会随机吃掉本体那条。
  local yield = occupied and occupied["spawnalias"] and not alias

  -- 同一坐标同一任务、同一件物品：并进已有节点，不另建
  if occupied and not yield and item and table.getn(occupied.item) > 0 then
    for id, name in pairs(occupied.item) do
      if name == item then return end
    end
    table.insert(occupied.item, item)
    return
  end

  -- create new combined data node from given meta data
  if not bucket[sindex] then
    bucket[sindex] = {}
    for key, val in pairs(meta) do bucket[sindex][key] = val end
    bucket[sindex].item = { [1] = item }
  end

  -- 提示键与地图槽位分开结算：槽位只有一个（决定那儿画谁的图标），下面可能因为
  -- 图层不够而早退；提示键按 TooltipRank 归属，输了槽位也照样要登记。
  if spawn and title then register(spawn) end
  if alias and title and alias ~= spawn then register(alias) end

  if occupied and not yield and occupied.layer and layer and occupied.layer >= layer then
    -- identical node already exists, exit here
    return
  end

  -- set current node to combined node
  pfMap.nodes[addon][map][coords][title] = bucket[sindex]

  -- add node to unified cluster cache
  if not meta["cluster"] and not meta["texture"] then
    local node_index = meta.item or meta.spawn or UNKNOWN
    local x, y = tonumber(meta.x), tonumber(meta.y)

    -- create prerequisite table structure
    unifiedcache[title] = unifiedcache[title] or {}
    unifiedcache[title][map] = unifiedcache[title][map] or {}

    if not unifiedcache[title][map][node_index] then
      -- create new unified node from given meta data
      local unified_meta = {}
      for key, val in pairs(meta) do unified_meta[key] = val end

      -- save node to unified cache
      unifiedcache[title][map][node_index] = { meta = unified_meta, coords = {} }
    end

    -- append new coords to unified cache unified cache
    table.insert(unifiedcache[title][map][node_index].coords, { x, y })
  end

  pfMap.queue_update = GetTime()
end

function pfMap:GetNodes(addon, title)
  local nodes = {}

  if title and pfMap.nodes[addon] then
    for map, foo in pairs(pfMap.nodes[addon]) do
      for coords, node in pairs(pfMap.nodes[addon][map]) do
        if pfMap.nodes[addon][map][coords][title] then
          table.insert(nodes, pfMap.nodes[addon][map][coords][title])
        end
      end
    end
  end

  return nodes
end

function pfMap:DeleteNode(addon, title)
  -- remove tooltips
  if not addon then
    pfMap.tooltips = {}
  else
    for mk, mv in pairs(pfMap.tooltips) do
      for tk, tv in pairs(mv) do
        if title and tk == title then
          pfMap.tooltips[mk][tk] = nil
        elseif not title then
          -- tv 是 { [地图] = 节点 } 的中间表，addon 记在节点上而不是 tv 上。
          -- 旧判断 tv.addon 恒为 nil，按 addon 整删（ResetAll：切换追踪方式、
          -- /db query 补全历史）从来清不掉 tooltip——交付过的任务会以 [!]
          -- 滞留在 NPC 鼠标提示里。addon 回落 "PFDB" 与 AddNode 的默认一致。
          for map, node in pairs(tv) do
            if ( node.addon or "PFDB" ) == addon then tv[map] = nil end
          end
          if IsEmpty(tv) then pfMap.tooltips[mk][tk] = nil end
        end
      end
    end
  end

  -- remove nodes
  -- 节点对象缓存与 pfMap.nodes 同键，两边必须一起清，漏了它重建时会复用旧对象
  if not addon then
    pfMap.nodes = {}
    for k in pairs(similar_nodes) do similar_nodes[k] = nil end
  elseif not title then
    pfMap.nodes[addon] = {}
    similar_nodes[addon] = nil
  else
    if similar_nodes[addon] then similar_nodes[addon][title] = nil end

    if pfMap.nodes[addon] then
      for map, foo in pairs(pfMap.nodes[addon]) do
        for coords, node in pairs(pfMap.nodes[addon][map]) do
          if pfMap.nodes[addon][map][coords][title] then
            pfMap.nodes[addon][map][coords][title] = nil
            if IsEmpty(pfMap.nodes[addon][map][coords]) then
              pfMap.nodes[addon][map][coords] = nil
            end
          end
        end
      end
    end
  end

  pfMap.queue_update = GetTime()
end

function pfMap:NodeClick()
  if IsShiftKeyDown() then
    if this.questid and this.texture and this.layer < 5 then
      -- mark questnode as done
      pfQuest_history[this.questid] = { time(), UnitLevel("player") }
    end

    if this.node and this.title and this.node[this.title] then
      -- delete node from map
      pfMap:DeleteNode(this.node[this.title].addon, this.title)
    end

    pfQuest.updateQuestGivers = true
  elseif this.texture and pfQuest.route and
   (( pfQuest_config["routecluster"] == "1" and this.layer >= 9 ) or
    ( pfQuest_config["routeender"] == "1" and this.layer == 4) or
    ( pfQuest_config["routestarter"] == "1" and this.layer == 1) or
    ( pfQuest_config["routestarter"] == "1" and this.layer == 2))
  then
    -- set as arrow target priority
    pfQuest.route.SetTarget((not pfQuest.route.IsTarget(this) and this))
    pfMap.queue_update = GetTime()
  else
    -- switch color
    pfQuest_colors[this.color] = { str2rgb(this.color .. GetTime()) }
    pfMap.queue_update = GetTime()
  end
end

function pfMap:NodeEnter()
  -- wotlk: need to disable blop tooltips first
  if compat.client >= 30300 then
    WorldMapPOIFrame.allowBlobTooltip = false
  end

  local tooltip = this:GetParent() == WorldMapButton and WorldMapTooltip or GameTooltip
  tooltip:SetOwner(this, "ANCHOR_LEFT")
  this.spawn = this.spawn or UNKNOWN

  -- 召唤类节点画在召唤源的落点上，抬头就报召唤源：玩家要去找的是它，
  -- 被召唤者还不存在。等级/类型也跟着换成召唤源的，重生本来就是借来那条落点的。
  local src = this.summonsrc
  local name = src and src.name or this.spawn
  local id = src and src.id or this.spawnid
  local level = src and (src.lvl or pfQuest_Loc["N/A"]) or this.level
  local kind = src and ( src.kind == "U" and pfQuest_Loc["Unit"] or pfQuest_Loc["Object"] ) or this.spawntype

  -- 手改 2026-09-06：id 加 nil 判断。有节点带 spawn 却没有 spawnid（frame.spawnid 在
  -- map.lua:972 是无条件从 tab.spawnid 抄过来的，源 meta 缺这个字段时就是 nil），
  -- 开着 showids 指上去会 "attempt to concatenate local 'id'" 直接报错。
  -- 少显示一个 id 也比整条提示炸掉强；根因另查。
  tooltip:SetText(name..(pfQuest_config.showids == "1" and id and " |cffcccccc("..id..")|r" or ""), .3, 1, .8)
  tooltip:AddDoubleLine(pfQuest_Loc["Level"] .. ":", (level or UNKNOWN), .8,.8,.8, 1,1,1)
  tooltip:AddDoubleLine(pfQuest_Loc["Type"] .. ":", (kind or UNKNOWN), .8,.8,.8, 1,1,1)
  tooltip:AddDoubleLine(pfQuest_Loc["Respawn"] .. ":", (this.respawn or UNKNOWN), .8,.8,.8, 1,1,1)

  -- 传召唤源的名字当 hovered，图钉提示就与世界里指向召唤源时一字不差；
  -- 非召唤节点 spawnalias 为 nil，行为不变
  for title, meta in pairs(this.node) do
    pfMap:ShowTooltip(meta, tooltip, meta["spawnalias"])
  end

  -- add tooltip help if setting is enabled
  if pfQuest_config["tooltiphelp"] == "1" then
    local text = pfQuest_Loc["Use <Shift>-Click To Remove Nodes"]

    if this.cluster then
      text = pfQuest_Loc["Hold <Ctrl> To Hide Cluster"]
    elseif tooltip == GameTooltip then
      text = pfQuest_Loc["Hold <Ctrl> To Hide Minimap Nodes"]
    elseif not this.texture then
      text = pfQuest_Loc["Click Node To Change Color"]
    elseif this.questid and this.texture and this.layer < 5 then
      text = pfQuest_Loc["Use <Shift>-Click To Mark Quest As Done"]
    end

    -- update tooltip and sizes
    tooltip:AddLine(text, .6, .6, .6)
    tooltip:Show()
  end

  pfMap.highlight = pfQuest_config["mouseover"] == "1" and this.title
end

function pfMap:NodeLeave()
  -- wotlk: re-enable blop tooltips
  if compat.client >= 30300 then
    WorldMapPOIFrame.allowBlobTooltip = true
  end

  local tooltip = this:GetParent() == WorldMapButton and WorldMapTooltip or GameTooltip
  tooltip:Hide()
  pfMap.highlight = nil
end

function pfMap:BuildNode(name, parent)
  local f = CreateFrame("Button", name, parent)

  if parent == WorldMapButton then
    f.defalpha = tonumber(pfQuest_config["worldmaptransp"]) or 1
    f.defsize = 14
  else
    f.defalpha = tonumber(pfQuest_config["minimaptransp"]) or 1
    f.defsize = 14
    f.minimap = true
  end

  f:SetWidth(f.defsize)
  f:SetHeight(f.defsize)

  f.Animate = NodeAnimate
  f:SetScript("OnEnter", pfMap.NodeEnter)
  f:SetScript("OnLeave", pfMap.NodeLeave)

  f.tex = f:CreateTexture(nil, "BACKGROUND")
  f.tex:SetAllPoints(f)

  f.pic = f:CreateTexture(nil, "NORMAL")
  f.pic:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
  f.pic:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)

  f.hl = f:CreateTexture(nil, "BORDER")
  f.hl:SetTexture(pfQuestConfig.path.."\\img\\track")
  f.hl:SetPoint("TOPLEFT", f, "TOPLEFT", -5, 5)
  f.hl:SetWidth(12)
  f.hl:SetHeight(12)
  return f
end

pfMap.highlightdb = {}
function pfMap:UpdateNode(frame, node, color, obj, distance)
  -- clear node to title association table
  if pfMap.highlightdb[frame] then
    for k,v in pairs(pfMap.highlightdb[frame]) do
      pfMap.highlightdb[frame][k] = nil
    end
  else
    pfMap.highlightdb[frame] = {}
  end

  -- reset layer
  frame.layer = 0

  for title, tab in pairs(node) do
    pfMap.highlightdb[frame][title] = true

    tab.layer = GetLayerByTexture(tab.texture)

    -- use prioritized clusters
    if tab.cluster and tab.priority then
      tab.layer = tab.layer + (10 - min(tab.priority , 10))
    end

    if tab.spawn and ( tab.layer > frame.layer or not frame.spawn ) then
      frame.updateTexture = (frame.texture ~= tab.texture)
      frame.updateVertex = (frame.vertex ~= tab.vertex )
      frame.updateColor = (frame.color ~= tab.color)
      frame.updateLayer = (frame.layer ~= tab.layer)

      -- set title and texture to the entry with highest layer
      -- and add core information
      frame.layer       = tab.layer
      frame.spawn       = tab.spawn
      frame.spawnid     = tab.spawnid
      frame.spawnalias  = tab.spawnalias
      frame.summonsrc   = tab.summonsrc
      frame.spawntype   = tab.spawntype
      frame.respawn     = tab.respawn
      frame.level       = tab.level
      frame.questid     = tab.questid
      frame.texture     = tab.texture
      frame.vertex      = tab.vertex
      frame.title       = title
      frame.func        = tab.func
      frame.cluster     = tab.cluster
      frame.description = tab.description
      frame.priority    = tab.priority
      frame.quest       = tab.quest
      frame.qlvl        = tab.qlvl
      frame.itemreq     = tab.itemreq
      frame.arrow       = tab.arrow
      frame.icon        = tab.icon
      frame.fade_range  = tab.fade_range

      if pfQuest_config["spawncolors"] == "1" then
        frame.color = tab.spawn or tab.title
      else
        frame.color = tab.title
      end
    end
  end

  if ( frame.updateTexture or frame.updateVertex or not frame.tex:GetTexture() ) and frame.texture then
    frame.tex:SetTexture(frame.texture)
    frame.tex:SetVertexColor(1,1,1)
    frame.pic:Hide()

    if frame.updateVertex and frame.vertex then
      local r, g, b = unpack(frame.vertex)
      if r > 0 or g > 0 or b > 0 then
        frame.tex:SetVertexColor(r, g, b, 1)
      end
    end
  end

  if ( frame.updateColor or frame.updateTexture or not frame.tex:GetTexture() ) and not frame.texture then
    local r, g, b = str2rgb(frame.color)

    if (frame.title and pfQuest.icons[frame.title]) or frame.icon then
      local texture = (frame.title and pfQuest.icons[frame.title]) or frame.icon
      frame.pic:SetTexture(texture)
      frame.pic:Show()

      if obj == "minimap" then
        local halfsize = pfMap.drawlayer:GetWidth()/2
        local fade_range = frame.fade_range or 8
        local fade_in = halfsize/100*(fade_range-4)
        local fade_out = halfsize/100*(fade_range+4)
        local alpha = ((distance or fade_out) - fade_in) / (fade_out - fade_in)
        alpha = math.max(alpha, 0)
        alpha = math.min(alpha, 1)
        frame.pic:SetAlpha(alpha)
      end
    else
      frame.pic:Hide()
    end

    if obj == "minimap" and pfQuest_config["cutoutminimap"] == "1" then
      frame.tex:SetTexture(pfQuestConfig.path.."\\img\\nodecut")
      frame.tex:SetVertexColor(r,g,b,1)
    elseif obj ~= "minimap" and pfQuest_config["cutoutworldmap"] == "1" then
      frame.tex:SetTexture(pfQuestConfig.path.."\\img\\nodecut")
      frame.tex:SetVertexColor(r,g,b,1)
    else
      frame.tex:SetTexture(pfQuestConfig.path.."\\img\\node")
      frame.tex:SetVertexColor(r,g,b,1)
    end
  end

  if frame.updateLayer then
    frame:SetFrameLevel((obj == "minimap" and 4 or 112) + frame.layer)
  end

  if frame.updateTexture or frame.updateVertex or frame.updateColor or frame.updateLayer then
    frame:SetScript("OnClick", (frame.func or pfMap.NodeClick))
  end

  local highlight = frame.texture and pfMap.highlightdb[frame][pfMap.highlight] and true or nil
  local target = frame.texture and pfQuest.route and pfQuest.route.IsTarget(frame) or nil

  -- set default sizes for different node types
  frame.defsize = (frame.cluster or frame.layer == 4) and 18 or 14

  -- make the current route target visible
  if target then frame.hl:Show() else frame.hl:Hide() end

  -- reset frame size except for highlights
  if not highlight then
    frame:SetWidth(frame.defsize)
    frame:SetHeight(frame.defsize)
  end

  frame.node = node
end

function pfMap:UpdateNodes()
  pfQuest:Debug("Update Nodes")

  local color = pfQuest_config["spawncolors"] == "1" and "spawn" or "title"
  local map = pfMap:GetMapID(GetCurrentMapContinent(), GetCurrentMapZone())
  local i = 1

  -- reset tracker
  pfQuest.tracker.Reset()

  -- reset route
  pfQuest.route:Reset()

  -- refresh all nodes
  for addon, _ in pairs(pfMap.nodes) do
    if pfMap.nodes[addon][map] then
      for coords, node in pairs(pfMap.nodes[addon][map]) do
        if not pfMap.pins[i] then
          pfMap.pins[i] = pfMap:BuildNode("pfMapPin" .. i, WorldMapButton)
        end

        pfMap:UpdateNode(pfMap.pins[i], node, color)

        -- set position
        local _, _, x, y = strfind(coords, "(.*)|(.*)")

        -- write points to the route plan
        if ( pfQuest_config["routecluster"] == "1" and pfMap.pins[i].layer >= 9 ) or
          ( pfQuest_config["routeender"] == "1" and pfMap.pins[i].layer == 4) or
          ( pfQuest_config["routestarter"] == "1" and pfMap.pins[i].layer == 1 and pfMap.pins[i].texture) or
          ( pfQuest_config["routestarter"] == "1" and pfMap.pins[i].layer == 2) or
          pfMap.pins[i].arrow == true
        then
          pfQuest.route:AddPoint({ x, y, pfMap.pins[i] })
        end

        -- hide cluster nodes if set
        if pfQuest_config["showcluster"] == "0" and pfMap.pins[i].cluster then
          pfMap.pins[i]:Hide()
        -- hide individual quest spawns
        elseif pfQuest_config["showspawn"] == "0" and addon == "PFQUEST" and not pfMap.pins[i].texture then
          pfMap.pins[i]:Hide()
        else
          -- populate quest list on map
          for title, node in pairs(pfMap.pins[i].node) do
            pfQuest.tracker.ButtonAdd(title, node)
          end

          x = x / 100 * WorldMapButton:GetWidth()
          y = y / 100 * WorldMapButton:GetHeight()

          pfMap.pins[i]:ClearAllPoints()
          pfMap.pins[i]:SetPoint("CENTER", WorldMapButton, "TOPLEFT", x, -y)

          pfMap.pins[i]:Show()
        end

        i = i + 1
      end
    end
  end

  -- hide remaining pins
  for j=i, table.getn(pfMap.pins) do
    if pfMap.pins[j] then pfMap.pins[j]:Hide() end
  end

  -- 记录本次真正渲染的地图。写在渲染末尾而不是事件处理器里，所有调用路径
  -- （事件、0.25 秒防抖队列、追踪器/浏览器的直接调用）都会经过这里，
  -- 事件门槛就永远不会与画面脱节：即使本次读到的是过渡期的旧区域，
  -- 下一次 WORLD_MAP_UPDATE 带着落定后的区域进来，比较必然不等，立即重画纠正。
  pfMap.lastUpdateZone = map
  -- 地图已完成一次完整渲染，之后的换区就是用户的主动操作了
  pfMap.mapJustOpened = nil
end

local coord_cache = {}
function pfMap:UpdateMinimap()
  -- check for disabled minimap nodes
  if pfQuest_config["minimapnodes"] == "0" then
    return
  end

  -- hide all minimap nodes while shift is pressed
  if controlkey.pressed and MouseIsOver(pfMap.drawlayer) then
    this.xPlayer = nil

    for id, pin in pairs(pfMap.mpins) do
      pin:Hide()
    end

    return
  end

  -- hide nodes and skip further processing in dungeons
  local xPlayer, yPlayer = GetPlayerMapPosition("player")
  if xPlayer == 0 and yPlayer == 0 then
    for pins, pin in pairs(pfMap.mpins) do pin:Hide() end
    return
  end

  local mZoom = pfMap.drawlayer:GetZoom()
  xPlayer, yPlayer = xPlayer * 100, yPlayer * 100

  -- force refresh every second even without changed values, otherwise skip
  if this.xPlayer == xPlayer and this.yPlayer == yPlayer and this.mZoom == mZoom then
    if ( this.tick or 1) > GetTime() then return else this.tick = GetTime() + 1 end
  end

  this.xPlayer, this.yPlayer, this.mZoom = xPlayer, yPlayer, mZoom
  local color = pfQuest_config["spawncolors"] == "1" and "spawn" or "title"
  local mapID = pfMap:GetMapIDByName(GetRealZoneText())
  local mapZoom = minimap_zoom[minimap_indoor()][mZoom]
  local mapWidth = minimap_sizes[mapID] and minimap_sizes[mapID][1] or 0
  local mapHeight = minimap_sizes[mapID] and minimap_sizes[mapID][2] or 0

  if mapWidth == 0 or mapHeight == 0 then
    for pins, pin in pairs(pfMap.mpins) do pin:Hide() end
    return
  end

  local xScale = mapZoom / mapWidth
  local yScale = mapZoom / mapHeight

  local xDraw = pfMap.drawlayer:GetWidth() / xScale / 100
  local yDraw = pfMap.drawlayer:GetHeight() / yScale / 100

  local i = 1

  -- refresh all nodes
  for addon, data in pairs(pfMap.nodes) do
    -- hide minimap nodes in continent view
    if data[mapID] and minimap_sizes[mapID] and pfMap:HasMinimap(mapID) then
      for coords, node in pairs(data[mapID]) do
        local x, y
        if coord_cache[coords] then
          x, y = coord_cache[coords][1], coord_cache[coords][2]
        else
          local _, _, strx, stry = strfind(coords, "(.*)|(.*)")
          x, y = strx + 0, stry + 0
          coord_cache[coords] = { x, y }
        end

        local xPos = ( x - xPlayer) * xDraw
        local yPos = ( y - yPlayer) * yDraw

        if pfQuestCompat.rotateMinimap then
          -- TODO: this part is broken and does not work yet.
          local sinFacing = sin(pfQuestCompat.GetPlayerFacing())
          local cosFacing = cos(pfQuestCompat.GetPlayerFacing())

          local dx, dy = xPos, -yPos
          xPos = (dx * cosFacing) + (dy * sinFacing)
          yPos = -((-dx * sinFacing) + (dy * cosFacing))
        end

        local display = nil
        local distance = sqrt(xPos * xPos + yPos * yPos)

        if pfUI.minimap then
          display = ( abs(xPos) + 8 < pfMap.drawlayer:GetWidth() / 2 and abs(yPos) + 8 < pfMap.drawlayer:GetHeight()/2 ) and true or nil
        else
          display = ( distance + 8 < pfMap.drawlayer:GetWidth() / 2 ) and true or nil
        end

        if display then
          if not pfMap.mpins[i] then
            pfMap.mpins[i] = pfMap:BuildNode(nodename .. i, pfMap.drawlayer)
          end

          pfMap:UpdateNode(pfMap.mpins[i], node, color, "minimap", distance)

          pfMap.mpins[i].hl:Hide()

          if pfQuest_config["showclustermini"] == "0" and pfMap.mpins[i].cluster then
            pfMap.mpins[i]:Hide()
          elseif pfQuest_config["showspawnmini"] == "0" and addon == "PFQUEST" and not pfMap.mpins[i].texture then
            pfMap.mpins[i]:Hide()
          else
            pfMap.mpins[i]:ClearAllPoints()
            pfMap.mpins[i]:SetPoint("CENTER", pfMap.drawlayer, "CENTER", xPos, -yPos)
            pfMap.mpins[i]:Show()
          end

          i = i + 1
        end
      end
    end
  end

  -- hide remaining pins
  for j=i, table.getn(pfMap.mpins) do
    if pfMap.mpins[j] then pfMap.mpins[j]:Hide() end
  end
end

pfMap:RegisterEvent("ZONE_CHANGED")
pfMap:RegisterEvent("ZONE_CHANGED_NEW_AREA")
pfMap:RegisterEvent("MINIMAP_ZONE_CHANGED")
-- PLAYER_ENTERING_WORLD：登录/传送/进出副本时 ZONE_CHANGED* 不保证到达，
-- 关闭状态的世界地图需要靠它 SetMapToCurrentZone 重新同步，否则任务日志扫描
-- 产生的 AddNode 会按旧区域渲染，画出上一个区域的图钉。
pfMap:RegisterEvent("PLAYER_ENTERING_WORLD")
pfMap:RegisterEvent("WORLD_MAP_UPDATE")
pfMap:SetScript("OnEvent", function()
  -- set map to current zone when possible
  if event == "ZONE_CHANGED" or event == "MINIMAP_ZONE_CHANGED"
    or event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
    if not WorldMapFrame:IsShown() then
      SetMapToCurrentZone()
    end
  end

  -- 真正换区（ZONE_CHANGED_NEW_AREA 只在跨区时触发）或读图完成后强制作废门槛：
  -- "force" 不会等于任何渲染键（数字或 nil），下一次 WORLD_MAP_UPDATE 必定重画。
  -- 不依赖「过渡期两次取值恰好不同」这种运气，无论根因是序号碰撞还是地图未同步都能兜住。
  if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
    pfMap.lastUpdateZone = "force"
  end

  -- update nodes on world map changes
  -- 分情形结构取自上游 8.0.0 的 5ca49d2（防抖改造），刻意不引入其后 4da6aed 的
  -- playerZone/当前区域追踪——那套机制带着上游 issue #15 的追踪回归。
  if event == "WORLD_MAP_UPDATE" then
    -- 必须用 GetMapID 解析成「全局唯一」的区域 id，不能直接用 GetCurrentMapZone()：
    -- 后者只是当前大陆内部的序号（卡利姆多第 3 区和东部王国第 3 区都返回 3），
    -- 跨大陆移动到序号相同的区域时会被判成「没换区」，UpdateNodes 被吞 -> 旧图钉残留。
    -- 这个表达式与 UpdateNodes 内部逐字相同，保证门槛与渲染键永远一致。
    local newzone = pfMap:GetMapID(GetCurrentMapContinent(), GetCurrentMapZone())

    if newzone == nil then
      -- 大陆/世界视图、副本、解析不出名字的区域：渲染键为 nil，画面注定为空。
      -- 只在上一帧还有内容时清一次（清图钉、路线、追踪列表，与 7.0.1 原有行为一致），
      -- 之后这类视图互切不再反复触发。
      if pfMap.lastUpdateZone ~= nil then
        pfMap:UpdateNodes()
      end
    elseif pfMap.mapJustOpened then
      -- 开图瞬间这个事件会连发一大串，此时框架尺寸还没定型：立即渲染会把图钉
      -- 画到错误的位置，且随后的门槛判断会挡住纠正机会。改走 0.25 秒防抖，
      -- 等事件停了再画一次干净的（防抖队列在 OnUpdate 里消费）。
      pfMap.queue_update = GetTime()
    elseif newzone ~= pfMap.lastUpdateZone then
      -- 查看的区域变了（用户翻图或换区后的重新同步）：立即重画。
      -- 取消已排队的防抖——本次全量渲染已覆盖它要做的事。
      pfMap.queue_update = nil
      pfMap:UpdateNodes()
    end
  end
end)

local hlstate, shiftstate, transition, hidecluster, fps, resetmap
pfMap:SetScript("OnUpdate", function()
  -- handle highlights and animations
  if pfMap.queue_update or transition or pfMap.highlight ~= hlstate or shiftstate ~= hidecluster then
    hlstate, shiftstate, transition = pfMap.highlight, hidecluster, nil
    fps = math.max(.2, GetFramerate() / 30)

    for frame, data in pairs(pfMap.highlightdb) do
      local highlight = pfMap.highlightdb[frame][pfMap.highlight] and true or nil

      if hidecluster and frame.cluster then
        -- hide clusters
        transition = frame:Animate(frame.defsize, 0, fps) or transition
      elseif highlight then
        -- zoom node
        transition = frame:Animate((frame.texture and frame.defsize + 4 or frame.defsize), 1, fps) or transition
      elseif not highlight and pfMap.highlight then
        -- fade node
        transition = frame:Animate(frame.defsize, tonumber(pfQuest_config["nodefade"]) or 0.3, fps) or transition
      elseif frame.texture or frame.cluster then
        -- defaults for textured nodes
        transition = frame:Animate(frame.defsize, 1, fps) or transition
      else
        -- defaults
        transition = frame:Animate(frame.defsize, frame.defalpha, fps) or transition
      end
    end
  end

  -- limit all map updates to once per .05 seconds
  if ( this.throttle or .2) > GetTime() then return else this.throttle = GetTime() + .05 end

  -- process node updates if required
  if pfMap.queue_update and pfMap.queue_update + .25 < GetTime() then
    pfMap.queue_update = nil
    pfMap:UpdateNodes()
  end

  -- reset map to current zone once map is closed
  if WorldMapFrame:IsShown() then
    if not resetmap then
      -- 开图边沿：标记「刚打开」，让 WORLD_MAP_UPDATE 走防抖而不是立即渲染，
      -- 渲染完成后由 UpdateNodes 末尾清掉
      pfMap.mapJustOpened = true
    end
    resetmap = true
  elseif resetmap == true then
    SetMapToCurrentZone()
    resetmap = nil
  end

  -- refresh minimap
  pfMap:UpdateMinimap()

  -- update hidecluster detection
  if controlkey.pressed then
    hidecluster = MouseIsOver(WorldMapFrame)
  else
    hidecluster = nil
  end
end)

-- only hook for 3.3.5
if compat.client >= 30300 then
  -- Initialize a variable to track the previous clicked title
  local previousTitle = nil
  -- Highlight Map Quest Log Selection Nodes
  local pfHookWorldMapQuestFrame_OnMouseUp = WorldMapQuestFrame_OnMouseUp
  WorldMapQuestFrame_OnMouseUp = function(self)
    pfHookWorldMapQuestFrame_OnMouseUp(self)
    WorldMapBlobFrame:Hide()
    WorldMapFrame_ClearQuestPOIs()
    if not IsShiftKeyDown() then
      pfMap.highlight = nil
      local questLogIndex = GetQuestLogSelection()
      local title = GetQuestLogTitle(questLogIndex)

      if title then
        if previousTitle == title then
          -- Reset the highlight if the same title is clicked again
          pfMap.highlight = nil
          previousTitle = nil
        else
          -- Logic for highlighting nodes associated with the clicked quest
          pfMap.highlight = title
          previousTitle = title
          pfMap.queue_update = GetTime()
        end
      end
    end
  end
end
