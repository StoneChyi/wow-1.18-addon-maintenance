# PallyPower 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/PallyPower.md)

## 插件概况

- 分类：经过版本迭代或修改的插件。

- 插件：`PallyPower`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

增加单人操作与个人祝福，同时修正团队目标判断。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

现有依据尚不能拆分成日期可靠的逐次记录；下方保留早期汇总，不以本次整理日期代替修改日期。

## 早期历史汇总与维护依据

<details>
<summary>展开早期原始说明与证据（不是当前问题或优化清单）</summary>

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

增加单人操作与个人祝福，同时修正团队目标判断。

### 记录中的修改

- 单人模式参考 HolyHope 球形入口，独立缩放/位置/透明度/锁定及 buff 条；职业/宠物图标和计时状态修复。
- 新增个人祝福预设及菜单，保留原 PP_PerUser 等旧配置。
- 团队单位匹配避免 raid1 误中 raid10；区分大/小祝福目标和跳过条件。
- 修正小祝福图标、开关和缩放，与 pfUI 皮肤联动。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [PallyPower-Extensions.lua](../../Interface/AddOns/PallyPower/PallyPower-Extensions.lua)
- [PallyPower.lua](../../Interface/AddOns/PallyPower/PallyPower.lua)
- [PallyPower.toc](../../Interface/AddOns/PallyPower/PallyPower.toc)
- [PallyPower.xml](../../Interface/AddOns/PallyPower/PallyPower.xml)

### 关联插件

[pfUI-addonskinner](pfUI-addonskinner.md)、[RaidCheck](RaidCheck.md)。更新时同时检查对应入口与数据口径。

### 已回退方案及更新注意

RaidCheck 后续已经删除 PP 自动关联，不能按其 09-27 中间方案恢复耦合；单人模式与团队功能保持各自判断。

### 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

### 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/PallyPower)
- [Interface/AddOns/PallyPower/.workbuddy/memory/2026-09-27.md](../../Interface/AddOns/PallyPower/.workbuddy/memory/2026-09-27.md)
- [Interface/AddOns/PallyPower/.workbuddy/memory/2026-09-28.md](../../Interface/AddOns/PallyPower/.workbuddy/memory/2026-09-28.md)
- [Interface/AddOns/PallyPower/.workbuddy/memory/2026-09-29.md](../../Interface/AddOns/PallyPower/.workbuddy/memory/2026-09-29.md)
- [Interface/AddOns/PallyPower/.workbuddy/memory/MEMORY.md](../../Interface/AddOns/PallyPower/.workbuddy/memory/MEMORY.md)
- [PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json](../../PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json)
- [PluginHistory/Evidence/reports/20261006/适配指南草稿.md](../../PluginHistory/Evidence/reports/20261006/%E9%80%82%E9%85%8D%E6%8C%87%E5%8D%97%E8%8D%89%E7%A8%BF.md)
- [PluginHistory/Evidence/legacy-20261006/Docs/Files/PallyPower](../../PluginHistory/Evidence/legacy-20261006/Docs/Files/PallyPower)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。

---

[返回插件修改记录](README.md)

</details>
