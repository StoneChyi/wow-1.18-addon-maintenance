# pfQuest-turtle 合并产物核对

    cd Interface/AddOns/pfQuest-turtle/tests && lua run_merge.lua

失败时退出码为 1。本机 Lua 是 5.5，插件代码写给 1.12 的 Lua 5.0，`harness_db.lua`
补回被移除的 `table.getn` / `string.gfind` 等。

此目录**不出现在任何 `.toc` 里**，游戏客户端不会加载它 —— 客户端只加载 `.toc`
逐行列出的文件和其中 XML `<Include>` 的文件，不扫描目录（`pfQuest/toolbox/` 同理）。

## 存在的理由

**db 的最终值不是文件里写的值。** 要经过：

1. `pfQuest-turtle/overwrites.lua` 的删记录（`"_"`）、清字段，以及末尾那段把基础库的
   `start` / `end` / `obj` / `pre` / `close` / `class` / `skill` 七个字段抄进乌龟层
   空缺处的兜底循环；
2. `patchtable.lua` 把 `data-turtle` **整条**合并进 `data`。

只看 db 文件推断合并结果会漏算（"乌龟层没写某字段" ≠ "最终没有该字段"），用 Python
模拟这两步又容易跟代码走偏 —— 所以直接跑真的：`harness_db.lua` 按 `pfQuest.toc` /
`pfQuest-turtle.toc` 和各 `init/*.xml` 的顺序 `dofile` 真实数据文件，跑完两个
`overwrites.lua` 与 `patchtable.lua`，再对最终的 `pfDB.quests.data` 下断言。

改完 `db/*.lua` 跑一遍即可。

## 现有用例

1. **加载本身。** `overwrites.lua` 里有按 id 索引 `data-turtle` 的循环（清 `event`
   那段），db 条目被改坏会在加载期就报错，所以"加载不出错"本身就是一条断言。
2. **手工补的 `pre` 在合并后生效。** 写在乌龟层的要能压住基础库，写在基础库的要不被
   `patchtable` 冲掉，两个方向都验。
3. **每个 `pre` 来源都得是能做完的任务。** 前置被 `"_"` 删掉 / 合并后不存在 / 没有
   名字，目标就永远解锁不了 —— 786、7141、7142 栽过这个坑，见 `overwrites.lua`
   里那段注释。
4. **`pre` 图无环、无自指。** 环上的任务互相等，`QuestFilter` 永远放不出来。
   2026-09-11 修掉过一个（8595 ↔ 8579）和一个自指（8223）。
5. **`QuestFilter` 的实际行为。** 空历史下隐藏，做完任一前置后放出来。
6. **有意跳过的战场重复任务不该被顺手补上 `pre`。**
7. **互斥组（`close`）。** 整组都要列全；`/db query` 的回包处理器**不该**把互斥兄弟
   伪造进 history。驱动的是 `patchtable.lua` 里真实的 `OnEvent`，不是复刻。
8. **互斥组在 `QuestFilter` 里就被挡住**，不依赖 `/db query`。history 里只放真正交掉
   的那一条，模拟"刚交完还没同步"。
9. **分叉任务链**：选了一边，被放弃那边整条 6 环都不该显示。两种 history 各验一次。

用例 7~9 覆盖的是 2026-09-11 对 `patchtable.lua` 的两处改动（`QuestFilter` 加互斥组
检查、`complete()` 去掉 close 展开），**包裹层是真代码**——`harness_db.lua` 在加载
`patchtable.lua` 之前放了一个复刻的 `QuestFilter` 基座供它包裹，所以跑的是线上那份
包裹逻辑，只有基座里 history / pre 那几关是复刻的。

`harness_db.lua` 里那个 `QuestFilter` 基座复刻的是 `pfQuest/database.lua` 里与
任务栏 / history / `pre` 有关的四段；等级 / 种族 / 职业 / 专业 / 节日那几条与本文件
关注点无关，没有复刻。上游改动 `QuestFilter` 时记得同步。查可见性用 `Visible(id, history)`。

## 加断言前

**先做负向对照** —— 故意把值改错，确认断言真的会挂，再改回来。否则很容易写出恒真的
断言，跑得再绿也说明不了什么。

## 另一套测试

`pfQuest/tests/run.lua` 测的是**引擎逻辑**（召唤坐标回退、tooltip 文案、同名任务串号
……），`pfDB` 是空壳、用例自己塞假数据，跟本目录正好互补，但两者不能在同一个进程里跑。
那个目录被 `.gitignore` 排掉了（pfQuest 是 vendored 上游，测试桩留在本地免得升级时
碍事），只在磁盘上，跑法见它自己的 README.md。
