# !Libs 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/!Libs.md)

## 插件概况

- 插件：`!Libs`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

2026-10-18 核对：10 月 16 日包有更新，尚未部署；当前实现保持不变，差异与合并注意见最新记录。

补记共享词库差异，并修复 HealComm 群体治疗预估清理。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

<a id="change-!Libs-20261018-01"></a>

### 2026-10-18｜10 月 16 日包与当前个人版差异核对（未部署）

- 记录编号：`!Libs-20261018-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户提供 10 月 16 日新包，要求沿用旧包/当前个人版/新包三方逻辑核对。
- 修改内容：只检查并记录，没有更新插件。原包变化：33 个加载/代码文件变化；模组检测/封装、光环增量、治疗/耗蓝取值、词条；精简非中英文翻译；补回旧 SpellStatus。
- 当前个人版：HealComm 11733 修复；已同时加载旧 SpellStatus 与 V2。
- 涉及文件：`!Libs.toc`、`!MyLib/api/luaAPI.lua`、`!MyLib/api/wowAPI.lua`、`!MyLib/libs/LibMobHealthCache-1.0.lua`、`Abacus-2.0/Abacus-2.0.lua`、`Ace2/AceAddon-2.0/AceAddon-2.0.lua`、`Ace2/AceConsole-2.0/AceConsole-2.0.lua`、`Ace2/AceDB-2.0/AceDB-2.0.lua`、`Ace2/AceDebug-2.0/AceDebug-2.0.lua`、`Ace2/AceLocale-2.0/AceLocale-2.0.lua`、`Ace2/AceLocale-2.2/AceLocale-2.2.lua`、`Ace3/AceLocale-3.0/AceLocale-3.0.lua`、`Babble/Babble-Boss-2.2/Babble-Boss-2.2.lua`、`Babble/Babble-Class-2.2/Babble-Class-2.2.lua`、`Babble/Babble-Faction-2.2/Babble-Faction-2.2.lua`、`Babble/Babble-ItemSet-2.2/Babble-ItemSet-2.2.lua`、`Babble/Babble-Spell-2.2/Babble-Spell-2.2.lua`、`Babble/Babble-Zone-2.2/Babble-Zone-2.2.lua`、`Babble/Babble-Zone-2.3/Babble-Zone-2.3.lua`、`CastLib-1.0/CastLib-1.0.lua`、`Dewdrop-2.0/Dewdrop-2.0.lua`、`FiveSecLib-1.0/FiveSecLib-1.0.lua`、`FuBarPlugin-2.0/FuBarPlugin-2.0.lua`、`HealComm-1.0/HealComm-1.0.lua`、`Hewdrop-2.0/Hewdrop-2.0.lua`、`LibSharedMedia-3.0/LibSharedMedia-3.0.lua`、`ParserLib/FixGlobalString.lua`、`ParserLib/ParserLib.lua`、`SE/SpecialEvents-Aura-2.0/SpecialEvents-Aura-2.0.lua`、`SpellStatusV2-2.0/SpellStatusV2-2.0.lua`、`Tablet-2.0/Tablet-2.0.lua`、`Tourist-2.0/Tourist-2.0.lua`、`Waterfall-1.0/Waterfall-1.0.lua`。
- 关联功能与处理：合并；TOC/HealComm 无文本冲突，但 TOC 试算重复加载旧库，需去重；保留治疗预估修复。
- 检查结果：本次逐文件字节/指纹及三方关系核对；原包相关 Lua 32 个，其中 32 个通过 Lua 5.1 语法检查。无冲突 TOC 试算产生旧库重复条目，需人工去重。 三份来源完成前再次校验未变；[完整报告](../Research/三版本插件对比-20261010-20261016-20261018.md)及[逐文件结果](../Research/三版本插件对比-20261010-20261016-20261018.json)。
- 游戏验收与未确认：本次为差异核对，未合并部署，未进行游戏内加载、界面或多人验收；文本无冲突不代表运行兼容。原维护状态和历史作者归属不作改变。

<a id="change-!Libs-20261012-01"></a>

### 2026-10-12｜迁入 10 月 10 日包（已部署）

- 记录编号：`!Libs-20261012-01`
- 记录类型：更新合并
- 游戏验收：待游戏验收
- 对应提交：[2cb3d25](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/2cb3d25c95baa5b07a9872bece9ce190e3bee4f3)


- 目的与处理：迁入新包新增 Ace3、LDB、DBIcon、SpellStatusV2 及词条/命令更新，保留个人 HealComm 11733 和其他不在原包增量内的文件。
- 主要文件：`!Libs.toc`、`!MyLib/api/luaAPI.lua`、`!MyLib/libs/LibItem-Level-1.0.lua`、`!MyLib/libs/LibMobHealthCache-1.0.lua`、`Ace3/AceAddon-3.0/AceAddon-3.0.lua`、`Ace3/AceAddon-3.0/AceAddon-3.0.xml`、`Ace3/AceCore-3.0.lua`、`Ace3/AceDB-3.0/AceDB-3.0.lua`、`Ace3/AceDB-3.0/AceDB-3.0.xml`、`Ace3/AceGUI-3.0/AceGUI-3.0.lua`、`Ace3/AceGUI-3.0/AceGUI-3.0.xml`、`Ace3/AceGUI-3.0/widgets/AceGUIContainer-BlizOptionsGroup.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIContainer-DropDownGroup.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIContainer-Frame.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIContainer-InlineGroup.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIContainer-ScrollFrame.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIContainer-SimpleGroup.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIContainer-TabGroup.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIContainer-TreeGroup.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIContainer-Window.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIWidget-Button.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIWidget-CheckBox.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIWidget-ColorPicker.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIWidget-DropDown-Items.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIWidget-DropDown.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIWidget-EditBox.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIWidget-Heading.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIWidget-Icon.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIWidget-InteractiveLabel.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIWidget-Keybinding.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIWidget-Label.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIWidget-MultiLineEditBox.lua`、`Ace3/AceGUI-3.0/widgets/AceGUIWidget-Slider.lua`、`Ace3/AceGUI-3.0/widgets/widgets.xml`、`Ace3/AceHook-3.0.lua`、`Ace3/AceLocale-3.0/AceLocale-3.0.lua`、`Ace3/AceLocale-3.0/AceLocale-3.0.xml`、`Babble/Babble-Spell-2.2/Babble-Spell-2.2.lua`、`LibDBIcon-1.0/LibDBIcon-1.0.lua`、`LibDataBroker-1.1/LibDataBroker-1.1.lua`、`SpellStatusV2-2.0/SpellStatusV2-2.0.lua`。
- 依据：[实施记录](../Research/插件更新实施-20261012.md)及[逐文件校验](../Research/插件更新实施-20261012.json)；更新前标签 `before/package-update-20261012`。
- 验证：本次 74 个 Lua 语法、7 个 XML 与 TOC/XML 文件引用核对通过；新增库初始化、聊天条/BigWigs、字体前置条件和金额修复见关联检查，HealComm/NotGrid 106 组行为通过。现用文件与已审查候选逐字节一致。
- 未确认：尚未做真实 1.12 游戏验收；具体多人通信、首领战斗、邮件操作或界面行为按实施记录列出的范围继续验证。
- 关联兼容补充：新包仅加载 SpellStatusV2，但 BigWigs/CommonAuras 仍依赖 SpellStatus-1.0 及旧事件；本次 TOC 同时加载两者，完整新旧库的受控初始化、不同事件名和旧查询接口检查通过。最终安装目录关联行为检查通过，真实游戏仍待验收。

<a id="change-!Libs-20261011-01"></a>

### 2026-10-11｜两包更新与个人版三方核对（未部署）

- 记录编号：`!Libs-20261011-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：[0b5c895](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/0b5c8959ca36a914bb144edc25225506adddbf67)


- 目的与证据：按用户补充的 10 月 5 日包，对照 10 月 10 日包和当前个人版；详见[三方核对报告](../Research/三方插件更新核对-20261005-20261010-20261011.md)。不据文件相等推断作者或最早来源。
- 两包变化：5 个既有功能文件改变、36 个库文件新增；Ace3/LDB/DBIcon/SpellStatusV2、中文词条及调试命令变化。
- 个人版处理：所有待更新文件当前等于旧包；HealComm 两包相同，当前 11733 为独立个人修复，更新其他库时保留。
- 验证与未确认：本次只核对原始字节/差异及文本试算；新包本次改变或新增的 75 个 Lua 全部通过 Lua 5.1 语法检查。未修改本插件功能，未部署候选，真实 1.12 加载、界面和多人行为待后续验收。


<a id="change-!Libs-20261010-01"></a>

### 2026-10-10｜修复 HealComm 群体治疗预估清理

- 记录编号：`!Libs-20261010-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[fa644ef](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/fa644efccdb2a2079d63165d35c4b05287c6948a)


- 目的：修复 NotGrid 治疗祷言预估条长期残留的共享库原因。本次维护不改变既有 Babble 词库差异的历史归属。
- 主要文件：[HealComm-1.0/HealComm-1.0.lua](../../Interface/AddOns/!Libs/HealComm-1.0/HealComm-1.0.lua)。群体治疗使用独立计时器；同一治疗者开始新治疗前移除其旧单体/群体状态，并通知原目标刷新；单体/群体停止及延迟消息互不取消对方计时器。正常施法结束立即清除本地预估并沿用 Healstop/GrpHealstop 协议广播；预估量及治疗数读取均检查结束时间；单体停止和延迟增加缺失记录保护。
- 版本：本地 AceLibrary 维护版本为 11733，高于旧副本 11732；文件顶部上游 Revision 标记仍保留 11732，不声明这是新的官方版本。[QuickHeal 副本](QuickHeal.md) 同步相同修复，避免加载顺序选中旧实现。
- 关联功能：[NotGrid](NotGrid.md) 的预估条/文本和死亡状态显示、QuickHeal 的预估治疗计算；持续治疗及复活数据继续使用原有流程。
- 验证：[Tools/tests/test_notgrid_incoming_heals.py](../../Tools/tests/test_notgrid_incoming_heals.py) 的 106 组 Lua 5.1 行为检查通过，包含两份完整库、两个语言环境、实际 AceEvent 调度实现及两种库加载顺序；相关插件 Lua 语法与维护说明检查通过。共享库保留 UTF-8 无 BOM、LF。
- 未确认：真实多人通讯、游戏内事件顺序和其他使用此共享库插件的完整游戏验收待补充。原 Babble 差异的作者与原始日期仍不明确。


## 早期历史汇总与维护依据

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09；后续维护：2026-10-10。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；初始化部分为历史整理；2026-10-10 的实际维护另列于下文。

### 修改目的

补记可核对的共享词库差异。

### 记录中的修改

- 现用 Babble-Boss-2.2 相比目录内备份，增加 Blackwing Alchemist、Timbermaw Trash、Alterac Valley、Arathi Basin 的英文基础键及中文译名。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [Babble/Babble-Boss-2.2/Babble-Boss-2.2.lua](../../Interface/AddOns/!Libs/Babble/Babble-Boss-2.2/Babble-Boss-2.2.lua)

### 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。初始化整理仅核对历史、文件存在与文档链接；后续功能维护与验证另列。

### 待补充

这些词条是个人补充还是整合包更新，以及修改时间/原因，请补充；备份文件名日期不是可信提交时间。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/!Libs)
- [Interface/AddOns/!Libs/Babble/Babble-Boss-2.2/Babble-Boss-2.2.lua.20260918125911.bak](../../Interface/AddOns/!Libs/Babble/Babble-Boss-2.2/Babble-Boss-2.2.lua.20260918125911.bak)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。


---

[返回插件修改记录](README.md)
