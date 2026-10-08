# aux-addon 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

修正充能物品上架，并减少扫描和重复查询。

## 记录中的修改

- SuperWoW 返回负数充能时，物品数量按一瓶处理，剩余次数单独保留；修正上架滑条、保管费/单价和 Shift 提示计价。
- 扫描逻辑引入批量历史更新，并设置扫描等待阈值；搜索、定价缓存及临时表复用记录在优化报告。
- ChatThrottleLib 调用增加异常保护及限频诊断，用于处理 Invalid escape 报错。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [core/history.lua](../../Interface/AddOns/aux-addon/core/history.lua)
- [core/pricing_cache.lua](../../Interface/AddOns/aux-addon/core/pricing_cache.lua)
- [core/scan.lua](../../Interface/AddOns/aux-addon/core/scan.lua)
- [core/search_cache.lua](../../Interface/AddOns/aux-addon/core/search_cache.lua)
- [core/tooltip.lua](../../Interface/AddOns/aux-addon/core/tooltip.lua)
- [libs/ChatThrottleLib.lua](../../Interface/AddOns/aux-addon/libs/ChatThrottleLib.lua)
- [tabs/post/core.lua](../../Interface/AddOns/aux-addon/tabs/post/core.lua)
- [util.lua](../../Interface/AddOns/aux-addon/util.lua)
- [util/info.lua](../../Interface/AddOns/aux-addon/util/info.lua)
- [util/temptable.lua](../../Interface/AddOns/aux-addon/util/temptable.lua)

## 关联插件

[OneBag](OneBag.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

OPTIMIZATION_SUMMARY 中的百分比性能收益没有可复核基准，不作为已测量结果；ChatThrottleLib 异常保护不证明原始消息一定来自 aux-addon。

## 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

## 待补充

缓存与扫描优化的真实游戏收益、异常消息根源仍待补充。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/aux-addon)
- [Interface/AddOns/aux-addon/.workbuddy/memory/2026-09-28.md](../../Interface/AddOns/aux-addon/.workbuddy/memory/2026-09-28.md)
- [Interface/AddOns/aux-addon/OPTIMIZATION_SUMMARY.md](../../Interface/AddOns/aux-addon/OPTIMIZATION_SUMMARY.md)
- [Interface/AddOns/OneBag/.workbuddy/memory/2026-09-23.md](../../Interface/AddOns/OneBag/.workbuddy/memory/2026-09-23.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
