-- pfQuest 桩环境：在桌面 Lua 里加载真实 database.lua 与 map.lua。见 README.md。
local HERE, HERE_N = string.gsub(debug.getinfo(1).source, "^@(.*)/[^/]*$", "%1")
if HERE_N == 0 then HERE = "." end
local ADDON = HERE .. "/.."

----------------------------------------------------------------------
-- Lua 5.0 兼容垫片：本机是 5.5
----------------------------------------------------------------------
if not table.getn then table.getn = function(t) return #t end end
if not table.setn then table.setn = function() end end
if not string.gfind then string.gfind = string.gmatch end
if not getfenv then getfenv = function() return _G end end
if not unpack then unpack = table.unpack end
strfind, strlen, strlower, strupper, strsub =
  string.find, string.len, string.lower, string.upper, string.sub
format, gsub, strrep = string.format, string.gsub, string.rep
max, min, floor, ceil, abs = math.max, math.min, math.floor, math.ceil, math.abs
mod = math.fmod
math.mod = math.fmod
bit = { band = function(a, b)
  local r, p = 0, 1
  while a > 0 and b > 0 do
    if math.fmod(a,2) == 1 and math.fmod(b,2) == 1 then r = r + p end
    a, b, p = floor(a/2), floor(b/2), p*2
  end
  return r
end }

NOW = 100
function GetTime() return NOW end
function time() return 1000000 end
function SecondsToTime(s) return tostring(s) .. "s" end

----------------------------------------------------------------------
-- 框架桩：大驼峰返回空函数（WoW 方法都是大驼峰），小写返回 nil（状态字段）
----------------------------------------------------------------------
local proto = {}
proto.__index = function(t, k)
  if type(k) == "string" and string.find(k, "^%u") then return function() end end
  return nil
end

local function mkframe(name)
  local f = setmetatable({}, proto)
  f.__name, f.__scripts, f.__events = name, {}, {}
  f.SetScript = function(s, e, fn) s.__scripts[e] = fn end
  f.GetScript = function(s, e) return s.__scripts[e] end
  f.RegisterEvent = function(s, e) s.__events[e] = true end
  f.UnregisterAllEvents = function(s) s.__events = {} end
  f.CreateFontString = function() return mkframe("fs") end
  f.CreateTexture = function() return mkframe("tex") end
  f.GetName = function(s) return s.__name end
  f.IsShown = function() return false end
  f.IsVisible = function() return false end
  f.GetText = function() return "" end
  f.GetParent = function() return nil end
  f.GetWidth = function() return 100 end
  f.GetHeight = function() return 100 end
  f.GetZoom = function() return 1 end
  return f
end
function CreateFrame(t, n, p) return mkframe(n or "anon") end

UIParent = mkframe("UIParent")
WorldFrame = mkframe("WorldFrame")
Minimap = mkframe("Minimap")
Minimap.GetChildren = function() return nil end
MinimapCluster = mkframe("MinimapCluster")
WorldMapFrame = mkframe("WorldMapFrame")
WorldMapButton = mkframe("WorldMapButton")
WorldMapBlobFrame = mkframe("WorldMapBlobFrame")
WorldMapPOIFrame = mkframe("WorldMapPOIFrame")
WorldMapQuestFrame = mkframe("WorldMapQuestFrame")
WorldMapTooltip = mkframe("WorldMapTooltip")
GameTooltip = mkframe("GameTooltip")
ItemRefTooltip = mkframe("ItemRefTooltip")
ItemRefTooltipTextLeft1 =
  { IsVisible = function() return true end, GetText = function() return "炉石" end }
NUM_CHAT_WINDOWS = 1
ChatFrame1 = mkframe("ChatFrame1")
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
StaticPopupDialogs = {}
TEXT = function(s) return s end
QUIT_NOW, CANCEL = "退", "消"
function getglobal(n) return _G[n] end
function ForceQuit() end
STANDARD_TEXT_FONT = ""
UNKNOWN = "未知"

function GetNumAddOns() return 0 end
function GetAddOnInfo() return nil end
function GetBuildInfo() return "1.12.1", "5875", "x", 11200 end
function GetLocale() return "zhCN" end
function GetCVar(k) if k == "minimapZoom" then return "1" end return "0" end
function SetCVar() end
function GetFramerate() return 60 end
function UnitLevel() return 40 end
function UnitName() return "测试" end
-- 鼠标当前指向的是不是一个单位。用例通过 Hover(name, isunit) 改写 MOUSEOVER；
-- 游戏里这是 1.12 原生行为：指向怪/NPC 时 mouseover 存在，指向场景物时不存在。
MOUSEOVER = nil
function UnitExists(unit) if unit == "mouseover" then return MOUSEOVER end return nil end
function UnitClass() return "战士", "WARRIOR" end
function UnitRace() return "人类", "Human" end
function UnitSex() return 2 end
function UnitFactionGroup() return "Alliance" end
function GetPlayerMapPosition() return 0.5, 0.5 end
function GetCurrentMapContinent() return 2 end
function GetCurrentMapZone() return 1 end
function SetMapToCurrentZone() end
function GetRealZoneText() return "测试区" end
function GetZoneText() return "测试区" end
function GetMapInfo() return "Test" end
function GetMapZones() return {} end
function GetNumSkillLines() return 0 end
function GetSkillLineInfo() return nil end
function GetContainerNumSlots() return 0 end
function GetContainerItemLink() return nil end
function GetInventoryItemLink() return nil end
function GetItemInfo() return nil end
function IsShiftKeyDown() return false end
function IsControlKeyDown() return false end
function MouseIsOver() return false end
function GetMouseFocus() return nil end
QUEST_MONSTERS_KILLED = "%s 已被杀死：%d/%d"
QUEST_OBJECTS_FOUND = "%s：%d/%d"

-- 任务日志：用例通过 QLOG 改写
QLOG = { title = nil, complete = nil, boards = {} }
function GetNumQuestLogEntries() return (QLOG.title and 1 or 0), (QLOG.title and 1 or 0) end
function GetQuestLogTitle(i) return QLOG.title, 40, nil, nil, nil, QLOG.complete end
function SelectQuestLogEntry() end
function GetQuestLogSelection() return 0 end
function GetQuestLogQuestText() return "", "" end
function GetNumQuestLeaderBoards() return table.getn(QLOG.boards) end
function GetQuestLogLeaderBoard(i)
  local b = QLOG.boards[i]
  if not b then return nil end
  return b[1], b[2], b[3]
end
function IsQuestWatched() return nil end

pfUI = { api = {
  emulated = true,
  SkinButton = function() end,
  rgbhex = function() return "|cffffffff" end,
  CreateBackdrop = function() end,
  SanitizePattern = function(p) return (string.gsub(p, "%%[sd]", "(.+)")) end,
} }

pfQuestConfig = { path = "Interface\\AddOns\\pfQuest" }
pfQuest_Loc = setmetatable({}, { __index = function(t, k) return k end })
pfQuest_config = {
  trackingmethod = 1, currentquestgivers = "1", allquestgivers = "1",
  questlogbuttons = "0", worldmapmenu = "0", showlowlevel = "0",
  showhighlevel = "0", showfestival = "0", mindropchance = "1",
  nodefade = "0.3", showtooltips = "1", clustermono = "0",
}
pfQuest_history, pfQuest_questcache, pfQuest_colors = {}, {}, {}
pfQuest_track, pfQuest_server = nil, { items = {} }
pfQuest = { questlog = {}, questlog_tmp = {}, queue = {}, icons = {} }

----------------------------------------------------------------------
-- 数据库：用例直接改写这些表，改完调 pfDatabase.Reload()
----------------------------------------------------------------------
pfDB = {
  quests = { data = {}, zhCN = {} },
  units = { data = {}, zhCN = {} },
  objects = { data = {}, zhCN = {} },
  items = { data = {}, zhCN = { [6948] = "炉石" } },
  zones = { data = {}, zhCN = {} },
  professions = { zhCN = {} },
  ["quests-itemreq"] = { data = {} },
  objtext = { zhCN = {} },
  areatrigger = { data = {} },
  refloot = { data = {} },
  meta = { herbs = {}, mines = {} },
}

-- 顺序与 init/addon.xml 一致：compat -> database -> map。
-- locales.lua 不加载，pfQuest_Loc 上面已用「缺键回落为键本身」的桩顶替。
dofile(ADDON .. "/compat/client.lua")
dofile(ADDON .. "/database.lua")
dofile(ADDON .. "/map.lua")

pfMap.GetMapID = function() return CURZONE end
CURZONE = 1

----------------------------------------------------------------------
-- 探针
----------------------------------------------------------------------
PINS = {}
local realAddNode = pfMap.AddNode
pfMap.AddNode = function(self, meta, cluster)
  local copy = {}
  for k, v in pairs(meta) do copy[k] = v end
  table.insert(PINS, copy)
  return realAddNode(self, meta, cluster)
end

function ResetNodes()
  PINS = {}
  pfMap.nodes = {}
  pfMap.tooltips = {}
  for k in pairs(pfMap.unifiedcache) do pfMap.unifiedcache[k] = nil end
end

-- 模拟鼠标指向名为 name 的实体，返回 GameTooltip 收到的文本行（已剥颜色码）
-- isunit：true 模拟指向怪物/NPC，nil/false 模拟指向场景物。
-- 名字不同的用例两者结果一样（走名字判据），同名用例必须显式给。
function Hover(name, isunit)
  local lines = {}
  MOUSEOVER = isunit and 1 or nil
  GameTooltip.AddLine = function(self, text) table.insert(lines, text) end
  GameTooltip.Show = function() end
  GameTooltipTextLeft1 = { GetText = function() return name end }
  pfMap.tooltip_lock = nil
  pfMap.tooltip.__scripts.OnShow()
  local out = {}
  for _, l in ipairs(lines) do
    table.insert(out, (string.gsub(string.gsub(l, "|c........", ""), "|r", "")))
  end
  return out
end
