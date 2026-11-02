# S_ChatBar 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/S_ChatBar.md)

## 插件概况

- 分类：经过版本迭代或修改的插件。

- 插件：`S_ChatBar`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

2026-11-02：新增“职”快捷入口，位于“驱”后，左键打开现有pfUI统一职责窗口；接入原显示菜单和文字/色块布局。窗口沿用共享服务，便于后续团队Buff管理联动。

2026-11-02：聊天栏“驱”入口提示更新为净界驱散PureDispel；左键控制统一窗口、右键始终打开设置，旧插件目录/配置入口兼容。

2026-11-02 已补记当前个人版维护署名 `StoneChyi & Codex`；仅新增 TOC metadata 与可见说明，原有功能、原作者和许可证保留。见[本次记录](#change-S_ChatBar-20261102-01)。

集中进入定制插件并完善 Roll 和常用工具。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

<a id="change-S_ChatBar-20261102-03"></a>

### 2026-11-02｜聊天栏新增“职”，直达pfUI统一职责管理

- 记录编号：`S_ChatBar-20261102-03`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户希望在聊天界面底部统一插件管理栏快速打开职责管理，保持pfUI风格和便捷操作，并为后续团队Buff管理联动保留统一数据口径。
- 修改内容：在“驱”后新增默认显示的“职”，左键调用现有pfUI:OpenTeamRoles；旧配置缺少新开关时自动补齐，已选择隐藏时保留。接入原骰子右键显示菜单、文字/色块布局和提示；pfUI职责模块不可用时隐藏入口。复用现有窗口和服务，不增加查询、缓存或刷新任务。按钮字体加GameFontNormal模板后备，保证自定义字体加载失败时首次SetText已有有效字体。原作者、许可证及StoneChyi & Codex维护署名保留。
- 涉及文件：[ChatBar.lua](../../Interface/AddOns/S_ChatBar/ChatBar.lua)。
- 检查结果：真实源码与严格字体模拟通过7组入口检查（新旧配置、显示开关、按钮次序及窗口复用、文字/色块、缺少pfUI/模块、全部SetFont失败）；净界驱散45组及pfUI职责窗口11项回归通过，改动文件实际Lua5.0语法通过。原编码/BOM与既有逐行换行保留；未登录游戏，真实聊天栏位置、视觉效果和点击仍待验收。
- 关联说明：[pfUI统一职责管理](pfUI.md#change-pfUI-20261102-03)、[共享职责接口](../../Interface/AddOns/!Libs/SC_TeamRoles.md)。职责窗口继续沿用pfUI字体、背景/边框透明度及共享服务；后续团队Buff插件可使用同一数据与变更通知，本次未修改Buff分配逻辑。

<a id="change-S_ChatBar-20261102-02"></a>

### 2026-11-02｜驱散入口适配净界驱散2.0

- 记录编号：`S_ChatBar-20261102-02`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：关联hyx重构为净界驱散，保持用户已有聊天栏按钮操作。
- 修改内容：仅更新ChatBar.lua中“驱”按钮的提示文字；继续调用XinDispel.ToggleLists和XinSettingFrame:Show，支持新统一窗口。TOC维护署名另见本页当日01记录。
- 涉及文件：[ChatBar.lua](../../Interface/AddOns/S_ChatBar/ChatBar.lua)、[hyx对应记录](hyx.md#change-hyx-20261102-01)。
- 检查结果：净界驱散37组行为检查包含真实ChatBar.lua加载及左键整窗开关、连续右键保持设置打开；已有按钮文字与原编码/BOM/逐行换行保持。未登录游戏验收。

<a id="change-S_ChatBar-20261102-01"></a>

### 2026-11-02｜补记个人版维护署名，保留原作者与许可

- 记录编号：`S_ChatBar-20261102-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户确认以 `StoneChyi & Codex` 统一标识现有个人版与后续插件维护。
- 修改内容：根 TOC 新增 `X-Maintained-By` 和限定个人修改范围的 `X-Maintenance-Scope`；现有 Notes／本地化 Notes 保留原文并追加可见维护署名，无 Notes 时新增。原作者、版权、许可证和早期修改归属继续按既有证据保留。本条只记录当日 metadata 维护，不代表重新实现早期功能。
- 涉及文件：[S_ChatBar.toc](../../Interface/AddOns/S_ChatBar/S_ChatBar.toc)。
- 检查结果：9 项署名字节与幂等检查通过；本插件 TOC 与操作前 Git 字节的预期增量编辑完全一致，加载文件与顺序、BOM、既有编码和行尾保留；未进行游戏内插件列表显示验收。
- 关联说明：[统一维护署名规范](../MaintenanceAttribution.md)、[本次补记清单](../Research/插件维护署名-20261102.json)。

<a id="change-S_ChatBar-20261012-01"></a>

### 2026-10-12｜迁入 10 月 10 日包（已部署）

- 记录编号：`S_ChatBar-20261012-01`
- 记录类型：更新合并
- 游戏验收：待游戏验收
- 对应提交：[9a22a48](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/9a22a483d12da3d25b31e7e7eb7d0ebb81929cbb)


- 目的与处理：保留个人“驱”、独立标记助手及药剂多窗口入口，仅合入新包“查”中键集合刷 BUFF 语音和检查提示两处字节增量。
- 主要文件：`ChatBar.lua`。
- 依据：[实施记录](../Research/插件更新实施-20261012.md)及[逐文件校验](../Research/插件更新实施-20261012.json)；更新前标签 `before/package-update-20261012`。
- 验证：本次 74 个 Lua 语法、7 个 XML 与 TOC/XML 文件引用核对通过；新增库初始化、聊天条/BigWigs、字体前置条件和金额修复见关联检查，HealComm/NotGrid 106 组行为通过。现用文件与已审查候选逐字节一致。
- 未确认：尚未做真实 1.12 游戏验收；具体多人通信、首领战斗、邮件操作或界面行为按实施记录列出的范围继续验证。

<a id="change-S_ChatBar-20261011-01"></a>

### 2026-10-11｜两包更新与个人版三方核对（未部署）

- 记录编号：`S_ChatBar-20261011-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：[0b5c895](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/0b5c8959ca36a914bb144edc25225506adddbf67)


- 目的与证据：按用户补充的 10 月 5 日包，对照 10 月 10 日包和当前个人版；详见[三方核对报告](../Research/三方插件更新核对-20261005-20261010-20261011.md)。不据文件相等推断作者或最早来源。
- 两包变化：ChatBar.lua 的原包更新只有“查”中键增加集合广播和提示。
- 个人版处理：与个人入口试算文本合并无冲突，临时候选通过 Lua 5.1 语法检查；保留“驱”、独立标记助手和药剂多窗口入口。原包两版本都未包含这些入口。
- 验证与未确认：本次只核对原始字节/差异及文本试算；新包本次改变或新增的 75 个 Lua 全部通过 Lua 5.1 语法检查。未修改本插件功能，未部署候选，真实 1.12 加载、界面和多人行为待后续验收。


## 早期历史汇总与维护依据

<details>
<summary>展开早期原始说明与证据（不是当前问题或优化清单）</summary>

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

集中进入定制插件并完善 Roll 和常用工具。

### 记录中的修改

- 新增“药”打开 CatPotion；“装”右键切换 Outfitter QuickSwap，“查”右键打开 RaidCheck 分配。
- Roll 统计可选前 N 名、只计首次、限定队伍/团队，通报带组号和职业色，默认前 3 名。
- 修正内置就位/倒数按钮被误当外部插件而在重载后隐藏。
- 标记插件新增“标”入口，AutoMarker 原入口改为“自”；配置菜单与旧存档迁移保留。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [ChatBar.lua](../../Interface/AddOns/S_ChatBar/ChatBar.lua)

### 关联插件

[CatPotion](CatPotion.md)、[Outfitter](Outfitter.md)、[RaidCheck](RaidCheck.md)、[SimpleRaidTargetIcons](SimpleRaidTargetIcons.md)、[AutoMarker](AutoMarker.md)。更新时同时检查对应入口与数据口径。

### 已回退方案及更新注意

自行公布就位未确认名单的方案已回退，“位”回到调用系统就位确认；Roll 扩展保留。

### 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

### 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/S_ChatBar)
- [Interface/AddOns/S_ChatBar/.workbuddy/memory/2026-08-20.md](../../Interface/AddOns/S_ChatBar/.workbuddy/memory/2026-08-20.md)
- [Interface/AddOns/S_ChatBar/.workbuddy/memory/2026-08-25.md](../../Interface/AddOns/S_ChatBar/.workbuddy/memory/2026-08-25.md)
- [Interface/AddOns/S_ChatBar/.workbuddy/memory/2026-09-02.md](../../Interface/AddOns/S_ChatBar/.workbuddy/memory/2026-09-02.md)
- [Interface/AddOns/RaidCheck/.workbuddy/memory/2026-09-27.md](../../Interface/AddOns/RaidCheck/.workbuddy/memory/2026-09-27.md)
- [PluginHistory/Evidence/reports/SimpleRaidTargetIcons-20261007.md](../../PluginHistory/Evidence/reports/SimpleRaidTargetIcons-20261007.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。


---

[返回插件修改记录](README.md)

</details>
