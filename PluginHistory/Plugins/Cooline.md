# Cooline 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

提供图形设置并减少冷却扫描与显示问题。

## 记录中的修改

- 修复旧客户端 SetShown/SetPoint 兼容；配置面板迁至 settings.lua，通过 /cl 或 /cooline 打开，支持 pfUI 皮肤和 ESC。
- 分离背包/装备与技能书冷却扫描，事件 0.1 秒防抖；去除重复全表查找，每帧统一层级排序。
- 无 SuperWoW 时缓存动作槽法术名，动作变化后失效重扫。
- 走马灯技能名开关不再受条高限制；同名冷却进入面板，滑块标签和复选框布局收紧。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [Cooline.lua](../../Interface/AddOns/Cooline/Cooline.lua)
- [settings.lua](../../Interface/AddOns/Cooline/settings.lua)

## 关联插件

[pfUI](pfUI.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

最终删除 /zmd；滚动方向/出现时机两列方案已退回两行，复选框两列布局保留，不能混用中间版本。

## 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

## 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/Cooline)
- [Interface/AddOns/Cooline/.workbuddy/memory/2026-08-15.md](../../Interface/AddOns/Cooline/.workbuddy/memory/2026-08-15.md)
- [Interface/AddOns/Cooline/.workbuddy/memory/2026-08-24.md](../../Interface/AddOns/Cooline/.workbuddy/memory/2026-08-24.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
