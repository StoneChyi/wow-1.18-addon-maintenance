# !Libs 修改说明

整理日期：2026-10-09；后续维护：2026-10-10。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；初始化部分为历史整理；2026-10-10 的实际维护另列于下文。

## 修改目的

补记可核对的共享词库差异。

## 记录中的修改

- 现用 Babble-Boss-2.2 相比目录内备份，增加 Blackwing Alchemist、Timbermaw Trash、Alterac Valley、Arathi Basin 的英文基础键及中文译名。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [Babble/Babble-Boss-2.2/Babble-Boss-2.2.lua](../../Interface/AddOns/!Libs/Babble/Babble-Boss-2.2/Babble-Boss-2.2.lua)

## 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。初始化整理仅核对历史、文件存在与文档链接；后续功能维护与验证另列。

## 待补充

这些词条是个人补充还是整合包更新，以及修改时间/原因，请补充；备份文件名日期不是可信提交时间。

## 2026-10-10 修复 HealComm 群体治疗预估清理

- 目的：修复 NotGrid 治疗祷言预估条长期残留的共享库原因。本次维护不改变既有 Babble 词库差异的历史归属。
- 主要文件：[HealComm-1.0/HealComm-1.0.lua](../../Interface/AddOns/!Libs/HealComm-1.0/HealComm-1.0.lua)。群体治疗使用独立计时器；同一治疗者开始新治疗前移除其旧单体/群体状态，并通知原目标刷新；单体/群体停止及延迟消息互不取消对方计时器。正常施法结束立即清除本地预估并沿用 Healstop/GrpHealstop 协议广播；预估量及治疗数读取均检查结束时间；单体停止和延迟增加缺失记录保护。
- 版本：本地 AceLibrary 维护版本为 11733，高于旧副本 11732；文件顶部上游 Revision 标记仍保留 11732，不声明这是新的官方版本。[QuickHeal 副本](QuickHeal.md) 同步相同修复，避免加载顺序选中旧实现。
- 关联功能：[NotGrid](NotGrid.md) 的预估条/文本和死亡状态显示、QuickHeal 的预估治疗计算；持续治疗及复活数据继续使用原有流程。
- 验证：[Tools/tests/test_notgrid_incoming_heals.py](../../Tools/tests/test_notgrid_incoming_heals.py) 的 106 组 Lua 5.1 行为检查通过，包含两份完整库、两个语言环境、实际 AceEvent 调度实现及两种库加载顺序；相关插件 Lua 语法与维护说明检查通过。共享库保留 UTF-8 无 BOM、LF。
- 未确认：真实多人通讯、游戏内事件顺序和其他使用此共享库插件的完整游戏验收待补充。原 Babble 差异的作者与原始日期仍不明确。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/!Libs)
- [Interface/AddOns/!Libs/Babble/Babble-Boss-2.2/Babble-Boss-2.2.lua.20260918125911.bak](../../Interface/AddOns/!Libs/Babble/Babble-Boss-2.2/Babble-Boss-2.2.lua.20260918125911.bak)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
