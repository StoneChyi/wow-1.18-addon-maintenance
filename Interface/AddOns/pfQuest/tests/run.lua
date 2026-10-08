dofile("harness.lua")

local pass, fail = 0, 0
function check(name, cond, detail)
  if cond then pass = pass + 1
  else fail = fail + 1 print("  FAIL " .. name .. (detail and ("  -- " .. detail) or "")) end
end

----------------------------------------------------------------------
-- 用例 1：summon.O —— 场景物召唤，坐标取自场景物
----------------------------------------------------------------------
ResetNodes()
CURZONE = 101
pfDB.units.data[9001] = { coords = {}, lvl = "40" }
pfDB.units.data[9001].summon = { O = 7001 }
pfDB.units.zhCN[9001] = "召唤怪甲"
pfDB.objects.data[7001] = { coords = { { 11.1, 22.2, 101, 0 } } }
pfDB.objects.zhCN[7001] = "祭坛甲"
pfDatabase.Reload()

pfDatabase:SearchMobID(9001, { addon = "T", quest = "任务甲", QTYPE = "UNIT_OBJECTIVE" })
check("summon.O 画出一个图钉", table.getn(PINS) == 1, "实得 " .. table.getn(PINS))
check("summon.O 坐标取自场景物", PINS[1] and PINS[1].x == 11.1 and PINS[1].y == 22.2)
check("summon.O spawn 是单位名", PINS[1] and PINS[1].spawn == "召唤怪甲", PINS[1] and PINS[1].spawn)
check("summon.O 别名是场景物名", PINS[1] and PINS[1].spawnalias == "祭坛甲", PINS[1] and tostring(PINS[1].spawnalias))

----------------------------------------------------------------------
-- 用例 2：summon.A 不再被支持 —— 区域标记一律虚构一个占位场景物写 O
----------------------------------------------------------------------
ResetNodes()
CURZONE = 102
pfDB.units.data[9002] = { coords = {}, lvl = "40" }
pfDB.units.data[9002].summon = { A = 900901 }
pfDB.units.zhCN[9002] = "召唤怪乙"
pfDB.areatrigger.data[900901] = { coords = { { 33.3, 44.4, 1022 } } }
pfDatabase.Reload()

pfDatabase:SearchMobID(9002, { addon = "T", quest = "任务乙", QTYPE = "UNIT_OBJECTIVE" })
check("summon.A 不画图钉", table.getn(PINS) == 0, "实得 " .. table.getn(PINS))

-- 同一个位置改用占位场景物表达，这才是现在的写法
ResetNodes()
pfDB.objects.data[7002] = { coords = { { 33.3, 44.4, 1022, 0 } } }
pfDB.objects.zhCN[7002] = "占位物乙"
pfDB.units.data[9002].summon = { O = 7002 }
pfDatabase.Reload()

pfDatabase:SearchMobID(9002, { addon = "T", quest = "任务乙", QTYPE = "UNIT_OBJECTIVE" })
check("占位场景物画出一个图钉", table.getn(PINS) == 1, "实得 " .. table.getn(PINS))
check("占位场景物坐标照搬", PINS[1] and PINS[1].x == 33.3 and PINS[1].y == 44.4)
check("占位场景物名字进别名", PINS[1] and PINS[1].spawnalias == "占位物乙",
      PINS[1] and tostring(PINS[1].spawnalias))

----------------------------------------------------------------------
-- 用例 3：真实落点优先于 summon
----------------------------------------------------------------------
ResetNodes()
CURZONE = 103
pfDB.units.data[9003] = { coords = { { 55.5, 66.6, 103, 300 } }, lvl = "40" }
pfDB.units.data[9003].summon = { O = 7003 }
pfDB.units.zhCN[9003] = "召唤怪丙"
pfDB.objects.data[7003] = { coords = { { 77.7, 88.8, 103, 0 } } }
pfDB.objects.zhCN[7003] = "祭坛丙"
pfDatabase.Reload()

pfDatabase:SearchMobID(9003, { addon = "T", quest = "任务丙", QTYPE = "UNIT_OBJECTIVE" })
check("有真实落点时不走 summon", PINS[1] and PINS[1].x == 55.5, PINS[1] and tostring(PINS[1].x))
check("有真实落点时无别名", PINS[1] and PINS[1].spawnalias == nil)

----------------------------------------------------------------------
-- 用例 4：召唤源缺失 / 无坐标时安全返回
----------------------------------------------------------------------
ResetNodes()
CURZONE = 104
pfDB.units.data[9004] = { coords = {}, lvl = "40" }
pfDB.units.data[9004].summon = { O = 7999 }        -- 场景物不存在
pfDB.units.zhCN[9004] = "召唤怪丁"
pfDB.units.data[9005] = { coords = {}, lvl = "40" }
pfDB.units.data[9005].summon = { O = 7005 }
pfDB.units.zhCN[9005] = "召唤怪戊"
pfDB.objects.data[7005] = { coords = {} }          -- 场景物有条目但无坐标
pfDB.objects.zhCN[7005] = "祭坛戊"
pfDatabase.Reload()

local ok1 = pcall(function()
  pfDatabase:SearchMobID(9004, { addon = "T", quest = "任务丁", QTYPE = "UNIT_OBJECTIVE" })
end)
local ok2 = pcall(function()
  pfDatabase:SearchMobID(9005, { addon = "T", quest = "任务戊", QTYPE = "UNIT_OBJECTIVE" })
end)
check("召唤源不存在不报错", ok1)
check("召唤源无坐标不报错", ok2)
check("两者都不画图钉", table.getn(PINS) == 0, "实得 " .. table.getn(PINS))

----------------------------------------------------------------------
-- 用例 5：coords 键整个缺失时也走回退（nil 与空表两种形态都要覆盖）
----------------------------------------------------------------------
ResetNodes()
CURZONE = 105
pfDB.units.data[9006] = { lvl = "40" }             -- 没有 coords 键
pfDB.units.data[9006].summon = { O = 7006 }
pfDB.units.zhCN[9006] = "召唤怪己"
pfDB.objects.data[7006] = { coords = { { 12.5, 25.0, 105, 0 } } }
pfDB.objects.zhCN[7006] = "祭坛己"
pfDatabase.Reload()

local ok3 = pcall(function()
  pfDatabase:SearchMobID(9006, { addon = "T", quest = "任务己", QTYPE = "UNIT_OBJECTIVE" })
end)
check("coords 键缺失时不报错", ok3)
check("coords 键缺失时也走回退", table.getn(PINS) == 1 and PINS[1].x == 12.5,
      "实得 " .. table.getn(PINS))

----------------------------------------------------------------------
-- 用例 6：别名 —— 指向场景物本体也显示任务信息（场景物与怪物不同名）
----------------------------------------------------------------------
ResetNodes()
CURZONE = 106
QLOG.title, QLOG.complete = "任务庚", nil
QLOG.boards = { { "召唤怪庚 已被杀死：0/1", "monster", nil } }
pfDB.quests.data[8106] = { lvl = 40, min = 40, obj = { U = { 9007 } } }
pfDB.quests.zhCN[8106] = { T = "任务庚", O = "杀掉召唤怪庚", D = "描述" }
pfDB.units.data[9007] = { coords = {}, lvl = "40" }
pfDB.units.data[9007].summon = { O = 7007 }
pfDB.units.zhCN[9007] = "召唤怪庚"
pfDB.objects.data[7007] = { coords = { { 14.0, 28.0, 106, 0 } } }
pfDB.objects.zhCN[7007] = "祭坛庚"
pfDatabase.Reload()

pfDatabase:SearchQuestID(8106, { addon = "PFQUEST", qlogid = 1 })

local hitMob = Hover("召唤怪庚")
local hitObj = Hover("祭坛庚")
check("指向怪物有任务信息", table.getn(hitMob) > 0)
check("指向怪物有进度行",
      table.getn(hitMob) > 1 and string.find(hitMob[2], "0/1", 1, true) ~= nil,
      hitMob[2])
check("指向场景物也有任务信息", table.getn(hitObj) > 0,
      "实得 " .. table.getn(hitObj) .. " 行")

----------------------------------------------------------------------
-- 用例 7：同名时别名写入幂等，不产生重复节点
----------------------------------------------------------------------
ResetNodes()
CURZONE = 107
QLOG.title, QLOG.complete = "任务辛", nil
QLOG.boards = { { "同名怪 已被杀死：0/1", "monster", nil } }
pfDB.quests.data[8107] = { lvl = 40, min = 40, obj = { U = { 9008 } } }
pfDB.quests.zhCN[8107] = { T = "任务辛", O = "杀掉同名怪", D = "描述" }
pfDB.units.data[9008] = { coords = {}, lvl = "40" }
pfDB.units.data[9008].summon = { O = 7008 }
pfDB.units.zhCN[9008] = "同名怪"
pfDB.objects.data[7008] = { coords = { { 16.0, 32.0, 107, 0 } } }
pfDB.objects.zhCN[7008] = "同名怪"
pfDatabase.Reload()

pfDatabase:SearchQuestID(8107, { addon = "PFQUEST", qlogid = 1 })
local tipcount = 0
for _ in pairs(pfMap.tooltips) do tipcount = tipcount + 1 end
check("同名时只注册一个提示键", tipcount == 1, "实得 " .. tipcount)

----------------------------------------------------------------------
-- 用例 8：DeleteNode 后别名条目一并清除
----------------------------------------------------------------------
pfMap:DeleteNode("PFQUEST")
local left = 0
for _, tv in pairs(pfMap.tooltips) do
  for _ in pairs(tv) do left = left + 1 end
end
check("DeleteNode 清空别名提示", left == 0, "残留 " .. left)

----------------------------------------------------------------------
-- 用例 8b：别名与单位【不同名】时，确实注册了两个独立的提示键
-- （这是用例 7 缺的区分力：同名数据下 Lua 同键幂等，测不出别名功能是否存在）
----------------------------------------------------------------------
ResetNodes()
CURZONE = 112
QLOG.title, QLOG.complete = "任务寅", nil
QLOG.boards = { { "召唤怪寅 已被杀死：0/1", "monster", nil } }
pfDB.quests.data[8112] = { lvl = 40, min = 40, obj = { U = { 9013 } } }
pfDB.quests.zhCN[8112] = { T = "任务寅", O = "杀掉召唤怪寅", D = "描述" }
pfDB.units.data[9013] = { coords = {}, lvl = "40" }
pfDB.units.data[9013].summon = { O = 7013 }
pfDB.units.zhCN[9013] = "召唤怪寅"
pfDB.objects.data[7013] = { coords = { { 26.0, 52.0, 112, 0 } } }
pfDB.objects.zhCN[7013] = "祭坛寅"
pfDatabase.Reload()

pfDatabase:SearchQuestID(8112, { addon = "PFQUEST", qlogid = 1 })

local keys = {}
for name in pairs(pfMap.tooltips) do table.insert(keys, name) end
table.sort(keys)
check("不同名时注册两个提示键", table.getn(keys) == 2,
      "实得 " .. table.getn(keys) .. " 个: " .. table.concat(keys, ","))
check("提示键含单位名", pfMap.tooltips["召唤怪寅"] ~= nil)
check("提示键含召唤源名", pfMap.tooltips["祭坛寅"] ~= nil)

----------------------------------------------------------------------
-- 用例 8c：DeleteNode 确实清掉【不同名】的别名条目
-- （用例 8 只清到同名合并条目，测不出别名条目会不会被清）
----------------------------------------------------------------------
pfMap:DeleteNode("PFQUEST")
local leftAlias = 0
for _, tv in pairs(pfMap.tooltips) do
  for _ in pairs(tv) do leftAlias = leftAlias + 1 end
end
check("DeleteNode 清空不同名的别名条目", leftAlias == 0, "残留 " .. leftAlias)

----------------------------------------------------------------------
-- 用例 9：obj.I 三段链 —— 场景物召唤怪 -> 击杀 -> 拾取任务物品
----------------------------------------------------------------------
ResetNodes()
CURZONE = 108
QLOG.title, QLOG.complete = "任务壬", nil
QLOG.boards = { { "任务物品壬：0/8", "item", nil } }
pfDB.quests.data[8108] = { lvl = 40, min = 40, obj = { I = { 6108 } } }
pfDB.quests.zhCN[8108] = { T = "任务壬", O = "收集任务物品壬", D = "描述" }
pfDB.items.data[6108] = { U = { [9009] = 100 } }
pfDB.items.zhCN[6108] = "任务物品壬"
pfDB.units.data[9009] = { coords = {}, lvl = "40" }
pfDB.units.data[9009].summon = { O = 7009 }
pfDB.units.zhCN[9009] = "召唤怪壬"
pfDB.objects.data[7009] = { coords = { { 18.0, 36.0, 108, 0 } } }
pfDB.objects.zhCN[7009] = "祭坛壬"
pfDatabase.Reload()

pfDatabase:SearchQuestID(8108, { addon = "PFQUEST", qlogid = 1 })
check("三段链画出图钉", table.getn(PINS) > 0, "实得 " .. table.getn(PINS))

local hitMob9 = Hover("召唤怪壬")
check("三段链指向怪物有任务信息", table.getn(hitMob9) > 0)
check("三段链进度行含物品数量",
      table.getn(hitMob9) > 1 and string.find(hitMob9[2], "0/8", 1, true) ~= nil,
      hitMob9[2])

----------------------------------------------------------------------
-- 用例 10：obj.T 对话链路同样恢复
----------------------------------------------------------------------
ResetNodes()
CURZONE = 109
QLOG.title, QLOG.complete = "任务癸", nil
QLOG.boards = {}
pfDB.quests.data[8109] = { lvl = 40, min = 40, obj = { T = { 9010 } } }
pfDB.quests.zhCN[8109] = { T = "任务癸", O = "与召唤怪癸交谈", D = "描述" }
pfDB.units.data[9010] = { coords = {}, lvl = "40" }
pfDB.units.data[9010].summon = { O = 7010 }
pfDB.units.zhCN[9010] = "召唤怪癸"
pfDB.objects.data[7010] = { coords = { { 20.0, 40.0, 109, 0 } } }
pfDB.objects.zhCN[7010] = "祭坛癸"
pfDatabase.Reload()

pfDatabase:SearchQuestID(8109, { addon = "PFQUEST", qlogid = 1 })
check("obj.T 链路画出图钉", table.getn(PINS) > 0, "实得 " .. table.getn(PINS))

----------------------------------------------------------------------
-- 用例 11b：obj.IR（用物品目标）链路同样恢复
-- IR 比其它三条多一道门槛：只有玩家背包里有该物品时才画图钉
----------------------------------------------------------------------
ResetNodes()
CURZONE = 113
QLOG.title, QLOG.complete = "任务卯", nil
QLOG.boards = {}
pfDB.quests.data[8113] = { lvl = 40, min = 40, obj = { IR = { 6113 } } }
pfDB.quests.zhCN[8113] = { T = "任务卯", O = "对召唤怪卯使用道具卯", D = "描述" }
pfDB.items.zhCN[6113] = "道具卯"
pfDB["quests-itemreq"].data[6113] = { [9014] = 1 }   -- 正数 = creature
pfDB.units.data[9014] = { coords = {}, lvl = "40" }
pfDB.units.data[9014].summon = { O = 7014 }
pfDB.units.zhCN[9014] = "召唤怪卯"
pfDB.objects.data[7014] = { coords = { { 28.0, 56.0, 113, 0 } } }
pfDB.objects.zhCN[7014] = "祭坛卯"
pfDatabase.Reload()

-- 没有物品时不应画图钉（IR 分支的门槛）
pfDatabase.itemlist.db["道具卯"] = nil
pfDatabase:SearchQuestID(8113, { addon = "PFQUEST", qlogid = 1 })
check("obj.IR 无物品时不画图钉", table.getn(PINS) == 0, "实得 " .. table.getn(PINS))

-- 有物品时应走 SearchMobID 的 summon 回退画出图钉
ResetNodes()
pfDatabase.itemlist.db["道具卯"] = true
pfDatabase:SearchQuestID(8113, { addon = "PFQUEST", qlogid = 1 })
check("obj.IR 有物品时画出图钉", table.getn(PINS) > 0, "实得 " .. table.getn(PINS))
check("obj.IR 图钉坐标取自召唤源",
      PINS[1] and PINS[1].x == 28.0 and PINS[1].y == 56.0,
      PINS[1] and tostring(PINS[1].x) .. "," .. tostring(PINS[1].y))

-- obj.IR 的节点没有目标物品，兜底那行该说"对它用哪件道具"，而不是复述怪的名字
local irlines = table.concat(Hover("召唤怪卯"), "\n")
check("obj.IR 提示行说使用道具", string.find(irlines, "Use 道具卯", 1, true) ~= nil, irlines)
check("obj.IR 提示行不再复述怪名", string.find(irlines, "- 召唤怪卯", 1, true) == nil, irlines)

-- meta.itemreq 从不清空，会残留到同任务后续目标的节点上；判据必须认 QTYPE 而不是它
ResetNodes()
CURZONE = 121
pfDB.quests.data[8118] = { lvl = 40, min = 40, obj = { IR = { 6119 }, U = { 9033 } } }
pfDB.quests.zhCN[8118] = { T = "任务申二", O = "目标申二", D = "描述" }
pfDB.items.zhCN[6119] = "道具申二"
pfDB["quests-itemreq"].data[6119] = { [9032] = 1 }
pfDB.units.data[9032] = { coords = { { 81.1, 82.2, 121, 300 } }, lvl = "40" }
pfDB.units.zhCN[9032] = "用道具的目标申二"
pfDB.units.data[9033] = { coords = { { 83.3, 84.4, 121, 300 } }, lvl = "40" }
pfDB.units.zhCN[9033] = "普通击杀目标申二"
pfDatabase.Reload()
QLOG.title, QLOG.complete, QLOG.boards = "任务申二", nil, {}
pfDatabase.itemlist.db["道具申二"] = true
pfDatabase:SearchQuestID(8118, { addon = "PFQUEST", qlogid = 1 })

local irnode, killnode
for _, p in ipairs(PINS) do
  if p.spawn == "用道具的目标申二" then irnode = p end
  if p.spawn == "普通击杀目标申二" then killnode = p end
end
check("IR 节点与击杀节点都画出来了", irnode ~= nil and killnode ~= nil)
check("残留证据：击杀节点确实带着上一分支的 itemreq",
      killnode and killnode.itemreq == "道具申二", killnode and tostring(killnode.itemreq))
local irhover = table.concat(Hover("用道具的目标申二"), "\n")
local killhover = table.concat(Hover("普通击杀目标申二"), "\n")
check("IR 目标出使用道具行", string.find(irhover, "Use 道具申二", 1, true) ~= nil, irhover)
check("击杀目标不出使用道具行（QTYPE 判据挡住了残留）",
      string.find(killhover, "Use 道具申二", 1, true) == nil, killhover)

----------------------------------------------------------------------
-- 用例 12：召唤不影响描述文案 —— 按 obj 类型正常显示
-- （召唤专用措辞已废除：箭头只说"击杀 X"/"拾取 X 来自 Y"，
--   召唤这一步由鼠标指向召唤源时的"召唤 X"行承担）
----------------------------------------------------------------------
ResetNodes()
CURZONE = 110
pfDB.units.data[9011] = { coords = {}, lvl = "40" }
pfDB.units.data[9011].summon = { O = 7011, I = 6110 }   -- I 进 meta，供提示行说"使用某物"
pfDB.units.zhCN[9011] = "召唤怪子"
pfDB.items.zhCN[6110] = "召唤法器"
pfDB.objects.data[7011] = { coords = { { 22.0, 44.0, 110, 0 } } }
pfDB.objects.zhCN[7011] = "祭坛子"
pfDatabase.Reload()

pfDatabase:SearchMobID(9011, { addon = "T", quest = "任务子", QTYPE = "UNIT_OBJECTIVE" })
check("召唤怪的图钉存在", table.getn(PINS) == 1, "实得 " .. table.getn(PINS))

local descKill = pfDatabase:BuildQuestDescription({
  title = "任务子", quest = "任务子", QTYPE = "UNIT_OBJECTIVE", spawn = "召唤怪子",
})
local descPlain = pfDatabase:BuildQuestDescription({
  title = "任务子", quest = "任务子", QTYPE = "UNIT_OBJECTIVE", spawn = "普通怪子",
})
check("击杀链描述就是普通击杀措辞",
      descKill and descPlain and string.gsub(descPlain, "普通怪子", "召唤怪子") == descKill,
      tostring(descKill) .. "  vs  " .. tostring(descPlain))
check("描述不再提召唤物品",
      descKill and string.find(descKill, "召唤法器", 1, true) == nil, tostring(descKill))

local descLoot = pfDatabase:BuildQuestDescription({
  title = "任务子", quest = "任务子", QTYPE = "ITEM_OBJECTIVE_LOOT",
  spawn = "召唤怪子", item = "战利品子",
})
check("拾取链描述是拾取措辞",
      descLoot and string.find(descLoot, "战利品子", 1, true) ~= nil
        and string.find(descLoot, "召唤怪子", 1, true) ~= nil, tostring(descLoot))

-- summon.I 进 meta 供提示行用；上面"描述不再提召唤物品"那条守着箭头不许再提
check("summon.I 解析进 meta.summonsrc.item",
      PINS[1] and PINS[1].summonsrc and PINS[1].summonsrc.item == "召唤法器",
      PINS[1] and PINS[1].summonsrc and tostring(PINS[1].summonsrc.item))

----------------------------------------------------------------------
-- 用例 12b：真正的 meta 复用 —— 同一个 meta 表连续两次调用
-- （用例 12 用的是各自新建的表，测不出"复用时字段未被清空"。
--   spawnalias 与 summonsrc 都是复用敏感字段，两个都得盯）
----------------------------------------------------------------------
ResetNodes()
CURZONE = 111
pfDB.units.data[9012] = { coords = {}, lvl = "40", summon = { O = 7012, I = 6112 } }
pfDB.units.zhCN[9012] = "召唤怪丑"
pfDB.objects.data[7012] = { coords = { { 24.0, 48.0, 111, 0 } } }
pfDB.objects.zhCN[7012] = "祭坛丑"
pfDB.items.data[6112] = {}
pfDB.items.zhCN[6112] = "道具丑"
pfDB.units.data[9030] = { coords = { { 26.0, 52.0, 111, 300 } }, lvl = "40" }
pfDB.units.zhCN[9030] = "普通怪丑"
pfDatabase.Reload()

local shared = { addon = "T", quest = "任务辰", QTYPE = "UNIT_OBJECTIVE" }
pfDatabase:SearchMobID(9012, shared)   -- 有召唤源，应写入别名
pfDatabase:SearchMobID(9030, shared)   -- 无召唤源，复用同一个 meta
check("复用 meta：第一次带上召唤源别名",
      PINS[1] and PINS[1].spawnalias == "祭坛丑", PINS[1] and tostring(PINS[1].spawnalias))
check("复用 meta：第二次不残留别名",
      PINS[2] and PINS[2].spawnalias == nil,
      PINS[2] and tostring(PINS[2].spawnalias) or "无第二个图钉")
check("复用 meta：第一次带上召唤物品名",
      PINS[1] and PINS[1].summonsrc and PINS[1].summonsrc.item == "道具丑",
      PINS[1] and PINS[1].summonsrc and tostring(PINS[1].summonsrc.item))
check("复用 meta：第二次不残留召唤物品名",
      PINS[2] and PINS[2].summonsrc == nil,
      PINS[2] and tostring(PINS[2].summonsrc) or "无第二个图钉")

----------------------------------------------------------------------
-- 用例 13：meta 字段不跨 Search* 泄漏
-- 同一任务里 obj.U(召唤怪) 先跑、obj.O(无关物件) 后跑，共用同一个 meta 表
----------------------------------------------------------------------
ResetNodes()
CURZONE = 114
QLOG.title, QLOG.complete = "任务巳", nil
QLOG.boards = {}
pfDB.quests.data[8114] = { lvl = 40, min = 40,
  obj = { U = { 9015 }, O = { 7016 } } }
pfDB.quests.zhCN[8114] = { T = "任务巳", O = "目标巳", D = "描述" }
pfDB.units.data[9015] = { coords = {}, lvl = "40" }
pfDB.units.data[9015].summon = { O = 7015, I = 6115 }
pfDB.units.zhCN[9015] = "召唤怪巳"
pfDB.objects.data[7015] = { coords = { { 30.0, 60.0, 114, 0 } } }
pfDB.objects.zhCN[7015] = "祭坛巳"
pfDB.objects.data[7016] = { coords = { { 32.0, 64.0, 114, 0 } } }
pfDB.objects.zhCN[7016] = "无关物件巳"
pfDB.items.data[6115] = {}
pfDB.items.zhCN[6115] = "道具巳"
pfDatabase.Reload()

pfDatabase:SearchQuestID(8114, { addon = "PFQUEST", qlogid = 1 })

local stray
for _, p in ipairs(PINS) do
  if p.spawn == "无关物件巳" then stray = p end
end
check("无关物件的图钉存在", stray ~= nil)
check("无关物件不带召唤源别名", stray and stray.spawnalias == nil,
      stray and tostring(stray.spawnalias))
check("无关物件不带召唤物品名（SearchObjectID 清空了它）",
      stray and stray.summonsrc == nil, stray and tostring(stray.summonsrc))

----------------------------------------------------------------------
-- 用例 14：summon.U —— 单位召唤源，坐标取自该单位的全部落点
----------------------------------------------------------------------
ResetNodes()
CURZONE = 114
pfDB.units.data[9020] = { coords = {}, lvl = "50" }
pfDB.units.data[9020].summon = { U = 9021 }
pfDB.units.zhCN[9020] = "召唤怪未"
pfDB.units.data[9021] = { coords = { { 12.1, 13.2, 114, 300 }, { 14.3, 15.4, 114, 300 } }, lvl = "50" }
pfDB.units.zhCN[9021] = "宿主怪未"
pfDatabase.Reload()

pfDatabase:SearchMobID(9020, { addon = "T", quest = "任务未", QTYPE = "UNIT_OBJECTIVE" })
check("summon.U 每个宿主落点各一个图钉", table.getn(PINS) == 2, "实得 " .. table.getn(PINS))
check("summon.U 坐标取自宿主单位", PINS[1] and PINS[1].x == 12.1 and PINS[1].y == 13.2)
check("summon.U spawn 仍是被召唤者", PINS[1] and PINS[1].spawn == "召唤怪未", PINS[1] and PINS[1].spawn)
check("summon.U 别名是宿主名", PINS[1] and PINS[1].spawnalias == "宿主怪未", PINS[1] and tostring(PINS[1].spawnalias))
check("summon.U 保留宿主的 respawn", PINS[1] and PINS[1].respawn == "300s", PINS[1] and tostring(PINS[1].respawn))

----------------------------------------------------------------------
-- 用例 14b：真实落点优先于 summon.U；宿主无坐标时安全返回
----------------------------------------------------------------------
ResetNodes()
CURZONE = 115
pfDB.units.data[9022] = { coords = { { 21.1, 22.2, 115, 300 } }, lvl = "50", summon = { U = 9021 } }
pfDB.units.zhCN[9022] = "召唤怪申"
pfDB.units.data[9023] = { coords = {}, lvl = "50", summon = { U = 9024 } }
pfDB.units.zhCN[9023] = "召唤怪酉"
pfDB.units.data[9024] = { coords = {}, lvl = "50" }
pfDB.units.zhCN[9024] = "空宿主酉"
pfDatabase.Reload()

pfDatabase:SearchMobID(9022, { addon = "T", quest = "任务申", QTYPE = "UNIT_OBJECTIVE" })
check("有真实落点时不走 summon.U", PINS[1] and PINS[1].x == 21.1, PINS[1] and tostring(PINS[1].x))
local before = table.getn(PINS)
pfDatabase:SearchMobID(9023, { addon = "T", quest = "任务酉", QTYPE = "UNIT_OBJECTIVE" })
check("宿主无坐标时不画图钉且不报错", table.getn(PINS) == before, "实得 " .. table.getn(PINS))

----------------------------------------------------------------------
-- 用例 15：三段链 obj.I -> item.U -> summon.U（4642 融合软泥怪的形态）
----------------------------------------------------------------------
ResetNodes()
CURZONE = 116
pfDB.units.data[9025] = { coords = {}, lvl = "50", summon = { U = 9026, I = 6116 } }
pfDB.units.zhCN[9025] = "召唤怪戌"
pfDB.units.data[9026] = { coords = { { 31.1, 32.2, 116, 300 } }, lvl = "50" }
pfDB.units.zhCN[9026] = "宿主怪戌"
pfDB.items.data[6117] = { U = { [9025] = 100 } }
pfDB.items.zhCN[6117] = "样本戌"
pfDB.items.data[6116] = {}
pfDB.items.zhCN[6116] = "药剂戌"
pfDB.quests.data[8116] = { obj = { I = { 6117 } } }
pfDB.quests.zhCN[8116] = { T = "任务戌" }
pfDatabase.Reload()

QLOG.title, QLOG.complete = "任务戌", nil
QLOG.boards = { { "样本戌：0/1", "item", nil } }
pfDatabase:SearchQuestID(8116, { addon = "T", quest = "任务戌", questid = 8116 })

local chain
for _, p in ipairs(PINS) do
  if not p.cluster and p.spawn == "召唤怪戌" then chain = p end
end
check("三段链走到宿主坐标", chain and chain.x == 31.1, chain and tostring(chain.x) or "无节点")
check("三段链带上目标物品名", chain and chain.item == "样本戌", chain and tostring(chain.item))
check("三段链带上宿主别名", chain and chain.spawnalias == "宿主怪戌", chain and tostring(chain.spawnalias))
check("三段链解析出召唤道具", chain and chain.summonsrc and chain.summonsrc.item == "药剂戌",
      chain and chain.summonsrc and tostring(chain.summonsrc.item))
check("三段链记下召唤源是单位", chain and chain.summonsrc and chain.summonsrc.kind == "U",
      chain and chain.summonsrc and tostring(chain.summonsrc.kind))
-- PINS 是 AddNode 之前的副本，description 还没算（item 也还是字符串），这里现算。
-- 箭头现在也说召唤源那句话：目标怪还没被召唤出来，说"拾取样本"玩家没法照做
local chaindesc = chain and pfDatabase:BuildQuestDescription(chain)
check("三段链箭头说对宿主用道具",
      chaindesc and string.find(chaindesc, "宿主怪戌", 1, true) ~= nil
        and string.find(chaindesc, "药剂戌", 1, true) ~= nil, tostring(chaindesc))
check("三段链箭头不再说拾取样本",
      chaindesc and string.find(chaindesc, "样本戌", 1, true) == nil, tostring(chaindesc))

-- 宿主自己也是单位，传 isunit=true 也必须出召唤行（名字不同时名字判据说话）。
-- 这条钉住「isunit 只在同名时当裁判」：放宽成"是单位就不出"会把三段链打回原形。
local hov = Hover("宿主怪戌", true)
local joined = table.concat(hov, "\n")
check("指向宿主显示任务名", string.find(joined, "任务戌", 1, true) ~= nil, joined)
-- { U, I } 形态：说"对<宿主>使用<道具>"
check("指向宿主显示对它用道具", string.find(joined, "On 宿主怪戌 use 药剂戌", 1, true) ~= nil, joined)
-- 召唤源不掉样本，进度行归被召唤者与地图图钉，指向宿主只说"召唤谁"
check("指向宿主不显示物品进度", string.find(joined, "样本戌", 1, true) == nil, joined)
check("指向宿主只有任务名与召唤行两行", table.getn(hov) == 2, joined)

local hov2 = Hover("召唤怪戌", true)
local joined2 = table.concat(hov2, "\n")
check("指向被召唤者不显示召唤行",
      string.find(joined2, "On 宿主怪戌 use", 1, true) == nil, joined2)
check("指向被召唤者仍显示物品进度", string.find(joined2, "样本戌: 0/1", 1, true) ~= nil, joined2)

----------------------------------------------------------------------
-- 用例 16：召唤行的边界 —— 同名靠 isunit 分、未接任务照样出、无 hovered 不出
----------------------------------------------------------------------
ResetNodes()
CURZONE = 117
pfDB.units.data[9027] = { coords = {}, lvl = "50", summon = { O = 7017 } }
pfDB.units.zhCN[9027] = "同名火亥"
pfDB.objects.data[7017] = { coords = { { 41.1, 42.2, 117, 0 } } }
pfDB.objects.zhCN[7017] = "同名火亥"
pfDatabase.Reload()

QLOG.title, QLOG.boards = nil, {}
pfDatabase:SearchMobID(9027, { addon = "T", quest = "任务亥", QTYPE = "UNIT_OBJECTIVE" })
-- 同名时名字判不出来，全靠 isunit：场景物不是单位 -> 是召唤源本体
local sameObj = table.concat(Hover("同名火亥", nil), "\n")
check("同名·指向场景物时出召唤行",
      string.find(sameObj, "Use 同名火亥", 1, true) ~= nil, sameObj)
local sameUnit = table.concat(Hover("同名火亥", true), "\n")
check("同名·指向怪物时不出召唤行",
      string.find(sameUnit, "Summon", 1, true) == nil, sameUnit)
check("同名·指向怪物时任务名照常显示",
      string.find(sameUnit, "任务亥", 1, true) ~= nil, sameUnit)

ResetNodes()
CURZONE = 118
pfDB.units.data[9028] = { coords = {}, lvl = "50", summon = { O = 7018 } }
pfDB.units.zhCN[9028] = "召唤怪寅"
pfDB.objects.data[7018] = { coords = { { 51.1, 52.2, 118, 0 } } }
pfDB.objects.zhCN[7018] = "祭坛寅"
pfDatabase.Reload()

QLOG.title, QLOG.boards = nil, {}
pfDatabase:SearchMobID(9028, { addon = "T", quest = "任务寅", QTYPE = "UNIT_OBJECTIVE" })
local notakenlines = Hover("祭坛寅")
local notaken = table.concat(notakenlines, "\n")
check("未接任务时召唤行照样出", string.find(notaken, "Use 祭坛寅", 1, true) ~= nil, notaken)
-- 未接任务时兜底分支本会再打一行"- 召唤怪寅"（spawn 名），召唤源上同样要让开
check("未接任务时召唤源不出兜底行", table.getn(notakenlines) == 2, notaken)

-- 地图图钉悬停走 map.lua 的另一个调用点，没有 hovered 名字，不该出召唤行。
-- 主语必须是上面那个【带别名】的节点，换成普通怪就测不出东西了。
-- 且必须取 AddNode 存下的真节点：PINS 是 AddNode 之前的副本，那里的 item 还是字符串，
-- 喂给 ShowTooltip 会在 pairs(meta.item) 处炸，测不到图钉悬停的真实形态。
local aliasnode
for _, obj in pairs(pfMap.tooltips["祭坛寅"] or {}) do
  if obj[118] then aliasnode = obj[118] end
end
check("图钉用例的主语确实带别名", aliasnode and aliasnode.spawnalias == "祭坛寅",
      aliasnode and tostring(aliasnode.spawnalias))
local pinlines = {}
GameTooltip.AddLine = function(self, text) table.insert(pinlines, text) end
pfMap:ShowTooltip(aliasnode, GameTooltip)
check("无 hovered 参数时不出召唤行",
      string.find(table.concat(pinlines, "\n"), "Summon", 1, true) == nil,
      table.concat(pinlines, "\n"))
check("无 hovered 参数时任务名照常显示",
      string.find(table.concat(pinlines, "\n"), "任务寅", 1, true) ~= nil,
      table.concat(pinlines, "\n"))

-- 普通怪（无 spawnalias）不该出召唤行 —— 守卫的另一半
ResetNodes()
CURZONE = 119
pfDB.units.data[9029] = { coords = { { 61.1, 62.2, 119, 300 } }, lvl = "50" }
pfDB.units.zhCN[9029] = "普通怪卯"
pfDatabase.Reload()
QLOG.title, QLOG.boards = nil, {}
pfDatabase:SearchMobID(9029, { addon = "T", quest = "任务卯", QTYPE = "UNIT_OBJECTIVE" })
local plain = table.concat(Hover("普通怪卯"), "\n")
check("普通怪不出召唤行", string.find(plain, "Summon", 1, true) == nil, plain)
check("普通怪任务名照常显示", string.find(plain, "任务卯", 1, true) ~= nil, plain)

----------------------------------------------------------------------
-- 用例 19：obj.A / obj.Z 接在召唤目标之后 —— 这两个 Search* 也得清空两个字段
-- （此前没有用例走到它们，那几行清空是纯防御，删掉也没人发现）
----------------------------------------------------------------------
ResetNodes()
CURZONE = 120
pfDB.quests.data[8117] = { lvl = 40, min = 40, obj = { U = { 9031 }, A = { 900951 }, Z = { 900950 } } }
pfDB.quests.zhCN[8117] = { T = "任务未二", O = "目标未二", D = "描述" }
pfDB.units.data[9031] = { coords = {}, lvl = "40", summon = { O = 7017, I = 6118 } }
pfDB.units.zhCN[9031] = "召唤怪未二"
pfDB.objects.data[7017] = { coords = { { 71.1, 72.2, 120, 0 } } }
pfDB.objects.zhCN[7017] = "祭坛未二"
pfDB.items.data[6118] = {}
pfDB.items.zhCN[6118] = "道具未二"
pfDB.areatrigger.data[900951] = { coords = { { 75.5, 76.6, 120 } } }
pfDB.zones.data[900950] = { 120, 100, 100, 73.3, 74.4 }
pfDB.zones.zhCN[900950] = "区域未二"
pfDatabase.Reload()

QLOG.title, QLOG.complete, QLOG.boards = "任务未二", nil, {}
pfDatabase:SearchQuestID(8117, { addon = "PFQUEST", qlogid = 1 })

local summoned, zonepin
for _, p in ipairs(PINS) do
  if p.spawn == "召唤怪未二" then summoned = p end
  if p.spawn == "区域未二" then zonepin = p end
end
check("召唤目标带上召唤道具名",
      summoned and summoned.summonsrc and summoned.summonsrc.item == "道具未二",
      summoned and summoned.summonsrc and tostring(summoned.summonsrc.item) or "无召唤图钉")
check("区域图钉存在", zonepin ~= nil)
check("区域图钉不残留召唤源别名", zonepin and zonepin.spawnalias == nil,
      zonepin and tostring(zonepin.spawnalias))
check("区域图钉不残留召唤源", zonepin and zonepin.summonsrc == nil,
      zonepin and tostring(zonepin.summonsrc))

-- obj.A 探索目标同理：SearchAreaTriggerID 的两行清空此前同样没有用例覆盖
local trigpin
for _, p in ipairs(PINS) do
  if p.spawntype == "Trigger" then trigpin = p end
end
check("探索图钉存在", trigpin ~= nil)
check("探索图钉不残留召唤源别名", trigpin and trigpin.spawnalias == nil,
      trigpin and tostring(trigpin.spawnalias))
check("探索图钉不残留召唤源", trigpin and trigpin.summonsrc == nil,
      trigpin and tostring(trigpin.summonsrc))

----------------------------------------------------------------------
-- 用例 20：summon 的四种形态各说一句固定措辞
----------------------------------------------------------------------
local function strip(t) return (string.gsub(string.gsub(t, "|c........", ""), "|r", "")) end

local FORMS = {
  { z = 130, u = 9040, s = 9041, kind = "U", item = nil,  want = "Talk to 源辰一" },
  { z = 131, u = 9042, s = 9043, kind = "U", item = 6130, want = "On 源辰二 use 道具辰二" },
  { z = 132, u = 9044, s = 7040, kind = "O", item = nil,  want = "Use 源辰三" },
  { z = 133, u = 9046, s = 7041, kind = "O", item = 6133, want = "On 源辰四 use 道具辰四" },
}
local FORMNAME = { "{ U } 与某人交谈", "{ U, I } 对某人使用某物",
                   "{ O } 使用某物件", "{ O, I } 对某物件使用某物" }

for i, f in ipairs(FORMS) do
  ResetNodes()
  CURZONE = f.z
  local srcname = "源辰" .. ({ "一", "二", "三", "四" })[i]
  local summon = { [f.kind] = f.s }
  if f.item then
    summon.I = f.item
    pfDB.items.zhCN[f.item] = "道具辰" .. ({ "一", "二", "三", "四" })[i]
  end
  pfDB.units.data[f.u] = { coords = {}, lvl = "40", summon = summon }
  pfDB.units.zhCN[f.u] = "被召唤者辰" .. i
  if f.kind == "U" then
    pfDB.units.data[f.s] = { coords = { { 10.0 + i, 20.0 + i, f.z, 300 } }, lvl = "45" }
    pfDB.units.zhCN[f.s] = srcname
  else
    pfDB.objects.data[f.s] = { coords = { { 10.0 + i, 20.0 + i, f.z, 0 } } }
    pfDB.objects.zhCN[f.s] = srcname
  end
  pfDatabase.Reload()
  QLOG.title, QLOG.boards = nil, {}
  pfDatabase:SearchMobID(f.u, { addon = "T", quest = "任务辰" .. i, QTYPE = "UNIT_OBJECTIVE" })

  local hov = table.concat(Hover(srcname, f.kind == "U"), "\n")
  check("形态 " .. FORMNAME[i] .. "：世界提示", string.find(hov, f.want, 1, true) ~= nil, hov)
  local desc = PINS[1] and strip(pfDatabase:BuildQuestDescription(PINS[1]))
  check("形态 " .. FORMNAME[i] .. "：导航箭头", desc == f.want, tostring(desc))
end

----------------------------------------------------------------------
-- 用例 21：本体节点永远赢过借坐标的召唤节点（与插入顺序无关）
-- 源与被召唤者掉同一件任务物品时，同一任务在同一坐标上会冒出两个节点，
-- 槽位只有一个。谁先建谁赢的话，pairs 顺序会随机吃掉本体那条进度信息。
----------------------------------------------------------------------
local function clashsetup()
  ResetNodes()
  CURZONE = 134
  pfDB.units.data[9050] = { coords = { { 40.0, 41.0, 134, 300 } }, lvl = "50" }
  pfDB.units.zhCN[9050] = "本体怪巳二"
  pfDB.units.data[9051] = { coords = {}, lvl = "50", summon = { U = 9050, I = 6134 } }
  pfDB.units.zhCN[9051] = "被召唤者巳二"
  pfDB.items.zhCN[6134] = "道具巳二"
  pfDatabase.Reload()
  QLOG.title, QLOG.complete, QLOG.boards = "任务巳二", nil, { { "战利品巳二：0/5", "item", nil } }
end

local function clashrun(order)
  clashsetup()
  for _, id in ipairs(order) do
    pfDatabase:SearchMobID(id, { addon = "T", quest = "任务巳二",
      QTYPE = "ITEM_OBJECTIVE_LOOT", item = "战利品巳二", droprate = 100 })
  end
  local slot
  for _, bymap in pairs(pfMap.nodes["T"] or {}) do
    for _, bytitle in pairs(bymap) do
      for _, node in pairs(bytitle) do slot = node end
    end
  end
  local reg
  for _, bymap in pairs(pfMap.tooltips["本体怪巳二"] or {}) do
    for _, node in pairs(bymap) do reg = node end
  end
  return slot, reg, table.concat(Hover("本体怪巳二", true), "\n")
end

for _, case in ipairs({ { { 9050, 9051 }, "本体先入" }, { { 9051, 9050 }, "召唤节点先入" } }) do
  local slot, reg, hov = clashrun(case[1])
  check("撞车（" .. case[2] .. "）：槽位归本体",
        slot and slot.spawn == "本体怪巳二", slot and tostring(slot.spawn))
  check("撞车（" .. case[2] .. "）：提示键归本体",
        reg and reg.spawn == "本体怪巳二", reg and tostring(reg.spawn))
  check("撞车（" .. case[2] .. "）：指向本体拿到进度而不是召唤提示",
        string.find(hov, "战利品巳二", 1, true) ~= nil
          and string.find(hov, "道具巳二", 1, true) == nil, hov)
end

----------------------------------------------------------------------
-- 用例 22：召唤类图钉的抬头是召唤源，提示与世界里指向召唤源时一字不差
----------------------------------------------------------------------
ResetNodes()
CURZONE = 135
pfDB.units.data[9060] = { coords = {}, lvl = "60", summon = { U = 9061, I = 6135 } }
pfDB.units.zhCN[9060] = "被召唤者午二"
pfDB.units.data[9061] = { coords = { { 50.0, 51.0, 135, 300 } }, lvl = "55" }
pfDB.units.zhCN[9061] = "源午二"
pfDB.items.zhCN[6135] = "道具午二"
pfDatabase.Reload()
QLOG.title, QLOG.complete, QLOG.boards = "任务午二", nil, {}
pfDatabase:SearchMobID(9060, { addon = "T", quest = "任务午二", QTYPE = "UNIT_OBJECTIVE" })

local pinnode
for _, obj in pairs(pfMap.tooltips["源午二"] or {}) do
  if obj[135] then pinnode = obj[135] end
end
check("图钉节点存在", pinnode ~= nil)

local head, pinlines = nil, {}
GameTooltip.SetText = function(self, text) head = text end
GameTooltip.AddDoubleLine = function(self, a, b) table.insert(pinlines, strip(tostring(a)) .. tostring(b)) end
GameTooltip.AddLine = function(self, text) table.insert(pinlines, strip(text)) end
this = { spawn = pinnode.spawn, spawnid = pinnode.spawnid, summonsrc = pinnode.summonsrc,
         level = pinnode.level, spawntype = pinnode.spawntype, respawn = pinnode.respawn,
         node = { ["任务午二"] = pinnode }, GetParent = function() return nil end }
pfMap:NodeEnter()

check("图钉抬头是召唤源而不是被召唤者", strip(tostring(head)) == "源午二", tostring(head))
check("图钉等级取召唤源的",
      string.find(table.concat(pinlines, "\n"), "55", 1, true) ~= nil, table.concat(pinlines, "\n"))
check("图钉提示与指向召唤源一致",
      string.find(table.concat(pinlines, "\n"), "On 源午二 use 道具午二", 1, true) ~= nil,
      table.concat(pinlines, "\n"))

----------------------------------------------------------------------
-- 用例 23：召唤源同时是任务交付者时，提示键归目标节点而不是交付标记
-- 40571 就是这个形态：伯特·马诺既是交付者，也是"与他交谈召唤恶魔"的召唤源。
-- 任务还没完成，那个感叹号点不动，玩家要看的是"现在该做什么"。
----------------------------------------------------------------------
local function enderfirst(order)
  ResetNodes()
  CURZONE = 136
  pfDB.units.data[9070] = { coords = {}, lvl = "40", summon = { U = 9071 } }
  pfDB.units.zhCN[9070] = "被召唤者申三"
  pfDB.units.data[9071] = { coords = { { 60.0, 61.0, 136, 300 } }, lvl = "40" }
  pfDB.units.zhCN[9071] = "交付者兼召唤源申三"
  pfDatabase.Reload()
  QLOG.title, QLOG.complete, QLOG.boards = "任务申三", nil, {}

  local steps = {
    ender = function()
      pfMap:AddNode({ addon = "T", zone = 136, x = 60.0, y = 61.0, title = "任务申三",
        quest = "任务申三", spawn = "交付者兼召唤源申三", spawnid = 9071,
        spawntype = "生物", QTYPE = "NPC_END", texture = "complete", layer = 3 })
    end,
    objective = function()
      pfDatabase:SearchMobID(9070, { addon = "T", quest = "任务申三", QTYPE = "UNIT_OBJECTIVE" })
    end,
  }
  for _, k in ipairs(order) do steps[k]() end
  return table.concat(Hover("交付者兼召唤源申三", true), "\n")
end

for _, case in ipairs({ { { "ender", "objective" }, "交付标记先入" },
                        { { "objective", "ender" }, "目标节点先入" } }) do
  local hov = enderfirst(case[1])
  check("交付者兼召唤源（" .. case[2] .. "）：出召唤提示",
        string.find(hov, "Talk to 交付者兼召唤源申三", 1, true) ~= nil, hov)
end

----------------------------------------------------------------------
-- 用例 24：summon.hint —— 条件复杂到四种措辞都套不上时，数据里给语言表的键
----------------------------------------------------------------------
ResetNodes()
CURZONE = 137
pfDB.units.data[9080] = { coords = {}, lvl = "50",
  summon = { U = 9081, I = 6137, hint = "Kill $source, then use $item, and $target shows up" } }
pfDB.units.zhCN[9080] = "被召唤者酉二"
pfDB.units.data[9081] = { coords = { { 70.0, 71.0, 137, 300 } }, lvl = "45" }
pfDB.units.zhCN[9081] = "源酉二"
pfDB.items.zhCN[6137] = "道具酉二"
pfDatabase.Reload()
QLOG.title, QLOG.complete, QLOG.boards = nil, nil, {}
pfDatabase:SearchMobID(9080, { addon = "T", quest = "任务酉二", QTYPE = "UNIT_OBJECTIVE" })

-- 桩环境没有语言表，pfQuest_Loc 缺键回落成键本身——正好验「没译文时回落到英文」
local hinthov = table.concat(Hover("源酉二", true), "\n")
check("hint 的 $source 换成召唤源名",
      string.find(hinthov, "Kill 源酉二,", 1, true) ~= nil, hinthov)
check("hint 的 $item 换成道具名",
      string.find(hinthov, "use 道具酉二,", 1, true) ~= nil, hinthov)
check("hint 的 $target 换成被召唤者名",
      string.find(hinthov, "and 被召唤者酉二 shows up", 1, true) ~= nil, hinthov)
check("hint 压过 { U, I } 的默认措辞",
      string.find(hinthov, "On 源酉二 use", 1, true) == nil, hinthov)

-- 装上译文：hint 必须查语言表，不能把键当成品文本直接吐出来
pfQuest_Loc["Kill $source, then use $item, and $target shows up"] = "打死$source，$target就出来了"
local zhhov = table.concat(Hover("源酉二", true), "\n")
check("hint 走语言表取译文",
      string.find(zhhov, "打死 源酉二", 1, true) == nil
        and string.find(zhhov, "打死", 1, true) ~= nil
        and string.find(zhhov, "被召唤者酉二就出来了", 1, true) ~= nil, zhhov)
check("有译文时不再吐英文键",
      string.find(zhhov, "shows up", 1, true) == nil, zhhov)
pfQuest_Loc["Kill $source, then use $item, and $target shows up"] = nil
check("hint 也是箭头文案",
      PINS[1] and string.find(pfDatabase:BuildQuestDescription(PINS[1]), "Kill", 1, true) ~= nil,
      PINS[1] and tostring(pfDatabase:BuildQuestDescription(PINS[1])))
-- 占位符替换出来的名字要跟内置四句一样上青色
check("占位符替换后自动上色",
      PINS[1] and string.find(pfDatabase:BuildQuestDescription(PINS[1]),
        "|cff33ffcc源酉二|r", 1, true) ~= nil,
      PINS[1] and tostring(pfDatabase:BuildQuestDescription(PINS[1])))
check("hint 不影响别名注册（图钉仍挂在召唤源名下）",
      PINS[1] and PINS[1].spawnalias == "源酉二", PINS[1] and tostring(PINS[1].spawnalias))

----------------------------------------------------------------------
-- 用例 25：多个召唤源 —— U 写成列表，每个落点认领自己那个源
----------------------------------------------------------------------
ResetNodes()
CURZONE = 138
pfDB.units.data[9090] = { coords = {}, lvl = "56",
  summon = { U = { 9091, 9092 }, hint = "Kill either to release $target" } }
pfDB.units.zhCN[9090] = "被召唤者戌二"
pfDB.units.data[9091] = { coords = { { 80.0, 81.0, 138, 300 }, { 82.0, 83.0, 138, 300 } }, lvl = "54" }
pfDB.units.zhCN[9091] = "源甲戌二"
pfDB.units.data[9092] = { coords = { { 84.0, 85.0, 138, 300 } }, lvl = "58" }
pfDB.units.zhCN[9092] = "源乙戌二"
pfDatabase.Reload()
QLOG.title, QLOG.complete, QLOG.boards = nil, nil, {}
pfDatabase:SearchMobID(9090, { addon = "T", quest = "任务戌二", QTYPE = "UNIT_OBJECTIVE" })

local bysrc = {}
for _, p in ipairs(PINS) do
  if p.spawnalias then bysrc[p.spawnalias] = (bysrc[p.spawnalias] or 0) + 1 end
end
check("两个源的落点都画出来了（2 + 1）",
      bysrc["源甲戌二"] == 2 and bysrc["源乙戌二"] == 1,
      "甲=" .. tostring(bysrc["源甲戌二"]) .. " 乙=" .. tostring(bysrc["源乙戌二"]))
check("每个落点认领自己的源等级",
      (function()
        for _, p in ipairs(PINS) do
          if p.spawnalias == "源乙戌二" and p.summonsrc.lvl ~= "58" then return false end
          if p.spawnalias == "源甲戌二" and p.summonsrc.lvl ~= "54" then return false end
        end
        return true
      end)())
check("指向源甲出 hint",
      string.find(table.concat(Hover("源甲戌二", true), "\n"), "Kill either to release 被召唤者戌二", 1, true) ~= nil)
check("指向源乙同样出 hint",
      string.find(table.concat(Hover("源乙戌二", true), "\n"), "Kill either to release 被召唤者戌二", 1, true) ~= nil)

-- 单个 id 的老写法必须原样可用
ResetNodes()
CURZONE = 140
pfDB.units.data[9093] = { coords = {}, lvl = "50", summon = { U = 9094 } }
pfDB.units.zhCN[9093] = "被召唤者亥二"
pfDB.units.data[9094] = { coords = { { 90.0, 91.0, 140, 300 } }, lvl = "50" }
pfDB.units.zhCN[9094] = "源亥二"
pfDatabase.Reload()
pfDatabase:SearchMobID(9093, { addon = "T", quest = "任务亥二", QTYPE = "UNIT_OBJECTIVE" })
check("单 id 写法不受影响", PINS[1] and PINS[1].spawnalias == "源亥二",
      PINS[1] and tostring(PINS[1].spawnalias))

----------------------------------------------------------------------
-- 目标图钉：SearchQuestID 每个目标还会额外画一个汇总（cluster）节点，这里只数目标本身
function ObjPins()
  local out = {}
  for _, p in ipairs(PINS) do if not p.cluster then table.insert(out, p) end end
  return out
end

----------------------------------------------------------------------
-- 用例 26：对话目标的日志文本与 NPC 名字对不上时，仍认得出完成
-- 40285 的实况：日志写"与守护者伊塞卢斯交谈"，NPC 叫"守护者艾瑟勒斯"，服务端翻译不一致
----------------------------------------------------------------------
ResetNodes()
CURZONE = 142
QLOG.title, QLOG.complete = "任务子三", nil
QLOG.boards = { { "与守护者伊塞卢斯交谈：1/1", "monster", nil } }
pfDB.quests.data[8142] = { lvl = 40, min = 40, obj = { T = { 9142 } } }
pfDB.quests.zhCN[8142] = { T = "任务子三", O = "与守护者艾瑟勒斯交谈", D = "描述" }
pfDB.units.data[9142] = { coords = { { 30.0, 31.0, 142, 300 } }, lvl = "58" }
pfDB.units.zhCN[9142] = "守护者艾瑟勒斯"
pfDatabase.Reload()

pfDatabase:SearchQuestID(8142, { addon = "PFQUEST", qlogid = 1 })
check("名字对不上但已完成时不再画图钉", table.getn(ObjPins()) == 0, "实得 " .. table.getn(ObjPins()))

-- 同一条链路未完成时照常画
ResetNodes()
QLOG.boards = { { "与守护者伊塞卢斯交谈：0/1", "monster", nil } }
pfDatabase:SearchQuestID(8142, { addon = "PFQUEST", qlogid = 1 })
check("名字对不上但未完成时照常画", table.getn(ObjPins()) == 1, "实得 " .. table.getn(ObjPins()))

----------------------------------------------------------------------
-- 用例 26b：措辞完全认不出来的目标行同样能归属（单目标时唯一可归）
----------------------------------------------------------------------
ResetNodes()
CURZONE = 143
QLOG.title, QLOG.complete = "任务丑三", nil
QLOG.boards = { { "已听完往事：1/1", "monster", nil } }
pfDB.quests.data[8143] = { lvl = 40, min = 40, obj = { T = { 9143 } } }
pfDB.quests.zhCN[8143] = { T = "任务丑三", O = "听老兵讲往事", D = "描述" }
pfDB.units.data[9143] = { coords = { { 32.0, 33.0, 143, 300 } }, lvl = "58" }
pfDB.units.zhCN[9143] = "老兵丑三"
pfDatabase.Reload()

pfDatabase:SearchQuestID(8143, { addon = "PFQUEST", qlogid = 1 })
check("措辞认不出时单目标也算完成", table.getn(ObjPins()) == 0, "实得 " .. table.getn(ObjPins()))

----------------------------------------------------------------------
-- 用例 26c：多个对话目标时不猜 —— 认不出名字就一个都不算完成
----------------------------------------------------------------------
ResetNodes()
CURZONE = 144
QLOG.title, QLOG.complete = "任务寅三", nil
QLOG.boards = {
  { "与甲使者交谈：1/1", "monster", nil },
  { "与乙使者交谈：0/1", "monster", nil },
}
pfDB.quests.data[8144] = { lvl = 40, min = 40, obj = { T = { 9144, 9145 } } }
pfDB.quests.zhCN[8144] = { T = "任务寅三", O = "与两位使者交谈", D = "描述" }
pfDB.units.data[9144] = { coords = { { 34.0, 35.0, 144, 300 } }, lvl = "58" }
pfDB.units.zhCN[9144] = "使者寅三甲"
pfDB.units.data[9145] = { coords = { { 36.0, 37.0, 144, 300 } }, lvl = "58" }
pfDB.units.zhCN[9145] = "使者寅三乙"
pfDatabase.Reload()

pfDatabase:SearchQuestID(8144, { addon = "PFQUEST", qlogid = 1 })
check("多目标且名字都对不上时两个都留着", table.getn(ObjPins()) == 2, "实得 " .. table.getn(ObjPins()))

----------------------------------------------------------------------
-- 用例 26d：名字对得上时仍按名字归属，不受回退影响
----------------------------------------------------------------------
ResetNodes()
CURZONE = 145
QLOG.title, QLOG.complete = "任务卯三", nil
QLOG.boards = {
  { "与使者卯三甲交谈：1/1", "monster", nil },
  { "与使者卯三乙交谈：0/1", "monster", nil },
}
pfDB.quests.data[8145] = { lvl = 40, min = 40, obj = { T = { 9146, 9147 } } }
pfDB.quests.zhCN[8145] = { T = "任务卯三", O = "与两位使者交谈", D = "描述" }
pfDB.units.data[9146] = { coords = { { 38.0, 39.0, 145, 300 } }, lvl = "58" }
pfDB.units.zhCN[9146] = "使者卯三甲"
pfDB.units.data[9147] = { coords = { { 40.0, 41.0, 145, 300 } }, lvl = "58" }
pfDB.units.zhCN[9147] = "使者卯三乙"
pfDatabase.Reload()

pfDatabase:SearchQuestID(8145, { addon = "PFQUEST", qlogid = 1 })
check("名字对得上时只留没完成的那个", table.getn(ObjPins()) == 1, "实得 " .. table.getn(ObjPins()))
check("留下的是未完成的乙", ObjPins()[1] and ObjPins()[1].spawn == "使者卯三乙",
      ObjPins()[1] and tostring(ObjPins()[1].spawn))

----------------------------------------------------------------------
-- 用例 27：objtext 配置 —— 自定义目标文本各归各（2681「禁锢我们的石头」的形态）
----------------------------------------------------------------------
ResetNodes()
CURZONE = 146
QLOG.title, QLOG.complete = "任务辰三", nil
QLOG.boards = {
  { "解放甲的仆从：3/3", "monster", nil },
  { "解放乙的仆从：0/3", "monster", nil },
}
pfDB.quests.data[8146] = { lvl = 40, min = 40, obj = { U = { 9148, 9149 } } }
pfDB.quests.zhCN[8146] = { T = "任务辰三", O = "解放仆从", D = "描述" }
pfDB.units.data[9148] = { coords = { { 42.0, 43.0, 146, 300 } }, lvl = "58" }
pfDB.units.zhCN[9148] = "甲的仆从辰三"
pfDB.units.data[9149] = { coords = { { 44.0, 45.0, 146, 300 } }, lvl = "58" }
pfDB.units.zhCN[9149] = "乙的仆从辰三"
pfDB.objtext.zhCN[8146] = {
  ["解放甲的仆从"] = { U = 9148 },
  ["解放乙的仆从"] = { U = 9149 },
}
pfDatabase.Reload()

pfDatabase:SearchQuestID(8146, { addon = "PFQUEST", qlogid = 1 })
check("配置命中后只剩没完成的那个", table.getn(ObjPins()) == 1, "实得 " .. table.getn(ObjPins()))
check("剩下的是乙", ObjPins()[1] and ObjPins()[1].spawn == "乙的仆从辰三",
      ObjPins()[1] and tostring(ObjPins()[1].spawn))

----------------------------------------------------------------------
-- 用例 27b：配置优先于常规「已被杀死」格式 —— 名字对得上也听配置的
----------------------------------------------------------------------
ResetNodes()
CURZONE = 147
QLOG.title, QLOG.complete = "任务巳三", nil
QLOG.boards = { { "甲怪巳三 已被杀死：3/3", "monster", nil } }
pfDB.quests.data[8147] = { lvl = 40, min = 40, obj = { U = { 9150, 9151 } } }
pfDB.quests.zhCN[8147] = { T = "任务巳三", O = "杀怪", D = "描述" }
pfDB.units.data[9150] = { coords = { { 46.0, 47.0, 147, 300 } }, lvl = "58" }
pfDB.units.zhCN[9150] = "甲怪巳三"
pfDB.units.data[9151] = { coords = { { 48.0, 49.0, 147, 300 } }, lvl = "58" }
pfDB.units.zhCN[9151] = "乙怪巳三"
pfDB.objtext.zhCN[8147] = { ["甲怪巳三 已被杀死"] = { U = 9151 } }
pfDatabase.Reload()

pfDatabase:SearchQuestID(8147, { addon = "PFQUEST", qlogid = 1 })
check("配置改判后留下的是甲", table.getn(ObjPins()) == 1 and ObjPins()[1].spawn == "甲怪巳三",
      ObjPins()[1] and tostring(ObjPins()[1].spawn))

----------------------------------------------------------------------
-- 用例 27c：一条目标行配多个 id（列表写法）
----------------------------------------------------------------------
ResetNodes()
CURZONE = 148
QLOG.title, QLOG.complete = "任务午三", nil
QLOG.boards = { { "扫清障碍：5/5", "monster", nil } }
pfDB.quests.data[8148] = { lvl = 40, min = 40, obj = { U = { 9152, 9153 } } }
pfDB.quests.zhCN[8148] = { T = "任务午三", O = "扫清障碍", D = "描述" }
pfDB.units.data[9152] = { coords = { { 50.0, 51.0, 148, 300 } }, lvl = "58" }
pfDB.units.zhCN[9152] = "障碍午三甲"
pfDB.units.data[9153] = { coords = { { 52.0, 53.0, 148, 300 } }, lvl = "58" }
pfDB.units.zhCN[9153] = "障碍午三乙"
pfDB.objtext.zhCN[8148] = { ["扫清障碍"] = { U = { 9152, 9153 } } }
pfDatabase.Reload()

pfDatabase:SearchQuestID(8148, { addon = "PFQUEST", qlogid = 1 })
check("列表写法两个都算完成", table.getn(ObjPins()) == 0, "实得 " .. table.getn(ObjPins()))

----------------------------------------------------------------------
-- 用例 27d：物品类目标行同样能配 —— 日志文本与物品名对不上
----------------------------------------------------------------------
ResetNodes()
CURZONE = 149
QLOG.title, QLOG.complete = "任务未三", nil
QLOG.boards = { { "收集碎片：8/8", "item", nil } }
pfDB.quests.data[8149] = { lvl = 40, min = 40, obj = { I = { 6149 } } }
pfDB.quests.zhCN[8149] = { T = "任务未三", O = "收集碎片", D = "描述" }
pfDB.items.data[6149] = { U = { [9154] = 100 } }
pfDB.items.zhCN[6149] = "神秘碎片未三"
pfDB.units.data[9154] = { coords = { { 54.0, 55.0, 149, 300 } }, lvl = "58" }
pfDB.units.zhCN[9154] = "碎片怪未三"
pfDatabase.Reload()

pfDatabase:SearchQuestID(8149, { addon = "PFQUEST", qlogid = 1 })
check("没配置时物品名对不上，图钉还在", table.getn(ObjPins()) == 1, "实得 " .. table.getn(ObjPins()))

ResetNodes()
pfDB.objtext.zhCN[8149] = { ["收集碎片"] = { I = 6149 } }
pfDatabase.Reload()
pfDatabase:SearchQuestID(8149, { addon = "PFQUEST", qlogid = 1 })
check("配上之后物品目标算完成", table.getn(ObjPins()) == 0, "实得 " .. table.getn(ObjPins()))

----------------------------------------------------------------------
-- 用例 27e：配置里没有这条任务时，一切照旧（回归）
----------------------------------------------------------------------
ResetNodes()
CURZONE = 150
QLOG.title, QLOG.complete = "任务申三", nil
QLOG.boards = { { "甲怪申三 已被杀死：3/3", "monster", nil } }
pfDB.quests.data[8150] = { lvl = 40, min = 40, obj = { U = { 9155, 9156 } } }
pfDB.quests.zhCN[8150] = { T = "任务申三", O = "杀怪", D = "描述" }
pfDB.units.data[9155] = { coords = { { 56.0, 57.0, 150, 300 } }, lvl = "58" }
pfDB.units.zhCN[9155] = "甲怪申三"
pfDB.units.data[9156] = { coords = { { 58.0, 59.0, 150, 300 } }, lvl = "58" }
pfDB.units.zhCN[9156] = "乙怪申三"
pfDatabase.Reload()

pfDatabase:SearchQuestID(8150, { addon = "PFQUEST", qlogid = 1 })
check("没配置时仍按名字归属", table.getn(ObjPins()) == 1 and ObjPins()[1].spawn == "乙怪申三",
      ObjPins()[1] and tostring(ObjPins()[1].spawn))

----------------------------------------------------------------------
-- 用例 28：objtext 也接进图钉提示的进度行 —— 名字对不上照样显示服务端原文
----------------------------------------------------------------------
ResetNodes()
CURZONE = 151
QLOG.title, QLOG.complete = "任务酉三", nil
QLOG.boards = { { "与守护者伊塞卢斯交谈：0/1", "monster", nil } }
pfDB.quests.data[8151] = { lvl = 40, min = 40, obj = { T = { 9157 } } }
pfDB.quests.zhCN[8151] = { T = "任务酉三", O = "与守护者交谈", D = "描述" }
pfDB.units.data[9157] = { coords = { { 60.0, 61.0, 151, 300 } }, lvl = "58" }
pfDB.units.zhCN[9157] = "守护者酉三"
pfDB.objtext.zhCN[8151] = { ["与守护者伊塞卢斯交谈"] = { U = 9157 } }
pfDatabase.Reload()

pfDatabase:SearchQuestID(8151, { addon = "PFQUEST", qlogid = 1 })
local tip28 = table.concat(Hover("守护者酉三"), "\n")
check("提示行显示服务端原文与进度",
      string.find(tip28, "与守护者伊塞卢斯交谈: 0/1", 1, true) ~= nil, tip28)

----------------------------------------------------------------------
-- 用例 28b：多目标各显示各的，不串台（2681 的形态）
----------------------------------------------------------------------
ResetNodes()
CURZONE = 152
QLOG.title, QLOG.complete = "任务戌三", nil
QLOG.boards = {
  { "解放甲的仆从：1/9", "monster", nil },
  { "解放乙的仆从：2/3", "monster", nil },
}
pfDB.quests.data[8152] = { lvl = 40, min = 40, obj = { U = { 9158, 9159 } } }
pfDB.quests.zhCN[8152] = { T = "任务戌三", O = "解放仆从", D = "描述" }
pfDB.units.data[9158] = { coords = { { 62.0, 63.0, 152, 300 } }, lvl = "58" }
pfDB.units.zhCN[9158] = "甲的仆从戌三"
pfDB.units.data[9159] = { coords = { { 64.0, 65.0, 152, 300 } }, lvl = "58" }
pfDB.units.zhCN[9159] = "乙的仆从戌三"
pfDB.objtext.zhCN[8152] = {
  ["解放甲的仆从"] = { U = 9158 },
  ["解放乙的仆从"] = { U = 9159 },
}
pfDatabase.Reload()

pfDatabase:SearchQuestID(8152, { addon = "PFQUEST", qlogid = 1 })
local tipA = table.concat(Hover("甲的仆从戌三"), "\n")
check("甲只显示自己那条", string.find(tipA, "解放甲的仆从: 1/9", 1, true) ~= nil, tipA)
check("甲不显示乙那条", string.find(tipA, "解放乙的仆从", 1, true) == nil, tipA)

----------------------------------------------------------------------
-- 用例 28c：场景物节点（O 槽）同样能显示
----------------------------------------------------------------------
ResetNodes()
CURZONE = 153
QLOG.title, QLOG.complete = "任务亥三", nil
QLOG.boards = { { "清点补给箱：2/5", "monster", nil } }
pfDB.quests.data[8153] = { lvl = 40, min = 40, obj = { T = { -7153 } } }
pfDB.quests.zhCN[8153] = { T = "任务亥三", O = "清点补给箱", D = "描述" }
pfDB.objects.data[7153] = { coords = { { 66.0, 67.0, 153, 0 } } }
pfDB.objects.zhCN[7153] = "补给箱亥三"
pfDB.objtext.zhCN[8153] = { ["清点补给箱"] = { O = 7153 } }
pfDatabase.Reload()

pfDatabase:SearchQuestID(8153, { addon = "PFQUEST", qlogid = 1 })
local tipO = table.concat(Hover("补给箱亥三"), "\n")
check("场景物节点显示进度行", string.find(tipO, "清点补给箱: 2/5", 1, true) ~= nil, tipO)

----------------------------------------------------------------------
-- 用例 28d：物品目标行（I 槽）—— 日志文本与物品名对不上时也能显示
----------------------------------------------------------------------
ResetNodes()
CURZONE = 154
QLOG.title, QLOG.complete = "任务子四", nil
QLOG.boards = { { "收集碎片：3/8", "item", nil } }
pfDB.quests.data[8154] = { lvl = 40, min = 40, obj = { I = { 6154 } } }
pfDB.quests.zhCN[8154] = { T = "任务子四", O = "收集碎片", D = "描述" }
pfDB.items.data[6154] = { U = { [9160] = 100 } }
pfDB.items.zhCN[6154] = "神秘碎片子四"
pfDB.units.data[9160] = { coords = { { 68.0, 69.0, 154, 300 } }, lvl = "58" }
pfDB.units.zhCN[9160] = "碎片怪子四"
pfDB.objtext.zhCN[8154] = { ["收集碎片"] = { I = 6154 } }
pfDatabase.Reload()

pfDatabase:SearchQuestID(8154, { addon = "PFQUEST", qlogid = 1 })
local tipI = table.concat(Hover("碎片怪子四"), "\n")
check("物品目标行也显示进度", string.find(tipI, "收集碎片: 3/8", 1, true) ~= nil, tipI)

----------------------------------------------------------------------
-- 用例 28e：没配 objtext 的任务，提示行行为一个字不变（回归）
----------------------------------------------------------------------
ResetNodes()
CURZONE = 155
QLOG.title, QLOG.complete = "任务丑四", nil
QLOG.boards = { { "普通怪丑四 已被杀死：2/6", "monster", nil } }
pfDB.quests.data[8155] = { lvl = 40, min = 40, obj = { U = { 9161 } } }
pfDB.quests.zhCN[8155] = { T = "任务丑四", O = "杀怪", D = "描述" }
pfDB.units.data[9161] = { coords = { { 70.0, 71.0, 155, 300 } }, lvl = "58" }
pfDB.units.zhCN[9161] = "普通怪丑四"
pfDatabase.Reload()

pfDatabase:SearchQuestID(8155, { addon = "PFQUEST", qlogid = 1 })
local tipN = table.concat(Hover("普通怪丑四"), "\n")
check("没配置时仍按常规格式显示", string.find(tipN, "普通怪丑四: 2/6", 1, true) ~= nil, tipN)

----------------------------------------------------------------------
-- 用例 29：route 重建后的指引箭头时序
--
-- 完成一个目标 -> UpdateNodes 重建路线（Reset + 一批 AddPoint）。重建后箭头
-- 必须立刻改指剩下的目标：曾经要等 route 自己的 tick / recalculate 门槛过期，
-- 玩家站着不动最坏 2 秒里箭头一直指着已经删掉图钉的旧目标。
-- 这里驱动的是真的 route.lua，不是复刻逻辑。
----------------------------------------------------------------------
pfQuest_config["arrow"] = "1"
pfQuest_config["routes"] = "1"
pfQuest_config["routeminimap"] = "0"
pfUI.api.GetColorGradient = function() return 1, 1, 1 end
pfUI.font_default = ""
pfUI_config = { global = { font_size = 12 } }
pfQuestCompat.GetPlayerFacing = function() return 0 end
function atan2(a, b) return math.atan(a, b) end
pfMap.HexDifficultyColor = function() return "|cffffffff" end
pfMap.str2rgb = function() return 1, 1, 1 end

-- 玩家固定在 (10,10)：不动才能暴露 tick 门槛（lastpos 不变时它才拦）
function GetPlayerMapPosition() return 0.10, 0.10 end

dofile("../route.lua")

local ARROW = pfQuest.route.arrow
for _, fs in pairs({ "title", "description", "distance" }) do
  local f = ARROW[fs]
  f.__text = ""
  f.SetText = function(s, t) s.__text = t end
end
ARROW.IsShown = function(s) return s.__shown end
ARROW.Show = function(s) s.__shown = true end
ARROW.Hide = function(s) s.__shown = false end
ARROW.__shown = true

-- 只有箭头读得到的字段才有意义：title / description / texture / priority
local function rnode(desc, tex)
  return { title = "路线任务", description = desc, texture = tex,
           priority = 1, layer = 9, cluster = true }
end

-- 推进 n 帧，两个 OnUpdate 都跑（游戏里它们是两个独立 frame）
local function rtick(n)
  for _ = 1, (n or 1) do
    NOW = NOW + 0.05
    this = pfQuest.route ; pfQuest.route.__scripts.OnUpdate()
    this = ARROW         ; ARROW.__scripts.OnUpdate()
  end
end

NOW = 1000
pfQuest.route:Reset()
pfQuest.route:AddPoint({ "12", "12", rnode("击杀 目标A", "texA") })  -- 近
pfQuest.route:AddPoint({ "80", "80", rnode("击杀 目标B", "texB") })  -- 远
rtick(3)
check("route 稳态指向最近的目标", ARROW.description.__text == "击杀 目标A|r.",
  ARROW.description.__text)
check("route 稳态箭头是显示的", ARROW.__shown == true)

-- 目标 A 完成：重建路线，只剩 B。玩家原地不动
pfQuest.route:Reset()
pfQuest.route:AddPoint({ "80", "80", rnode("击杀 目标B", "texB") })

rtick(1)
check("route 重建后 1 帧就改指新目标", ARROW.description.__text == "击杀 目标B|r.",
  ARROW.description.__text)
check("route 重建期间箭头没被隐藏", ARROW.__shown == true)
check("route 重建后立刻算出距离", pfQuest.route.coords[1][4] ~= nil)

rtick(25)
check("route 跑满 1 秒后不回退", ARROW.description.__text == "击杀 目标B|r.",
  ARROW.description.__text)

-- AddPoint 的顺序是 pfMap.nodes 的哈希序，不保证由近到远
pfQuest.route:Reset()
pfQuest.route:AddPoint({ "80", "80", rnode("击杀 远点", "texF") })
pfQuest.route:AddPoint({ "12", "12", rnode("击杀 近点", "texN") })
rtick(2)
check("route 乱序建点后仍排到最近的点", ARROW.description.__text == "击杀 近点|r.",
  ARROW.description.__text)

----------------------------------------------------------------------
-- 用例 30：similar_nodes 键必须区分 item 与 questid
--
-- 这张缓存表模块级、从不清空。键撞上就整份复用旧 meta，于是：
--   a) 同一只怪掉两条同名任务的不同物品 -> 后来的任务拿到前一条的物品名
--   b) 同名任务在同一 NPC 同一图层     -> 节点挂着兄弟任务的 questid
-- 两条都要按「先做 A，再做 B」的真实顺序验证：单独做 B 永远是对的。
----------------------------------------------------------------------
CURZONE = 700
QLOG.title, QLOG.complete, QLOG.boards = "同名书", nil, {}

-- 同一只怪同时掉两条同名任务要的两种不同物品
pfDB.units.data[9400] = { coords = { { 40.0, 41.0, 700, 300 } }, lvl = "12" }
pfDB.units.zhCN[9400] = "双掉落怪"
pfDB.items.data[7401] = { U = { [9400] = 30 } }
pfDB.items.zhCN[7401] = "物品甲"
pfDB.items.data[7402] = { U = { [9400] = 30 } }
pfDB.items.zhCN[7402] = "物品乙"
-- 同名的两条任务，交付 NPC 也是同一个
pfDB.units.data[9401] = { coords = { { 60.0, 61.0, 700, 0 } }, lvl = "12" }
pfDB.units.zhCN[9401] = "同一个交付人"
pfDB.quests.data[8400] = { lvl = 12, min = 12, obj = { I = { 7401 } }, ["end"] = { U = { 9401 } } }
pfDB.quests.zhCN[8400] = { T = "同名书", O = "收集物品甲", D = "描述甲" }
pfDB.quests.data[8401] = { lvl = 12, min = 12, obj = { I = { 7402 } }, ["end"] = { U = { 9401 } } }
pfDB.quests.zhCN[8401] = { T = "同名书", O = "收集物品乙", D = "描述乙" }
pfDatabase.Reload()

-- 按 spawn 名字取「同名书」标题槽位下的节点。不按坐标查：同一个刷点会派生出
-- 带微小偏移的副本，且桌面 Lua 5.5 把 60.0 拼成 "60.0" 而 1.12 的 5.0 拼成 "60"。
local function nodeOf(spawn)
  for _, maps in pairs(pfMap.nodes) do
    if maps[700] then
      for _, byTitle in pairs(maps[700]) do
        local n = byTitle["同名书"]
        if n and n.spawn == spawn then return n end
      end
    end
  end
end

-- 第一步：先做 8400，把缓存填上
ResetNodes()
pfDatabase:SearchQuestID(8400, { addon = "PFQUEST", qlogid = 1 })
local drop1, ender1 = nodeOf("双掉落怪"), nodeOf("同一个交付人")
check("30 前置：8400 的掉落点物品是物品甲", drop1 and drop1.item and drop1.item[1] == "物品甲",
  drop1 and tostring(drop1.item and drop1.item[1]))
check("30 前置：8400 的交付点 questid 是 8400", ender1 and tonumber(ender1.questid) == 8400,
  ender1 and tostring(ender1.questid))

-- 第二步：8400 交掉，接同名的 8401。pfQuest 每次任务更新都先按标题删节点，
-- 但 similar_nodes 不会跟着清 —— 这一步就是回归点。
pfMap:DeleteNode("PFQUEST", "同名书")
pfDatabase:SearchQuestID(8401, { addon = "PFQUEST", qlogid = 1 })
local drop2, ender2 = nodeOf("双掉落怪"), nodeOf("同一个交付人")

check("30a 同名任务换了物品，掉落点不再显示上一条的物品名",
  drop2 and drop2.item and drop2.item[1] == "物品乙",
  drop2 and tostring(drop2.item and drop2.item[1]))
check("30a 掉落点的 description 说的是物品乙",
  drop2 and drop2.description and strfind(drop2.description, "物品乙", 1, true) ~= nil,
  drop2 and tostring(drop2.description))
check("30b 同名任务的交付点挂当前 questid，不是兄弟任务的",
  ender2 and tonumber(ender2.questid) == 8401,
  ender2 and tostring(ender2.questid))

----------------------------------------------------------------------
print(string.format("\n通过 %d，失败 %d", pass, fail))
if fail > 0 then os.exit(1) end
