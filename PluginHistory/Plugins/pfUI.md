# pfUI 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/pfUI.md)

## 插件概况

- 插件：`pfUI`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

2026-10-18 核对：10 月 16 日包有更新，尚未部署；当前实现保持不变，差异与合并注意见最新记录。

整合个人界面、监控和旧客户端兼容修改。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

<a id="change-pfUI-20261018-01"></a>

### 2026-10-18｜10 月 16 日包与当前个人版差异核对（未部署）

- 记录编号：`pfUI-20261018-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户提供 10 月 16 日新包，要求沿用旧包/当前个人版/新包三方逻辑核对。
- 修改内容：只检查并记录，没有更新插件。原包变化：8.55.3；聊天复制打开回顶部，避免空白；姓名板复用清目标态，新板 alpha 判定延后 0.4 秒。
- 当前个人版：保留字符拖选/YY、监控与亮度、姓名板身份缓存/配色和个人布局。
- 涉及文件：`modules/chatcopy.lua`、`modules/nameplates.lua`、`pfUI-tbc.toc`、`pfUI.toc`。
- 关联功能与处理：合并；聊天复制无文本冲突，姓名板 1 处冲突；保留个人身份缓存和配色修复。
- 检查结果：本次逐文件字节/指纹及三方关系核对；原包相关 Lua 2 个，其中 2 个通过 Lua 5.1 语法检查。 三份来源完成前再次校验未变；[完整报告](../Research/三版本插件对比-20261010-20261016-20261018.md)及[逐文件结果](../Research/三版本插件对比-20261010-20261016-20261018.json)。
- 游戏验收与未确认：本次为差异核对，未合并部署，未进行游戏内加载、界面或多人验收；文本无冲突不代表运行兼容。原维护状态和历史作者归属不作改变。

<a id="change-pfUI-20261013-03"></a>

### 2026-10-13｜姓名板玩家/NPC 身份缓存修复

- 记录编号：`pfUI-20261013-03`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[80fba48](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/80fba486742530a62d317f8fc6f961f20021dfd8)


目的：用户截图中两只同名、同等级、满血蝙蝠在非战斗时分别显示红色与棕色，用户确认选中或移入鼠标后仍不恢复。原逻辑先缓存目标/鼠标单位的玩家身份，随后才检查是否对应姓名板；目标切换或框体复用时可能误写 PLAYER，后续又优先使用旧缓存，造成 NPC 持续套用玩家职业色。实际代码片段已离线复现这条路径，棕色与战士职业色相符；未读取到截图现场的运行中缓存，不将其记为游戏内根因已实证。

主要文件：[modules/nameplates.lua](../../Interface/AddOns/pfUI/modules/nameplates.lua)、[Tools/tests/test_pfui_nameplate_identity.py](../../Tools/tests/test_pfui_nameplate_identity.py)。先用姓名板有效 GUID 查询并核对单位名字，再允许身份入缓存；无法直接查询 GUID 时，目标/鼠标单位需通过存在、名字及可用 GUID 对应检查，目标切换事件中的不稳定令牌不写入身份。有效实时信息直接纠正旧缓存，包括 PLAYER → NPC，并立即用于本轮配色；缓存同时绑定名字与 GUID，同名单位换 GUID 时清除身份和技能计时缓存。普通姓名板重新显示时重新核验身份，GUID 复用时安排即时刷新。无 GUID 环境仍保留已校验目标/鼠标单位及名字数据库后备，固定目标姓名板沿用同一身份管线。

关联功能：玩家职业色、自定义 NPC 色、敌对/中立/友好配色、他人拾取归属灰色、战斗状态覆盖及固定目标姓名板；不通过关闭职业色或战斗染色规避问题。没有新增 FontString 或客户端 API；沿用本地 GetUnitGUID 兼容封装及原有 GUID 单位查询接口，原 Lua 文件 UTF-8 编码、无 BOM 和 CRLF 换行保持。

真实验证：Lua 5.1 检查运行实际身份判定、颜色写入、战斗染色、OnShow 和 GUID 注册更新代码，共 52 项通过；固定修复前提交 `8fce60b3036db7e996246f38c202ee053fd761cd` 可复现错误，修复后通过。覆盖目标事件错配、错误缓存双向纠正、鼠标错配、同名不同 GUID、GUID 暂不可查询/丢失/无效、NPC 与玩家名字数据库冲突、非 GUID 回退、玩家职业色开关、NPC 职业数据不越过实时身份、自定义色、归属灰色、战斗覆盖后脱战恢复、普通框体复用及固定目标板隔离。完整 nameplates.lua 语法通过；读取编译元数据确认 OnDataChanged 引用的外层局部变量仍为 32 个，未超过本项目记录的旧客户端上限。此测试不创建 FontString，不模拟字体初始化为空操作。

未确认事项：本次尚未游戏内实测；需 /reload 后，在原蝙蝠场景反复切换目标、悬停及移出/移入姓名板范围，确认两块血条非战斗配色一致，再检查玩家职业色与战斗染色恢复。离线模拟不等同于客户端验收；没有修改账号或角色设置。插件证据状态仍为“有维护记录”，初始化清单和历史证据保持原样。

<a id="change-pfUI-20261013-02"></a>

### 2026-10-13｜动作条监视不可用图标进一步调暗

- 记录编号：`pfUI-20261013-02`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[8fce60b](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/8fce60b3036db7e996246f38c202ee053fd761cd)


目的：用户希望不可用图标再暗一些，整体观感趋近其描述的正式服露露整合包中间 WA。当前未获得该整合包具体版本及参考画面，本次按明确的降低亮度方向调整，不将结果称为已还原其 WA 样式。

主要文件：[modules/actionbar.lua](../../Interface/AddOns/pfUI/modules/actionbar.lua)。将动作条监视不可用图标的 RGB 亮度系数从 0.45 降为 0.30，保持原色及不透明显示；可用图标仍恢复正常亮度。关联功能为超距、缺资源和其他不可用提示，继续遵循原有提示开关。

真实验证：执行内提取实际范围检测及着色代码，Lua 5.1 的 768 组状态/开关组合检查通过，覆盖 30% 调暗、可用后恢复、透明度和边框缓存；语法检查通过。仅修改亮度参数，原文件编码、换行及其他字节保持。未新增 FontString 或客户端接口。

未确认事项：本次尚未游戏内实测，需 /reload 后确认 30% 亮度的实际观感；没有参考图，尚不能确认与所指露露 WA 的相似程度。没有改写账号设置。


<a id="change-pfUI-20261013-01"></a>

### 2026-10-13｜动作条监视不可用状态改为降低亮度

- 记录编号：`pfUI-20261013-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[81ce3f9](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/81ce3f9d9c2f473c7beb8ac7455a27fee4ac374f)


目的：按用户截图反馈移除动作条监视在技能不可用时的红色覆盖。用户当日澄清目标为动作条监视。原监视图标超出范围时以红色乘色、缺资源时以蓝色乘色，视觉上改变技能图案的颜色。

主要文件：[modules/actionbar.lua](../../Interface/AddOns/pfUI/modules/actionbar.lua)。监视图标在超距、缺资源或其他不可用状态下统一使用 RGB 0.45/0.45/0.45 降低亮度，保留图案原色，透明度维持 1；可用时恢复正常亮度。沿用 glowrange/showoom/showna 原有开关，保留独立边框提示与冷却显示。范围检测先于亮度更新执行，消除进入/退出范围时图标状态落后一轮刷新的问题。关联功能为监控轻刷及多套监控方案；特殊快捷动作条和普通动作条的原有配色逻辑不改。

真实验证：本次执行内提取实际 MonitorUpdateButton 的范围检测与着色代码，在 Lua 5.1 中检查 768 组可用性、资源不足、动作存在/有无范围、距离返回 nil/0/1、三项提示开关和上一轮范围状态组合；亮度、透明度、同轮状态切换及边框缓存均通过。现有监视背景、仅监控模式五组及旧客户端提示归属六项回归通过，actionbar.lua 语法通过。未新增 FontString 或客户端 API，原文件编码及换行保持。

未确认事项：尚未进行本次改动的游戏内实测；需 /reload 后确认 45% 亮度的实际观感，离线模拟不等同于游戏验收。没有改写账号设置。


<a id="change-pfUI-20261012-03"></a>

### 2026-10-12｜手动锚点在解锁拖动后保持

- 记录编号：`pfUI-20261012-03`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[c3c8113](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/c3c811321f0ac218f3393747d10c22deae343876)


目的：用户报告特殊快捷动作条选 BOTTOMLEFT 后重新登录显示 BOTTOM；当日随后确认，实际触发为选择锚点后再次拖动动作条。检查发现解锁拖动结束时会对所有选中框体按屏幕区域调用 GetBestAnchor，再保存为新锚点；位于屏幕下方中间的框体会被改为 BOTTOM，因此属于拖动覆盖手动选择，而非退出游戏时丢失保存。普通动作条、宠物条、监控条与其他可移动框体均使用同一逻辑。

主要文件：[modules/unlock.lua](../../Interface/AddOns/pfUI/modules/unlock.lua)、[Tools/tests/test_pfui_anchor_persistence.py](../../Tools/tests/test_pfui_anchor_persistence.py)。下拉框选择锚点时同时记录 anchor_manual；后续单独或成组拖动逐框体使用手动指定的锚点，未指定者仍按屏幕区域自动判断。重置位置会删除整条位置记录，同时恢复自动判断。旧存档不推断哪些锚点为手动指定，更新后需要重新选择一次，以建立此标记。关联功能为拖动吸附后的定位、多框体移动及特殊快捷动作条随技能数量改变的延伸方向。

真实验证：Lua 5.1 离线检查调用实际下拉选择、拖动结束、SaveMovable、LoadMovable、UpdateMovable、GetBestAnchor 与 ConvertFrameAnchor 代码；45 组框体/锚点组合覆盖 9 个锚点、特殊/宠物/普通/监控动作条及玩家框体，通过拖动、尺寸变化及新框体恢复检查。旧存档和未指定锚点仍自动判断，混合成组拖动分别保留手动选择，重置后恢复自动判断。独立核对已保存 BOTTOMLEFT 在默认位置重建及 UpdateMovable(init=true) 后仍保留，未发现宠物动作条显隐逻辑改写已保存锚点。原版本可复现拖动覆盖手动锚点，修复后通过；测试不创建 FontString，修改 Lua 文件语法检查通过。

未确认事项：用户确认了原问题的拖动触发方式；本次修复尚未进行游戏内实测，离线检查不等同于重登验收。仅检查与锚点保存关联的路径，不声称其他所有配置均无问题。没有修改账号或角色设置；开始检查时存在的 Cooline 及其测试的其他未提交改动不属于本次维护，本次未改写这些文件。


<a id="change-pfUI-20261012-02"></a>

### 2026-10-12｜动作条监控关闭背景后清除图标独立底色

- 记录编号：`pfUI-20261012-02`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[58f8ce5](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/58f8ce592f76eb71d557fcd4a51decaf41d00989)


目的：修正关闭“显示背景”后图标周围仍有黑色的问题。整条监控区与每个监控按钮分别创建背景；原开关仅隐藏整条监控区的背景，而按钮底板仍保留全局背景色，并向图标外延伸 2 个界面单位，造成黑色残留。

主要文件：[modules/actionbar.lua](../../Interface/AddOns/pfUI/modules/actionbar.lua)、[tests/monitor-background.lua](../../Interface/AddOns/pfUI/tests/monitor-background.lua)。监控按钮创建背景时通过现有 CreateBackdrop 的透明度参数将填充设为透明，让“显示背景”统一控制底色；金色/超距边框仍由原有独立开关控制。关联功能为监控背景显隐、阴影和多套监控方案；普通动作条背景及图标间距不变。

真实验证：Lua 5.1 回归调用实际 CreateBackdrop、CreateBackdropShadow、监控按钮创建及背景切换代码，确认旧版本会因按钮仍有底色而失败，修复后通过。覆盖普通/暴雪边框样式、边框开关、默认关闭背景、反复开关背景与阴影显隐、超距边框更新，以及普通背景保持原透明度；该测试不创建 FontString。仅监控模式五组、旧客户端提示归属六项回归及 actionbar.lua 语法检查通过。

未确认事项：本次未进行游戏内实测，需要 /reload 后关闭“显示背景”确认实际观感。图标贴图本身的黑色区域仍属于技能图案；若只需纯图标，可同时关闭原有金色边框开关。离线模拟不等同于客户端验收。


<a id="change-pfUI-20261012-01"></a>

### 2026-10-12｜动作条监控图标间距按屏幕像素统一

- 记录编号：`pfUI-20261012-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[f7a1156](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/f7a11565056958ef6fbf3e0ce93cd785b2cde6b0)


目的：修正用户截图中右侧图标间隙比其他间隙小的问题。原布局直接使用逻辑尺寸和间距，经过 UI 与监控框体缩放后产生小数像素，图标边缘分别取整会出现一像素差异；以 1440p、UI 缩放 0.75、框体缩放 1.1、图标 21、间距 1 的组合和分数位置可复现前六处 2 像素、末处 1 像素。

主要文件：[modules/actionbar.lua](../../Interface/AddOns/pfUI/modules/actionbar.lua)。按旧客户端 768 单位画布、当前分辨率和 GetEffectiveScale 换算真实像素，将图标宽高、间距、内边距及容器尺寸使用同一整像素网格；正间距至少保留一个屏幕像素，零间距仍为零。保存的配置尺寸不改写。沿用已有 0.25 秒检查，在分辨率或继承缩放改变时重排；拖动排序期间延迟布局，空闲时不重复重排。关联功能包括多行布局、Shift 排序、多套监控方案、天赋匹配及仅监控模式。

真实验证：[Tools/tests/test_pfui_monitor_spacing.py](../../Tools/tests/test_pfui_monitor_spacing.py) 调用实际布局及更新代码，复现旧间隙不一致并验证修复；2592 组图标尺寸、间距、行数、数量、缩放和分辨率组合通过，覆盖分数位置、多行、零间距、空列表、缩放/分辨率动态刷新、空闲缓存、拖动期间延迟及无效分辨率后备。该几何测试不创建 FontString。仅监控五组及旧客户端提示归属六项回归通过。历史动作监控综合模拟在执行内补充实际分辨率接口、IsOwned、字体模板初始化与 SetText 字体前置检查，并模拟配置字体 SetFont 失败后通过排序、方案切换、提示开关及设置同步；历史证据文件未改写。修改的 Lua 文件语法检查通过。

未确认事项：未进行本次游戏内实测，重载后需确认截图所示间隙的实际观感；离线像素模型和界面模拟不等同于客户端验收。没有修改账号设置或上传截图。


<a id="change-pfUI-20261009-03"></a>

### 2026-10-09｜动作条监控增加仅监控模式

- 记录编号：`pfUI-20261009-03`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[c6983d4](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/c6983d44dbfb3b4da721b2c9f357a1ab9e333a1f)


目的：避免点击监控图标时误施法。动作条监控设置新增“仅监控，禁止点击施法”，默认关闭以保留已有行为；每套监控方案独立保存此开关，旧方案缺少该字段时按关闭处理，避免继承上一方案的禁用状态。

主要文件：`modules/actionbar.lua`、`modules/gui.lua`、`api/config.lua`、`env/translations_zhCN.lua`。开启后屏蔽监控按钮的左右键、自施法和独立监控热键施法，同时调整悬停说明；Alt 加入/移出监控、Shift 拖动排序、冷却及状态显示保留，原动作条的点击与热键逻辑不变。关联功能为多套监控方案及天赋自动切换。

真实验证：四个修改 Lua 文件语法通过；[仅监控模式回归](../../Interface/AddOns/pfUI/tests/monitor-display-only.lua)的五组离线模拟检查通过，覆盖默认点击、自施法、模式拦截、管理手势、独立热键、提示文字和旧方案迁移；已有 `tests/monitor-tooltip-owner.lua` 六项旧客户端兼容回归通过。现有动作监控综合模拟也通过（仅在测试执行内将过时的 GetOwner 桩改为 IsOwned，历史证据文件保持原样），包含跨行排序、拖动不施法、配置持久化、天赋自动切换和设置页同步。

未确认事项：本次未进行游戏内实测；需重载后检查监控点击、排序和方案切换的实际交互。不将离线检查扩大为游戏验收。


<a id="change-pfUI-20261009-02"></a>

### 2026-10-09｜聊天复制取消单击整条消息选择

- 记录编号：`pfUI-20261009-02`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[ceb3241](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/ceb324121e29de2e2dc7aafdca52b3473be0d2e5)


目的：按用户反馈移除单击即选中整条消息及 Shift 点击按消息范围选择的机制，避免误选。单击现在清除文字选区；拖动鼠标选取任意文字，Shift 点击只扩展已有字符选区；“复制选中”没有选区时仅提示，不回退复制整条消息。“复制全部”按钮与团队 YY 提取保留。

主要文件：[modules/chatcopy.lua](../../Interface/AddOns/pfUI/modules/chatcopy.lua)、[env/translations_zhCN.lua](../../Interface/AddOns/pfUI/env/translations_zhCN.lua)。关联功能：中文字符拖选、跨消息选择、透明 EditBox 的 Ctrl+C 回退、团队 YY 去空格复制。移除整条消息选区状态和底色，提示改为拖选文字。

验证：[Tools/tests/test_pfui_chatcopy_drag_only.py](../../Tools/tests/test_pfui_chatcopy_drag_only.py) 使用 Lua 5.1 模拟界面，验证单击/无文字锚点的 Shift 点击不会选择整条消息，无选区复制不会改写剪贴板；已有文字的 Shift 点击扩选、中文/反向/跨消息拖选、复制全部、剪贴板 API 与 Ctrl+C 回退均通过。团队 YY 的 12 种输入回归通过，包含 `YY:123 123 123` → `123123123`；频道隔离、退团清空、换行、缓存和拖动释放检查也通过。

未确认事项：尚未进行本次改动的游戏内实测；离线界面模拟不等同于客户端验收。历史依据与初始化清单保持原样。


<a id="change-pfUI-20261009-01"></a>

### 2026-10-09｜技能栏初始化兼容修复（本次确认）

- 记录编号：`pfUI-20261009-01`
- 记录类型：修改
- 游戏验收：用户实测（限本条范围）
- 对应提交：[34c00bb](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/34c00bba956b1aaad8ee9a43211239398d0dd998)


技能栏监控调用旧客户端缺少的 GameTooltip:GetOwner 导致后续模块未加载；已改用 IsOwned。六项离线模拟检查通过，用户执行 /reload 后确认头像、小地图和按钮收纳均恢复。主要文件：modules/actionbar.lua、tests/monitor-tooltip-owner.lua。详见[本次修复与验证记录](../pfUI-tooltip-fix-20261009.md)。此结论不代表所有监控方案均已实测；哨塔隐藏需求尚未重新实施。



## 早期历史汇总与维护依据

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

整合个人界面、监控和旧客户端兼容修改。

### 记录中的修改

- 平砍计时修正猎人远程异常，目标平砍支持 Nampower/SuperWoW/无 DLL 回退；固定目标姓名板复刻血条、施法、减益和仇恨，支持移动及独立尺寸。
- 团队宠物布局、反向填充、light/lightH 预设及自定义布局修复；后续 09-18 又拆分团队人数/宠物池并调整拖动，不能只恢复 08-18 中间方案。
- 单位框队长/助理图标、焦点引导、GUID/名字兼容；提示生命/能量条的字体、排序、位置和百分比开关。
- 玩家光环黑白名单、色盲品质文字、中文数值缩写；姓名板控制技能高亮及默认开关、堆叠兼容和图标签名缓存。
- libdebuff 按 Cursive 等资料修正时长，处理 Nampower 实际光环槽、溢出减益标志、原始/紧凑索引、重复图标和悬停提示。
- 分离/监控 Buff、Debuff：分别拖动，目标采用复制监控；取消未激活灰显方案，监控名单上限调整和动态布局。
- 聊天复制入口稳定、自动 /who 静默与手动查询区分、密语非粘性开关及聊天标签调整。
- 动作条冷却/触发高亮、姿态条物品计数及动作条监控；保留点击、锁定、外观、宏名/热键等能力。
- 面板移植/扩展 diminfo 信息模块，顶部/底部信息条、按需刷新及团队冷却队列。
- 全局材质批量选择、pfUI-Z 补全、材质下拉缩略图；自动下马、节日判断和商人批量购买队列等修复。
- 2026-10-04 自身装备悬停不再做无意义的自我装备对比。
- 2026-10-08 距离框左侧圆点表示视线、右侧圆角方块表示近战条件；图形抗锯齿、字号居中补偿及固定锚点，数字位数改变不推动标记。
- 2026-10-08 聊天复制窗口支持任意拖选、Ctrl+C/复制选中；提取团队 YY，去空格保留前导零，退团清除，世界广告不覆盖。
- 2026-10-08 动作监控增加隐藏技能描述、解锁后 Shift 拖动排序、多套独立方案和完整天赋加点绑定；未匹配时保留现方案。
- 仇恨显示接入 ShaguDPS 坦克模式多目标数据，目标仇恨框采用连续渐变，最终文字只保留百分比。

- 2026-10-09 修正动作监控配置使用旧客户端不存在的 GameTooltip:GetOwner 导致初始化中断，改用 IsOwned(button) 并跳过缺失按钮；提交 `4feabd8` 及独立报告记录六项离线回归通过，用户重载后确认头像、小地图和按钮收纳恢复。这个验收范围不扩大为所有 pfUI 功能已实测。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [api/api.lua](../../Interface/AddOns/pfUI/api/api.lua)
- [api/config.lua](../../Interface/AddOns/pfUI/api/config.lua)
- [api/ui-widgets.lua](../../Interface/AddOns/pfUI/api/ui-widgets.lua)
- [api/unitframes.lua](../../Interface/AddOns/pfUI/api/unitframes.lua)
- [env/profiles.lua](../../Interface/AddOns/pfUI/env/profiles.lua)
- [env/translations_zhCN.lua](../../Interface/AddOns/pfUI/env/translations_zhCN.lua)
- [libs/libdebuff.lua](../../Interface/AddOns/pfUI/libs/libdebuff.lua)
- [modules/actionbar.lua](../../Interface/AddOns/pfUI/modules/actionbar.lua)
- [modules/actionbar_glow.lua](../../Interface/AddOns/pfUI/modules/actionbar_glow.lua)
- [modules/buff.lua](../../Interface/AddOns/pfUI/modules/buff.lua)
- [modules/buyemall.lua](../../Interface/AddOns/pfUI/modules/buyemall.lua)
- [modules/chat.lua](../../Interface/AddOns/pfUI/modules/chat.lua)
- [modules/chatcopy.lua](../../Interface/AddOns/pfUI/modules/chatcopy.lua)
- [modules/energytick.lua](../../Interface/AddOns/pfUI/modules/energytick.lua)
- [modules/eqcompare.lua](../../Interface/AddOns/pfUI/modules/eqcompare.lua)
- [modules/gui.lua](../../Interface/AddOns/pfUI/modules/gui.lua)
- [modules/nameplates.lua](../../Interface/AddOns/pfUI/modules/nameplates.lua)
- [modules/panel.lua](../../Interface/AddOns/pfUI/modules/panel.lua)
- [modules/raid.lua](../../Interface/AddOns/pfUI/modules/raid.lua)
- [modules/swingtimer.lua](../../Interface/AddOns/pfUI/modules/swingtimer.lua)
- [modules/target.lua](../../Interface/AddOns/pfUI/modules/target.lua)
- [modules/tooltip.lua](../../Interface/AddOns/pfUI/modules/tooltip.lua)
- [modules/unlock.lua](../../Interface/AddOns/pfUI/modules/unlock.lua)

- [tests/monitor-tooltip-owner.lua](../../Interface/AddOns/pfUI/tests/monitor-tooltip-owner.lua)

### 关联插件

[pfUI-CustomMedia](pfUI-CustomMedia.md)、[pfUI-addonskinner](pfUI-addonskinner.md)、[Automatonex](Automatonex.md)、[ShaguDPS](ShaguDPS.md)、[diminfo](diminfo.md)、[WIM](WIM.md)、[Cat](Cat.md)。更新时同时检查对应入口与数据口径。

### 已回退方案及更新注意

09-14 的聊天按行拖选曾回退，10-08 采用新方案；灰显监控、固定姓名板光晕和 AGRO 差值后缀均曾被取消。最初关于特殊姿态条锚点的聊天仅给出设置建议，不记为已修代码。早期笔记中的多个客户端不能混为同一个当前安装。

### 验证与范围

日期笔记记录多轮语法、模拟和个别用户实测；10-08 聊天复制、动作监控与距离框完成报告明确仍需游戏验证。这里逐阶段保留来源，不将历史检查当作本次运行结果。

### 待补充

修改跨度较大，历史笔记不覆盖每行归属；游戏内最终布局、多人仇恨、光环和新监控方案的验收请补充。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/pfUI)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-08-15.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-08-15.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-08-16.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-08-16.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-08-17.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-08-17.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-08-18.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-08-18.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-08-19.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-08-19.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-08-20.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-08-20.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-08-21.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-08-21.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-08-22.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-08-22.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-08-23.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-08-23.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-08-24.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-08-24.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-08-25.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-08-25.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-08-26.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-08-26.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-08-28.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-08-28.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-08-29.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-08-29.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-08-30.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-08-30.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-08-31.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-08-31.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-09-01.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-09-01.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-09-03.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-09-03.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-09-04.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-09-04.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-09-05.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-09-05.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-09-07.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-09-07.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-09-08.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-09-08.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-09-09.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-09-09.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-09-10.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-09-10.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-09-12.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-09-12.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-09-13.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-09-13.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-09-14.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-09-14.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-09-17.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-09-17.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-09-18.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-09-18.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-09-19.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-09-19.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-09-23.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-09-23.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-09-24.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-09-24.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-09-29.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-09-29.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-10-02.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-10-02.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-10-04.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-10-04.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/MEMORY.md](../../Interface/AddOns/pfUI/.workbuddy/memory/MEMORY.md)
- [PluginHistory/Research/维护聊天摘录-20261009.json](../../PluginHistory/Research/%E7%BB%B4%E6%8A%A4%E8%81%8A%E5%A4%A9%E6%91%98%E5%BD%95-20261009.json)
- [Interface/AddOns/ShaguDPS/.workbuddy/memory/2026-10-03.md](../../Interface/AddOns/ShaguDPS/.workbuddy/memory/2026-10-03.md)
- [Interface/AddOns/pfUI-CustomMedia/.workbuddy/memory/2026-09-18.md](../../Interface/AddOns/pfUI-CustomMedia/.workbuddy/memory/2026-09-18.md)
- [PluginHistory/Evidence/reports/chatcopy_partial_yy_test.py](../../PluginHistory/Evidence/reports/chatcopy_partial_yy_test.py)
- [PluginHistory/Evidence/addons_tmp/check_action_monitor.py](../../PluginHistory/Evidence/addons_tmp/check_action_monitor.py)
- [PluginHistory/Evidence/addons_tmp/check_distance_status.py](../../PluginHistory/Evidence/addons_tmp/check_distance_status.py)
- [PluginHistory/Evidence/CodexBackups/pfUI/chatcopy-partial-yy-20261008/chatcopy.lua](../../PluginHistory/Evidence/CodexBackups/pfUI/chatcopy-partial-yy-20261008/chatcopy.lua)
- [PluginHistory/Evidence/CodexBackups/pfUI/chatcopy-partial-yy-20261008/translations_zhCN.lua](../../PluginHistory/Evidence/CodexBackups/pfUI/chatcopy-partial-yy-20261008/translations_zhCN.lua)
- [PluginHistory/Evidence/addons_tmp/action-monitor-options-backup-20261008-231021/actionbar.lua](../../PluginHistory/Evidence/addons_tmp/action-monitor-options-backup-20261008-231021/actionbar.lua)
- [PluginHistory/Evidence/addons_tmp/action-monitor-options-backup-20261008-231021/config.lua](../../PluginHistory/Evidence/addons_tmp/action-monitor-options-backup-20261008-231021/config.lua)
- [PluginHistory/Evidence/addons_tmp/action-monitor-options-backup-20261008-231021/gui.lua](../../PluginHistory/Evidence/addons_tmp/action-monitor-options-backup-20261008-231021/gui.lua)
- [PluginHistory/Evidence/addons_tmp/action-monitor-options-backup-20261008-231021/translations_zhCN.lua](../../PluginHistory/Evidence/addons_tmp/action-monitor-options-backup-20261008-231021/translations_zhCN.lua)
- [PluginHistory/Evidence/addons_tmp/distanceindicator-antialias-backup-20261008-194831/check_distance_status.py](../../PluginHistory/Evidence/addons_tmp/distanceindicator-antialias-backup-20261008-194831/check_distance_status.py)
- [PluginHistory/Evidence/addons_tmp/distanceindicator-antialias-backup-20261008-194831/unitxp.lua](../../PluginHistory/Evidence/addons_tmp/distanceindicator-antialias-backup-20261008-194831/unitxp.lua)
- [PluginHistory/Evidence/addons_tmp/distanceindicator-centering-backup-20261008/unitxp.lua.original](../../PluginHistory/Evidence/addons_tmp/distanceindicator-centering-backup-20261008/unitxp.lua.original)
- [PluginHistory/Evidence/addons_tmp/distanceindicator-fixed-markers-backup-20261008-215432/check_distance_status.py](../../PluginHistory/Evidence/addons_tmp/distanceindicator-fixed-markers-backup-20261008-215432/check_distance_status.py)
- [PluginHistory/Evidence/addons_tmp/distanceindicator-fixed-markers-backup-20261008-215432/unitxp.lua](../../PluginHistory/Evidence/addons_tmp/distanceindicator-fixed-markers-backup-20261008-215432/unitxp.lua)
- [PluginHistory/Evidence/addons_tmp/distanceindicator-shape-alignment-backup-20261008-194146/check_distance_status.py](../../PluginHistory/Evidence/addons_tmp/distanceindicator-shape-alignment-backup-20261008-194146/check_distance_status.py)
- [PluginHistory/Evidence/addons_tmp/distanceindicator-shape-alignment-backup-20261008-194146/unitxp.lua](../../PluginHistory/Evidence/addons_tmp/distanceindicator-shape-alignment-backup-20261008-194146/unitxp.lua)
- [PluginHistory/Evidence/addons_tmp/distanceindicator-solid-status-backup-20261008-193305/api/config.lua](../../PluginHistory/Evidence/addons_tmp/distanceindicator-solid-status-backup-20261008-193305/api/config.lua)
- [PluginHistory/Evidence/addons_tmp/distanceindicator-solid-status-backup-20261008-193305/env/translations_zhCN.lua](../../PluginHistory/Evidence/addons_tmp/distanceindicator-solid-status-backup-20261008-193305/env/translations_zhCN.lua)
- [PluginHistory/Evidence/addons_tmp/distanceindicator-solid-status-backup-20261008-193305/modules/gui.lua](../../PluginHistory/Evidence/addons_tmp/distanceindicator-solid-status-backup-20261008-193305/modules/gui.lua)
- [PluginHistory/Evidence/addons_tmp/distanceindicator-solid-status-backup-20261008-193305/modules/unitxp.lua](../../PluginHistory/Evidence/addons_tmp/distanceindicator-solid-status-backup-20261008-193305/modules/unitxp.lua)
- [Interface/AddOns/pfUI/init/modules.xml.20260924_195026.buyemall.bak](../../Interface/AddOns/pfUI/init/modules.xml.20260924_195026.buyemall.bak)
- [Interface/AddOns/pfUI/modules/eqcompare.20261004_093912.selfcompare.bak](../../Interface/AddOns/pfUI/modules/eqcompare.20261004_093912.selfcompare.bak)
- [Interface/AddOns/pfUI/modules/tooltip.20261002_212528.alwaysperc.bak](../../Interface/AddOns/pfUI/modules/tooltip.20261002_212528.alwaysperc.bak)

- [PluginHistory/pfUI-tooltip-fix-20261009.md](../../PluginHistory/pfUI-tooltip-fix-20261009.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。


---

[返回插件修改记录](README.md)
