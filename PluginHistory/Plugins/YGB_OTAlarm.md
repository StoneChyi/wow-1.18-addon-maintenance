# YGB_OTAlarm 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

修正仇恨报警配置、计时与界面。

## 记录中的修改

- 保存的 false/0 不再被默认值覆盖，界面显示跟随有效战斗状态。
- 缩放/布局与 pfUI 协调，使用 GetTime 节流刷新，缺 UnitXP 时提供回退。
- GUID 去重与报警判定调整，避免重复或错误目标。
- UI.lua 最终只保留兼容占位，实际界面逻辑在主文件。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [UI.lua](../../Interface/AddOns/YGB_OTAlarm/UI.lua)
- [YGB_OTAlarm.lua](../../Interface/AddOns/YGB_OTAlarm/YGB_OTAlarm.lua)
- [YGB_OTAlarm.toc](../../Interface/AddOns/YGB_OTAlarm/YGB_OTAlarm.toc)

## 关联插件

[pfUI](pfUI.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

不要把旧版独立 UI.lua 全量恢复，也不要将保存的关闭/零值当作缺失配置。

## 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

## 2026-10-15：移除仇恨条阈值数字

- 目的：取消仇恨条上方的“80%”等报警阈值文字，仅保留黄色提示线。
- 主要文件：`Interface/AddOns/YGB_OTAlarm/YGB_OTAlarm.lua`。移除阈值文字控件的创建、引用及尺寸刷新时的文字更新。
- 关联功能：黄色提示线的定位和颜色、设置面板的阈值数字及滑块、报警判定保持原有逻辑；不涉及 pfUI 或保存配置的修改。
- 验证：Lua 5.1 全文件语法检查通过；实际 `UpdateGeometry` 在没有阈值文字控件时，20 组阈值与宽度组合均能正常完成，提示线位置和填充宽度正确；检查其余代码及原始编码、BOM、换行保留。
- 未确认事项：尚未进行游戏内显示验收。重载界面后确认数字消失、黄色提示线仍显示，并随阈值调整移动。

## 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/YGB_OTAlarm)
- [PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json](../../PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json)
- [PluginHistory/Evidence/reports/20261006/适配指南草稿.md](../../PluginHistory/Evidence/reports/20261006/%E9%80%82%E9%85%8D%E6%8C%87%E5%8D%97%E8%8D%89%E7%A8%BF.md)
- [PluginHistory/Evidence/legacy-20261006/Docs/Files/YGB_OTAlarm](../../PluginHistory/Evidence/legacy-20261006/Docs/Files/YGB_OTAlarm)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
