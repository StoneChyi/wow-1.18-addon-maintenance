-- 合并产物核对：dofile 真实全量 db，跑完 overwrites 与 patchtable，对最终的
-- pfDB.quests.data 下断言。见 README.md。
--
--     cd pfQuest/tests && lua run_merge.lua
dofile("harness_db.lua")

local pass, fail = 0, 0
local function check(name, cond, detail)
  if cond then pass = pass + 1
  else fail = fail + 1 print("  FAIL " .. name .. (detail and ("  -- " .. detail) or "")) end
end

local function sortedstr(t)
  if not t then return "<nil>" end
  local r = {}
  for _, v in ipairs(t) do table.insert(r, v) end
  table.sort(r)
  for i, v in ipairs(r) do r[i] = tostring(v) end
  return table.concat(r, ", ")
end

----------------------------------------------------------------------
-- 用例 1：加载本身
-- overwrites.lua 里有按 id 索引 data-turtle 的循环（清 event 那段），db 条目
-- 被改坏会在这一步就报错，所以"加载不出错"本身就是一条断言。
----------------------------------------------------------------------
check("1 按 toc 顺序加载真实 db 不报错", table.getn(LOADED) > 50,
  "实得 " .. table.getn(LOADED) .. " 个文件")

local loccount = 0
for _ in pairs(pfDB.locales) do loccount = loccount + 1 end
check("1 装了 enUS 与 zhCN 两套语言表", loccount == 2, "实得 " .. loccount)

----------------------------------------------------------------------
-- 用例 2：手工补的 pre 在合并后确实生效
-- 这些 id 的 pre 是 2026-09-11 按社区库的 nextquest 补的。写在乌龟层的要能压住
-- 基础库，写在基础库的要不被 patchtable 冲掉，两个方向都在这里验。
----------------------------------------------------------------------
local EXPECT = {
  -- 多变体 → 同一后续（阵营镜像 / 等级段变体）
  [619]   = { 618, 8554 },      [1122]  = { 1120, 1121 },
  [2954]  = { 2946, 2966 },     [9029]  = { 8984, 9028 },
  [41279] = { 41277, 41278 },   [41291] = { 41286, 41290 },
  [5218]  = { 5216, 5229 },     [5221]  = { 5219, 5231 },
  [5224]  = { 5222, 5233 },     [5227]  = { 5225, 5235 },
  [3638]  = { 3526, 3629, 3633, 4181 },
  [3640]  = { 3630, 3632, 3634 },
  [3642]  = { 3635, 3637 },
  [8922]  = { 8905, 8906, 8907, 8908, 8909, 8910, 8911, 8912 },
  [8923]  = { 8913, 8914, 8915, 8916, 8917, 8918, 8919, 8920 },
  -- 单链
  [2206]  = { 2205 },           [7637]  = { 7638 },
  [7486]  = { 6824 },           -- 英雄的奖赏 ← 敌人之手
  -- 目标本来就有 pre，追加的是并行的另一条路
  [2801]  = { 2623, 2783 },     [9033]  = { 9121, 9122, 9123 },
  [7163]  = { 7161, 7162 },     [7164]  = { 7161, 7163 },
  [7381]  = { 7181, 8272 },     [7382]  = { 7202, 8271 },
  [80707] = { 80705, 80706 },
  -- 上游 prevquest 指向自己（"重复任务"的写法），被抽取脚本当成了前置
  [8223]  = { 8222 },
}

local ids = {}
for id in pairs(EXPECT) do table.insert(ids, id) end
table.sort(ids)

for _, id in ipairs(ids) do
  local got = Q[id] and Q[id]["pre"]
  check("2 " .. id .. "「" .. QName(id) .. "」的 pre",
    sortedstr(got) == sortedstr(EXPECT[id]),
    "实得 " .. sortedstr(got) .. "，期望 " .. sortedstr(EXPECT[id]))
end

----------------------------------------------------------------------
-- 用例 2b：手工删掉的 pre 在合并后确实是 nil
-- 光在 db/quests-turtle.lua 里删掉字段不生效——overwrites.lua 末尾的兜底循环见
-- 乌龟层缺 pre，会从基础库把原值抄回来。所以每条都配了一句 data 层的清除，
-- 这里验的就是"两处都在、且顺序对"。2975 / 2040 是抽取脚本把 NextQuestInChain
-- 当成硬前置的误判，786 / 7141 / 7142 是前置本身已被 "_" 删掉。
----------------------------------------------------------------------
local CLEARED = { 786, 2040, 2975, 7141, 7142 }
for _, id in ipairs(CLEARED) do
  check("2b " .. id .. "「" .. QName(id) .. "」的 pre 已清空",
    Q[id] and Q[id]["pre"] == nil,
    "实得 " .. sortedstr(Q[id] and Q[id]["pre"]))
end

----------------------------------------------------------------------
-- 用例 2c：2026-09-14 批量清掉的 98 条 NextQuestInChain 误判前置
-- 判据见 overwrites.lua 里 FALSE_PRE 上方的注释。这里逐条验合并后确实是 nil——
-- 光靠 overwrites 那个循环不够，它得同时压住基础层、乌龟层和末尾的兜底回填。
----------------------------------------------------------------------
local FALSE_PRE_CLEARED = {
  95, 261, 276, 297, 364, 455, 729, 788, 844, 870,
  960, 969, 1057, 1062, 1093, 1123, 1130, 1133, 1288, 1338,
  1362, 1364, 1390, 1420, 1641, 1645, 1688, 1716, 1796, 1799,
  1801, 2038, 2281, 2379, 2770, 2846, 2924, 2930, 3503, 3761,
  3764, 3791, 3792, 4122, 4490, 4505, 4621, 4861, 5143, 5148,
  5244, 5921, 6543, 6607, 6610, 6622, 6624, 6761, 7488, 7489,
  7668, 7795, 7800, 7805, 7811, 7818, 7823, 7824, 7836, 8115,
  8122, 8271, 8272, 8280, 8484, 8485, 8811, 8812, 8813, 8814,
  8815, 8816, 8817, 8818, 8819, 8820, 8821, 8822, 8823, 8824,
  8825, 8826, 8867, 9422, 41368, 41771, 41772, 41773,
}
local cleared_bad = {}
for _, id in ipairs(FALSE_PRE_CLEARED) do
  if not Q[id] or Q[id]["pre"] ~= nil then
    table.insert(cleared_bad, id .. "(" .. sortedstr(Q[id] and Q[id]["pre"]) .. ")")
  end
end
check("2c 98 条误判前置全部清空", table.getn(cleared_bad) == 0, table.concat(cleared_bad, " "))
check("2c 名单长度仍是 98", table.getn(FALSE_PRE_CLEARED) == 98,
  "实得 " .. table.getn(FALSE_PRE_CLEARED))

-- 有意保留的唯一例外：934「大地之冠」← 933，同名同 NPC 的真顺序链，pre 撑着
-- patchtable.lua 里 GetQuestChainInfo 的"第 N 环"标签。别被下次批量清理顺手带走。
check("2c 934「" .. QName(934) .. "」的 pre 有意保留", sortedstr(Q[934] and Q[934]["pre"]) == "933",
  "实得 " .. sortedstr(Q[934] and Q[934]["pre"]))

----------------------------------------------------------------------
-- 用例 2d：手工补回的目标物品来源
-- 上游把任务物品导成了空壳 `[id] = {}`，目标就解析不到任何怪——地图上没图钉，
-- 鼠标指到怪身上也不出提示（提示键是 AddNode 时按怪名登记的）。
-- 这类修订写在 db 里，重导上游会被覆盖，所以在这儿钉一条。
----------------------------------------------------------------------
local ITEM_SRC = {
  -- 物品, 来源怪, 掉率     -- 任务 / 说明
  { 41800, 4857, 100 },     -- 41733「重建遗物」← 石头看守者（奥达曼）
}
for _, e in ipairs(ITEM_SRC) do
  local iid, uid, chance = e[1], e[2], e[3]
  local rec = pfDB["items"]["data"][iid]
  local got = rec and rec["U"] and rec["U"][uid]
  check("2d 物品 " .. iid .. " 的来源含单位 " .. uid,
    got == chance, "实得 " .. tostring(got) .. "，期望 " .. chance)
end

----------------------------------------------------------------------
-- 用例 3：每个 pre 来源都得是能做完的任务
-- 前置被乌龟层用 "_" 删掉 / 合并后不存在 / 没有名字，目标就永远解锁不了。
-- 786、7141、7142 栽过这个坑，见 pfQuest-turtle/overwrites.lua 里的注释。
----------------------------------------------------------------------
local dead = {}
for id, rec in pairs(Q) do
  if type(rec) == "table" and rec["pre"] then
    for _, src in ipairs(rec["pre"]) do
      local why
      if Q[src] == nil then why = "合并后不存在"
      elseif QT[src] == "_" then why = "被乌龟层删掉"
      elseif not (QLOC[src] or QEN[src]) then why = "没有名字" end
      if why then
        table.insert(dead, id .. "「" .. QName(id) .. "」-> " .. src .. " " .. why)
      end
    end
  end
end
check("3 全库没有指向失效任务的 pre", table.getn(dead) == 0,
  table.getn(dead) > 0 and (table.getn(dead) .. " 条，首条：" .. dead[1]) or nil)

----------------------------------------------------------------------
-- 用例 4：pre 图不能有环
-- 环上的任务互相等，QuestFilter 永远放不出来。2026-09-11 修掉过一个：
-- 8595 的 pre = { 8579 } 来自基础库，8579 的 pre = { 8595 } 来自乌龟层。
----------------------------------------------------------------------
local state, cycles = {}, {}
local function dfs(id, stack)
  if state[id] == 2 then return end
  if state[id] == 1 then
    local s = {}
    for i, v in ipairs(stack) do s[i] = v .. "「" .. QName(v) .. "」" end
    table.insert(cycles, table.concat(s, " -> "))
    return
  end
  state[id] = 1
  table.insert(stack, id)
  local pre = Q[id] and Q[id]["pre"]
  if pre then
    for _, p in ipairs(pre) do
      if Q[p] then dfs(p, stack) end
    end
  end
  table.remove(stack)
  state[id] = 2
end
for id, rec in pairs(Q) do
  if type(rec) == "table" then dfs(id, {}) end
end
check("4 pre 图无环", table.getn(cycles) == 0,
  table.getn(cycles) > 0 and (table.getn(cycles) .. " 个，首个：" .. cycles[1]) or nil)

local selfref = {}
for id, rec in pairs(Q) do
  if type(rec) == "table" and rec["pre"] then
    for _, p in ipairs(rec["pre"]) do
      if p == id then table.insert(selfref, id) end
    end
  end
end
check("4 没有 pre 指向自己", table.getn(selfref) == 0, sortedstr(selfref))

----------------------------------------------------------------------
-- 用例 5：QuestFilter 的实际行为
-- 空历史下应当隐藏，做完任一前置后应当放出来。多来源的逐个来源各验一次。
----------------------------------------------------------------------
local CASES = {
  { 7486, 6824 }, { 2206, 2205 }, { 7637, 7638 }, { 8223, 8222 },
  { 619, 618 }, { 619, 8554 }, { 1122, 1120 }, { 1122, 1121 },
  { 9029, 8984 }, { 9029, 9028 }, { 3638, 4181 }, { 41279, 41278 },
  { 8595, nil },  -- 环修掉后，8595 本身不该再有前置门槛
}
for _, c in ipairs(CASES) do
  local id, src = c[1], c[2]
  if src then
    local v0 = PreVisible(id, {})
    local v1, why = PreVisible(id, { [src] = true })
    check("5 " .. id .. "「" .. QName(id) .. "」做完 " .. src .. " 才可见",
      v0 == false and v1 == true, "空历史=" .. tostring(v0) .. "，做完后=" .. tostring(v1) .. "（" .. why .. "）")
  else
    local v, why = PreVisible(id, {})
    check("5 " .. id .. "「" .. QName(id) .. "」空历史下即可见", v == true, why)
  end
end

----------------------------------------------------------------------
-- 用例 6：有意跳过的战场重复任务不该被顺手补上 pre
-- pfQuest 没有 repeatable 概念（extractor 算了 repeatable 但从没写进 db），
-- 这些任务一进 pfQuest_history 就被永久隐藏，补 pre 收益很低。
----------------------------------------------------------------------
for _, id in ipairs({ 8114, 8121, 8292, 8293, 8298, 8300 }) do
  check("6 " .. id .. "「" .. QName(id) .. "」仍无 pre", Q[id] and Q[id]["pre"] == nil,
    Q[id] and sortedstr(Q[id]["pre"]) or "条目不存在")
end

----------------------------------------------------------------------
-- 用例 7：互斥组（close）
-- close 全插件只有一个消费点：patchtable.lua 里 complete() 的递归展开，走的是
-- /db query -> 公会频道 .queststatus -> CHAT_MSG_ADDON 回包这条路。QuestFilter
-- 不看 close，靠的是"互斥兄弟被塞进 history，第二关按已完成拦下"。
-- 这里驱动的是真实的 OnEvent 处理器，不是复刻。
----------------------------------------------------------------------
local EXCLUSIVE = {
  { 40801, 40807 },   -- 耐心是关键 / 压力是关键（灰谷林歌神殿二选一）
  { 2998, 3681 },     -- 圣洁之书两个互斥起点
  { 1531, 1532 },     -- 空气的召唤
}
for _, grp in ipairs(EXCLUSIVE) do
  for _, id in ipairs(grp) do
    local close = Q[id] and Q[id]["close"]
    local has = false
    if close then
      for _, other in ipairs(grp) do
        local found = false
        for _, c in ipairs(close) do if c == other then found = true end end
        has = found
        if not found then break end
      end
    end
    check("7 " .. id .. "「" .. QName(id) .. "」的 close 含整组", has,
      sortedstr(close))
  end
  -- 服务端只回组里第一条：complete() **不该**把互斥兄弟也塞进 history
  -- （2026-09-11 移除了那段展开，理由见 patchtable.lua 里的注释），
  -- 遮住兄弟任务改由 QuestFilter 的互斥组检查负责。
  local h = RunQuestStatus(tostring(grp[1]))
  check("7 只回 " .. grp[1] .. " 时 history 里有它", h[grp[1]] ~= nil)
  for _, id in ipairs(grp) do
    if id ~= grp[1] then
      check("7 互斥兄弟 " .. id .. "「" .. QName(id) .. "」不该被伪造进 history",
        h[id] == nil)
    end
    local v, why = Visible(id, h)
    check("7 " .. id .. "「" .. QName(id) .. "」在图上被隐藏", v == false, why)
  end
end

----------------------------------------------------------------------
-- 用例 8：互斥组在 QuestFilter 里就被挡住（不依赖 /db query）
-- 平时交任务只把交掉的那一个 id 写进 history（quest.lua 的任务栏 diff，不展开
-- close），所以这里的 history 只放一条，模拟"刚交完、还没跑 /db query"。
-- patchtable.lua 包裹 QuestFilter 加的那一关就是为这个场景加的。
----------------------------------------------------------------------
for _, grp in ipairs(EXCLUSIVE) do
  for _, done in ipairs(grp) do
    local h = { [done] = { 0, 0 } }        -- 只有真正交掉的那一条
    for _, other in ipairs(grp) do
      if other ~= done then
        local v, why = Visible(other, h)
        check("8 只交了 " .. done .. " 后 " .. other .. "「" .. QName(other) .. "」被挡下",
          v == false, why)
        check("8 " .. other .. " 挡下的原因是互斥组而非已完成",
          why == "被互斥组挡下", why)
      end
    end
  end
end

-- 反过来：互斥组没人做过时，组内成员不该被这一关挡（别的关可能挡，看原因即可）
for _, grp in ipairs(EXCLUSIVE) do
  for _, id in ipairs(grp) do
    local _, why = Visible(id, {})
    check("8 " .. id .. "「" .. QName(id) .. "」在空历史下不该被互斥组挡",
      why ~= "被互斥组挡下", why)
  end
end

----------------------------------------------------------------------
-- 用例 9：分叉任务链——选了一边，被放弃那边整条都不该显示
-- 灰谷林歌神殿的二选一，两条分支各 6 环。close 只挂在两个分支头上，下游全靠 pre，
-- 所以一旦互斥兄弟被伪造进 history，被放弃那条的第二环就会冒出个接不到的 [!]。
-- 两种 history 都要验：刚交完（只有一条）、跑过 /db query（complete() 展开 pre）。
----------------------------------------------------------------------
local BRANCH = {
  [40801] = { 40802, 40803, 40804, 40805, 40806 },   -- 布罗森·铁林线
  [40807] = { 40808, 40809, 40810, 40811, 40812 },   -- 星风指挥官线
}
for head, chain in pairs(BRANCH) do
  local other_head, other_chain
  for h, c in pairs(BRANCH) do
    if h ~= head then other_head, other_chain = h, c end
  end
  local histories = {
    { "刚交完还没同步", { [head] = { 0, 0 } } },
    { "跑过 /db query", RunQuestStatus(tostring(head)) },
  }
  for _, hh in ipairs(histories) do
    local tag, h = hh[1], hh[2]
    check("9 " .. tag .. "：选了 " .. head .. " 后本线第二环 " .. chain[1] .. "「"
          .. QName(chain[1]) .. "」显示", Visible(chain[1], h) == true)
    local v, why = Visible(other_head, h)
    check("9 " .. tag .. "：另一头 " .. other_head .. "「" .. QName(other_head)
          .. "」隐藏", v == false, why)
    for _, id in ipairs(other_chain) do
      local v2, why2 = Visible(id, h)
      check("9 " .. tag .. "：放弃那线的 " .. id .. "「" .. QName(id) .. "」隐藏",
        v2 == false, why2)
    end
  end
end

----------------------------------------------------------------------
print(string.format("\n通过 %d，失败 %d", pass, fail))
if fail > 0 then os.exit(1) end
