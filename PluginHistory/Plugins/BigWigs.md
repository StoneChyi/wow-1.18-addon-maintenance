# BigWigs 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/BigWigs.md)

## 插件概况

- 插件：`BigWigs`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

适配乌龟服首领、中文日志以及竖行计时条。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

<a id="change-BigWigs-20261012-01"></a>

### 2026-10-12｜迁入 10 月 10 日包（已部署）

- 记录编号：`BigWigs-20261012-01`
- 记录类型：更新合并
- 游戏验收：待游戏验收
- 对应提交：[f5eee32](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/f5eee321230abae57ce1efd914c0e94fc9be17ed)


- 目的与处理：更新集合刷 BUFF 语音/命令、竖条点击通报及首领提醒，保留已有阶段备份。
- 主要文件：`Plugins/Pulltimer.lua`、`Plugins/Sound.lua`、`Plugins/VerticalBars.lua`、`Raids/AQ20/Guardians.lua`、`Raids/AQ20/Kurinaxx.lua`、`Raids/BWL/Broodlord.lua`、`Raids/BWL/Vaelastrasz.lua`、`Raids/Karazhan/ClawlordHowlfang.lua`、`Raids/Karazhan/KaraTrash.lua`、`Raids/Karazhan/Mephistroth.lua`、`Raids/MC/AncientCoreHound.lua`、`Raids/MC/Thaurissan.lua`、`Raids/Naxxramas/Anubrekhan.lua`、`Raids/Naxxramas/Gluth.lua`、`Raids/Naxxramas/Horsemen.lua`、`Raids/Naxxramas/Razuvious.lua`、`Raids/Naxxramas/SpiderTrash.lua`、`Raids/TMH/Partath.lua`、`Raids/TMH/Rotgrowl.lua`、`Raids/TMH/TimbermawTrash.lua`、`Raids/TMH/Ursol.lua`。
- 依据：[实施记录](../Research/插件更新实施-20261012.md)及[逐文件校验](../Research/插件更新实施-20261012.json)；更新前标签 `before/package-update-20261012`。
- 验证：本次 74 个 Lua 语法、7 个 XML 与 TOC/XML 文件引用核对通过；新增库初始化、聊天条/BigWigs、字体前置条件和金额修复见关联检查，HealComm/NotGrid 106 组行为通过。现用文件与已审查候选逐字节一致。
- 未确认：尚未做真实 1.12 游戏验收；具体多人通信、首领战斗、邮件操作或界面行为按实施记录列出的范围继续验证。

<a id="change-BigWigs-20261011-01"></a>

### 2026-10-11｜两包更新与个人版三方核对（未部署）

- 记录编号：`BigWigs-20261011-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：[0b5c895](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/0b5c8959ca36a914bb144edc25225506adddbf67)


- 目的与证据：按用户补充的 10 月 5 日包，对照 10 月 10 日包和当前个人版；详见[三方核对报告](../Research/三方插件更新核对-20261005-20261010-20261011.md)。不据文件相等推断作者或最早来源。
- 两包变化：21 个 Lua 更新：集合刷 BUFF、竖行条通报、自身中文日志锚定、帕萨斯/腐嚎/木喉小怪/乌索尔提醒。
- 个人版处理：21 个待更新文件当前均等于旧包；未发现额外独立个人功能文件差异，既有定制内容已出现在旧包。可按明确文件迁移，战斗与同步待验收。
- 验证与未确认：本次只核对原始字节/差异及文本试算；新包本次改变或新增的 75 个 Lua 全部通过 Lua 5.1 语法检查。未修改本插件功能，未部署候选，真实 1.12 加载、界面和多人行为待后续验收。


## 早期历史汇总与维护依据

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

适配乌龟服首领、中文日志以及竖行计时条。

### 记录中的修改

- 新增或调整木喉要塞提里奥克等首领模块；修正完整首领名、中文技能名、%s/%t 目标 token 和标点导致的标记失败。
- 加入 VerticalBars 竖行条，处理等待区排序；屏蔽原条时保留护盾、狂暴、减益等必须显示的特殊计时条。
- 世界首领冷却增加双状态检测并修正重复击杀误报；Threat.Enable 和版本查询增加空值兼容。
- 修正奈法利安猎人/盗贼等中文职业点名、首领菜单翻译和拉格纳罗斯坦克提醒刷屏。
- 对自身日志使用明确身份归一与锚定，避免名字含“你”时全团误报；涉及卡拉赞、木喉要塞和其他团本。
- CommonAuras 增加奴役恶魔与大恶魔叛变计时，修正换宠清理；Comm 支持小队同步。
- 佩罗萨恩净化火焰、魔网观察者光束、阿诺玛鲁斯过载等增加或修正喊话/声音提醒。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

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

### 已回退方案及更新注意

只迁移有实际用途的最终触发规则；不要重用旧的时间戳换宠旁路，也不要把无法解析的字面 token 当玩家名。日期笔记比长期备忘更能反映最终调整。

### 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

### 待补充

首领模块数量较多，各场战斗的最终实测情况请按需补充。

### 依据

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


---

[返回插件修改记录](README.md)
