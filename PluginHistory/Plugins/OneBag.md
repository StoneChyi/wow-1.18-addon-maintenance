# OneBag 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/OneBag.md)

## 插件概况

- 分类：经过版本迭代或修改的插件。

- 插件：`OneBag`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

解决整理卡灰、油类次数和拆分回归。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

<a id="change-OneBag-20261012-01"></a>

### 2026-10-12｜迁入 10 月 10 日包（已部署）

- 记录编号：`OneBag-20261012-01`
- 记录类型：更新合并
- 游戏验收：待游戏验收
- 对应提交：[afee1c2](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/afee1c2c14b3e5b73056cda419fb35b4d2d2f9be)


- 目的与处理：更新换包按钮悬停提示；主要 Lua 原样保留。
- 主要文件：`OneBag.xml`。
- 依据：[实施记录](../Research/插件更新实施-20261012.md)及[逐文件校验](../Research/插件更新实施-20261012.json)；更新前标签 `before/package-update-20261012`。
- 验证：本次 74 个 Lua 语法、7 个 XML 与 TOC/XML 文件引用核对通过；新增库初始化、聊天条/BigWigs、字体前置条件和金额修复见关联检查，HealComm/NotGrid 106 组行为通过。现用文件与已审查候选逐字节一致。
- 未确认：尚未做真实 1.12 游戏验收；具体多人通信、首领战斗、邮件操作或界面行为按实施记录列出的范围继续验证。

<a id="change-OneBag-20261011-01"></a>

### 2026-10-11｜两包更新与个人版三方核对（未部署）

- 记录编号：`OneBag-20261011-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：[0b5c895](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/0b5c8959ca36a914bb144edc25225506adddbf67)


- 目的与证据：按用户补充的 10 月 5 日包，对照 10 月 10 日包和当前个人版；详见[三方核对报告](../Research/三方插件更新核对-20261005-20261010-20261011.md)。不据文件相等推断作者或最早来源。
- 两包变化：OneBag.xml 仅增加换包按钮“更换背包”提示。
- 个人版处理：XML 当前等于旧包，主要 Lua 三份相同；没有背包核心或整理算法升级。
- 验证与未确认：本次只核对原始字节/差异及文本试算；新包本次改变或新增的 75 个 Lua 全部通过 Lua 5.1 语法检查。未修改本插件功能，未部署候选，真实 1.12 加载、界面和多人行为待后续验收。


## 早期历史汇总与维护依据

<details>
<summary>展开早期原始说明与证据（不是当前问题或优化清单）</summary>

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

解决整理卡灰、油类次数和拆分回归。

### 记录中的修改

- 钥匙链不再显示普通背包的材料计数。
- 乌龟服整理节奏/锁定等待调整；判断空格同时检查物品链接，避免陈旧锁将有物格清成空图标。
- SuperWoW 负数数量解释为油类充能，显示橙色 xN；普通堆叠恢复白字，低频轮询补刷。
- 统一数量显示时保留 button.count 副作用，恢复 Shift 拆分。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [OneBag.lua](../../Interface/AddOns/OneBag/OneBag.lua)
- [SortBags.lua](../../Interface/AddOns/OneBag/SortBags.lua)

### 关联插件

[aux-addon](aux-addon.md)。更新时同时检查对应入口与数据口径。

### 已回退方案及更新注意

不要只迁移充能显示而遗漏 09-25 的拆分回归修复；旧角色手动整理间隔与新默认值可能不同。

### 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

### 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/OneBag)
- [Interface/AddOns/OneBag/.workbuddy/memory/2026-09-18.md](../../Interface/AddOns/OneBag/.workbuddy/memory/2026-09-18.md)
- [Interface/AddOns/OneBag/.workbuddy/memory/2026-09-23.md](../../Interface/AddOns/OneBag/.workbuddy/memory/2026-09-23.md)
- [Interface/AddOns/OneBag/.workbuddy/memory/2026-09-25.md](../../Interface/AddOns/OneBag/.workbuddy/memory/2026-09-25.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。


---

[返回插件修改记录](README.md)

</details>
