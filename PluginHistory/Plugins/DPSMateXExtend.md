# DPSMateXExtend 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

让扩展统计详情参与 Boss/小怪汇总。

## 记录中的修改

- legacy 阶段记录的变更集中在有效治疗详情等与汇总相关的读取路径，统一使用选中统计的有效时间和聚合数据。
- 关联 DPSMateXEncounters 视图，保留原有扩展统计。

- 后续紧凑详情与中文界面维护同时涉及本插件的 Details Lua/XML：移除时间图相关绘制和控件、调整三栏与行高，保留数值/饼图及必要的统计入口。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [DPSMateX_Auras/DPSMateX_Details_Auras.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Auras/DPSMateX_Details_Auras.lua)
- [DPSMateX_Auras/DPSMateX_Details_Auras.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Auras/DPSMateX_Details_Auras.xml)
- [DPSMateX_Auras/DPSMateX_Details_AurasTotal.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Auras/DPSMateX_Details_AurasTotal.lua)
- [DPSMateX_Auras/DPSMateX_Details_AurasTotal.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Auras/DPSMateX_Details_AurasTotal.xml)
- [DPSMateX_Casts/DPSMateX_Details_Casts.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Casts/DPSMateX_Details_Casts.lua)
- [DPSMateX_Casts/DPSMateX_Details_Casts.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Casts/DPSMateX_Details_Casts.xml)
- [DPSMateX_Casts/DPSMateX_Details_CastsTotal.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Casts/DPSMateX_Details_CastsTotal.lua)
- [DPSMateX_Casts/DPSMateX_Details_CastsTotal.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Casts/DPSMateX_Details_CastsTotal.xml)
- [DPSMateX_CureDisease/DPSMateX_Details_CureDisease.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_CureDisease/DPSMateX_Details_CureDisease.lua)
- [DPSMateX_CureDisease/DPSMateX_Details_CureDisease.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_CureDisease/DPSMateX_Details_CureDisease.xml)
- [DPSMateX_CureDisease/DPSMateX_Details_CureDiseaseTotal.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_CureDisease/DPSMateX_Details_CureDiseaseTotal.lua)
- [DPSMateX_CureDisease/DPSMateX_Details_CureDiseaseTotal.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_CureDisease/DPSMateX_Details_CureDiseaseTotal.xml)
- [DPSMateX_CureDiseaseReceived/DPSMateX_Details_CureDiseaseReceived.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_CureDiseaseReceived/DPSMateX_Details_CureDiseaseReceived.lua)
- [DPSMateX_CureDiseaseReceived/DPSMateX_Details_CureDiseaseReceived.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_CureDiseaseReceived/DPSMateX_Details_CureDiseaseReceived.xml)
- [DPSMateX_CurePoison/DPSMateX_Details_CurePoison.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_CurePoison/DPSMateX_Details_CurePoison.lua)
- [DPSMateX_CurePoison/DPSMateX_Details_CurePoison.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_CurePoison/DPSMateX_Details_CurePoison.xml)
- [DPSMateX_CurePoison/DPSMateX_Details_CurePoisonTotal.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_CurePoison/DPSMateX_Details_CurePoisonTotal.lua)
- [DPSMateX_CurePoison/DPSMateX_Details_CurePoisonTotal.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_CurePoison/DPSMateX_Details_CurePoisonTotal.xml)
- [DPSMateX_CurePoisonReceived/DPSMateX_Details_CurePoisonReceived.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_CurePoisonReceived/DPSMateX_Details_CurePoisonReceived.lua)
- [DPSMateX_CurePoisonReceived/DPSMateX_Details_CurePoisonReceived.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_CurePoisonReceived/DPSMateX_Details_CurePoisonReceived.xml)
- [DPSMateX_DamageTaken/DPSMateX_Details_DamageTaken.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_DamageTaken/DPSMateX_Details_DamageTaken.lua)
- [DPSMateX_DamageTaken/DPSMateX_Details_DamageTaken.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_DamageTaken/DPSMateX_Details_DamageTaken.xml)
- [DPSMateX_DamageTaken/DPSMateX_Details_DamageTakenTotal.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_DamageTaken/DPSMateX_Details_DamageTakenTotal.lua)
- [DPSMateX_DamageTaken/DPSMateX_Details_DamageTakenTotal.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_DamageTaken/DPSMateX_Details_DamageTakenTotal.xml)
- [DPSMateX_Deaths/DPSMateX_Details_Deaths.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Deaths/DPSMateX_Details_Deaths.lua)
- [DPSMateX_Deaths/DPSMateX_Details_Deaths.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Deaths/DPSMateX_Details_Deaths.xml)
- [DPSMateX_Deaths/DPSMateX_Details_DeathsTotal.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Deaths/DPSMateX_Details_DeathsTotal.lua)
- [DPSMateX_Deaths/DPSMateX_Details_DeathsTotal.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Deaths/DPSMateX_Details_DeathsTotal.xml)
- [DPSMateX_Decurses/DPSMateX_Details_Decurses.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Decurses/DPSMateX_Details_Decurses.lua)
- [DPSMateX_Decurses/DPSMateX_Details_Decurses.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Decurses/DPSMateX_Details_Decurses.xml)
- [DPSMateX_Decurses/DPSMateX_Details_DecursesTotal.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Decurses/DPSMateX_Details_DecursesTotal.lua)
- [DPSMateX_Decurses/DPSMateX_Details_DecursesTotal.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Decurses/DPSMateX_Details_DecursesTotal.xml)
- [DPSMateX_DecursesReceived/DPSMateX_Details_DecursesReceived.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_DecursesReceived/DPSMateX_Details_DecursesReceived.lua)
- [DPSMateX_DecursesReceived/DPSMateX_Details_DecursesReceived.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_DecursesReceived/DPSMateX_Details_DecursesReceived.xml)
- [DPSMateX_Dispels/DPSMateX_Details_Dispels.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Dispels/DPSMateX_Details_Dispels.lua)
- [DPSMateX_Dispels/DPSMateX_Details_Dispels.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Dispels/DPSMateX_Details_Dispels.xml)
- [DPSMateX_Dispels/DPSMateX_Details_DispelsTotal.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Dispels/DPSMateX_Details_DispelsTotal.lua)
- [DPSMateX_Dispels/DPSMateX_Details_DispelsTotal.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Dispels/DPSMateX_Details_DispelsTotal.xml)
- [DPSMateX_DispelsReceived/DPSMateX_Details_DispelsReceived.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_DispelsReceived/DPSMateX_Details_DispelsReceived.lua)
- [DPSMateX_DispelsReceived/DPSMateX_Details_DispelsReceived.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_DispelsReceived/DPSMateX_Details_DispelsReceived.xml)
- [DPSMateX_EDD/DPSMateX_Details_EDD.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_EDD/DPSMateX_Details_EDD.lua)
- [DPSMateX_EDD/DPSMateX_Details_EDD.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_EDD/DPSMateX_Details_EDD.xml)
- [DPSMateX_EDD/DPSMateX_Details_EDDTotal.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_EDD/DPSMateX_Details_EDDTotal.lua)
- [DPSMateX_EDD/DPSMateX_Details_EDDTotal.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_EDD/DPSMateX_Details_EDDTotal.xml)
- [DPSMateX_EDT/DPSMateX_Details_EDT.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_EDT/DPSMateX_Details_EDT.lua)
- [DPSMateX_EDT/DPSMateX_Details_EDT.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_EDT/DPSMateX_Details_EDT.xml)
- [DPSMateX_EDT/DPSMateX_Details_EDTTotal.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_EDT/DPSMateX_Details_EDTTotal.lua)
- [DPSMateX_EDT/DPSMateX_Details_EDTTotal.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_EDT/DPSMateX_Details_EDTTotal.xml)
- [DPSMateX_Fails/DPSMateX_Details_Fails.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Fails/DPSMateX_Details_Fails.lua)
- [DPSMateX_Fails/DPSMateX_Details_Fails.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Fails/DPSMateX_Details_Fails.xml)
- [DPSMateX_Fails/DPSMateX_Details_FailsTotal.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Fails/DPSMateX_Details_FailsTotal.lua)
- [DPSMateX_Fails/DPSMateX_Details_FailsTotal.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Fails/DPSMateX_Details_FailsTotal.xml)
- [DPSMateX_FriendlyFire/DPSMateX_Details_FriendlyFire.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_FriendlyFire/DPSMateX_Details_FriendlyFire.lua)
- [DPSMateX_FriendlyFire/DPSMateX_Details_FriendlyFire.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_FriendlyFire/DPSMateX_Details_FriendlyFire.xml)
- [DPSMateX_FriendlyFire/DPSMateX_Details_FriendlyFireTotal.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_FriendlyFire/DPSMateX_Details_FriendlyFireTotal.lua)
- [DPSMateX_FriendlyFire/DPSMateX_Details_FriendlyFireTotal.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_FriendlyFire/DPSMateX_Details_FriendlyFireTotal.xml)
- [DPSMateX_HealingTaken/DPSMateX_Details_HealingTaken.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_HealingTaken/DPSMateX_Details_HealingTaken.lua)
- [DPSMateX_HealingTaken/DPSMateX_Details_HealingTaken.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_HealingTaken/DPSMateX_Details_HealingTaken.xml)
- [DPSMateX_HealingTaken/DPSMateX_Details_HealingTakenTotal.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_HealingTaken/DPSMateX_Details_HealingTakenTotal.lua)
- [DPSMateX_HealingTaken/DPSMateX_Details_HealingTakenTotal.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_HealingTaken/DPSMateX_Details_HealingTakenTotal.xml)
- [DPSMateX_Interrupts/DPSMateX_Details_Interrupts.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Interrupts/DPSMateX_Details_Interrupts.lua)
- [DPSMateX_Interrupts/DPSMateX_Details_Interrupts.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Interrupts/DPSMateX_Details_Interrupts.xml)
- [DPSMateX_Interrupts/DPSMateX_Details_InterruptsTotal.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Interrupts/DPSMateX_Details_InterruptsTotal.lua)
- [DPSMateX_Interrupts/DPSMateX_Details_InterruptsTotal.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_Interrupts/DPSMateX_Details_InterruptsTotal.xml)
- [DPSMateX_LiftMagic/DPSMateX_Details_LiftMagic.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_LiftMagic/DPSMateX_Details_LiftMagic.lua)
- [DPSMateX_LiftMagic/DPSMateX_Details_LiftMagic.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_LiftMagic/DPSMateX_Details_LiftMagic.xml)
- [DPSMateX_LiftMagic/DPSMateX_Details_LiftMagicTotal.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_LiftMagic/DPSMateX_Details_LiftMagicTotal.lua)
- [DPSMateX_LiftMagic/DPSMateX_Details_LiftMagicTotal.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_LiftMagic/DPSMateX_Details_LiftMagicTotal.xml)
- [DPSMateX_LiftMagicReceived/DPSMateX_Details_LiftMagicReceived.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_LiftMagicReceived/DPSMateX_Details_LiftMagicReceived.lua)
- [DPSMateX_LiftMagicReceived/DPSMateX_Details_LiftMagicReceived.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_LiftMagicReceived/DPSMateX_Details_LiftMagicReceived.xml)
- [DPSMateX_SunderArmor/DPSMateX_Details_SunderArmor.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_SunderArmor/DPSMateX_Details_SunderArmor.lua)
- [DPSMateX_SunderArmor/DPSMateX_Details_SunderArmor.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_SunderArmor/DPSMateX_Details_SunderArmor.xml)
- [DPSMateX_SunderArmor/DPSMateX_Details_SunderArmorTotal.lua](../../Interface/AddOns/DPSMateXExtend/DPSMateX_SunderArmor/DPSMateX_Details_SunderArmorTotal.lua)
- [DPSMateX_SunderArmor/DPSMateX_Details_SunderArmorTotal.xml](../../Interface/AddOns/DPSMateXExtend/DPSMateX_SunderArmor/DPSMateX_Details_SunderArmorTotal.xml)

## 关联插件

[DPSMateX](DPSMateX.md)、[DPSMateXEncounters](DPSMateXEncounters.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

legacy 索引中的光环、施法、控制等文件曾回到所选阶段快照；后续紧凑详情又改动了多份 Details 文件。需要按阶段先后比较，不能恢复已撤回的早期试验，也不能把早期撤回清单误当当前零差异证明。

## 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

## 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/DPSMateXExtend)
- [PluginHistory/Evidence/addons_tmp/DPSMateX-Encounters-change-report-20261006.md](../../PluginHistory/Evidence/addons_tmp/DPSMateX-Encounters-change-report-20261006.md)
- [PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json](../../PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json)
- [PluginHistory/Evidence/reports/20261006/适配指南草稿.md](../../PluginHistory/Evidence/reports/20261006/%E9%80%82%E9%85%8D%E6%8C%87%E5%8D%97%E8%8D%89%E7%A8%BF.md)
- [PluginHistory/Evidence/legacy-20261006/Docs/Files/DPSMateXExtend](../../PluginHistory/Evidence/legacy-20261006/Docs/Files/DPSMateXExtend)

- [PluginHistory/Evidence/addons_tmp/DPSMateX-compact-details-changes-20261006.md](../../PluginHistory/Evidence/addons_tmp/DPSMateX-compact-details-changes-20261006.md)

- [PluginHistory/Evidence/addons_tmp/DPSMateX-ui-localization-changes-20261006.md](../../PluginHistory/Evidence/addons_tmp/DPSMateX-ui-localization-changes-20261006.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
