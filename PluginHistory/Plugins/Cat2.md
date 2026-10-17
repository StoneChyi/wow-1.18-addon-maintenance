# Cat2 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/Cat2.md)

## 插件概况

- 插件：`Cat2`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

2026-10-18 已合并部署：合入两张猎人自定义卡、猫德流血/撕咬与拖拽显示更新；更新文件当前原与旧包相同，其他文件全部保留。 真实游戏验收待补充。

扩展流程编辑、配置调用和动作条入口。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

<a id="change-Cat2-20261018-02"></a>

### 2026-10-18｜合入 10 月 16 日包并保留个人功能（已部署）

- 记录编号：`Cat2-20261018-02`
- 记录类型：更新合并
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户授权除三个指定插件外更新新包，并要求个人功能完整保留、重复功能优先个人实现。
- 修改内容：合入两张猎人自定义卡、猫德流血/撕咬与拖拽显示更新；更新文件当前原与旧包相同，其他文件全部保留。
- 涉及文件：`Cards/Custom/HunterCannon.lua`、`Cards/Custom/HunterOrbitalMissile.lua`、`Cards/Druid/FerociousBite5_50.lua`、`Cards/Druid/FerociousBiteEmergencyRefill.lua`、`Cat2.lua`、`Cat2.toc`、`Core/CatEvent-Druid.lua`、`UI/FlowEditorCards.lua`、`UI/FlowEditorLists.lua`、`UI/FlowEditorWindow.lua`。
- 关联功能：详见[整批实施记录](../Research/10月16日包合并实施-20261018.md)；关联个人扩展、皮肤和其他未更新文件保留。
- 检查结果：9 个更新/新增 Lua 语法/闭包检查通过，TOC 引用无新增缺失；实际职业/模组施法待游戏验收。 现用目录与审查后的候选逐字节一致；[逐文件清单](../Research/10月16日包合并实施-20261018.json)保存校验和、保留范围与限制。
- 游戏验收与未确认：本次尚未游戏实测，语法与受控测试不等同于真实客户端验收；更新前可用标签 `before/package-20261016-20261018` 回退。
- 替代关系：本条在前一条差异核对之后实施，只更新当前摘要，不改写当时“未部署”的核对记录。此前个人修改作者与最早日期不作追认。

<a id="change-Cat2-20261018-01"></a>

### 2026-10-18｜10 月 16 日包与当前个人版差异核对（未部署）

- 记录编号：`Cat2-20261018-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户提供 10 月 16 日新包，要求沿用旧包/当前个人版/新包三方逻辑核对。
- 修改内容：只检查并记录，没有更新插件。原包变化：新增猎人加农炮/智轨自定义卡；调整猫德 5 星撕咬、紧急续杯和流血记录；改善拖拽/暂停/滚动提示。
- 当前个人版：功能文件同 10/10 包。
- 涉及文件：`Cards/Custom/HunterCannon.lua`、`Cards/Custom/HunterOrbitalMissile.lua`、`Cards/Druid/FerociousBite5_50.lua`、`Cards/Druid/FerociousBiteEmergencyRefill.lua`、`Cat2.lua`、`Cat2.toc`、`Core/CatEvent-Druid.lua`、`UI/FlowEditorCards.lua`、`UI/FlowEditorLists.lua`、`UI/FlowEditorWindow.lua`。
- 关联功能与处理：可按新包候选检查；猫德行为改变及新卡依赖需游戏确认。
- 检查结果：本次逐文件字节/指纹及三方关系核对；原包相关 Lua 9 个，其中 9 个通过 Lua 5.1 语法检查。 三份来源完成前再次校验未变；[完整报告](../Research/三版本插件对比-20261010-20261016-20261018.md)及[逐文件结果](../Research/三版本插件对比-20261010-20261016-20261018.json)。
- 游戏验收与未确认：本次为差异核对，未合并部署，未进行游戏内加载、界面或多人验收；文本无冲突不代表运行兼容。原维护状态和历史作者归属不作改变。

现有依据尚不能拆分成日期可靠的逐次记录；下方保留早期汇总，不以本次整理日期代替修改日期。

## 早期历史汇总与维护依据

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

扩展流程编辑、配置调用和动作条入口。

### 记录中的修改

- 2026-09-11 流程编辑器拆分窗口、列表、标题和卡片模块，保持配置存储结构。
- 配置宏图标按稳定配置 ID 绑定，使用共享角色宏；保留用户宏，避免全量刷新动作条和替换 GetActionText。
- 2026-09-12 增加 1–60 步跳转，前后跳转共享单次 60 步预算；无效跳转中断，暂停/被动跳过不破坏预算。
- 2026-09-16 增加“调用配置”逻辑卡：以稳定 ID/导入名称解析子配置，独立上下文并共用步数预算；防止递归，处理延迟施法、等待及中断。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [Cards/Logic/CallConfiguration.lua](../../Interface/AddOns/Cat2/Cards/Logic/CallConfiguration.lua)
- [Tests/ProfileMacroIconTest.lua](../../Interface/AddOns/Cat2/Tests/ProfileMacroIconTest.lua)
- [Tests/RunConfigurationTests.lua](../../Interface/AddOns/Cat2/Tests/RunConfigurationTests.lua)
- [UI/FlowEditor.lua](../../Interface/AddOns/Cat2/UI/FlowEditor.lua)
- [UI/FlowEditorCards.lua](../../Interface/AddOns/Cat2/UI/FlowEditorCards.lua)
- [UI/FlowEditorHeader.lua](../../Interface/AddOns/Cat2/UI/FlowEditorHeader.lua)
- [UI/FlowEditorLists.lua](../../Interface/AddOns/Cat2/UI/FlowEditorLists.lua)
- [UI/FlowEditorWindow.lua](../../Interface/AddOns/Cat2/UI/FlowEditorWindow.lua)
- [UI/ProfileMacroIcon.lua](../../Interface/AddOns/Cat2/UI/ProfileMacroIcon.lua)

### 已回退方案及更新注意

旧快捷图标方案已移除；不能恢复无限递归、每次子调用重置预算或批量动作条刷新。

### 验证与范围

开发说明记录了执行器/宏图标离线检查；同时明确尚需真实游戏和第三方动作条验证。本次只整理文档，没有重新执行这些测试。

### 待补充

第三方动作条兼容及调用配置的完整游戏场景验收待补充。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/Cat2)
- [Interface/AddOns/Cat2/DEVELOPMENT-NOTES.md](../../Interface/AddOns/Cat2/DEVELOPMENT-NOTES.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。

---

[返回插件修改记录](README.md)
