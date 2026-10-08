# diminfo 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

支持渐隐，并消除信息条空白处右键误触。

## 记录中的修改

- 2026-09-15 增加按角色保存的渐隐开关和透明度；默认关闭，移出后延时淡出，模块悬停提示仍可用。
- 2026-10-08 信息条背景鼠标穿透，空白处右键不再打开设置；子模块的点击功能保留。
- 设置通过 /dim 或 /diminfo 打开。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [panel.lua](../../Interface/AddOns/diminfo/panel.lua)

## 关联插件

[pfUI](pfUI.md)。更新时同时检查对应入口与数据口径。

## 验证与范围

历史记录含局部语法/代码检查；10-08 完成报告明确没有游戏内实测。本次只核对记录与现用 panel.lua。

## 待补充

请补充实际游戏中的渐隐手感、地图右键和子模块点击验收结果。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/diminfo)
- [Interface/AddOns/diminfo/.workbuddy/memory/2026-09-15.md](../../Interface/AddOns/diminfo/.workbuddy/memory/2026-09-15.md)
- [PluginHistory/Research/维护聊天摘录-20261009.json](../../PluginHistory/Research/%E7%BB%B4%E6%8A%A4%E8%81%8A%E5%A4%A9%E6%91%98%E5%BD%95-20261009.json)
- [PluginHistory/Evidence/CodexBackups/diminfo-click-through-20261008-162857/panel.lua](../../PluginHistory/Evidence/CodexBackups/diminfo-click-through-20261008-162857/panel.lua)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
