# BigWigs 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

适配乌龟服首领、中文日志以及竖行计时条。

## 记录中的修改

- 新增或调整木喉要塞提里奥克等首领模块；修正完整首领名、中文技能名、%s/%t 目标 token 和标点导致的标记失败。
- 加入 VerticalBars 竖行条，处理等待区排序；屏蔽原条时保留护盾、狂暴、减益等必须显示的特殊计时条。
- 世界首领冷却增加双状态检测并修正重复击杀误报；Threat.Enable 和版本查询增加空值兼容。
- 修正奈法利安猎人/盗贼等中文职业点名、首领菜单翻译和拉格纳罗斯坦克提醒刷屏。
- 对自身日志使用明确身份归一与锚定，避免名字含“你”时全团误报；涉及卡拉赞、木喉要塞和其他团本。
- CommonAuras 增加奴役恶魔与大恶魔叛变计时，修正换宠清理；Comm 支持小队同步。
- 佩罗萨恩净化火焰、魔网观察者光束、阿诺玛鲁斯过载等增加或修正喊话/声音提醒。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [Plugins/Comm.lua](../../Interface/AddOns/BigWigs/Plugins/Comm.lua)
- [Plugins/CommonAuras.lua](../../Interface/AddOns/BigWigs/Plugins/CommonAuras.lua)
- [Plugins/Threat.lua](../../Interface/AddOns/BigWigs/Plugins/Threat.lua)
- [Plugins/Version.lua](../../Interface/AddOns/BigWigs/Plugins/Version.lua)
- [Plugins/VerticalBars.lua](../../Interface/AddOns/BigWigs/Plugins/VerticalBars.lua)
- [Plugins/WorldBossCooldown.lua](../../Interface/AddOns/BigWigs/Plugins/WorldBossCooldown.lua)
- [Raids/BWL/Nefarian.lua](../../Interface/AddOns/BigWigs/Raids/BWL/Nefarian.lua)
- [Raids/Karazhan/Anomalus.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/Anomalus.lua)
- [Raids/Karazhan/BroodQueenAraxxna.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/BroodQueenAraxxna.lua)
- [Raids/Karazhan/ChessFight.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/ChessFight.lua)
- [Raids/Karazhan/ClawlordHowlfang.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/ClawlordHowlfang.lua)
- [Raids/Karazhan/DarkRiderChampion.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/DarkRiderChampion.lua)
- [Raids/Karazhan/EchoOfMedivh.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/EchoOfMedivh.lua)
- [Raids/Karazhan/Grizikil.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/Grizikil.lua)
- [Raids/Karazhan/Incantagos.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/Incantagos.lua)
- [Raids/Karazhan/KaraTrash.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/KaraTrash.lua)
- [Raids/Karazhan/KeeperGnarlmoon.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/KeeperGnarlmoon.lua)
- [Raids/Karazhan/Kruul.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/Kruul.lua)
- [Raids/Karazhan/LordBlackwaldII.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/LordBlackwaldII.lua)
- [Raids/Karazhan/Mephistroth.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/Mephistroth.lua)
- [Raids/Karazhan/Moroes.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/Moroes.lua)
- [Raids/Karazhan/PhantomServant.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/PhantomServant.lua)
- [Raids/Karazhan/Rupturan.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/Rupturan.lua)
- [Raids/Karazhan/SanvTasdal.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/SanvTasdal.lua)
- [Raids/MC/Ragnaros.lua](../../Interface/AddOns/BigWigs/Raids/MC/Ragnaros.lua)
- [Raids/TMH/Karrsh.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Karrsh.lua)
- [Raids/TMH/Kronn.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Kronn.lua)
- [Raids/TMH/Loktanag.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Loktanag.lua)
- [Raids/TMH/Ormanos.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Ormanos.lua)
- [Raids/TMH/Partath.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Partath.lua)
- [Raids/TMH/Perotharn.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Perotharn.lua)
- [Raids/TMH/Rotgrowl.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Rotgrowl.lua)
- [Raids/TMH/Selenaxx.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Selenaxx.lua)
- [Raids/TMH/TimbermawTrash.lua](../../Interface/AddOns/BigWigs/Raids/TMH/TimbermawTrash.lua)
- [Raids/TMH/Trioch.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Trioch.lua)
- [Raids/TMH/Ursol.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Ursol.lua)

## 已回退方案及更新注意

只迁移有实际用途的最终触发规则；不要重用旧的时间戳换宠旁路，也不要把无法解析的字面 token 当玩家名。日期笔记比长期备忘更能反映最终调整。

## 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

## 待补充

首领模块数量较多，各场战斗的最终实测情况请按需补充。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/BigWigs)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-08-21.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-08-21.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-08-25.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-08-25.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-08-28.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-08-28.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-01.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-01.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-02.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-02.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-04.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-04.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-08.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-08.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-09.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-09.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-13.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-13.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-15.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-15.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-17.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-17.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-18.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-18.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-19.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-19.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-23.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-23.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-24.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-24.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-28.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-28.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-29.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-29.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-10-02.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-10-02.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-10-03.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-10-03.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/MEMORY.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/MEMORY.md)
- [Interface/AddOns/BigWigs/Raids/BWL/Ezzel.lua.20260918125911.bak](../../Interface/AddOns/BigWigs/Raids/BWL/Ezzel.lua.20260918125911.bak)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
