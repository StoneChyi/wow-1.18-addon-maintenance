# Automatonex 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

完善模块配置、物品监控及与其他界面的协作。

## 记录中的修改

- 主页配置按角色保存；模块启停可选择按角色或按账户保存，修复默认禁用状态被旧存档遮蔽。
- 主题、背景透明度、搜索和滚动位置原地刷新，减少重建窗口导致的位置跳动和孤立框架。
- QuestItemBar 增加按角色保存的 itemID 监控、任务/监控物品独立开关、去重合计和无边框网格；锁定时隐藏底框。
- Plates 在副本及自定义位置隐藏玩家名字；AutoShout 修正按钮方向和提示；Tooltip 增加框架名称显示开关。
- Trainer 的小地图悬停脚本改为保留前一个处理器；superwow 模块与 pfUI 姓名板堆叠配置协调。
- Boomtime 计时窗口采用关闭按钮控制；后续笔记要求 ESC 不关闭它。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [Core.lua](../../Interface/AddOns/Automatonex/Core.lua)
- [Modules/AutoShout.lua](../../Interface/AddOns/Automatonex/Modules/AutoShout.lua)
- [Modules/Boomtime.lua](../../Interface/AddOns/Automatonex/Modules/Boomtime.lua)
- [Modules/Plates.lua](../../Interface/AddOns/Automatonex/Modules/Plates.lua)
- [Modules/QuestItemBar.lua](../../Interface/AddOns/Automatonex/Modules/QuestItemBar.lua)
- [Modules/Tooltip.lua](../../Interface/AddOns/Automatonex/Modules/Tooltip.lua)
- [Modules/Trainer.lua](../../Interface/AddOns/Automatonex/Modules/Trainer.lua)

## 关联插件

[pfUI](pfUI.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

“复制角色配置”功能当日已回退；自定义位置最初隐藏姓名板的实现已改为隐藏玩家名字；/qib、/qibdebug 已删除，不能按早期笔记重加。长期备忘与日期笔记冲突时优先较晚的明确决定。

## 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

## 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

## 2026-10-10 自动需求物品增加“不选择”

- 目的：所有需求类型设置均提供“需求、贪婪、放弃、不选择”，允许单独保留物品的手动掷骰窗口。
- 主要文件：[Modules/AutoNeed.lua](../../Interface/AddOns/Automatonex/Modules/AutoNeed.lua)。补齐自定义物品默认类型、杂项、卡拉赞、祖尔格拉布、安其拉废墟/神殿、熔火之心和纳克萨玛斯共 28 个设置；原有 3 个品质设置继续支持“不选择”。
- 行为：沿用“不选择”的内部值 `-1`，在拾取事件入口拦截，不调用 `RollOnLoot`，不安排自动确认。明确匹配的自定义或分类设置仍优先于品质规则；“放弃”继续使用 `0` 自动放弃。现有默认值与已保存的角色设置不变。
- 关联功能：自定义物品添加时保存的需求类型、分类设置缺省时的全局回退、按品质自动需求、掷骰确认弹窗。未修改其他插件或账号/角色设置文件。
- 验证：[Tools/tests/test_automaton_autoneed.py](../../Tools/tests/test_automaton_autoneed.py) 使用 Lua 5.1 加载现用模块，通过 31 个设置的四选项读写、67 个内置物品的四种选择与全局回退、自定义物品优先级、紫蓝绿品质、自动确认与保存设置保留检查。插件 Lua 保留 UTF-8 无 BOM、CRLF 和原有文件末尾形式。
- 未确认：尚未进入游戏验收设置菜单、真实拾取窗口及与其他自动掷骰插件同时启用的行为。重载界面后将所需物品的需求类型改为“不选择”即可保留手动选择；本次不会自动更改现有选择。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/Automatonex)
- [Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-07.md](../../Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-07.md)
- [Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-09.md](../../Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-09.md)
- [Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-12.md](../../Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-12.md)
- [Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-17.md](../../Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-17.md)
- [Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-27.md](../../Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-27.md)
- [Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-30.md](../../Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-30.md)
- [Interface/AddOns/Automatonex/.workbuddy/memory/MEMORY.md](../../Interface/AddOns/Automatonex/.workbuddy/memory/MEMORY.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-08-28.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-08-28.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-09-18.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-09-18.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
