# S_ChatBar 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

集中进入定制插件并完善 Roll 和常用工具。

## 记录中的修改

- 新增“药”打开 CatPotion；“装”右键切换 Outfitter QuickSwap，“查”右键打开 RaidCheck 分配。
- Roll 统计可选前 N 名、只计首次、限定队伍/团队，通报带组号和职业色，默认前 3 名。
- 修正内置就位/倒数按钮被误当外部插件而在重载后隐藏。
- 标记插件新增“标”入口，AutoMarker 原入口改为“自”；配置菜单与旧存档迁移保留。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [ChatBar.lua](../../Interface/AddOns/S_ChatBar/ChatBar.lua)

## 关联插件

[CatPotion](CatPotion.md)、[Outfitter](Outfitter.md)、[RaidCheck](RaidCheck.md)、[SimpleRaidTargetIcons](SimpleRaidTargetIcons.md)、[AutoMarker](AutoMarker.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

自行公布就位未确认名单的方案已回退，“位”回到调用系统就位确认；Roll 扩展保留。

## 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

## 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/S_ChatBar)
- [Interface/AddOns/S_ChatBar/.workbuddy/memory/2026-08-20.md](../../Interface/AddOns/S_ChatBar/.workbuddy/memory/2026-08-20.md)
- [Interface/AddOns/S_ChatBar/.workbuddy/memory/2026-08-25.md](../../Interface/AddOns/S_ChatBar/.workbuddy/memory/2026-08-25.md)
- [Interface/AddOns/S_ChatBar/.workbuddy/memory/2026-09-02.md](../../Interface/AddOns/S_ChatBar/.workbuddy/memory/2026-09-02.md)
- [Interface/AddOns/RaidCheck/.workbuddy/memory/2026-09-27.md](../../Interface/AddOns/RaidCheck/.workbuddy/memory/2026-09-27.md)
- [PluginHistory/Evidence/reports/SimpleRaidTargetIcons-20261007.md](../../PluginHistory/Evidence/reports/SimpleRaidTargetIcons-20261007.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。

## 2026-10-11 两包更新与个人版三方核对（未部署）

- 目的与证据：按用户补充的 10 月 5 日包，对照 10 月 10 日包和当前个人版；详见[三方核对报告](../Research/三方插件更新核对-20261005-20261010-20261011.md)。不据文件相等推断作者或最早来源。
- 两包变化：ChatBar.lua 的原包更新只有“查”中键增加集合广播和提示。
- 个人版处理：与个人入口试算文本合并无冲突，临时候选通过 Lua 5.1 语法检查；保留“驱”、独立标记助手和药剂多窗口入口。原包两版本都未包含这些入口。
- 验证与未确认：本次只核对原始字节/差异及文本试算；新包本次改变或新增的 75 个 Lua 全部通过 Lua 5.1 语法检查。未修改本插件功能，未部署候选，真实 1.12 加载、界面和多人行为待后续验收。

## 2026-10-12 迁入 10 月 10 日包（已部署）

- 目的与处理：保留个人“驱”、独立标记助手及药剂多窗口入口，仅合入新包“查”中键集合刷 BUFF 语音和检查提示两处字节增量。
- 主要文件：`ChatBar.lua`。
- 依据：[实施记录](../Research/插件更新实施-20261012.md)及[逐文件校验](../Research/插件更新实施-20261012.json)；更新前标签 `before/package-update-20261012`。
- 验证：本次 74 个 Lua 语法、7 个 XML 与 TOC/XML 文件引用核对通过；新增库初始化、聊天条/BigWigs、字体前置条件和金额修复见关联检查，HealComm/NotGrid 106 组行为通过。现用文件与已审查候选逐字节一致。
- 未确认：尚未做真实 1.12 游戏验收；具体多人通信、首领战斗、邮件操作或界面行为按实施记录列出的范围继续验证。
