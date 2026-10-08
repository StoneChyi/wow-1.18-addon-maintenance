# OneBag 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

解决整理卡灰、油类次数和拆分回归。

## 记录中的修改

- 钥匙链不再显示普通背包的材料计数。
- 乌龟服整理节奏/锁定等待调整；判断空格同时检查物品链接，避免陈旧锁将有物格清成空图标。
- SuperWoW 负数数量解释为油类充能，显示橙色 xN；普通堆叠恢复白字，低频轮询补刷。
- 统一数量显示时保留 button.count 副作用，恢复 Shift 拆分。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [OneBag.lua](../../Interface/AddOns/OneBag/OneBag.lua)
- [SortBags.lua](../../Interface/AddOns/OneBag/SortBags.lua)

## 关联插件

[aux-addon](aux-addon.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

不要只迁移充能显示而遗漏 09-25 的拆分回归修复；旧角色手动整理间隔与新默认值可能不同。

## 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

## 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/OneBag)
- [Interface/AddOns/OneBag/.workbuddy/memory/2026-09-18.md](../../Interface/AddOns/OneBag/.workbuddy/memory/2026-09-18.md)
- [Interface/AddOns/OneBag/.workbuddy/memory/2026-09-23.md](../../Interface/AddOns/OneBag/.workbuddy/memory/2026-09-23.md)
- [Interface/AddOns/OneBag/.workbuddy/memory/2026-09-25.md](../../Interface/AddOns/OneBag/.workbuddy/memory/2026-09-25.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
