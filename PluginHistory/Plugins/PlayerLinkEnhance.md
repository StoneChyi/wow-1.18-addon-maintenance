# PlayerLinkEnhance 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/PlayerLinkEnhance.md)

## 插件概况

- 分类：经过版本迭代或修改的插件。

- 插件：`PlayerLinkEnhance`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

2026-10-31 角色链接点击委托pfUI统一处理，保留邀请弹窗填名、Who、Ctrl目标、Alt取名、右键菜单与私聊；pfUI不运行时使用原路径。待游戏验收。

保持头像菜单紧凑分组，修复团队目标图标入口误勾选。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

<a id="change-PlayerLinkEnhance-20261031-01"></a>

### 2026-10-31｜与pfUI共享角色链接点击动作并保留菜单能力

- 记录编号：`PlayerLinkEnhance-20261031-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：pfUI、InterPlayerLink和本插件均处理SetItemRef，当前角色启用组合存在同功能拦截，并可能让聊天插入抢占好友／邀请弹窗填名。
- 修改内容：ple_SetItemRef优先调用pfUI共享角色动作处理器；处理器完整保留原独有分支，Shift先尝试好友／忽略／公会／团队弹窗，再处理聊天链接或Who，且统一去除角色链接的行号后缀。pfUI未加载／未就绪时回到原逻辑，非角色链接继续原调用链。
- 保留范围：原头像右键菜单、权限判断、紧凑分组、助理／分配者操作及其他业务代码不改；没有停用整个插件。
- 涉及文件：`Interface/AddOns/PlayerLinkEnhance/PlayerLinkEnhance.lua`；关联pfUI `chat_playerlinks.lua`、`chat.lua`及Automaton InterPlayerLink。
- 检查结果：10项新角色链接融合测试通过，覆盖两种加载顺序、4类弹窗优先、中文名和后缀、单次插入、各修饰键动作、配置迁移与独立回退；既有菜单10组和归档回归通过，生产Lua5.0编译通过。尚未游戏验收。
- 关联：[pfUI](pfUI.md)、[Automatonex](Automatonex.md)、[融合测试](../../Tools/tests/test_pfui_playerlinks_fusion.py)、[菜单回归](../../Tools/tests/test_playerlink_menu_checks.py)。

<a id="change-PlayerLinkEnhance-20261012-01"></a>

### 2026-10-12｜修复团队目标图标入口的错误对号

- 记录编号：`PlayerLinkEnhance-20261012-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[e34029e](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/e34029e308efb78e1b68c3417e643f26efc52b1e)


- 目的：头像右键菜单的“团队目标图标”只作为子菜单入口，不应显示勾选。
- 原因：旧版 `UnitPopup_ShowMenu` 用 `RAID_TARGET_` 前缀判断标记项，`RAID_TARGET_ICON` 入口也匹配；现有分组排序将自身菜单的入口提前后，目标标记编号可能恰好等于入口的菜单索引，原生构建过程便传入 `checked = 1`。共享下拉框的选中元数据也可能重新设置勾选。依据为[公开 1.12 FrameXML](https://github.com/MOUZU/Blizzard-WoW-Interface/blob/master/1.12.1/FrameXML/UnitPopup.lua)和复现检查。
- 修改：`Interface/AddOns/PlayerLinkEnhance/PlayerLinkEnhance.lua` 仅对 `RAID_TARGET_ICON` 清除输入勾选并标为不可勾选；布局和 OnShow 时清除该入口按钮的 `checked`、锁定高亮及 Check 贴图。保留右侧箭头，以及星星至骷髅实际标记项目的勾选。
- 关联范围：原生头像菜单、pfUI 头像右键入口及共享 DropDownList 按钮。未调整菜单尺寸、分组或透明度，也未修改 AutoMarker、SimpleRaidTargetIcons 的标记功能。
- 检查：新增 `Tools/tests/test_playerlink_menu_checks.py`，先在修复前复现失败，再在修复后通过 10 组 Lua 5.1 行为模拟：自身/玩家/队友菜单、所有标记、选中元数据、二级及 NPC 一级实际标记、共享按钮复用、OnShow 再校正和严格字体前置条件（包含 SetFont 失败）。同时通过归档菜单回归，覆盖观察/邀请、确认操作和共享菜单恢复；归档证据文件保持不变。
- 编码：主文件保留原始 UTF-8 无 BOM 和 CRLF，仅插入针对性代码。
- 未确认：尚未在实际 1.12 客户端验收；重载后应检查入口不带对号，展开后当前实际标记仍正常勾选。


## 早期历史汇总与维护依据

<details>
<summary>展开早期原始说明与证据（不是当前问题或优化清单）</summary>

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

让头像/玩家菜单更紧凑并减少互相干扰。

### 记录中的修改

- 扩展头像右键菜单并分组显示，适配旧客户端目标及队伍情形。
- 保护/恢复共享下拉菜单的状态，避免本插件的设置污染其他菜单。
- SaferMenu.lua 最终为兼容占位，功能合并回主文件。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [PlayerLinkEnhance.lua](../../Interface/AddOns/PlayerLinkEnhance/PlayerLinkEnhance.lua)
- [PlayerLinkEnhance.toc](../../Interface/AddOns/PlayerLinkEnhance/PlayerLinkEnhance.toc)
- [SaferMenu.lua](../../Interface/AddOns/PlayerLinkEnhance/SaferMenu.lua)

### 已回退方案及更新注意

不要从中间备份恢复独立 SaferMenu 完整实现，否则可能重复挂钩。

### 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

### 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/PlayerLinkEnhance)
- [PluginHistory/Evidence/addons_tmp/unit-menu-backup-20261006/README.md](../../PluginHistory/Evidence/addons_tmp/unit-menu-backup-20261006/README.md)
- [PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json](../../PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json)
- [PluginHistory/Evidence/reports/20261006/适配指南草稿.md](../../PluginHistory/Evidence/reports/20261006/%E9%80%82%E9%85%8D%E6%8C%87%E5%8D%97%E8%8D%89%E7%A8%BF.md)
- [PluginHistory/Evidence/legacy-20261006/Docs/Files/PlayerLinkEnhance](../../PluginHistory/Evidence/legacy-20261006/Docs/Files/PlayerLinkEnhance)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。

---

[返回插件修改记录](README.md)

</details>
