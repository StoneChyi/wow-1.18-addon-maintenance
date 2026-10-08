# HideOutdoorWorldState 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

保存并自动应用隐藏野外世界状态条的选择。

## 记录中的修改

- 新增独立插件，使用 HIDE_OUTDOOR_WORLD_STATE 隐藏野外计数/占领条；/outdoorui show、hide 切换并保存选择。
- 1.1.0 自动启动和换区不再调用 WorldStateAlwaysUpFrame_Update，改为事件后的单次延迟隐藏，避免广泛布局刷新。
- 保留战场显示；手动 show 时只重建一次原生界面。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [HideOutdoorWorldState.lua](https://github.com/StoneChyi/wow-1.18-addon-maintenance/blob/4feabd85022b2e3afbd8c6aca6d94fe7765cf124/Interface/AddOns/HideOutdoorWorldState/HideOutdoorWorldState.lua)
- [HideOutdoorWorldState.toc](https://github.com/StoneChyi/wow-1.18-addon-maintenance/blob/4feabd85022b2e3afbd8c6aca6d94fe7765cf124/Interface/AddOns/HideOutdoorWorldState/HideOutdoorWorldState.toc)
- [README.md](https://github.com/StoneChyi/wow-1.18-addon-maintenance/blob/4feabd85022b2e3afbd8c6aca6d94fe7765cf124/Interface/AddOns/HideOutdoorWorldState/README.md)
- [tests/lifecycle.lua](https://github.com/StoneChyi/wow-1.18-addon-maintenance/blob/4feabd85022b2e3afbd8c6aca6d94fe7765cf124/Interface/AddOns/HideOutdoorWorldState/tests/lifecycle.lua)

## 关联插件

[pfUI](pfUI.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

资料按 Git 已提交版本整理。本次开始时工作区的该插件 4 个文件处于未提交删除状态，未还原或纳入本次提交。随后 `4feabd8` 的独立报告确认 pfUI 启动故障来自动作监控 GetOwner 调用；删除本插件后故障仍存在，因此不能把该故障归因于本插件。

## 验证与范围

提交 011fec3 记录五组生命周期回归及旧实现失败复现通过；真实客户端 pfUI 布局验证仍待完成。本次不运行或恢复已删除文件。

## 待补充

是否继续保留该插件、删除后的原始野外计数隐藏需求如何处理，请由对应维护任务补充。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](https://github.com/StoneChyi/wow-1.18-addon-maintenance/tree/4feabd85022b2e3afbd8c6aca6d94fe7765cf124/Interface/AddOns/HideOutdoorWorldState)
- Git 提交 `5274190`（新增）和 `011fec3`（避免启动时广泛刷新）；源码/原 README 按核对基准提交读取。

- [PluginHistory/pfUI-tooltip-fix-20261009.md](../../PluginHistory/pfUI-tooltip-fix-20261009.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
