# S_ItemTip 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

统一观察布局、属性扫描及图标显示。

## 记录中的修改

- 观察框职业图标改为独立保存的 classicons.blp 及本地坐标表，不依赖 1.12 缺失的全局坐标。
- 与 BetterCharacterStats、StatCompare 协调观察窗口、宝石附魔显示和属性扫描。
- 修正角色窗口重复打开时物品评分/扫描刷新路径。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [Icons/classicons.blp](../../Interface/AddOns/S_ItemTip/Icons/classicons.blp)
- [InspectFrame.lua](../../Interface/AddOns/S_ItemTip/InspectFrame.lua)
- [InspectGemAndEnchant.lua](../../Interface/AddOns/S_ItemTip/InspectGemAndEnchant.lua)
- [ItemSocre.lua](../../Interface/AddOns/S_ItemTip/ItemSocre.lua)

## 关联插件

[BetterCharacterStats](BetterCharacterStats.md)、[StatCompare](StatCompare.md)、[RaidCheck](RaidCheck.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

ItemSocre.lua 的现有文件名拼写需保留；不能用旧文件整份覆盖新的附魔数据库。

## 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

## 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/S_ItemTip)
- [Interface/AddOns/S_ItemTip/.workbuddy/memory/2026-09-30.md](../../Interface/AddOns/S_ItemTip/.workbuddy/memory/2026-09-30.md)
- [PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json](../../PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json)
- [PluginHistory/Evidence/reports/20261006/适配指南草稿.md](../../PluginHistory/Evidence/reports/20261006/%E9%80%82%E9%85%8D%E6%8C%87%E5%8D%97%E8%8D%89%E7%A8%BF.md)
- [PluginHistory/Evidence/legacy-20261006/Docs/Files/S_ItemTip](../../PluginHistory/Evidence/legacy-20261006/Docs/Files/S_ItemTip)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
