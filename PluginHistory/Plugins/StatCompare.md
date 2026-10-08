# StatCompare 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

让属性比较面板与角色/观察窗口协调。

## 记录中的修改

- 统一锚点和打开/关闭行为，保留独立配置、属性预设与比较功能。
- 布局功能归并到主文件，PanelLayout.lua 为兼容占位。
- 与 BetterCharacterStats、S_ItemTip 共享协调点，减少重复扫描和界面冲突。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [PanelLayout.lua](../../Interface/AddOns/StatCompare/PanelLayout.lua)
- [SCOptions.lua](../../Interface/AddOns/StatCompare/SCOptions.lua)
- [StatCompare.lua](../../Interface/AddOns/StatCompare/StatCompare.lua)
- [StatCompare.toc](../../Interface/AddOns/StatCompare/StatCompare.toc)
- [StatCompare.xml](../../Interface/AddOns/StatCompare/StatCompare.xml)
- [StatScanner.lua](../../Interface/AddOns/StatCompare/StatScanner.lua)

## 关联插件

[BetterCharacterStats](BetterCharacterStats.md)、[S_ItemTip](S_ItemTip.md)、[pfUI-addonskinner](pfUI-addonskinner.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

StatScanner.lua 的扫描试改最终恢复到阶段快照，不能把撤销的跨插件全局刷新重新加入；PanelLayout 不应重复加载完整旧逻辑。

## 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

## 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/StatCompare)
- [PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json](../../PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json)
- [PluginHistory/Evidence/reports/20261006/适配指南草稿.md](../../PluginHistory/Evidence/reports/20261006/%E9%80%82%E9%85%8D%E6%8C%87%E5%8D%97%E8%8D%89%E7%A8%BF.md)
- [PluginHistory/Evidence/legacy-20261006/Docs/Files/StatCompare](../../PluginHistory/Evidence/legacy-20261006/Docs/Files/StatCompare)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
