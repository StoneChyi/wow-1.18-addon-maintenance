# WushuangLoot 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

保留个人交互外观，适配 DLL 和可调速度。

## 记录中的修改

- 按键名称中文化，缺少 WSLoot 接口时增加保护；优先 CorpseTick，旧 DLL 回退 NpcTick。
- 设置交互间隔 1–30 帧、默认 5，并保存 tickInterval；修正旧客户端滑块 API 错误。
- 小地图初始定位延后，处理中心坐标尚未就绪和拖动角度保存；补 /wsloot、/wsset 入口。
- 历史排查产生 WSLMain.lua/原文件加载探针，用于区分文件打开失败与逻辑错误。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [Bindings.xml](../../Interface/AddOns/WushuangLoot/Bindings.xml)
- [WSLMain.lua](../../Interface/AddOns/WushuangLoot/WSLMain.lua)
- [WushuangLoot.lua](../../Interface/AddOns/WushuangLoot/WushuangLoot.lua)
- [WushuangLoot.toc](../../Interface/AddOns/WushuangLoot/WushuangLoot.toc)

## 关联插件

[STSMmayor](STSMmayor.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

09-09 笔记末尾仍在等待加载探针结果，不能写成“无双全部问题已解决”；两份主文件是否同时加载需要单独确认。

## 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

## 待补充

请优先补充重启后的探针结果、当前实际加载文件、小地图/中文命令是否恢复以及现有 DLL 版本。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/WushuangLoot)
- [Interface/AddOns/WushuangLoot/.workbuddy/memory/2026-08-19.md](../../Interface/AddOns/WushuangLoot/.workbuddy/memory/2026-08-19.md)
- [Interface/AddOns/WushuangLoot/.workbuddy/memory/2026-08-28.md](../../Interface/AddOns/WushuangLoot/.workbuddy/memory/2026-08-28.md)
- [Interface/AddOns/WushuangLoot/.workbuddy/memory/2026-09-09.md](../../Interface/AddOns/WushuangLoot/.workbuddy/memory/2026-09-09.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
