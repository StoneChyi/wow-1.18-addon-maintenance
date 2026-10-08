# AtlasLoot 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

修正地图掉落映射和愿望清单的本地化错误。

## 记录中的修改

- 与 Atlas 同步木喉要塞首领号位和掉落表键。
- 愿望清单分类使用 HasTranslation 安全查询，防止不存在的翻译键直接触发 AceLocale 错误。
- 英文基础语言表补 9 个结构键，中文表补 12 个套装、世界首领和专业分类翻译。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [Core/WishList.lua](../../Interface/AddOns/AtlasLoot/Core/WishList.lua)
- [Database/Instances.lua](../../Interface/AddOns/AtlasLoot/Database/Instances.lua)
- [Locale/locale.cn.lua](../../Interface/AddOns/AtlasLoot/Locale/locale.cn.lua)
- [Locale/locale.en.lua](../../Interface/AddOns/AtlasLoot/Locale/locale.en.lua)

## 关联插件

[Atlas](Atlas.md)。更新时同时检查对应入口与数据口径。

## 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

## 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/AtlasLoot)
- [Interface/AddOns/AtlasLoot/.workbuddy/memory/2026-09-15.md](../../Interface/AddOns/AtlasLoot/.workbuddy/memory/2026-09-15.md)
- [Interface/AddOns/Atlas/.workbuddy/memory/2026-08-28.md](../../Interface/AddOns/Atlas/.workbuddy/memory/2026-08-28.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
