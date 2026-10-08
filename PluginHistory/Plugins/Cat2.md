# Cat2 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

扩展流程编辑、配置调用和动作条入口。

## 记录中的修改

- 2026-09-11 流程编辑器拆分窗口、列表、标题和卡片模块，保持配置存储结构。
- 配置宏图标按稳定配置 ID 绑定，使用共享角色宏；保留用户宏，避免全量刷新动作条和替换 GetActionText。
- 2026-09-12 增加 1–60 步跳转，前后跳转共享单次 60 步预算；无效跳转中断，暂停/被动跳过不破坏预算。
- 2026-09-16 增加“调用配置”逻辑卡：以稳定 ID/导入名称解析子配置，独立上下文并共用步数预算；防止递归，处理延迟施法、等待及中断。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

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

## 已回退方案及更新注意

旧快捷图标方案已移除；不能恢复无限递归、每次子调用重置预算或批量动作条刷新。

## 验证与范围

开发说明记录了执行器/宏图标离线检查；同时明确尚需真实游戏和第三方动作条验证。本次只整理文档，没有重新执行这些测试。

## 待补充

第三方动作条兼容及调用配置的完整游戏场景验收待补充。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/Cat2)
- [Interface/AddOns/Cat2/DEVELOPMENT-NOTES.md](../../Interface/AddOns/Cat2/DEVELOPMENT-NOTES.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
