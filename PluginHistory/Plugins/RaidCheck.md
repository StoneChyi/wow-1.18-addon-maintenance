# RaidCheck 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/RaidCheck.md)

## 插件概况

- 分类：经过版本迭代或修改的插件。

- 插件：`RaidCheck`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

区分未检测成员，并增加团队分配工具。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

<a id="change-RaidCheck-20261012-01"></a>

### 2026-10-12｜迁入 10 月 10 日包（已部署）

- 记录编号：`RaidCheck-20261012-01`
- 记录类型：更新合并
- 游戏验收：待游戏验收
- 对应提交：[14f4a45](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/14f4a45cd67cda2afb4becfe145d1344a2d87222)


- 目的与处理：更新职业色、基础 BUFF 跨队分配、骑士分配继承与交换。
- 主要文件：`RaidCheck.lua`、`RaidCheckBuffAssign.lua`。
- 依据：[实施记录](../Research/插件更新实施-20261012.md)及[逐文件校验](../Research/插件更新实施-20261012.json)；更新前标签 `before/package-update-20261012`。
- 验证：本次 74 个 Lua 语法、7 个 XML 与 TOC/XML 文件引用核对通过；新增库初始化、聊天条/BigWigs、字体前置条件和金额修复见关联检查，HealComm/NotGrid 106 组行为通过。现用文件与已审查候选逐字节一致。
- 未确认：尚未做真实 1.12 游戏验收；具体多人通信、首领战斗、邮件操作或界面行为按实施记录列出的范围继续验证。

<a id="change-RaidCheck-20261011-01"></a>

### 2026-10-11｜两包更新与个人版三方核对（未部署）

- 记录编号：`RaidCheck-20261011-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：[0b5c895](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/0b5c8959ca36a914bb144edc25225506adddbf67)


- 目的与证据：按用户补充的 10 月 5 日包，对照 10 月 10 日包和当前个人版；详见[三方核对报告](../Research/三方插件更新核对-20261005-20261010-20261011.md)。不据文件相等推断作者或最早来源。
- 两包变化：RaidCheck.lua、RaidCheckBuffAssign.lua 增加职业色、基础 BUFF 跨队分配、骑士换人继承分配。
- 个人版处理：两个待更新文件当前等于旧包，XML 三份相同；需检查团队分配与皮肤。
- 验证与未确认：本次只核对原始字节/差异及文本试算；新包本次改变或新增的 75 个 Lua 全部通过 Lua 5.1 语法检查。未修改本插件功能，未部署候选，真实 1.12 加载、界面和多人行为待后续验收。


## 早期历史汇总与维护依据

<details>
<summary>展开早期原始说明与证据（不是当前问题或优化清单）</summary>

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

区分未检测成员，并增加团队分配工具。

### 记录中的修改

- 修正奥抗索引，区分离线/死亡/距离过远的未检测成员与真正缺 buff/装等/抗性；报告消息合并并节流。
- 移植团队 Buff/诅咒/坦克/骑士祝福分配，自动检测骑士、职业图标和名单下拉；密语补 buff 检查复用发送队列。
- 坦克高级分配支持坦克/治疗和目标，修正通报、输入框和职业色；任务分配子窗口支持保存与通报。
- 10-05 修正萨满祭司完整职业名、同组重复选择和坦克占位排除治疗候选。
- S_ChatBar 右键“查”打开分配界面，pfUI-addonskinner 跟进动态窗口。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [Icons/classicons.blp](../../Interface/AddOns/RaidCheck/Icons/classicons.blp)
- [RaidCheck.lua](../../Interface/AddOns/RaidCheck/RaidCheck.lua)
- [RaidCheck.xml](../../Interface/AddOns/RaidCheck/RaidCheck.xml)
- [RaidCheckBuffAssign.lua](../../Interface/AddOns/RaidCheck/RaidCheckBuffAssign.lua)

### 关联插件

[S_ChatBar](S_ChatBar.md)、[pfUI-addonskinner](pfUI-addonskinner.md)、[PallyPower](PallyPower.md)。更新时同时检查对应入口与数据口径。

### 已回退方案及更新注意

09-30 已删除 PallyPower 自动关联，最终祝福分配/通报按 HDLRaidTools 口径；图标首字标签及主窗口补 buff 按钮等中间方案也已撤回。不能把笔记中的 BOM 排查结论当普遍编码转换要求。

### 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

### 待补充

分配数据在各阶段有会话保存的限制，当前所需持久化范围及团队实测结果请补充。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/RaidCheck)
- [Interface/AddOns/RaidCheck/.workbuddy/memory/2026-09-27.md](../../Interface/AddOns/RaidCheck/.workbuddy/memory/2026-09-27.md)
- [Interface/AddOns/RaidCheck/.workbuddy/memory/2026-09-29.md](../../Interface/AddOns/RaidCheck/.workbuddy/memory/2026-09-29.md)
- [Interface/AddOns/RaidCheck/.workbuddy/memory/2026-09-30.md](../../Interface/AddOns/RaidCheck/.workbuddy/memory/2026-09-30.md)
- [Interface/AddOns/RaidCheck/.workbuddy/memory/2026-10-02.md](../../Interface/AddOns/RaidCheck/.workbuddy/memory/2026-10-02.md)
- [Interface/AddOns/RaidCheck/.workbuddy/memory/2026-10-05.md](../../Interface/AddOns/RaidCheck/.workbuddy/memory/2026-10-05.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。


---

[返回插件修改记录](README.md)

</details>
