# DPSMateX 战斗分类实现记录（2026-10-06）

已新增独立 DPSMateXEncounters 模块，将 Boss汇总 / 小怪汇总接入原时间菜单。汇总独立于历史列表；Boss整场归类含失败尝试与增援，手动分段延续同一遭遇。未分类单独保存。原全程不被重新计算。

治疗与实际吸收、成功施放沿用 Insights。累计只保留金额、次数、技能和目标，不新增回放或曲线副本。详细使用方式与识别范围见 `Interface/AddOns/DPSMateXEncounters/README.md`。

验证：23组分类检查、27组 Insights 检查、锁窗回归通过；Lua与TOC检查通过；额外确认旧详情文件只修改有效时间访问。离线模拟不验证真实游戏帧率、排版及所有自定义首领。

未修改用户WTF/SavedVariables数据，未安装额外依赖。原文件备份为 `addons_tmp/dpsmatex-encounters-backup-20261006`。

## 修改的原文件

- DPSMateX/DPSMateX.lua
- DPSMateX/DPSMateX_DataBuilder.lua
- DPSMateX/DPSMateX_Options.lua
- DPSMateXInsights/Core.lua
- DPSMateXInsights/Details.lua
- DPSMateXInsights/Modules.lua
- DPSMateX/Damage/DPSMateX_Details_Damage.lua
- DPSMateX/Damage/DPSMateX_Details_DamageTotal.lua
- DPSMateX/DPSMateX_EHealing/DPSMateX_Details_EHealing.lua
- DPSMateX/DPSMateX_EHealing/DPSMateX_Details_EHealingTotal.lua
- DPSMateX/DPSMateX_Healing/DPSMateX_Details_Healing.lua
- DPSMateX/DPSMateX_Healing/DPSMateX_Details_HealingTotal.lua
- DPSMateXExtend/DPSMateX_EDD/DPSMateX_Details_EDDTotal.lua
- DPSMateXExtend/DPSMateX_EDT/DPSMateX_Details_EDTTotal.lua
- DPSMateXExtend/DPSMateX_HealingTaken/DPSMateX_Details_HealingTakenTotal.lua
- DPSMateXExtendMore/DPSMateX_EHealingTaken/DPSMateX_Details_EHealingTakenTotal.lua
- DPSMateXExtendMore/DPSMateX_OHealingTaken/DPSMateX_Details_OverhealingTakenTotal.lua
- DPSMateXExtendMore/DPSMateX_Overhealing/DPSMateX_Details_Overhealing.lua
- DPSMateXExtendMore/DPSMateX_Overhealing/DPSMateX_Details_OverhealingTotal.lua

## 新模块

- Interface/AddOns/DPSMateXEncounters/DPSMateXEncounters.toc
- Interface/AddOns/DPSMateXEncounters/Encounter.lua
- Interface/AddOns/DPSMateXEncounters/Merge.lua
- Interface/AddOns/DPSMateXEncounters/README.md
- Interface/AddOns/DPSMateXEncounters/Views.lua
