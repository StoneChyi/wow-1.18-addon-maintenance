# pfQuest 引擎测试

`run.lua` 在桌面 Lua 里搭一套 WoW API 桩环境（`harness.lua`），直接 `dofile`
上级目录的 `map.lua` 与 `database.lua`，对召唤坐标回退等纯逻辑跑断言。

    cd pfQuest/tests && lua run.lua

曾有一个 `run_legacy.lua` 专测 patchtable 对老版 pfQuest 引擎的降级段。
2026-08-13 起不再兼容老版本，降级段与该用例一并删除。

此目录**不出现在 `pfQuest.toc` 里**，游戏客户端不会加载它。

本机 Lua 是 5.5，而插件代码写给 1.12 的 Lua 5.0，`harness.lua` 补回被移除的
`table.getn` / `string.gfind` 等。

## 用例设计约束

`map.lua` 的 `similar_nodes` 是模块级缓存，键含坐标、任务名与 spawn。
**每个用例必须用互不相同的任务 id、任务名和坐标**，否则跨用例复用节点，
断言会读到上一个用例的残留。

## 另一套测试

这里测的是**引擎逻辑**，`pfDB` 是空壳、用例自己塞假数据。测**合并产物**
（真实全量 db 跑完 `overwrites` 与 `patchtable` 之后的最终值）的那套在
`pfQuest-turtle/tests/run_merge.lua`，两者互补但不能在同一个进程里跑。

放那边而不是这里，是因为本目录被 `.gitignore` 排掉了（pfQuest 是 vendored
上游插件，测试桩留在本地免得升级时碍事），而那套测试验的是我们自己在乌龟层
做的数据修订，该跟着乌龟层进版本库。
