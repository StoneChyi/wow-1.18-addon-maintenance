# pfUI-CustomMedia 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

让材质可见、可预览并容易应用。

## 记录中的修改

- 补充/核对 A–Z 材质注册，pfUI 核心下拉列表加入 pfUI-Z。
- 新增“自定义材质”预览页，26 张缩略图，选择应用目标并提示必要的重载。
- 材质下拉缩略图由 pfUI gui/ui-widgets 协作实现，池化条目复用时重置预览。
- 修正第三方页面裸调局部 CreateConfig 和缺 textures 表的报错。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [bars/pfUI-Z.tga](../../Interface/AddOns/pfUI-CustomMedia/bars/pfUI-Z.tga)
- [pfUI-CustomMedia-bars.lua](../../Interface/AddOns/pfUI-CustomMedia/pfUI-CustomMedia-bars.lua)
- [pfUI-CustomMedia-gui.lua](../../Interface/AddOns/pfUI-CustomMedia/pfUI-CustomMedia-gui.lua)
- [pfUI-CustomMedia-tbc.toc](../../Interface/AddOns/pfUI-CustomMedia/pfUI-CustomMedia-tbc.toc)
- [pfUI-CustomMedia.toc](../../Interface/AddOns/pfUI-CustomMedia/pfUI-CustomMedia.toc)

## 关联插件

[pfUI](pfUI.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

笔记中另一份 MHTUI 客户端的修改已还原，不作为本仓库改动；核心下拉缩略图实现属于 pfUI，更新时两边核对。

## 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

## 待补充

26 张材质的实际预览和各应用目标刷新结果待补充。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/pfUI-CustomMedia)
- [Interface/AddOns/pfUI-CustomMedia/.workbuddy/memory/2026-09-17.md](../../Interface/AddOns/pfUI-CustomMedia/.workbuddy/memory/2026-09-17.md)
- [Interface/AddOns/pfUI-CustomMedia/.workbuddy/memory/2026-09-18.md](../../Interface/AddOns/pfUI-CustomMedia/.workbuddy/memory/2026-09-18.md)
- [Interface/AddOns/pfUI-CustomMedia/.workbuddy/memory/MEMORY.md](../../Interface/AddOns/pfUI-CustomMedia/.workbuddy/memory/MEMORY.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
