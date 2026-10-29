# DPSMateX 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/DPSMateX.md)

## 插件概况

- 插件：`DPSMateX`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

完善紧凑详情、统计界面及扩展模块入口。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

现有依据尚不能拆分成日期可靠的逐次记录；下方保留早期汇总，不以本次整理日期代替修改日期。

## 早期历史汇总与维护依据

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

完善紧凑详情、统计界面及扩展模块入口。

### 记录中的修改

- 修正锁定窗口后的缩放/拖动体验，并统一紧凑详情窗口布局。
- 调整详情和统计表宽度、中文标签、菜单及历史/事件接入，为 Insights 和 Encounters 提供入口。
- 关联模块统一有效战斗时间，避免详情平均值与主统计口径不一致。

- 后续 10-06 报告记录原详情移除折线/堆叠/比较时间图，停用逐秒金额采样及曲线同步构造；累计金额、次数、极值、战斗时长和旧累计统计保留。
- 中文界面后续继续缩窄三栏、加大列表行高并修复已移除控件的引用；窗口几何经历多次调整，应以现用源码为准，不固定套用某份报告的旧尺寸。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [DPSMateX.lua](../../Interface/AddOns/DPSMateX/DPSMateX.lua)
- [DPSMateX_DataBuilder.lua](../../Interface/AddOns/DPSMateX/DPSMateX_DataBuilder.lua)
- [DPSMateX_EHealing/DPSMateX_Details_EHealing.lua](../../Interface/AddOns/DPSMateX/DPSMateX_EHealing/DPSMateX_Details_EHealing.lua)
- [DPSMateX_EHealing/DPSMateX_Details_EHealing.xml](../../Interface/AddOns/DPSMateX/DPSMateX_EHealing/DPSMateX_Details_EHealing.xml)
- [DPSMateX_EHealing/DPSMateX_Details_EHealingTotal.lua](../../Interface/AddOns/DPSMateX/DPSMateX_EHealing/DPSMateX_Details_EHealingTotal.lua)
- [DPSMateX_EHealing/DPSMateX_Details_EHealingTotal.xml](../../Interface/AddOns/DPSMateX/DPSMateX_EHealing/DPSMateX_Details_EHealingTotal.xml)
- [DPSMateX_Frame.xml](../../Interface/AddOns/DPSMateX/DPSMateX_Frame.xml)
- [DPSMateX_Healing/DPSMateX_Details_Healing.lua](../../Interface/AddOns/DPSMateX/DPSMateX_Healing/DPSMateX_Details_Healing.lua)
- [DPSMateX_Healing/DPSMateX_Details_Healing.xml](../../Interface/AddOns/DPSMateX/DPSMateX_Healing/DPSMateX_Details_Healing.xml)
- [DPSMateX_Healing/DPSMateX_Details_HealingTotal.lua](../../Interface/AddOns/DPSMateX/DPSMateX_Healing/DPSMateX_Details_HealingTotal.lua)
- [DPSMateX_Healing/DPSMateX_Details_HealingTotal.xml](../../Interface/AddOns/DPSMateX/DPSMateX_Healing/DPSMateX_Details_HealingTotal.xml)
- [DPSMateX_Options.lua](../../Interface/AddOns/DPSMateX/DPSMateX_Options.lua)
- [DPSMateX_Sync.lua](../../Interface/AddOns/DPSMateX/DPSMateX_Sync.lua)
- [Damage/DPSMateX_Details_Damage.lua](../../Interface/AddOns/DPSMateX/Damage/DPSMateX_Details_Damage.lua)
- [Damage/DPSMateX_Details_Damage.xml](../../Interface/AddOns/DPSMateX/Damage/DPSMateX_Details_Damage.xml)
- [Damage/DPSMateX_Details_DamageTotal.lua](../../Interface/AddOns/DPSMateX/Damage/DPSMateX_Details_DamageTotal.lua)
- [Damage/DPSMateX_Details_DamageTotal.xml](../../Interface/AddOns/DPSMateX/Damage/DPSMateX_Details_DamageTotal.xml)

### 关联插件

[DPSMateXInsights](DPSMateXInsights.md)、[DPSMateXEncounters](DPSMateXEncounters.md)、[DPSMateXExtend](DPSMateXExtend.md)、[DPSMateXExtendMore](DPSMateXExtendMore.md)。更新时同时检查对应入口与数据口径。

### 已回退方案及更新注意

最早保存的快照已含锁定缩放修复，无法还原该项最初差异；legacy 索引中的解析器、本地化和依赖库等多项试改在那个整理阶段曾恢复基线；后续紧凑详情/中文报告又有新修改，不能把早期“已恢复”清单当作当前所有文件均未改的结论。

### 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

### 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/DPSMateX)
- [PluginHistory/Evidence/addons_tmp/DPSMateX-compact-details-changes-20261006.md](../../PluginHistory/Evidence/addons_tmp/DPSMateX-compact-details-changes-20261006.md)
- [PluginHistory/Evidence/addons_tmp/DPSMateX-ui-localization-changes-20261006.md](../../PluginHistory/Evidence/addons_tmp/DPSMateX-ui-localization-changes-20261006.md)
- [PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json](../../PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json)
- [PluginHistory/Evidence/reports/20261006/适配指南草稿.md](../../PluginHistory/Evidence/reports/20261006/%E9%80%82%E9%85%8D%E6%8C%87%E5%8D%97%E8%8D%89%E7%A8%BF.md)
- [PluginHistory/Evidence/legacy-20261006/Docs/Files/DPSMateX](../../PluginHistory/Evidence/legacy-20261006/Docs/Files/DPSMateX)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。

---

[返回插件修改记录](README.md)
