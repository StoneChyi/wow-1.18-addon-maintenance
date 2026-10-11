# ShaguDPS 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

增加标准坦克模式统计视图并给 pfUI 提供多目标仇恨。

## 记录中的修改

- 解析 TMTv1 多目标包，维护 GUID 缓存；坦克模式最终集成到标准视图 26，按战斗中且多目标条件显示。
- 怪物名优先客户端本地化；点击选怪、二仇恨玩家/百分比提示和团队标记显示。
- Nampower/SuperWoW GUID 与团队标记兼容，pfUI 皮肤注册坦克按钮。
- 最终随基础仇恨请求同时发送 TWT_UDTSv4_TM，数据不依赖打开视图 26；pfUI 姓名板使用其数据作为补位。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [core.lua](../../Interface/AddOns/ShaguDPS/core.lua)
- [parser.lua](../../Interface/AddOns/ShaguDPS/parser.lua)
- [pfui_skin.lua](../../Interface/AddOns/ShaguDPS/pfui_skin.lua)
- [settings.lua](../../Interface/AddOns/ShaguDPS/settings.lua)
- [window.lua](../../Interface/AddOns/ShaguDPS/window.lua)

## 关联插件

[pfUI](pfUI.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

最初独立坦克小窗已删除，左侧“坦克模式数据请求”复选框已删除，tankmode 命令已标记废弃；同 NPC ID 多只怪仍受协议条目覆盖限制。

## 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

## 待补充

服务器响应、多人战斗及无 SuperWoW 时的兼容结果待补充。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/ShaguDPS)
- [Interface/AddOns/ShaguDPS/.workbuddy/memory/2026-10-03.md](../../Interface/AddOns/ShaguDPS/.workbuddy/memory/2026-10-03.md)
- [Interface/AddOns/ShaguDPS/.workbuddy/memory/2026-10-04.md](../../Interface/AddOns/ShaguDPS/.workbuddy/memory/2026-10-04.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。

## 2026-10-11 两包更新与个人版三方核对（未部署）

- 目的与证据：按用户补充的 10 月 5 日包，对照 10 月 10 日包和当前个人版；详见[三方核对报告](../Research/三方插件更新核对-20261005-20261010-20261011.md)。不据文件相等推断作者或最早来源。
- 两包变化：core/parser/settings/window 四文件增加破甲分类、排序与详情，坦克按钮高亮，移除废弃配置/调试入口。
- 个人版处理：四个待更新文件当前等于旧包，坦克视图 26 与多目标/pfUI 配合已在旧包，不能记为本次新增；皮肤三份相同。
- 验证与未确认：本次只核对原始字节/差异及文本试算；新包本次改变或新增的 75 个 Lua 全部通过 Lua 5.1 语法检查。未修改本插件功能，未部署候选，真实 1.12 加载、界面和多人行为待后续验收。
