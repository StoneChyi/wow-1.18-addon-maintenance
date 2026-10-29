# SimpleRaidTargetIcons 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/SimpleRaidTargetIcons.md)

## 插件概况

- 插件：`SimpleRaidTargetIcons`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

完善标记条生命显示、团队工具和透明图标；单击仅定位对应标记，找不到时保留当前目标，双击八种团队图标可给当前目标设置或取消标记（单击等待约 0.3 秒以区分双击）。保留右键 / Ctrl+左键快捷标记、Ctrl+右键拖动、直接清标与队外玩家本地标记。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

<a id="change-SimpleRaidTargetIcons-20261027-01"></a>

### 2026-10-27｜修复单击误选最近目标并增加图标双击标记

- 记录编号：`SimpleRaidTargetIcons-20261027-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户反馈单击团队图标会自动选择附近目标，并要求双击标记图标可给当前目标设置 / 取消标记。离线复现确认，旧寻标函数在未找到图标时反复调用 TargetNearestEnemy，最终把最近单位留为目标；两次左击也只会定位旧标记单位，不会对原目标执行标记切换。
- 修改内容：移除最近敌人的盲选循环。单击通过当前目标 / 鼠标指向 / 宠物、SuperWoW 的 mark1–mark8、队伍 / 团队成员及其目标和已识别姓名板定位对应标记，找不到时不改当前目标。右键 / Ctrl+左键没有目标时仅提示，不再先找其他单位后给其标记。
- 双击操作：普通左键同一图标在 0.3 秒内双击时，对当前目标执行一次设置 / 取消；第一下延迟寻标，避免在第二下之前切走原目标。仅同图标、相同目标身份的两次点击配对；无 GUID 的原生环境依靠 PLAYER_TARGET_CHANGED 取消旧点击，有 GUID 时另核对 GUID 与目标存在状态。慢速点击、不同图标或三击不会无限触发切换。
- 生命周期与原有操作：目标变化、拖动、清标、右键 / Ctrl+左键或停用插件会取消等待中的单击；处理完成即移除计时回调和临时目标事件，没有空闲常驻计时器。保留快捷键、Alt+左键清标、队外玩家本地标记与既有分配功能。猎人图标仍是技能施放；不把已存在的猎人印记误当作可通过原生团队标记 0 移除的效果。登录及悬停提示同步更新。
- 涉及文件：[Banana.lua](../../Interface/AddOns/SimpleRaidTargetIcons/Banana.lua)、新增[标记条点击检查](../../Tools/tests/test_srti_bar_clicks.py)、本页及生成的记录索引。没有新增贴图、字体、DLL 或 FontString；保留原编码和各修改区域的换行格式。
- 关联功能：沿用 1.12 的 GetTime、Frame OnUpdate / OnEvent、PLAYER_TARGET_CHANGED、UnitExists 及既有标记接口；未采用新版计时或安全按钮接口。姓名板仍按已识别图标定位；无 SuperWoW 且单位 / 姓名板不可识别时不再盲选附近敌人。
- 检查结果：57 组 Lua 5.1 标记条检查通过，覆盖八图标双击设置 / 取消、原目标保持、单击延迟、无目标、不同图标 / 慢击 / 三击、目标事件与 GUID 变化、拖动 / 清标 / 停用取消、猎人施法和严格字体初始化 / SetFont 失败后备；用修改前提交源码在同一模拟中分别复现最近目标残留和双击不赋标。另实际运行并通过 64 组目标标记、19 组直接清标、20 组分配 / 排序回归，以及历史完整 Lua/XML、生命 / 姓名 / 布局、猎人显示、保存还原和聊天栏回归；历史脚本仅在内存补充 UnitIsPlayer 模拟，未改证据文件。
- 游戏验收与未确认：本次尚未游戏实测。需 /reload 后验证有 / 无对应标记时单击、选中其他单位时双击设置再双击取消、无目标、队外玩家本地标记及实际鼠标双击节奏。单击延迟约 0.3 秒是区分双击所需的交互变化；模拟不代表 1.12 运行中已验收。

<a id="change-SimpleRaidTargetIcons-20261013-02"></a>

### 2026-10-13｜补充：直接清标与队外玩家本地标记

- 记录编号：`SimpleRaidTargetIcons-20261013-02`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[37b4985](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/37b498512712f266f6d0bc95c79727e7536c842c)


- 用户后续反馈：圆形菜单的原闪标问题已消失，但点击清除按钮时自己头上仍出现骷髅；同时希望继续标记队外玩家。此前只拦截队外玩家的处理限制过多，本节记录对此的调整，不改写前一项维护记录。
- 主要文件：[Banana.lua](../../Interface/AddOns/SimpleRaidTargetIcons/Banana.lua)、[SimpleRaidTargetIcons.lua](../../Interface/AddOns/SimpleRaidTargetIcons/SimpleRaidTargetIcons.lua)、[RaidTools.lua](../../Interface/AddOns/SimpleRaidTargetIcons/RaidTools.lua)。清除全部标记不再向自己轮流设置 1–8，也不再依赖隐藏自身血条掩盖临时标记。改为收集 mark1–mark8 及当前目标 / 鼠标指向 / 自己 / 宠物 / 队伍与团队单位、其目标和宠物，直接对实际已标记单位发送取消请求。
- 清除范围与重试：SuperWoW 优先固定 GUID，再清理服务器标记及本地标记；只对原单位、原标记最多重试 10 次，且任务最多保留 3 秒。切换目标、标记被其他单位复用或原单位改用另一标记时，不清除新标记；任一新的有效赋标（含圆形菜单）取消待执行清标。没有 GUID 时只立即清理一次，避免别名改变后清错对象。无 SuperWoW 时只能清理当前可识别单位，不再借用自己的头顶标记；清除按钮悬停说明已更新。
- 队外玩家：有 SuperWoW 时，队外敌方 / 友方玩家统一使用第三参数的本地标记，支持单人 / 队伍 / 团队以及标记条、圆形菜单的设置与取消，仅自己可见；普通队员也能打开队外玩家的本地圆形菜单，服务器标记菜单沿用已有权限控制。自己、队内成员和普通 NPC 的既有标记方式保留；无 SuperWoW 时仍拒绝会失败的队外玩家原生请求并给出说明。
- 接口依据：核对 [SuperWoW 官方功能文档](https://github.com/balakethelock/SuperWoW/wiki/Features)，其中说明 UnitExists 额外返回 GUID、mark1–mark8 单位令牌和 SetRaidTarget 第三个本地标记参数；本机现有 AutoMarker 和 pfUI 也使用这些扩展。未部署或修改 DLL。服务器标记和本地标记可并存的清理行为使用分离状态模拟覆盖，仍需当前客户端实测。
- 验证：[直接清标检查](../../Tools/tests/test_srti_clear_marks.py) 19 组通过，模拟分别维护服务器 / 本地标记，覆盖按钮与 Alt+左键、延迟响应、原 GUID 重试、自身原有骷髅、空清理 / 连续清理、重复别名、缺失 GUID、标记复用、两种标记并存、长时间停用以及新赋标取消。清理期间若任何接口调用试图赋予正编号标记，测试立即失败；前一提交确实触发此断言。
- 验证：[标记目标检查](../../Tools/tests/test_srti_marker_targets.py) 64 组通过，扩为 SuperWoW 各组队状态下队外玩家 8 种本地标记 / 取消、GUID、敌方 / 友方玩家、圆环外取消及普通队员路径；前一提交未提供队伍中的队外玩家本地标记，同一检查确实失败。[分配与排序检查](../../Tools/tests/test_srti_loot_mode.py) 20 组与历史完整 Lua/XML、血条 / 姓名 / 布局、猎人图标、权限、倒计时、保存还原和聊天栏回归通过；历史脚本仍只在内存补充 UnitIsPlayer 模拟，未修改证据文件。严格字体检查通过，无新增 FontString。
- 未确认事项：本次改写尚未游戏内验收。需 /reload 后分别验证清除按钮 / Alt+左键是否不再向自身新增骷髅、场上怪物和队外玩家本地标记能否清除，以及队内成员服务器标记是否正常。模拟通过不代表当前客户端已验证；无扩展时不保证清除无法通过任何可识别单位取得的远处标记。


<a id="change-SimpleRaidTargetIcons-20261013-01"></a>

### 2026-10-13｜补充：队外玩家标记失败时自身闪标

- 记录编号：`SimpleRaidTargetIcons-20261013-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[a32f273](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/a32f2730977a28b69278bf47764bf7db31208009)


- 目的：处理用户反馈的现象：尝试标记不在当前队伍中的玩家时，客户端提示无法标记，同时自己头上短暂出现所点击的标记。
- 主要文件：[Banana.lua](../../Interface/AddOns/SimpleRaidTargetIcons/Banana.lua)、[SimpleRaidTargetIcons.lua](../../Interface/AddOns/SimpleRaidTargetIcons/SimpleRaidTargetIcons.lua)。标记条与圆形菜单统一在调用客户端接口前检查单位是否存在；使用原生标记时，玩家必须是自己或与当前 party / raid 单位身份一致的成员。通过 1.12 的 UnitExists / UnitIsPlayer / UnitIsUnit 和队伍人数接口判断，不靠名字、阵营或目标字符串猜测归属，兼容 SuperWoW GUID 单位。
- 修复范围：标记条右键、Ctrl+左键、圆形菜单设置 / 取消以及圆环外右键取消均执行检查。队外玩家和已经消失的单位直接拒绝，不提交可能产生自身闪标的请求，拒绝后不播放设置或清除成功音效。提示沿用现有错误文字 / 声音开关。
- 关联行为：保留普通 NPC、自己、同队 / 同团玩家，以及 SuperWoW 单人模式第三参数本地标记；不改变猎人印记施法分支。拒绝的赋标不会取消仍在进行的清除全部标记重试，也不主动清除自己原有的真实标记。
- 验证：[目标检查脚本](../../Tools/tests/test_srti_marker_targets.py) 的 62 组 Lua 5.1 行为检查通过，覆盖原生 / SuperWoW、单人 / 队伍 / 团队、右键 / Ctrl+左键 / 圆形菜单 / 圆环外取消、8 种标记、取消、队外玩家 GUID、目标消失、party4 / raid40 成员、自己和 NPC。模拟客户端把错误请求回落到自身，以确认修复在接口调用前阻断；用修改前提交内容运行同一检查，确实在“不应调用原生接口”的断言失败。模拟也启用严格字体前置条件。
- 回归：[清标脚本](../../Tools/tests/test_srti_clear_marks.py) 扩为 12 组，通过拒绝队外玩家后继续清标的新增检查；[分配与排序脚本](../../Tools/tests/test_srti_loot_mode.py) 原有 20 组通过。历史完整 Lua/XML、血条、姓名、布局、猎人标记显示、权限、倒计时、保存还原和聊天栏回归通过；历史脚本只在内存补充 UnitIsPlayer 模拟，未修改历史证据文件。新增生产代码未创建或修改 FontString。
- 未确认事项：客户端拒绝请求时的内部闪标机制尚未在运行中的游戏复现；模拟的故障副作用仅用于验证阻断请求，不代表还原客户端内部实现。需游戏内 /reload 后，对队外敌方 / 友方玩家、队内成员和怪物分别验收，尤其检查自己已有标记和清标重试时的行为。


<a id="change-SimpleRaidTargetIcons-20261012-03"></a>

### 2026-10-12｜补充：分配简称与菜单对号残留

- 记录编号：`SimpleRaidTargetIcons-20261012-03`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[0d3b76f](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/0d3b76f671c5db91f2997c5fe0d9f166516ae6b5)


- 目的：提升双字按钮的辨识度，并修复进入物品分配者页面时，原分配菜单的对号残留到成员或“返回分配方式”行的问题。
- 主要文件：[RaidTools.lua](../../Interface/AddOns/SimpleRaidTargetIcons/RaidTools.lua)。按钮改为“自由 / 轮流 / 队长 / 队伍 / 需求”，保持 36 宽度；“队长”“队伍”比“队分”“队拾”更符合日常称呼。悬停和菜单仍使用“队长分配”“队伍拾取”的完整名称，队长分配规则继续说明由指定分配者分配。
- 原因核对：读取[1.12.1 原生下拉菜单源码](https://github.com/MOUZU/Blizzard-WoW-Interface/blob/master/1.12.1/FrameXML/UIDropDownMenu.lua)，确认 `UIDropDownMenuButton_OnClick` 在菜单回调之后仍根据 `keepShownOnClick` 修改同一原生按钮的对号；同步重建菜单会复用该按钮，导致操作落到新页面上，且这一步不检查 `notCheckable`。
- 修复：从原生菜单回调触发的选人、翻页、返回及名单失效重选，改为点击处理完成后的下一 UI 帧重建。每次打开所属菜单前清空 selectedID / selectedValue / selectedName、共享按钮对号和高亮，未选中项显式设为 false。位置选择菜单也使用同一清理逻辑；返回分配菜单时仅重建实际模式的对号。
- 关联与生命周期：沿用分配权限、服务器同步、40 人分页和具体位置设置；延后一帧的刷新完成后立即移除回调，关闭插件、退队或打开其他所属菜单不会使待切换页面重新弹出。
- 验证：[扩展回归脚本](../../Tools/tests/test_srti_loot_mode.py) 在修复前复现菜单复用后的残留对号，修复后 20 组 Lua 5.1 行为检查通过。新增覆盖原生回调之后的对号更新、不可勾选行、旧选择缓存、选人 / 返回 / 分页 / 位置菜单复用，以及排队切换时关闭插件、退队和改开位置菜单；保留 1.12 字体失败 / 后备检查、模式切换、权限、服务器延迟、排序与顺序加载检查。原有完整 Lua/XML 与清标回归另行通过。
- 未确认事项：对号修复与新简称尚需游戏内 `/reload` 后验收；模拟检查和原生源码核对不代替运行中游戏验证。


<a id="change-SimpleRaidTargetIcons-20261012-02"></a>

### 2026-10-12｜补充：工具具体位置与紧凑分配切换

- 记录编号：`SimpleRaidTargetIcons-20261012-02`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[054f4f6](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/054f4f6bfd3bd57d92bcd420ec315dcc8ae4a430)


- 用户反馈：上一版分配方式显示已达到效果，但按钮偏宽，且不能点击切换；同时要求工具可以选择同侧第 1、2 等具体位置。
- 主要文件：[RaidTools.lua](../../Interface/AddOns/SimpleRaidTargetIcons/RaidTools.lua)。就位、倒数、分配、存 / 还原、清标、重置、设置七项工具均增加“第几位”菜单，按所在侧由标记向外排列，第 1 位最靠近标记。移动一侧工具不改变另一侧的相对顺序；隐藏工具不占实际位置，重新启用后按保存顺序参与排列。单人时仍可预设分配按钮组队后的顺序，其他工具当前位置不计入隐藏的分配按钮。
- 配置与迁移：新顺序保存在原有配置表的新字段 `BANANA_CONFIG.TOOL_ORDER` 中，继续使用原左右设置；缺失、重复、未知顺序项会补齐 / 去重。恢复默认会重置顺序，左右批量按钮保留相对顺序。设置页扩宽以并排放置左右和具体位置选择，不挤压原有文字。
- 分配按钮：宽度从 82 缩为普通工具的 36，移除两行标题，改用“自由 / 轮流 / 队分 / 队拾 / 需求”及原有颜色，悬停查看完整名称和规则。左键打开五种分配方式菜单，当前模式打勾；普通成员仅可查看，切换项置灰。选择“队长分配”后再选择分配者，团队名单每页 10 人，支持 40 人团队及翻页 / 返回。
- 切换校验：提交前重新核对队长 / 团长权限及所选成员姓名，防止菜单打开后身份或名单变化导致误操作；退队或关闭工具时关闭所属分配菜单。显示继续读取游戏实际模式，不把尚未被服务器确认的请求提前显示为生效。
- 1.12 接口：核对本机 PlayerLinkEnhance、Automatonex 的 `SetLootMethod(method)` / `SetLootMethod("master", name)` 用法，及 pfUI、Bagshui 的原生下拉菜单、`keepShownOnClick`、32 项上限与菜单缓存处理。新控件使用原生有效字体模板，分配文本保留内置字体后备。
- 验证：[扩展回归脚本](../../Tools/tests/test_srti_loot_mode.py) 的 18 组 Lua 5.1 行为检查通过，覆盖紧凑模式、旧显示与开关路径、切换权限 / 服务器延迟、名单变化、40 人分页、20 种布局 / 侧别下各工具第 1 / 2 / 末位移动、隐藏补位、另一侧顺序保留、重建模拟环境后的顺序加载、异常顺序修复及恢复默认。菜单模拟保留 1.12 缓存和 32 项限制，字体模拟会拒绝未初始化的 `SetText`，并在字体设置失败时覆盖控件创建、预览、隐藏与复用。原有完整 Lua/XML、血条 / 布局 / 猎人 / 聊天栏回归及清标 10 组检查通过。
- 未确认事项：本次新增排序、菜单实际画面与服务器切换结果尚未在运行中的游戏验收；需 `/reload` 后打开 `/srti` 调整各项左右与第几位，并在拥有权限的队伍 / 团队中检查分配切换。模拟通过不表示已完成游戏实测。


<a id="change-SimpleRaidTargetIcons-20261012-01"></a>

### 2026-10-12｜新增组队分配方式按钮

- 记录编号：`SimpleRaidTargetIcons-20261012-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[0057857](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/00578573fcf1b4535909a2abee4ead4d2236f0c4)


- 目的：在标记条旁直接看清队伍 / 团队当前的物品分配方式，无需先打开菜单。
- 主要文件：[RaidTools.lua](../../Interface/AddOns/SimpleRaidTargetIcons/RaidTools.lua)。新增默认开启的分配方式按钮，以两行文字显示“分配方式”及完整模式名称，并用颜色区分自由拾取、轮流拾取、队长分配、队伍拾取、需求优先；未收到有效模式时显示“等待同步”。悬停说明分配规则，左键在本地聊天窗口显示当前模式。
- 显隐与布局：单人隐藏，加入队伍或团队后自动显示，退队立即隐藏并收回占位；遵循插件总开关及队伍 / 团队显示设置。设置页增加“分配方式（组队显示）”独立开关、左右位置选择，支持“工具全部放左 / 右侧”、五种布局、反向排列和原有缩放。设置页高度相应扩展，避免新增选项挤压下方控件。
- 关联功能与接口：沿用已有工具布局及刷新；读取 1.12 `GetLootMethod()` 的首返回值，并监听 `PARTY_LOOT_METHOD_CHANGED`、`PARTY_MEMBERS_CHANGED`、`RAID_ROSTER_UPDATE`、`PLAYER_ENTERING_WORLD`，同时保留现有定时刷新作同步补充。接口及事件用法核对本机 11200 插件 Bagshui 的 GameInfo 与 pfUI；不依赖现代客户端接口。按钮不更改分配设置，点击不会向队伍 / 团队发送消息。
- 字体：工具按钮及血条文本先继承内置 `GameFontNormal` 模板，再尝试设置字体，确保新按钮、隐藏控件、血条和短姓名在字体加载失败时仍有有效后备。
- 验证：[分配按钮回归脚本](../../Tools/tests/test_srti_loot_mode.py) 的 12 组 Lua 5.1 检查通过，覆盖五种模式、初始化、事件 / 定时更新、组队 / 团队 / 退队、旧设置迁移、独立与总开关、20 种布局 / 左右组合、三档缩放、设置预览及复用；使用[严格字体模拟](../../Tools/tests/wow112_fontstring_mock.lua)，确认未初始化字体的 `SetText` 会失败，并在 `SetFont` 失败条件下验证回退、模式变化及血条 / 姓名写入。原有完整 Lua/XML、血条、布局、猎人印记、聊天栏等回归，以及清标修复 10 组检查均通过。
- 未确认事项：以上为客户端模拟检查；尚未在运行中的乌龟服游戏里验收实际画面和服务器分配事件。需 `/reload` 后组队查看，不能以模拟结果代替游戏验收。


<a id="change-SimpleRaidTargetIcons-20261010-01"></a>

### 2026-10-10｜清除全部标记时的骷髅血条修复

- 记录编号：`SimpleRaidTargetIcons-20261010-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[1bab3e2](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/1bab3e2c53043abe9eae43a91751376c561daded)


- 目的：修复点击“清”后，骷髅下方短暂显示玩家血条的问题；Alt+左键清标共用同一修复。
- 原因：旧逻辑依次将八个团队标记转到玩家身上，最后留下骷髅，等后续刷新再取消；血条扫描先于取消执行，将玩家误当成骷髅目标。
- 主要文件：[Banana.lua](../../Interface/AddOns/SimpleRaidTargetIcons/Banana.lua)。清标结束立即取消玩家标记并刷新显示；后续重试先清标再扫描，等待服务器同步时忽略玩家及其 party/raid、SuperWoW mark 单位别名上的临时标记。插件内主动设置新团队标记时停止旧清标重试，避免刚设置的标记被清掉。
- 关联功能：“清”按钮、Alt+左键清标、普通客户端单位扫描、SuperWoW mark1–mark8 扫描、目标血条与姓名显示。真实标记目标仍按实际血量刷新；已保存的标记记录不受影响。
- 验证：[新增回归脚本](../../Tools/tests/test_srti_clear_marks.py) 在旧代码上检测到缺少立即取消标记；修复后 10 组行为检查通过，覆盖普通客户端/SuperWoW、即时/延迟同步、按钮/Alt 入口、八个标记清除、最后一轮重试、真实骷髅血量变化及主动重新标记。[原有完整回归脚本](../../PluginHistory/Evidence/addons_tmp/test_srti_tools.py) 对当前插件执行通过，包括 Lua/XML、启动初始化、血条掉血/死亡/消失、短姓名、左右布局、猎人印记开关、权限/倒数/保存还原与聊天栏入口。
- 未确认事项：本次为 Lua 5.1 客户端模拟，尚未在运行中的游戏里确认服务器响应和实际画面；游戏内需 `/reload` 后验证。


## 早期历史汇总与维护依据

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

完善标记条生命显示、团队工具和透明图标。

### 记录中的修改

- 增加血条/百分比、短姓名、掉血黄色缓冲区、三档宽度和猎人印记开关；兼容不同布局、缩放及反向排列。
- 增加就位、倒数、清标、重置副本、设置等工具，各自开关及左右位置；重置含游戏确认和权限检查。
- 接入去外描边的透明图集，保存原图，标记条、侧边和圆环保持一致。
- 修正 Banana 初始化前 OnUpdate 扫描、重复加载事件和旧禁用配置；GUID 保存/还原支持 SuperWoW。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [Banana.lua](../../Interface/AddOns/SimpleRaidTargetIcons/Banana.lua)
- [Banana.xml](../../Interface/AddOns/SimpleRaidTargetIcons/Banana.xml)
- [IconTextures.lua](../../Interface/AddOns/SimpleRaidTargetIcons/IconTextures.lua)
- [RaidTools.lua](../../Interface/AddOns/SimpleRaidTargetIcons/RaidTools.lua)
- [SimpleRaidTargetIcons.lua](../../Interface/AddOns/SimpleRaidTargetIcons/SimpleRaidTargetIcons.lua)
- [SimpleRaidTargetIcons.toc](../../Interface/AddOns/SimpleRaidTargetIcons/SimpleRaidTargetIcons.toc)
- [img/srti_icons_borderless.png](../../Interface/AddOns/SimpleRaidTargetIcons/img/srti_icons_borderless.png)
- [img/srti_icons_borderless.tga](../../Interface/AddOns/SimpleRaidTargetIcons/img/srti_icons_borderless.tga)

### 关联插件

[S_ChatBar](S_ChatBar.md)。更新时同时检查对应入口与数据口径。

### 已回退方案及更新注意

原标记 GUID 不保证跨副本重置还原；PNG 与客户端 TGA、图集坐标必须配套。

### 验证与范围

维护报告记录 Lua/XML、素材透明通道/坐标和多组客户端模拟通过；明确没有运行中游戏实测。本次未重新执行。

### 待补充

服务器就位/重置响应、实际血条和缩放效果待游戏确认。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/SimpleRaidTargetIcons)
- [PluginHistory/Evidence/reports/SimpleRaidTargetIcons-20261007.md](../../PluginHistory/Evidence/reports/SimpleRaidTargetIcons-20261007.md)
- [PluginHistory/Evidence/reports/SimpleRaidTargetIcons-borderless-icons-20261007.md](../../PluginHistory/Evidence/reports/SimpleRaidTargetIcons-borderless-icons-20261007.md)
- [PluginHistory/Evidence/reports/CatPotion-魔法橘子沙漏与标记报错修复-20261007.md](../../PluginHistory/Evidence/reports/CatPotion-%E9%AD%94%E6%B3%95%E6%A9%98%E5%AD%90%E6%B2%99%E6%BC%8F%E4%B8%8E%E6%A0%87%E8%AE%B0%E6%8A%A5%E9%94%99%E4%BF%AE%E5%A4%8D-20261007.md)
- [PluginHistory/Evidence/addons_tmp/srti-borderless-backup-20261007/Banana.lua](../../PluginHistory/Evidence/addons_tmp/srti-borderless-backup-20261007/Banana.lua)
- [PluginHistory/Evidence/addons_tmp/srti-borderless-backup-20261007/SimpleRaidTargetIcons.lua](../../PluginHistory/Evidence/addons_tmp/srti-borderless-backup-20261007/SimpleRaidTargetIcons.lua)
- [PluginHistory/Evidence/addons_tmp/srti-borderless-backup-20261007/SimpleRaidTargetIcons.toc](../../PluginHistory/Evidence/addons_tmp/srti-borderless-backup-20261007/SimpleRaidTargetIcons.toc)
- [PluginHistory/Evidence/addons_tmp/srti-layout-health-backup-20261007/Banana.lua](../../PluginHistory/Evidence/addons_tmp/srti-layout-health-backup-20261007/Banana.lua)
- [PluginHistory/Evidence/addons_tmp/srti-layout-health-backup-20261007/RaidTools.lua](../../PluginHistory/Evidence/addons_tmp/srti-layout-health-backup-20261007/RaidTools.lua)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/ChatBar.lua](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/ChatBar.lua)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Banana.lua](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Banana.lua)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Banana.xml](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Banana.xml)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/BananaConfig.xml](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/BananaConfig.xml)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Bindings.xml](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Bindings.xml)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Localization.lua](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Localization.lua)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/SimpleRaidTargetIcons.lua](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/SimpleRaidTargetIcons.lua)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/SimpleRaidTargetIcons.toc](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/SimpleRaidTargetIcons.toc)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/helper_version.ini](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/helper_version.ini)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/SRTIGlow.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/SRTIGlow.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/SRTIRing.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/SRTIRing.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/blank.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/blank.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/cross.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/cross.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/diamond.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/diamond.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/huntermark.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/huntermark.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/moon.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/moon.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/nipple.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/nipple.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/skull.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/skull.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/square.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/square.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/srti_mark.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/srti_mark.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/srti_save.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/srti_save.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/star.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/star.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/triangle.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/triangle.tga)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。

---

[返回插件修改记录](README.md)
