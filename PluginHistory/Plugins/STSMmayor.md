# STSMmayor 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

精简盾牌/修理机器人界面并提高交互预判准确性。

## 记录中的修改

- 紧凑单行界面，缩放、锚点和位置独立保存；机器人 GUID 候选与动态降频扫描。
- 2.4.7 佩戴力反馈盾牌时自动开启插件和面板，2.4.8 机器人存在判断，2.4.9 使用无双 DLL 有效范围，2.4.10 增加 UnitXP 视线检查。
- 亮绿必须为存活友方修理机器人、可读取、5 码范围内且视线明确通过；遮挡候选保留以便绕墙后恢复。
- 接口缺失/错误/未知不报绿；检测只查询，不自动交互或改无双设置。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [STSMmayor.lua](../../Interface/AddOns/STSMmayor/STSMmayor.lua)
- [STSMmayor.toc](../../Interface/AddOns/STSMmayor/STSMmayor.toc)

## 关联插件

[WushuangLoot](WushuangLoot.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

绿色只是客户端预判，不保证服务器接受交互；不得把候选 DLL 自动部署。

## 验证与范围

2.4.10 说明记录 68 项 Lua 模拟检查通过，并明确真实墙体和服务器尚未验收。本次只整理这些阶段结果。

## 待补充

真实墙体碰撞及服务器交互规则待实测。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/STSMmayor)
- [PluginHistory/Evidence/CodexBackups/STSMmayor/force-disk-2.4.7/修改说明.md](../../PluginHistory/Evidence/CodexBackups/STSMmayor/force-disk-2.4.7/%E4%BF%AE%E6%94%B9%E8%AF%B4%E6%98%8E.md)
- [PluginHistory/Evidence/CodexBackups/STSMmayor/robot-presence-2.4.8/修改说明.md](../../PluginHistory/Evidence/CodexBackups/STSMmayor/robot-presence-2.4.8/%E4%BF%AE%E6%94%B9%E8%AF%B4%E6%98%8E.md)
- [PluginHistory/Evidence/CodexBackups/STSMmayor/interaction-range-2.4.9/修改说明.md](../../PluginHistory/Evidence/CodexBackups/STSMmayor/interaction-range-2.4.9/%E4%BF%AE%E6%94%B9%E8%AF%B4%E6%98%8E.md)
- [PluginHistory/Evidence/CodexBackups/STSMmayor/interaction-los-2.4.10/修改说明.md](../../PluginHistory/Evidence/CodexBackups/STSMmayor/interaction-los-2.4.10/%E4%BF%AE%E6%94%B9%E8%AF%B4%E6%98%8E.md)
- [PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json](../../PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json)
- [PluginHistory/Evidence/reports/20261006/适配指南草稿.md](../../PluginHistory/Evidence/reports/20261006/%E9%80%82%E9%85%8D%E6%8C%87%E5%8D%97%E8%8D%89%E7%A8%BF.md)
- [PluginHistory/Evidence/legacy-20261006/Docs/Files/STSMmayor](../../PluginHistory/Evidence/legacy-20261006/Docs/Files/STSMmayor)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
