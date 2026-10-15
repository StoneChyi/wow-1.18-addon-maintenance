# AtlasQuest 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/AtlasQuest.md)

## 插件概况

- 插件：`AtlasQuest`
- 维护状态：**有备份差异，来源待确认**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

补记可核对的任务本地化差异。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

现有依据尚不能拆分成日期可靠的逐次记录；下方保留早期汇总，不以本次整理日期代替修改日期。

## 早期历史汇总与维护依据

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有备份差异，来源待确认**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

补记可核对的任务本地化差异。

### 记录中的修改

- 现用 localization.cn.lua 相比 .bak 有新增副本标注、任务目标/奖励和条目调整，例如月神圣地废墟、水域污染；这只是现用文件与该阶段备份的差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [Locale/localization.cn.lua](../../Interface/AddOns/AtlasQuest/Locale/localization.cn.lua)

### 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

### 待补充

请确认是否本人增加乌龟服任务资料，还是随整合包更新带入；旧备份不是官方原版。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/AtlasQuest)
- [Interface/AddOns/AtlasQuest/Locale/localization.cn.lua.bak](../../Interface/AddOns/AtlasQuest/Locale/localization.cn.lua.bak)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。

---

[返回插件修改记录](README.md)
