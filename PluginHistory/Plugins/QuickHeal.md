# QuickHeal 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/QuickHeal.md)

## 插件概况

- 分类：经过版本迭代或修改的插件。

- 插件：`QuickHeal`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

2026-11-02：QuickHeal职责筛选共用自动识别，未知不当作非坦克，普通治疗保留。

2026-11-02：独立职责名单与TWA已撤除；普通治疗保留，职责限定宏无有效共享数据时不执行。

2026-11-02 已补记当前个人版维护署名 `StoneChyi & Codex`；仅新增 TOC metadata 与可见说明，原有功能、原作者和许可证保留。见[本次记录](#change-QuickHeal-20261102-01)。

同步内置 HealComm 预估清理修复，保证库加载顺序兼容。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

<a id="change-QuickHeal-20261102-03"></a>

### 2026-11-02｜接通自动统一职责服务

- 记录编号：`QuickHeal-20261102-03`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户确认将天赋查询和职责缓存整合进现有共享库和pfUI，减少重复查询与手动维护。
- 修改内容：OnLoad申请共享需求，既有mt/nonmt从同一provider取可靠数据，不复制名单；无可靠数据的受限动作停止，普通治疗与直接目标治疗保持。 维护署名StoneChyi & Codex、原作者和许可保留。
- 涉及文件：[QuickHeal.lua](../../Interface/AddOns/QuickHeal/QuickHeal.lua)、[QuickHeal.toc](../../Interface/AddOns/QuickHeal/QuickHeal.toc)。
- 检查结果：共享核心20项、pfUI11项、净界45组/预设21项/适配6项、桥与治疗15项、GoubayuHeal两组、HealComm/NotGrid106组、观察30组双模式、面板36项和共享属性回归通过；本轮13个Lua实际Lua5.0、XML/七TOC路径与编码/署名通过。[联合记录](../Research/统一天赋职责服务-20261102.md)。
- 未确认事项：本轮未游戏验收；混合天赋和协议异常保留未知，识别不等于实际任务分工；同名迟到包的协议限制仍存在，不声称实际资源降幅。

<a id="change-QuickHeal-20261102-02"></a>

### 2026-11-02｜撤除独立职责名单与TWA，保护旧宏范围

- 记录编号：`QuickHeal-20261102-02`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户确认撤除三个插件的独立手工职责分工，保留治疗和仇恨，并预留统一接口。
- 修改内容：移除四类名单CRUD/窗口/默认字段和TWA/分工广播；tanklist/tl仅停用提示。mt/nonmt在入口、自救、目标优先、候选及执行前使用统一数据，未知不算非坦克，无数据不触发校准或取消施法；普通治疗、直接选目标和HealComm保留。配套皮肤引用同步移除。 维护署名StoneChyi & Codex、原作者和许可保留。
- 涉及文件：[QuickHeal.lua](../../Interface/AddOns/QuickHeal/QuickHeal.lua)、[QuickHeal.toc](../../Interface/AddOns/QuickHeal/QuickHeal.toc)、[QuickHeal.xml](../../Interface/AddOns/QuickHeal/QuickHeal.xml)、[QuickHealDruid.lua](../../Interface/AddOns/QuickHeal/QuickHealDruid.lua)、[QuickHealPaladin.lua](../../Interface/AddOns/QuickHeal/QuickHealPaladin.lua)、[QuickHealPriest.lua](../../Interface/AddOns/QuickHeal/QuickHealPriest.lua)、[QuickHealShaman.lua](../../Interface/AddOns/QuickHeal/QuickHealShaman.lua)、[README.md](../../Interface/AddOns/QuickHeal/README.md)、[localization.en.lua](../../Interface/AddOns/QuickHeal/localization.en.lua)。
- 检查结果：14项共享/消费者联合检查、QuickHeal实际Lua5.0完整主文件场景、GoubayuHeal两组源函数场景、106组HealComm/NotGrid回归通过；本轮17个Lua文件实际Lua5.0语法、2个XML解析及编码/署名检查通过。详见[联合检查记录](../Research/独立职责撤除与统一接口-20261102.md)。
- 未确认事项：尚未在游戏验收真实界面、按键/施法及团队通信；没有部署真实职责提供者，默认职责未知，普通治疗不因此停用。旧账号配置不重置，旧名单不再消费。

<a id="change-QuickHeal-20261102-01"></a>

### 2026-11-02｜补记个人版维护署名，保留原作者与许可

- 记录编号：`QuickHeal-20261102-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户确认以 `StoneChyi & Codex` 统一标识现有个人版与后续插件维护。
- 修改内容：根 TOC 新增 `X-Maintained-By` 和限定个人修改范围的 `X-Maintenance-Scope`；现有 Notes／本地化 Notes 保留原文并追加可见维护署名，无 Notes 时新增。原作者、版权、许可证和早期修改归属继续按既有证据保留。本条只记录当日 metadata 维护，不代表重新实现早期功能。
- 涉及文件：[QuickHeal.toc](../../Interface/AddOns/QuickHeal/QuickHeal.toc)。
- 检查结果：9 项署名字节与幂等检查通过；本插件 TOC 与操作前 Git 字节的预期增量编辑完全一致，加载文件与顺序、BOM、既有编码和行尾保留；未进行游戏内插件列表显示验收。
- 关联说明：[统一维护署名规范](../MaintenanceAttribution.md)、[本次补记清单](../Research/插件维护署名-20261102.json)。

<a id="change-QuickHeal-20261010-01"></a>

### 2026-10-10｜同步内置 HealComm 预估清理修复

- 记录编号：`QuickHeal-20261010-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[fa644ef](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/fa644efccdb2a2079d63165d35c4b05287c6948a)


- 目的：为 NotGrid 治疗祷言残留修复同步依赖副本，避免 QuickHeal 先加载时使用旧实现；本次没有改动 QuickHeal 的选人或施法策略。
- 主要文件：[libs/HealComm-1.0/HealComm-1.0.lua](../../Interface/AddOns/QuickHeal/libs/HealComm-1.0/HealComm-1.0.lua)。与 [!Libs](%21Libs.md) 同步独立群体计时器、同一施法者新治疗替换旧状态并刷新原目标、正常施法结束的停止广播、预估到期过滤及缺失记录保护。仅替换相关逻辑，保留内置副本原有法术、翻译、其他代码及 UTF-8 无 BOM、CRLF。
- 版本：本地 AceLibrary 维护版本提高至 11733，上游 Revision 11732 标记保留；两份修复库无论谁先加载均提供修复行为，旧版本无法覆盖它们。
- 关联功能：[NotGrid](NotGrid.md) 预估显示、QuickHeal 中调用 getHeal 的选人计算，以及原有持续治疗/复活追踪。
- 验证：[Tools/tests/test_notgrid_incoming_heals.py](../../Tools/tests/test_notgrid_incoming_heals.py) 的 106 组 Lua 5.1 行为检查通过，覆盖两份库、中英文、通讯和调度清理、NotGrid 显示、持续治疗与复活，以及两种加载顺序；相关插件 Lua 语法和维护说明检查通过。
- 未确认：尚未游戏验收真实团队事件、与其他治疗插件同时启用的场景及 QuickHeal 完整选人流程；2026-10-10 前是否存在个人修改仍待补充。


## 早期历史汇总与维护依据

<details>
<summary>展开早期原始说明与证据（不是当前问题或优化清单）</summary>

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09；后续维护：2026-10-10。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；初始化部分为历史整理；2026-10-10 的实际维护另列于下文。

### 当前记录

初始化时已保存完整个人使用版快照，但在当时检索的阶段报告、修改备份索引、插件内开发笔记和相关维护提交中，尚未找到足以归属于本插件的个人修改说明。不能据此认定它从未修改，也不能将现有功能全部写成本项目新增。

### 待补充

如果你修改过此插件，请补充：改了什么、希望更新时保留什么；有大致日期、相关文件或截图描述更好。2026-10-10 前的修改归属仍待确认，不能把本次新维护反填为旧历史。

### 更新注意

没有经过核实的完整旧原包，暂不能自动区分个人修改与整合包带入内容。更新前保存提交，在独立目录比较现用版与新包，避免直接覆盖。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/QuickHeal)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。

---

[返回插件修改记录](README.md)

</details>
