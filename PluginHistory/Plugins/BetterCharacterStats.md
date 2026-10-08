# BetterCharacterStats 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

保持角色属性面板布局稳定，并与观察、换天赋功能协调。

## 记录中的修改

- 职业默认方案、自定义属性与独立显示选项；统一面板锚点、开关及角色/观察窗口打开行为。
- 与 StatCompare、S_ItemTip 协调布局和扫描复用，避免反复打开角色面板时重复刷新。
- BrainwasherPro 天赋应用期间使用静默同步，减少整界面重载和动作条重复应用。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [BCS_PropertiesPanel.lua](../../Interface/AddOns/BetterCharacterStats/BCS_PropertiesPanel.lua)
- [BetterCharacterStats.lua](../../Interface/AddOns/BetterCharacterStats/BetterCharacterStats.lua)
- [BetterCharacterStats.xml](../../Interface/AddOns/BetterCharacterStats/BetterCharacterStats.xml)
- [helper.lua](../../Interface/AddOns/BetterCharacterStats/helper.lua)

## 关联插件

[StatCompare](StatCompare.md)、[S_ItemTip](S_ItemTip.md)、[BrainwasherPro](BrainwasherPro.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

几轮全局刷新/缓存试验已回退，不能把每个阶段补丁都叠加；各插件配置仍独立。

## 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

## 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/BetterCharacterStats)
- [Interface/AddOns/BetterCharacterStats/.workbuddy/memory/2026-08-16.md](../../Interface/AddOns/BetterCharacterStats/.workbuddy/memory/2026-08-16.md)
- [Interface/AddOns/BetterCharacterStats/.workbuddy/memory/2026-09-12.md](../../Interface/AddOns/BetterCharacterStats/.workbuddy/memory/2026-09-12.md)
- [Interface/AddOns/BetterCharacterStats/.workbuddy/memory/MEMORY.md](../../Interface/AddOns/BetterCharacterStats/.workbuddy/memory/MEMORY.md)
- [PluginHistory/Evidence/addons_tmp/talent-panel-actionbar-change-notes.md](../../PluginHistory/Evidence/addons_tmp/talent-panel-actionbar-change-notes.md)
- [PluginHistory/Evidence/addons_tmp/character-bcs-scan-backup-20261006/README.md](../../PluginHistory/Evidence/addons_tmp/character-bcs-scan-backup-20261006/README.md)
- [PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json](../../PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json)
- [PluginHistory/Evidence/reports/20261006/适配指南草稿.md](../../PluginHistory/Evidence/reports/20261006/%E9%80%82%E9%85%8D%E6%8C%87%E5%8D%97%E8%8D%89%E7%A8%BF.md)
- [PluginHistory/Evidence/legacy-20261006/Docs/Files/BetterCharacterStats](../../PluginHistory/Evidence/legacy-20261006/Docs/Files/BetterCharacterStats)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
