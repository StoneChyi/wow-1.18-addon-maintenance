# HideOutdoorWorldState 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/HideOutdoorWorldState.md)

## 插件概况

- 分类：经过版本迭代或修改的插件。

- 插件：`HideOutdoorWorldState`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

已移除：2026-10-10 用户确认不再需要并主动删除；保留原功能维护历史。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

<a id="change-HideOutdoorWorldState-20261010-01"></a>

### 2026-10-10｜用户确认主动删除并停用

- 记录编号：`HideOutdoorWorldState-20261010-01`
- 记录类型：停用
- 游戏验收：不适用（说明或停用记录）
- 对应提交：[a594f5b](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/a594f5bc9bc4595df9f44da265d5c6afc474e750)


- 目的：用户明确表示该插件已经不再需要，现有删除是其主动操作；将此前未提交的删除正式纳入 Git 历史。
- 主要文件：删除现用目录中的 `HideOutdoorWorldState.lua`、`HideOutdoorWorldState.toc`、`README.md` 和 `tests/lifecycle.lua`，共 4 个已跟踪文件。目录在本次确认前已不存在，本次没有重新删除或恢复文件。
- 关联功能：不再由该插件隐藏野外世界状态计数/占领条；移除 `/outdoorui` 的插件命令入口。保留上文原有功能与 pfUI 故障排查的历史依据；删除原因是用户不再需要，不能改写成已确认由该插件引起 pfUI 故障。后续维护不主动恢复该插件。
- 验证：核对 Git 删除清单与目录不存在状态；现用其他插件的 Lua、XML、TOC 未检出对 `HideOutdoorWorldState` 的引用；维护说明覆盖和链接检查通过。当前插件已移除，没有运行已删除的生命周期测试，也没有游戏内功能验收。
- 范围：只提交用户确认的 4 个删除文件及本页、总索引、机器可读索引和待补充清单；保留历史提交和阶段证据。未更改 `WTF`、账号/角色设置或其他插件。
- 日期与未确认事项：确认日期为 2026-10-10；用户未给出实际删除时间，不作推断。没有需要继续确认的保留需求。


<a id="change-HideOutdoorWorldState-20261008-02"></a>

### 2026-10-08｜避免启动时广泛刷新世界状态界面

- 记录编号：`HideOutdoorWorldState-20261008-02`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[011fec3](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/011fec3dcab58e406d1c291c915b4e7b9334c62d)

- 补录日期：2026-10-15；修改日期取自上述真实提交。
- 修改内容与验证：启动及换区改用事件后的单次延迟隐藏，避免广泛布局刷新。原提交记载五组生命周期回归及旧实现失败复现通过，真实 pfUI 布局验收待完成；现有删除记录继续保留。
- 涉及文件：原插件源码、TOC/README；具体增删见对应提交。


<a id="change-HideOutdoorWorldState-20261008-01"></a>

### 2026-10-08｜新增隐藏野外状态条插件

- 记录编号：`HideOutdoorWorldState-20261008-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[5274190](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/52741908802c952d01e44c4770c17affff3891ad)

- 补录日期：2026-10-15；修改日期取自上述真实提交。
- 修改内容与验证：新增独立插件和保存开关。原提交记载 TOC 与静态检查通过，真实客户端验收待完成。此条从实际 Git 提交补录，当前插件已停用，不能据此恢复。
- 涉及文件：原插件源码、TOC/README；具体增删见对应提交。


## 早期历史汇总与维护依据

<details>
<summary>展开早期原始说明与证据（不是当前问题或优化清单）</summary>

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09；删除确认：2026-10-10。状态：**有维护记录**。当前已移除。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；早期功能说明为历史整理，2026-10-10 的删除确认另列于下文。

### 修改目的

保存并自动应用隐藏野外世界状态条的选择。

### 记录中的修改

- 新增独立插件，使用 HIDE_OUTDOOR_WORLD_STATE 隐藏野外计数/占领条；/outdoorui show、hide 切换并保存选择。
- 1.1.0 自动启动和换区不再调用 WorldStateAlwaysUpFrame_Update，改为事件后的单次延迟隐藏，避免广泛布局刷新。
- 保留战场显示；手动 show 时只重建一次原生界面。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [HideOutdoorWorldState.lua](https://github.com/StoneChyi/wow-1.18-addon-maintenance/blob/4feabd85022b2e3afbd8c6aca6d94fe7765cf124/Interface/AddOns/HideOutdoorWorldState/HideOutdoorWorldState.lua)
- [HideOutdoorWorldState.toc](https://github.com/StoneChyi/wow-1.18-addon-maintenance/blob/4feabd85022b2e3afbd8c6aca6d94fe7765cf124/Interface/AddOns/HideOutdoorWorldState/HideOutdoorWorldState.toc)
- [README.md](https://github.com/StoneChyi/wow-1.18-addon-maintenance/blob/4feabd85022b2e3afbd8c6aca6d94fe7765cf124/Interface/AddOns/HideOutdoorWorldState/README.md)
- [tests/lifecycle.lua](https://github.com/StoneChyi/wow-1.18-addon-maintenance/blob/4feabd85022b2e3afbd8c6aca6d94fe7765cf124/Interface/AddOns/HideOutdoorWorldState/tests/lifecycle.lua)

### 关联插件

[pfUI](pfUI.md)。更新时同时检查对应入口与数据口径。

### 已回退方案及更新注意

资料按 Git 已提交版本整理。本次开始时工作区的该插件 4 个文件处于未提交删除状态，未还原或纳入本次提交。随后 `4feabd8` 的独立报告确认 pfUI 启动故障来自动作监控 GetOwner 调用；删除本插件后故障仍存在，因此不能把该故障归因于本插件。

### 验证与范围

提交 011fec3 记录五组生命周期回归及旧实现失败复现通过；真实客户端 pfUI 布局验证仍待完成。本次不运行或恢复已删除文件。

### 待补充

用户已于 2026-10-10 确认不再需要该插件，删除归属与是否保留已明确，无需继续询问。实际删除日期未确认；只记录本次确认日期，不反填历史日期。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](https://github.com/StoneChyi/wow-1.18-addon-maintenance/tree/4feabd85022b2e3afbd8c6aca6d94fe7765cf124/Interface/AddOns/HideOutdoorWorldState)
- Git 提交 `5274190`（新增）和 `011fec3`（避免启动时广泛刷新）；源码/原 README 按核对基准提交读取。

- [PluginHistory/pfUI-tooltip-fix-20261009.md](../../PluginHistory/pfUI-tooltip-fix-20261009.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。

---

[返回插件修改记录](README.md)

</details>
