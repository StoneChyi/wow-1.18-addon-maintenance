# DPSMateXExtendMore 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/DPSMateXExtendMore.md)

## 插件概况

- 分类：经过版本迭代或修改的插件。

- 插件：`DPSMateXExtendMore`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

2026-11-02 已补记当前个人版维护署名 `StoneChyi & Codex`；仅新增 TOC metadata 与可见说明，原有功能、原作者和许可证保留。见[本次记录](#change-DPSMateXExtendMore-20261102-01)。

统一额外统计与汇总详情的口径。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

现有依据尚不能拆分成日期可靠的逐次记录；下方保留早期汇总，不以本次整理日期代替修改日期。

<a id="change-DPSMateXExtendMore-20261102-01"></a>

### 2026-11-02｜补记个人版维护署名，保留原作者与许可

- 记录编号：`DPSMateXExtendMore-20261102-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户确认以 `StoneChyi & Codex` 统一标识现有个人版与后续插件维护。
- 修改内容：根 TOC 新增 `X-Maintained-By` 和限定个人修改范围的 `X-Maintenance-Scope`；现有 Notes／本地化 Notes 保留原文并追加可见维护署名，无 Notes 时新增。原作者、版权、许可证和早期修改归属继续按既有证据保留。本条只记录当日 metadata 维护，不代表重新实现早期功能。
- 涉及文件：[DPSMateXExtendMore.toc](../../Interface/AddOns/DPSMateXExtendMore/DPSMateXExtendMore.toc)。
- 检查结果：9 项署名字节与幂等检查通过；本插件 TOC 与操作前 Git 字节的预期增量编辑完全一致，加载文件与顺序、BOM、既有编码和行尾保留；未进行游戏内插件列表显示验收。
- 关联说明：[统一维护署名规范](../MaintenanceAttribution.md)、[本次补记清单](../Research/插件维护署名-20261102.json)。

## 早期历史汇总与维护依据

<details>
<summary>展开早期原始说明与证据（不是当前问题或优化清单）</summary>

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

统一额外统计与汇总详情的口径。

### 记录中的修改

- 吸收及过量治疗详情接入选中战斗/汇总视图的数据和有效时间。
- 与 Encounters 的聚合上下文协调，避免详情取到默认战斗的数据。

- 后续紧凑详情与中文界面维护同时涉及本插件的 Details Lua/XML：移除时间图相关绘制和控件、调整三栏与行高，保留数值/饼图及必要的统计入口。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [DPSMateX_Absorbs/DPSMateX_Absorbs.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_Absorbs/DPSMateX_Absorbs.lua)
- [DPSMateX_Absorbs/DPSMateX_Details_Absorbs.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_Absorbs/DPSMateX_Details_Absorbs.lua)
- [DPSMateX_Absorbs/DPSMateX_Details_Absorbs.xml](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_Absorbs/DPSMateX_Details_Absorbs.xml)
- [DPSMateX_Absorbs/DPSMateX_Details_AbsorbsTotal.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_Absorbs/DPSMateX_Details_AbsorbsTotal.lua)
- [DPSMateX_Absorbs/DPSMateX_Details_AbsorbsTotal.xml](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_Absorbs/DPSMateX_Details_AbsorbsTotal.xml)
- [DPSMateX_AbsorbsTaken/DPSMateX_Details_AbsorbsTaken.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_AbsorbsTaken/DPSMateX_Details_AbsorbsTaken.lua)
- [DPSMateX_AbsorbsTaken/DPSMateX_Details_AbsorbsTaken.xml](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_AbsorbsTaken/DPSMateX_Details_AbsorbsTaken.xml)
- [DPSMateX_AbsorbsTaken/DPSMateX_Details_AbsorbsTakenTotal.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_AbsorbsTaken/DPSMateX_Details_AbsorbsTakenTotal.lua)
- [DPSMateX_AbsorbsTaken/DPSMateX_Details_AbsorbsTakenTotal.xml](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_AbsorbsTaken/DPSMateX_Details_AbsorbsTakenTotal.xml)
- [DPSMateX_CCBreaker/DPSMateX_Details_CCBreaker.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_CCBreaker/DPSMateX_Details_CCBreaker.lua)
- [DPSMateX_CCBreaker/DPSMateX_Details_CCBreaker.xml](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_CCBreaker/DPSMateX_Details_CCBreaker.xml)
- [DPSMateX_CCBreaker/DPSMateX_Details_CCBreakerTotal.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_CCBreaker/DPSMateX_Details_CCBreakerTotal.lua)
- [DPSMateX_CCBreaker/DPSMateX_Details_CCBreakerTotal.xml](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_CCBreaker/DPSMateX_Details_CCBreakerTotal.xml)
- [DPSMateX_EHealingTaken/DPSMateX_Details_EHealingTaken.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_EHealingTaken/DPSMateX_Details_EHealingTaken.lua)
- [DPSMateX_EHealingTaken/DPSMateX_Details_EHealingTaken.xml](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_EHealingTaken/DPSMateX_Details_EHealingTaken.xml)
- [DPSMateX_EHealingTaken/DPSMateX_Details_EHealingTakenTotal.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_EHealingTaken/DPSMateX_Details_EHealingTakenTotal.lua)
- [DPSMateX_EHealingTaken/DPSMateX_Details_EHealingTakenTotal.xml](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_EHealingTaken/DPSMateX_Details_EHealingTakenTotal.xml)
- [DPSMateX_FriendlyFireTaken/DPSMateX_Details_FriendlyFireTaken.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_FriendlyFireTaken/DPSMateX_Details_FriendlyFireTaken.lua)
- [DPSMateX_FriendlyFireTaken/DPSMateX_Details_FriendlyFireTaken.xml](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_FriendlyFireTaken/DPSMateX_Details_FriendlyFireTaken.xml)
- [DPSMateX_FriendlyFireTaken/DPSMateX_Details_FriendlyFireTakenTotal.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_FriendlyFireTaken/DPSMateX_Details_FriendlyFireTakenTotal.lua)
- [DPSMateX_FriendlyFireTaken/DPSMateX_Details_FriendlyFireTakenTotal.xml](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_FriendlyFireTaken/DPSMateX_Details_FriendlyFireTakenTotal.xml)
- [DPSMateX_HealingAndAbsorbs/DPSMateX_Details_HealingAndAbsorbs.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_HealingAndAbsorbs/DPSMateX_Details_HealingAndAbsorbs.lua)
- [DPSMateX_HealingAndAbsorbs/DPSMateX_Details_HealingAndAbsorbs.xml](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_HealingAndAbsorbs/DPSMateX_Details_HealingAndAbsorbs.xml)
- [DPSMateX_HealingAndAbsorbs/DPSMateX_Details_HealingAndAbsorbsTotal.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_HealingAndAbsorbs/DPSMateX_Details_HealingAndAbsorbsTotal.lua)
- [DPSMateX_HealingAndAbsorbs/DPSMateX_Details_HealingAndAbsorbsTotal.xml](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_HealingAndAbsorbs/DPSMateX_Details_HealingAndAbsorbsTotal.xml)
- [DPSMateX_OHealingTaken/DPSMateX_Details_OHealingTaken.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_OHealingTaken/DPSMateX_Details_OHealingTaken.lua)
- [DPSMateX_OHealingTaken/DPSMateX_Details_OHealingTaken.xml](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_OHealingTaken/DPSMateX_Details_OHealingTaken.xml)
- [DPSMateX_OHealingTaken/DPSMateX_Details_OverhealingTakenTotal.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_OHealingTaken/DPSMateX_Details_OverhealingTakenTotal.lua)
- [DPSMateX_OHealingTaken/DPSMateX_Details_OverhealingTakenTotal.xml](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_OHealingTaken/DPSMateX_Details_OverhealingTakenTotal.xml)
- [DPSMateX_Overhealing/DPSMateX_Details_Overhealing.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_Overhealing/DPSMateX_Details_Overhealing.lua)
- [DPSMateX_Overhealing/DPSMateX_Details_Overhealing.xml](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_Overhealing/DPSMateX_Details_Overhealing.xml)
- [DPSMateX_Overhealing/DPSMateX_Details_OverhealingTotal.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_Overhealing/DPSMateX_Details_OverhealingTotal.lua)
- [DPSMateX_Overhealing/DPSMateX_Details_OverhealingTotal.xml](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_Overhealing/DPSMateX_Details_OverhealingTotal.xml)
- [DPSMateX_Overhealing/DPSMateX_OHPS.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_Overhealing/DPSMateX_OHPS.lua)
- [DPSMateX_Overhealing/DPSMateX_Overhealing.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_Overhealing/DPSMateX_Overhealing.lua)
- [DPSMateX_Procs/DPSMateX_Details_Procs.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_Procs/DPSMateX_Details_Procs.lua)
- [DPSMateX_Procs/DPSMateX_Details_Procs.xml](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_Procs/DPSMateX_Details_Procs.xml)
- [DPSMateX_Procs/DPSMateX_Details_ProcsTotal.lua](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_Procs/DPSMateX_Details_ProcsTotal.lua)
- [DPSMateX_Procs/DPSMateX_Details_ProcsTotal.xml](../../Interface/AddOns/DPSMateXExtendMore/DPSMateX_Procs/DPSMateX_Details_ProcsTotal.xml)

### 关联插件

[DPSMateX](DPSMateX.md)、[DPSMateXEncounters](DPSMateXEncounters.md)。更新时同时检查对应入口与数据口径。

### 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

### 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/DPSMateXExtendMore)
- [PluginHistory/Evidence/addons_tmp/DPSMateX-Encounters-change-report-20261006.md](../../PluginHistory/Evidence/addons_tmp/DPSMateX-Encounters-change-report-20261006.md)
- [PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json](../../PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json)
- [PluginHistory/Evidence/reports/20261006/适配指南草稿.md](../../PluginHistory/Evidence/reports/20261006/%E9%80%82%E9%85%8D%E6%8C%87%E5%8D%97%E8%8D%89%E7%A8%BF.md)
- [PluginHistory/Evidence/legacy-20261006/Docs/Files/DPSMateXExtendMore](../../PluginHistory/Evidence/legacy-20261006/Docs/Files/DPSMateXExtendMore)

- [PluginHistory/Evidence/addons_tmp/DPSMateX-compact-details-changes-20261006.md](../../PluginHistory/Evidence/addons_tmp/DPSMateX-compact-details-changes-20261006.md)

- [PluginHistory/Evidence/addons_tmp/DPSMateX-ui-localization-changes-20261006.md](../../PluginHistory/Evidence/addons_tmp/DPSMateX-ui-localization-changes-20261006.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。

---

[返回插件修改记录](README.md)

</details>
