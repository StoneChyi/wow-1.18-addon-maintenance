-- pfQuest + pfQuest-turtle 的**真实全量 db** 合并环境。见 README.md。
--
-- 与 pfQuest/tests/harness.lua 的分工：那边的 pfDB 是空壳，给引擎用例塞假数据用；
-- 本文件相反，按 .toc / init/*.xml 的顺序 dofile 真实数据文件，跑完 overwrites
-- 与 patchtable，用来核对**合并产物**。两者不能共用一个进程。
--
-- 放在 pfQuest-turtle 而不是 pfQuest：pfQuest 是 vendored 的上游插件，
-- .gitignore 把 pfQuest/tests/ 整个排掉了（升级上游时碍事），而这套测试验的
-- 是我们自己在乌龟层做的数据修订，该跟着乌龟层进版本库。
local HERE, HERE_N = string.gsub(debug.getinfo(1).source, "^@(.*)/[^/]*$", "%1")
if HERE_N == 0 then HERE = "." end
local ADDONS = HERE .. "/../.."

----------------------------------------------------------------------
-- Lua 5.0 兼容垫片：本机是 5.5
----------------------------------------------------------------------
if not table.getn then table.getn = function(t) return #t end end
if not string.gfind then string.gfind = string.gmatch end
if not unpack then unpack = table.unpack end

----------------------------------------------------------------------
-- WoW API 桩：只需覆盖 overwrites.lua 与 patchtable.lua 在**加载期**碰到的
-- 那些。函数体里才用到的（strsplit / complete / GetQuestChainInfo 等）不会
-- 在加载时执行，桩到能取到全局即可。
----------------------------------------------------------------------
function GetLocale() return "zhCN" end
function GetMapZones() return end
function GetMapContinents() return end
function GetTime() return 0 end
function gcinfo() return 0 end
function IsInInstance() return false end
function GetCurrentMapContinent() return 1 end
function GetMouseFocus() return nil end
function SendChatMessage() end

-- SavedVariables。complete() 会读 pfQuest_history[qid] 取旧的完成时间/等级，
-- 空表相当于一个还没同步过的角色。
pfQuest_history, pfQuest_questcache, pfQuest_turtlecount = {}, {}, nil

DEFAULT_CHAT_FRAME = { AddMessage = function() end }
GameTooltip = { SetText = function() end, Show = function() end, AddLine = function() end }
pfMap = { GetMapIDByName = function() return nil end }
pfDatabase = { Reload = function() end }
pfQuest = { Debug = function() end, questlog = {} }

-- pfQuest/database.lua 不加载（那要一整套 WoW UI 桩，见 pfQuest/tests/harness.lua），
-- 这里放一个**复刻**的 QuestFilter 基座，只含与 history / pre 有关的三段；等级、种族、
-- 职业、专业、节日那几条与本文件关注点无关，没有复刻。
--
-- 放在 patchtable.lua 之前是必须的：patchtable.lua 用
-- `local _QuestFilter = pfDatabase.QuestFilter` 手动包裹它来加互斥组检查，
-- 基座缺席的话包出来的就是个会在调用时炸的 nil。**包裹层是真代码，跑的就是线上那份。**
FILTER_REASON = nil
function pfDatabase:QuestFilter(id, plevel, pclass, prace)
  FILTER_REASON = nil
  if pfQuest.questlog[id] then FILTER_REASON = "在任务栏里" return end
  if pfQuest_history[id] then FILTER_REASON = "已完成" return end
  if not (pfDB["quests"]["zhCN"][id] or pfDB["quests"]["enUS"][id]) then
    FILTER_REASON = "无名字" return
  end

  local pre = pfDB["quests"]["data"][id] and pfDB["quests"]["data"][id]["pre"]
  if pre then
    local one_complete = nil
    for _, p in ipairs(pre) do
      if pfQuest_history[p] then one_complete = true end
    end
    if not one_complete then FILTER_REASON = "前置未完成" return end
  end

  return true
end

-- 大驼峰方法一律返回空函数；SetScript 要真存下来，否则够不到 patchtable.lua 里
-- 那个处理 .queststatus 回包的 OnEvent（用例 7 要驱动它）。
local frameproto = { __index = function() return function() end end }
FRAMES = {}
function CreateFrame()
  local f = setmetatable({}, frameproto)
  f.__scripts = {}
  f.SetScript = function(self, e, fn) self.__scripts[e] = fn end
  f.GetScript = function(self, e) return self.__scripts[e] end
  table.insert(FRAMES, f)
  return f
end

----------------------------------------------------------------------
-- 按加载顺序 dofile
----------------------------------------------------------------------
LOADED = {}
local function load(rel)
  local path = ADDONS .. "/" .. rel
  local f, err = loadfile(path)
  if not f then error("loadfile 失败: " .. rel .. "\n" .. tostring(err), 0) end
  local ok, err2 = pcall(f)
  if not ok then error("执行出错: " .. rel .. "\n" .. tostring(err2), 0) end
  table.insert(LOADED, rel)
end

local function loadall(dir, names, suffix)
  for _, n in ipairs(names) do load(dir .. "/" .. n .. (suffix or "") .. ".lua") end
end

local LOCFILES = { "items", "units", "objects", "quests", "objtext", "zones", "professions" }

-- === pfQuest.toc ===
load("pfQuest/db/init.lua")                                          -- init/data.xml
loadall("pfQuest/db", { "items", "units", "objects", "refloot", "quests-itemreq",
                        "quests", "zones", "minimap", "areatrigger", "meta" })
loadall("pfQuest/db/enUS", LOCFILES)                                 -- init/enUS.xml
loadall("pfQuest/db/zhCN", LOCFILES)                                 -- init/zhCN.xml
load("pfQuest/overwrites.lua")                                       -- init/addon.xml

-- database.lua 里唯一影响合并结果的那段（database.lua:11）：locales 表，
-- 再按"该语言的 quests 表存不存在"裁剪。pfQuest-turtle/overwrites.lua 的
-- removeTurtleRecord 与 patchtable.lua 的语言表合并都要遍历它。
pfDB.locales = {
  ["enUS"] = "English", ["koKR"] = "Korean", ["frFR"] = "French",
  ["deDE"] = "German", ["zhCN"] = "Chinese (Simplified)",
  ["zhTW"] = "Chinese (Traditional)", ["esES"] = "Spanish",
  ["ruRU"] = "Russian", ["ptBR"] = "Portuguese",
}
for key in pairs(pfDB.locales) do
  if not pfDB["quests"][key] then pfDB.locales[key] = nil end
end

-- === pfQuest-turtle.toc ===
loadall("pfQuest-turtle/db", { "items", "units", "objects", "refloot", "quests-itemreq",
                               "quests", "patches", "zones", "minimap", "areatrigger",
                               "meta" }, "-turtle")
loadall("pfQuest-turtle/db/enUS", LOCFILES, "-turtle")
loadall("pfQuest-turtle/db/zhCN", LOCFILES, "-turtle")
load("pfQuest-turtle/db/items-vanillafix.lua")
load("pfQuest-turtle/overwrites.lua")
load("pfQuest-turtle/patchtable.lua")

----------------------------------------------------------------------
-- 取数便捷函数
----------------------------------------------------------------------
Q    = pfDB["quests"]["data"]           -- 合并后的最终产物
QT   = pfDB["quests"]["data-turtle"]    -- 乌龟差分层（判断某 id 是否被 "_" 删掉）
QLOC = pfDB["quests"]["zhCN"]
QEN  = pfDB["quests"]["enUS"]

function QName(id)
  local e = QLOC[id] or QEN[id]
  return (e and e.T) or "<无名字>"
end

-- 在给定 history 下问一次 QuestFilter。调的是 patchtable.lua 包裹之后的那个
-- pfDatabase:QuestFilter —— 互斥组那一关是真代码，pre / history 那几关是上面
-- 的复刻基座。返回 true/false 和一句原因。
function Visible(id, history)
  local saved = pfQuest_history
  pfQuest_history = history or {}
  local ok = pfDatabase:QuestFilter(id, 60, 0, 0)
  local why = FILTER_REASON
  pfQuest_history = saved
  if ok then return true, "可见" end
  return false, why or "被互斥组挡下"
end

-- 兼容旧名
PreVisible = Visible

-- 驱动 pfQuest-turtle/patchtable.lua 里那个 .queststatus 回包处理器，跑的是**真的**
-- complete()（沿 close 与 pre 递归展开），不是复刻。qids 是服务端回的那串 id。
-- 返回它写进 pfQuest_history 的那张表。
function RunQuestStatus(qids)
  local frame
  for _, f in ipairs(FRAMES) do
    if f.__scripts and f.__scripts["OnEvent"] and f.__scripts["OnShow"] then frame = f end
  end
  if not frame then error("没找到 patchtable.lua 建的 query frame", 0) end
  this = frame
  frame.history = {}
  arg1, arg2 = "TWQUEST", qids
  frame.__scripts["OnEvent"]()
  return frame.history
end
