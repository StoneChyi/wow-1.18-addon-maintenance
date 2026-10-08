-- Initialize all static variables
local loc = GetLocale()
local dbs = { "items", "quests", "quests-itemreq", "objects", "units", "zones", "professions", "areatrigger", "refloot", "objtext" }
local noloc = { "items", "quests", "objects", "units" }

-- Patch databases to merge TurtleWoW data
local function patchtable(base, diff)
  for k, v in pairs(diff) do
    if type(v) == "string" and v == "_" then
      base[k] = nil
    else
      base[k] = v
    end
  end
end

-- Detect a typo from old clients and re-apply the typo to the zones table
-- This is a workaround which is required until all clients are updated
for id, name in pairs({GetMapZones(2)}) do
  if name == "Northwind " then
    pfDB["zones"]["enUS-turtle"][5581] = "Northwind "
  end
end

local loc_core, loc_update
for _, db in pairs(dbs) do
  if pfDB[db]["data-turtle"] then
    patchtable(pfDB[db]["data"], pfDB[db]["data-turtle"])
  end

  for loc, _ in pairs(pfDB.locales) do
    if pfDB[db][loc] and pfDB[db][loc.."-turtle"] then
      loc_update = pfDB[db][loc.."-turtle"] or pfDB[db]["enUS-turtle"]
      patchtable(pfDB[db][loc], loc_update)
    end
  end
end

loc_core = pfDB["professions"][loc] or pfDB["professions"]["enUS"]
loc_update = pfDB["professions"][loc.."-turtle"] or pfDB["professions"]["enUS-turtle"]
if loc_update then patchtable(loc_core, loc_update) end

if pfDB["minimap-turtle"] then patchtable(pfDB["minimap"], pfDB["minimap-turtle"]) end
if pfDB["meta-turtle"] then patchtable(pfDB["meta"], pfDB["meta-turtle"]) end

-- Detect german client patch and switch some databases
if TURTLE_DE_PATCH then
  pfDB["zones"]["loc"] = pfDB["zones"]["deDE"] or pfDB["zones"]["enUS"]
  pfDB["professions"]["loc"] = pfDB["professions"]["deDE"] or pfDB["professions"]["enUS"]
end

-- Update bitmasks to include custom races
if pfDB.bitraces then
  pfDB.bitraces[256] = "Goblin"
  pfDB.bitraces[512] = "BloodElf"
end

-- Use turtle-wow database url
pfQuest.dburl = "https://database.turtlecraft.gg/?quest="

-- 户外世界地图（大陆 1/2）可达的区域集合，首次调用时枚举一次。
-- 乌龟服把自制的副本内部地图挂在大陆 3 及以后，这些区域号不该出现在户外小地图上。
local outdoor_maps
local function IsOutdoorMap(id)
  if not outdoor_maps then
    outdoor_maps = {}
    for cid in pairs({GetMapContinents()}) do
      if cid < 3 then
        for _, name in pairs({GetMapZones(cid)}) do
          local zid = pfMap:GetMapIDByName(name)
          if zid then outdoor_maps[zid] = true end
        end
      end
    end
  end
  return outdoor_maps[id]
end

-- Disable Minimap in custom dungeon maps
function pfMap:HasMinimap(map_id)
  if IsInInstance() then
    -- 副本/战场内：只有挂在真实大陆下的地图（如奥特兰克山谷）才画小地图图钉
    return GetCurrentMapContinent() < 3
  end

  -- 副本外：解析出的区域必须在户外世界地图上。副本入口周边的地块共用副本
  -- 区域号（如通灵学院门口），GetRealZoneText 会提前返回副本名，不挡住就会把
  -- 副本内部坐标按户外位置乱画在小地图上
  if map_id and not IsOutdoorMap(map_id) then
    return false
  end

  return true
end

-- 互斥组（close）也要挡住图钉。QuestFilter 只看 pfQuest_history[id] 本身，不看 close，
-- 而平时在游戏里交任务走的是 quest.lua 的任务栏 diff，只把交掉的那一个 id 写进
-- history，不展开互斥兄弟——只有手动跑 /db query 时 patchtable 里的 complete() 才沿
-- close 递归展开。结果就是二选一的任务做掉一条，另一条的 [!] 还挂在图上，要等下次
-- /db query 才消失。40801「耐心是关键」/ 40807「压力是关键」是一例（灰谷林歌神殿
-- 二选一），玩家反馈与此相符，但尚未逐项核对细节，标 [代码推导 + 待实测]。
--
-- 按 history 命中即隐藏是安全的：close 只由 ExclusiveGroup > 0 生成
-- （pfQuest/toolbox/extractor.lua:1116），语义就是"做了组里任一条，其余的都接不到了"；
-- ExclusiveGroup < 0 那种"整组都要做完"的不会进 close。全库 351 条。
-- 用手动包裹而不是 hooksecurefunc：1.12 的 hooksecurefunc 不支持表方法。
local _QuestFilter = pfDatabase.QuestFilter
function pfDatabase:QuestFilter(id, plevel, pclass, prace)
  if not _QuestFilter(self, id, plevel, pclass, prace) then return end

  local close = pfDB["quests"]["data"][id] and pfDB["quests"]["data"][id]["close"]
  if close then
    for _, qid in pairs(close) do
      -- 组里含自己，自己那条已经被 _QuestFilter 的 history 检查管了
      if qid ~= id and pfQuest_history[qid] then return end
    end
  end

  return true
end

-- Reload all pfQuest internal database shortcuts
pfDatabase:Reload()

-- 合并完立刻做一次完整垃圾回收。patchtable 是整条替换，基础库里被乌龟层盖掉的
-- 记录（约三成，本机实测近 30 MB）此刻全是垃圾；Lua 5.0 的回收阈值是上次存活量
-- 的两倍，不主动收就要等总量再翻一倍才会被清。此时还在加载界面，卡顿看不见。
-- 前后数值留给下面的 PLAYER_ENTERING_WORLD 用 /db debug 打印，方便真机核对。
local gc_before = gcinfo()
collectgarbage()
local gc_after = gcinfo()

local function strsplit(delimiter, subject)
  if not subject then return nil end
  local delimiter, fields = delimiter or ":", {}
  local pattern = string.format("([^%s]+)", delimiter)
  string.gsub(subject, pattern, function(c) fields[table.getn(fields)+1] = c end)
  return unpack(fields)
end

-- Complete quest id including all pre quests
local function complete(history, qid)
  -- ignore empty or broken questid
  if not qid or not tonumber(qid) then return end

  -- mark quest as complete
  local time = pfQuest_history[qid] and pfQuest_history[qid][1] or 0
  local level = pfQuest_history[qid] and pfQuest_history[qid][2] or 0
  history[qid] = { time, level }

  -- 上游这里还会沿 close 把互斥兄弟一并标成"已完成"。**已移除**：
  -- 那是在 QuestFilter 不看 close 的年代用来遮住兄弟任务 [!] 的变通，现在
  -- QuestFilter 自己会查互斥组（见本文件上方的包裹层），这一步就只剩坏处——
  -- 它往 history 里塞玩家其实没做过的 id，而下游任务的 pre 指向那些 id 时
  -- 就被误判为"前置已完成"，于是被放弃那条分支的第二环冒出一个接不到的 [!]。
  -- 实例：40801「耐心是关键」/ 40807「压力是关键」二选一，各带 5 环后续；
  -- 展开 close 会让 40802 与 40808 同时显示，其中一个必然是幽灵。
  -- 副作用：浏览器里互斥兄弟不再显示成"已完成"（它确实没做过），
  -- 但地图上照样被互斥组那一关挡住。[代码推导 + 待实测]

  -- make sure all prequests are marked as done aswell
  local prequests = pfDB["quests"]["data"][qid] and pfDB["quests"]["data"][qid]["pre"]
  if prequests then
    for _, qid in pairs(prequests) do
      if not history[qid] then complete(history, qid) end
    end
  end
end

-- Temporary workaround for a faction group translation error

-- Add function to query for quest completion
local query = CreateFrame("Frame")
query:Hide()

query:SetScript("OnEvent", function()
  if arg1 == "TWQUEST" then
    for _, qid in pairs({strsplit(" ", arg2)}) do
      complete(this.history, tonumber(qid))
    end
  end
end)

query:SetScript("OnShow", function()
  this.history = {}
  this.time = GetTime()
  this:RegisterEvent("CHAT_MSG_ADDON")
  SendChatMessage(".queststatus", "GUILD")
end)

query:SetScript("OnHide", function()
  this:UnregisterEvent("CHAT_MSG_ADDON")

  local count = 0
  for qid in pairs(this.history) do count = count + 1 end

  DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest|r: 共有 " .. count .. " 项任务被标记为已完成。")

  pfQuest_history = this.history
  this.history = nil

  pfQuest:ResetAll()
end)

query:SetScript("OnUpdate", function()
  if GetTime() > this.time + 3 then this:Hide() end
end)

function pfDatabase:QueryServer()
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest|r: 从服务器接收任务数据中...")
  query:Show()
end

-- Automatically clear quest cache if new turtle quests have been found
local updatecheck = CreateFrame("Frame")
updatecheck:RegisterEvent("PLAYER_ENTERING_WORLD")
updatecheck:SetScript("OnEvent", function()
  if pfDB["quests"]["data-turtle"] then
    -- count all known turtle-wow quests
    local count = 0
    for k, v in pairs(pfDB["quests"]["data-turtle"]) do
      count = count + 1
    end

    pfQuest:Debug("TurtleWoW loaded with |cff33ffcc" .. count .. "|r quests.")
    pfQuest:Debug("Post-merge GC: |cff33ffcc" .. gc_before .. "|r KB -> |cff33ffcc" .. gc_after .. "|r KB")

    -- check if the last count differs to the current amount of quests
    if not pfQuest_turtlecount or pfQuest_turtlecount ~= count then
      -- remove quest cache to force reinitialisation of all quests.
      pfQuest:Debug("New quests found. Reloading |cff33ffccCache|r")
      pfQuest_questcache = {}
    end

    -- write current count to the saved variable
    pfQuest_turtlecount = count
  end
end)

-- Returns the chain position and total length for a quest, or nil if not in a chain.
-- Walks backward via ["pre"] to the root, then forward via reverse-pre to count length.
-- Guards against loops with a visited set. Only fires for same-name chains.
local function GetQuestChainInfo(id)
  local qdata = pfDB["quests"]["data"]
  local qloc  = pfDB["quests"]["loc"]
  if not qdata or not qloc then return nil end

  local name = qloc[id] and qloc[id]["T"]
  if not name then return nil end

  -- Walk backward to find the root (quest with no pre, or whose pre has a different name)
  local pos     = 1
  local visited = { [id] = true }
  local current = id
  while true do
    local pre = qdata[current] and qdata[current]["pre"]
    if not pre then break end
    -- use first pre-req only (handles convergent chains gracefully)
    local preId = pre[1]
    if not preId or visited[preId] then break end
    local preName = qloc[preId] and qloc[preId]["T"]
    if preName ~= name then break end  -- chain boundary: different quest name
    visited[preId] = true
    pos     = pos + 1
    current = preId
  end
  local root = current

  -- Walk forward from root: find all quests whose pre chain leads back here
  -- Build a successor map for same-name quests only (scan once per hover is fine
  -- for chains that are at most ~10 long in practice)
  local chain  = { root }
  local seen   = { [root] = true }
  local tip    = root
  local safety = 0
  while safety < 20 do
    safety = safety + 1
    local found = nil
    for qid, qd in pairs(qdata) do
      if not seen[qid] and qd["pre"] then
        for _, preId in pairs(qd["pre"]) do
          if preId == tip then
            local qname = qloc[qid] and qloc[qid]["T"]
            if qname == name then
              found = qid
              break
            end
          end
        end
      end
      if found then break end
    end
    if not found then break end
    seen[found] = true
    table.insert(chain, found)
    tip = found
  end

  local total = table.getn(chain)
  if total < 2 then return nil end  -- single quest, not a chain worth labelling
  -- find our position in the ordered chain
  for i, qid in ipairs(chain) do
    if qid == id then return i, total end
  end
  return pos, total
end

-- Extend ShowExtendedTooltip to append chain position and "Introduced in: X".
-- Uses manual wrap since hooksecurefunc on table methods is not available in 1.12.
local _ShowExtendedTooltip = pfDatabase.ShowExtendedTooltip
function pfDatabase:ShowExtendedTooltip(id, tooltip, parent, anchor, offx, offy)
  _ShowExtendedTooltip(self, id, tooltip, parent, anchor, offx, offy)
  local tt = tooltip or GameTooltip

  local part, total = GetQuestChainInfo(id)
  if part then
    tt:AddLine("|cffaaaaaa" .. "Part " .. part .. " of " .. total .. "|r")
  end

  local patch = pfDB["quests"]["patch"] and pfDB["quests"]["patch"][id]
  if patch then
    if not part then tt:AddLine(" ") end
    tt:AddLine("|cffaaaaaa" .. "Introduced in: " .. patch .. "|r")
  end

  if part or patch then tt:Show() end
end

-- Wraps GameTooltip:SetText to append " +" to the NPC name for elite/rare-elite.
-- Guarded to only fire when hovering a pfQuest units result button.
local _GameTooltipSetText = GameTooltip.SetText
function GameTooltip:SetText(text, r, g, b, a, wordWrap)
  local focus = GetMouseFocus()
  if focus and focus.pfResultButton and focus.btype == "units" and focus.id then
    local rnk = pfDB["units"]["data"][focus.id] and pfDB["units"]["data"][focus.id]["rnk"]
    -- rnk "1" = elite, "2" = rare elite; both get a + on the name
    if (rnk == "1" or rnk == "2") and text == focus.name then
      text = text .. " +"
    end
  end
  _GameTooltipSetText(self, text, r, g, b, a, wordWrap)
end

-- Extend the NPC tooltip in the browser to append rank, coords (single-zone only)
-- and "Introduced in: X". Units are rendered inline in a local function in
-- browser.lua so we wrap GameTooltip:Show and check GetMouseFocus().
local _GameTooltipShow = GameTooltip.Show
function GameTooltip:Show()
  local focus = GetMouseFocus()
  if focus and focus.pfResultButton and focus.btype == "units" and focus.id then
    local id       = focus.id
    local unitData = pfDB["units"]["data"][id]
    local rnk      = unitData and unitData["rnk"]

    -- "Rare" label: rnk "2" = rare elite, "4" = rare
    if rnk == "2" or rnk == "4" then
      self:AddLine("|cffc0c0c0Rare|r")
    end

    -- Coords: only show when all spawn points are in exactly one zone
    if unitData and unitData["coords"] then
      local zoneId     = nil
      local singleZone = true
      local sumX, sumY, count = 0, 0, 0

      for _, c in pairs(unitData["coords"]) do
        local czone = c[3]
        if zoneId == nil then
          zoneId = czone
        elseif czone ~= zoneId then
          singleZone = false
          break
        end
        sumX  = sumX  + c[1]
        sumY  = sumY  + c[2]
        count = count + 1
      end

      if singleZone and count > 0 then
        local avgX = math.floor((sumX / count) * 10 + 0.5) / 10
        local avgY = math.floor((sumY / count) * 10 + 0.5) / 10
        self:AddLine("|cffaaaaaa" .. avgX .. ", " .. avgY .. "|r")
      end
    end

    -- "Introduced in:" patch tag
    local patch = pfDB["units"]["patch"] and pfDB["units"]["patch"][id]
    if patch then
      self:AddLine(" ")
      self:AddLine("|cffaaaaaa" .. "Introduced in: " .. patch .. "|r")
    end
  end
  _GameTooltipShow(self)
end
