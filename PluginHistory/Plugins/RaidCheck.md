# RaidCheck 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

区分未检测成员，并增加团队分配工具。

## 记录中的修改

- 修正奥抗索引，区分离线/死亡/距离过远的未检测成员与真正缺 buff/装等/抗性；报告消息合并并节流。
- 移植团队 Buff/诅咒/坦克/骑士祝福分配，自动检测骑士、职业图标和名单下拉；密语补 buff 检查复用发送队列。
- 坦克高级分配支持坦克/治疗和目标，修正通报、输入框和职业色；任务分配子窗口支持保存与通报。
- 10-05 修正萨满祭司完整职业名、同组重复选择和坦克占位排除治疗候选。
- S_ChatBar 右键“查”打开分配界面，pfUI-addonskinner 跟进动态窗口。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [Icons/classicons.blp](../../Interface/AddOns/RaidCheck/Icons/classicons.blp)
- [RaidCheck.lua](../../Interface/AddOns/RaidCheck/RaidCheck.lua)
- [RaidCheck.xml](../../Interface/AddOns/RaidCheck/RaidCheck.xml)
- [RaidCheckBuffAssign.lua](../../Interface/AddOns/RaidCheck/RaidCheckBuffAssign.lua)

## 关联插件

[S_ChatBar](S_ChatBar.md)、[pfUI-addonskinner](pfUI-addonskinner.md)、[PallyPower](PallyPower.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

09-30 已删除 PallyPower 自动关联，最终祝福分配/通报按 HDLRaidTools 口径；图标首字标签及主窗口补 buff 按钮等中间方案也已撤回。不能把笔记中的 BOM 排查结论当普遍编码转换要求。

## 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

## 待补充

分配数据在各阶段有会话保存的限制，当前所需持久化范围及团队实测结果请补充。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/RaidCheck)
- [Interface/AddOns/RaidCheck/.workbuddy/memory/2026-09-27.md](../../Interface/AddOns/RaidCheck/.workbuddy/memory/2026-09-27.md)
- [Interface/AddOns/RaidCheck/.workbuddy/memory/2026-09-29.md](../../Interface/AddOns/RaidCheck/.workbuddy/memory/2026-09-29.md)
- [Interface/AddOns/RaidCheck/.workbuddy/memory/2026-09-30.md](../../Interface/AddOns/RaidCheck/.workbuddy/memory/2026-09-30.md)
- [Interface/AddOns/RaidCheck/.workbuddy/memory/2026-10-02.md](../../Interface/AddOns/RaidCheck/.workbuddy/memory/2026-10-02.md)
- [Interface/AddOns/RaidCheck/.workbuddy/memory/2026-10-05.md](../../Interface/AddOns/RaidCheck/.workbuddy/memory/2026-10-05.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
