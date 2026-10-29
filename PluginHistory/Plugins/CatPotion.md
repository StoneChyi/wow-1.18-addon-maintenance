# CatPotion 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/CatPotion.md)

## 插件概况

- 分类：经过版本迭代或修改的插件。

- 插件：`CatPotion`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

2026-10-30：斯坦索姆圣水支持左键手选落点、右键脚下投掷（需要现用 UnitXP 对应接口，异常保留手选）；一键补药开关改为 Shift+右键，Shift+左键拖拽排序保留。最小化一/两列窗口始终保留设置入口，设置按钮左键打开配置、右键独立锁定/解锁该小窗。阈值自动使用与 AutoBar 分类快捷条仅讨论方案，尚未实现或开启。

2026-10-25 已合并部署：只新增巧克力鱼条目；迷你计时红色已由个人版实现，保留 Window/Settings 原字节及多窗口、排序、拖拽、毒药和共享冷却。


2026-10-18 已合并部署：完整保留个人多窗口、快捷入口、排序/拖拽预览、各类消耗品、共享/GCD 与毒药计时。只加入神圣巫师之油计时文本识别和计时亮度修复；重复的布局、设置及显示版本采用个人版。 真实游戏验收待补充。

扩展常用物品，并完善多配置窗口和使用反馈。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 进一步优化方案

以下为 2026-10-30 与用户讨论的后续方案，尚未实施：

- 恢复品左键手动使用、右键打开独立阈值设置；自动使用默认关闭，可按每物品设置生命/法力百分比或缺失量、仅战斗及优先级。此功能独立于原一键补长期 Buff 宏；圣水右键脚下投掷保持独立语义。
- 只处理显式开启的少数物品，合并玩家血蓝事件，约 0.2 秒检查，复用已有背包和冷却缓存。调度独立于窗口显隐；每轮只发一个请求，按真实冷却与库存确认，失败退避，使用重新武装阈值防止反复触发。药水与茶/符文分组协调，符文另设生命安全下限。客户端自动用物品能力仍需实际验证，可保留提示/按键兼容模式。
- 替代 AutoBar 可先以多个 CatPotion 小窗分开长期药剂、战斗恢复品与工程物品，再按需加入“固定类别槽＋候选选择＋独立快捷键”；参考 AutoBar 按背包更新的增量扫描，保留 CatPotion 现有 ID、实际/共享冷却和使用确认。可选统一 Cat/Cat2 的物品服务是更后续的独立改动。本次未停用或删除 AutoBar，未新增自动使用循环。

## 逐次修改记录

<a id="change-CatPotion-20261030-01"></a>

### 2026-10-30｜圣水左右键投掷、Shift右键补药开关与窄小窗锁定

- 记录编号：`CatPotion-20261030-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户希望借鉴 Cat2 的瞬发炸药使用逻辑；最小化两列窗口因宽度 104 小于旧阈值 114 而隐藏设置按钮；同时希望方便锁定窗口，并将宏调用开关与普通右键功能分开。用户最终确定 Shift+右键切换宏调用，替代此前讨论的 Shift+左键方案。
- 修改内容：仅将已确认白名单的斯坦索姆圣水（13180）增加左键手选落点/右键脚下投掷；右键前检查已有目标选择、UnitXP 支持、库存锁定及实际冷却，按 Cat2 的版本门槛调用 `castAOE/player`，不依赖加载 Cat2。临时关闭已有 Nampower 快速地面施法和排队设置，所有出口尝试恢复原值并核对；缺支持时在发物品请求前拒绝右键，保留左键手选。无同步落点或接口失败时保留人工选点并提示，不留下可能误投后续技能的重试队列，不扩展到未核实炸药。
- 修改内容：普通药剂的一键补药开关由右键改为 Shift+右键，仅修改所属窗口配置，不消费物品；Shift+左键仍用于排序，拖动和松手抑制期不切宏、不使用。武器强化和仅手动物品继续不参与补药，普通右键不再开关宏；恢复品阈值设置本次仅方案。
- 修改内容：窄窗设置入口保留为 22 宽的“设”，最小化最窄宽度 94，两列仍为 104，切换/设置/关闭三按钮独立于物品列数。设置按钮左键选中对应配置并打开设置，右键复用该配置已有 `locked` 字段锁定/解锁窗口位置，悬停显示状态；不影响其他配置或物品按钮，现有位置和外观存档沿用。
- 涉及文件：`Core.lua`、`Window.lua`、`Settings.lua`；新增 `tests/instant-ground.lua`、`tests/header-lock.lua`，更新原物品、表头、多窗口与排序测试及共享严格字体模拟接入；`Tools/tests/test_catpotion_personal_merge.py`、本页和生成索引。未变更 DLL 或 AutoBar。
- 检查结果：Core/Window/Settings 三个生产文件真实 Lua 5.0 编译通过；统一 13 套个人功能回归通过，新增圣水 210 项及窄窗/锁定/按键/字体 125 项断言。覆盖左右键/Shift 右键分流、不同配置、现有拖拽和副手物品行为、白名单、缺/旧/异常接口、已有落点、库存/冷却/不可用、快速施法与排队设置异常恢复、一/两/三列及空窗、锁定持久化、所有新增文本模板初始化和 FRIZ SetFont 失败后备。三文件原本混合换行保持，未改内容没有仅换行变动。维护索引生成/一致性、说明覆盖/链接及兼容 CRLF 的差异检查均通过。
- 游戏验收与未确认：需要 `/reload` 后验证最小化两列可点击“设”、左键设置/右键锁定、Shift+右键只切所属配置宏，以及圣水左键选点/右键脚下。未在游戏中消费物品；UnitXP 静态接口与旧代码调用证据不代表真实投掷成功；若客户端延迟出现落点圈，本次保守保留手选，不声称已自动投出。所有离线回归均不等于游戏验收。

<a id="change-CatPotion-20261025-02"></a>

### 2026-10-25｜合入 10 月 24 日包并保留个人功能（已部署）

- 记录编号：`CatPotion-20261025-02`
- 记录类型：更新合并
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户要求结合明确更新、保留核心个人功能，不确定项等待确认；另明确同意治疗预读改按键与超级宏改角色独立，属性统计继续暂缓。
- 修改内容：只新增巧克力鱼条目；迷你计时红色已由个人版实现，保留 Window/Settings 原字节及多窗口、排序、拖拽、毒药和共享冷却。
- 涉及文件：`Core.lua`。
- 关联功能与保留：参见[整批实施记录](../Research/10月24日包合并实施-20261025.md)，所有未变及个人独有路径保留；不夹带 DLL 或账号设置。
- 检查结果：11 套完整个人功能回归及严格字体失败后备通过。 整批 176 个变更 Lua 与 32 upvalue 检查通过，TOC/XML 无新增缺失；现用目录与审查候选逐字节一致。[部署清单](../Research/10月24日包合并实施-20261025.json)保存文件指纹和限制。
- 游戏验收与未确认：尚未真实游戏验收；预读/宏迁移/服务器事件与各职业操作仍待实机确认，受控模拟不等同游戏验收。
- 替代关系：本条记录跟随本日差异核对，旧记录保持原有核对时状态；本次仍保留的未确认项目见整批报告。

<a id="change-CatPotion-20261025-01"></a>

### 2026-10-25｜10 月 24 日原包三版本差异核对（未部署）

- 记录编号：`CatPotion-20261025-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户提供 10 月 24 日插件包，要求与 10 月 16 日旧原包及当前个人版对比。
- 修改内容：仅核对并记录，未更新插件。新包变化：新增巧克力鱼（1 闪避/4 防御）、调整食物顺序；迷你图标剩余时间不足阈值时整段标红；设置版本日期更新。
- 当前个人版：多窗口、独立入口、排序/预览、更多物品、共享/GCD 与毒药计时均是现用增强；3 个变更文件均有冲突。
- 涉及文件：`Core.lua`、`Settings.lua`、`Window.lua`。
- 关联功能与处理：只迁移新增物品和预警行为，保留个人多窗口与设置体系，不用新包整文件覆盖。
- 检查结果：逐文件字节及 SHA-256、三方关系与机械合并冲突核对；整批新包变更 Lua 186/187 可编译，GoubayuHeal 原 UI 超过 200 局部变量；可编译文件嵌套函数未超 32 upvalue。相关 TOC/XML 没有新增缺失引用。另运行 BCS 缓存、治疗 UI 编译与 ShaguDPS 兜底受控检查；具体结果与限制见[整批对照报告](../Research/三版本插件对比-20261016-20261024-20261025.md)和[逐文件清单](../Research/三版本插件对比-20261016-20261024-20261025.json)。
- 游戏验收与未确认：本次未部署、未真实游戏或多人验收；既有个人改动归属及证据状态不变，不将原包功能记作本项目新增。

<a id="change-CatPotion-20261018-02"></a>

### 2026-10-18｜合入 10 月 16 日包并保留个人功能（已部署）

- 记录编号：`CatPotion-20261018-02`
- 记录类型：更新合并
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户授权除三个指定插件外更新新包，并要求个人功能完整保留、重复功能优先个人实现。
- 修改内容：完整保留个人多窗口、快捷入口、排序/拖拽预览、各类消耗品、共享/GCD 与毒药计时。只加入神圣巫师之油计时文本识别和计时亮度修复；重复的布局、设置及显示版本采用个人版。
- 涉及文件：`Core.lua`、`Window.lua`。
- 关联功能：详见[整批实施记录](../Research/10月16日包合并实施-20261018.md)；关联个人扩展、皮肤和其他未更新文件保留。
- 检查结果：11 套完整个人回归通过，涵盖多窗口、快捷选择、拖拽排序、页边/分页、标题栏、虫洞、共享/GCD/最后一件物品和毒药；严格字体/SetFont 失败路径及新增计时检查通过。 现用目录与审查后的候选逐字节一致；[逐文件清单](../Research/10月16日包合并实施-20261018.json)保存校验和、保留范围与限制。
- 游戏验收与未确认：本次尚未游戏实测，语法与受控测试不等同于真实客户端验收；更新前可用标签 `before/package-20261016-20261018` 回退。
- 替代关系：本条在前一条差异核对之后实施，只更新当前摘要，不改写当时“未部署”的核对记录。此前个人修改作者与最早日期不作追认。

<a id="change-CatPotion-20261018-01"></a>

### 2026-10-18｜10 月 16 日包与当前个人版差异核对（未部署）

- 记录编号：`CatPotion-20261018-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户提供 10 月 16 日新包，要求沿用旧包/当前个人版/新包三方逻辑核对。
- 修改内容：只检查并记录，没有更新插件。原包变化：增强神圣巫师之油属性文本识别；无物品但计时生效时保持亮度；普通窗口保留设置/切换按钮。
- 当前个人版：多窗口选择、独立入口、排序/预览、更多消耗品及个人外观。
- 涉及文件：`Core.lua`、`Settings.lua`、`Window.lua`。
- 关联功能与处理：人工合并；Core/Settings/Window 共 3 个文件冲突；保留个人窗口体系。
- 检查结果：本次逐文件字节/指纹及三方关系核对；原包相关 Lua 3 个，其中 3 个通过 Lua 5.1 语法检查。 三份来源完成前再次校验未变；[完整报告](../Research/三版本插件对比-20261010-20261016-20261018.md)及[逐文件结果](../Research/三版本插件对比-20261010-20261016-20261018.json)。
- 游戏验收与未确认：本次为差异核对，未合并部署，未进行游戏内加载、界面或多人验收；文本无冲突不代表运行兼容。原维护状态和历史作者归属不作改变。

现有依据尚不能拆分成日期可靠的逐次记录；下方保留早期汇总，不以本次整理日期代替修改日期。

## 早期历史汇总与维护依据

<details>
<summary>展开早期原始说明与证据（不是当前问题或优化清单）</summary>

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

扩展常用物品，并完善多配置窗口和使用反馈。

### 记录中的修改

- 常用消耗品扩充，涵盖功能药水、恢复品、炸药和工程道具；排除必须装备的工程饰品、头盔和靴子。
- 增加魔法橘子、沙漏等物品，区分脱战进食、战斗使用、无冷却和类别共享冷却；不适合自动补药的项目排除在宏外。
- 药剂小窗支持排序、拖动预览、多配置、快捷入口及菜单边缘处理；虫洞等项目依据增量备份核对。
- 使用实际客户端冷却与数量变化，处理最后一件消耗、失败使用和共享冷却。

- 更早的插件内 README 记录多配置迁移、每套独立开窗及默认配置宏；武器强化/毒药按主副手分别监控，毒药剩余次数使用独立角标。
- 针对旧客户端拖到屏幕边缘崩溃，停用原生夹紧和拖动结束自动回拉；只保存当前锚点，出屏后使用“窗口归位”。可见窗口的重排由下一帧驱动器执行，避免鼠标回调中直接重排。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [Core.lua](../../Interface/AddOns/CatPotion/Core.lua)
- [README.md](../../Interface/AddOns/CatPotion/README.md)
- [Settings.lua](../../Interface/AddOns/CatPotion/Settings.lua)
- [Window.lua](../../Interface/AddOns/CatPotion/Window.lua)

### 关联插件

[S_ChatBar](S_ChatBar.md)。更新时同时检查对应入口与数据口径。

### 已回退方案及更新注意

阶段报告中的 135/139 项是各次修改当时的数量，不是本次重新统计的最终总量；原有功能不等于全部由本项目新增。拖动夹紧、松手读取四边再回拉以及下一帧自动回拉曾在真实旧客户端失败，不应恢复；毒药计时/次数必须按主副手隔离。

### 验证与范围

两份阶段报告记录语法检查和多组模拟回归通过，但都明确未在真实游戏中点击验证；本次未重新执行插件测试。

### 待补充

部分早期窗口功能缺完整修改前对照；实际新增物品的游戏点击结果待补充。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/CatPotion)
- [PluginHistory/Evidence/reports/CatPotion-常用消耗品更新-20261006.md](../../PluginHistory/Evidence/reports/CatPotion-%E5%B8%B8%E7%94%A8%E6%B6%88%E8%80%97%E5%93%81%E6%9B%B4%E6%96%B0-20261006.md)
- [PluginHistory/Evidence/reports/CatPotion-魔法橘子沙漏与标记报错修复-20261007.md](../../PluginHistory/Evidence/reports/CatPotion-%E9%AD%94%E6%B3%95%E6%A9%98%E5%AD%90%E6%B2%99%E6%BC%8F%E4%B8%8E%E6%A0%87%E8%AE%B0%E6%8A%A5%E9%94%99%E4%BF%AE%E5%A4%8D-20261007.md)
- [PluginHistory/Evidence/addons_tmp/catpotion-row-order-backup-20261007/README.md](../../PluginHistory/Evidence/addons_tmp/catpotion-row-order-backup-20261007/README.md)
- [PluginHistory/Evidence/addons_tmp/catpotion-drag-preview-backup-20261007/README.md](../../PluginHistory/Evidence/addons_tmp/catpotion-drag-preview-backup-20261007/README.md)
- [PluginHistory/Evidence/addons_tmp/catpotion-wormholes-backup-20261007/README.md](../../PluginHistory/Evidence/addons_tmp/catpotion-wormholes-backup-20261007/README.md)
- [PluginHistory/Evidence/addons_tmp/catpotion-shortcut-backup-20261007/README.md](../../PluginHistory/Evidence/addons_tmp/catpotion-shortcut-backup-20261007/README.md)
- [PluginHistory/Evidence/addons_tmp/catpotion-menu-edge-backup-20261006/README.md](../../PluginHistory/Evidence/addons_tmp/catpotion-menu-edge-backup-20261006/README.md)
- [PluginHistory/Evidence/addons_tmp/catpotion-consumables-backup-20261006/Core.lua](../../PluginHistory/Evidence/addons_tmp/catpotion-consumables-backup-20261006/Core.lua)
- [PluginHistory/Evidence/addons_tmp/catpotion-consumables-backup-20261006/README.md](../../PluginHistory/Evidence/addons_tmp/catpotion-consumables-backup-20261006/README.md)
- [PluginHistory/Evidence/addons_tmp/catpotion-consumables-backup-20261006/Settings.lua](../../PluginHistory/Evidence/addons_tmp/catpotion-consumables-backup-20261006/Settings.lua)
- [PluginHistory/Evidence/addons_tmp/catpotion-consumables-backup-20261006/Window.lua](../../PluginHistory/Evidence/addons_tmp/catpotion-consumables-backup-20261006/Window.lua)
- [PluginHistory/Evidence/addons_tmp/catpotion-drag-preview-backup-20261007/Window.lua](../../PluginHistory/Evidence/addons_tmp/catpotion-drag-preview-backup-20261007/Window.lua)
- [PluginHistory/Evidence/addons_tmp/catpotion-header-backup-20261006/Window.lua](../../PluginHistory/Evidence/addons_tmp/catpotion-header-backup-20261006/Window.lua)
- [PluginHistory/Evidence/addons_tmp/catpotion-menu-edge-backup-20261006/Window.lua](../../PluginHistory/Evidence/addons_tmp/catpotion-menu-edge-backup-20261006/Window.lua)
- [PluginHistory/Evidence/addons_tmp/catpotion-orange-hourglass-srti-backup-20261007/Banana.lua](../../PluginHistory/Evidence/addons_tmp/catpotion-orange-hourglass-srti-backup-20261007/Banana.lua)
- [PluginHistory/Evidence/addons_tmp/catpotion-orange-hourglass-srti-backup-20261007/Banana.xml](../../PluginHistory/Evidence/addons_tmp/catpotion-orange-hourglass-srti-backup-20261007/Banana.xml)
- [PluginHistory/Evidence/addons_tmp/catpotion-orange-hourglass-srti-backup-20261007/Core.lua](../../PluginHistory/Evidence/addons_tmp/catpotion-orange-hourglass-srti-backup-20261007/Core.lua)
- [PluginHistory/Evidence/addons_tmp/catpotion-orange-hourglass-srti-backup-20261007/README.md](../../PluginHistory/Evidence/addons_tmp/catpotion-orange-hourglass-srti-backup-20261007/README.md)
- [PluginHistory/Evidence/addons_tmp/catpotion-orange-hourglass-srti-backup-20261007/test_srti_tools.py](../../PluginHistory/Evidence/addons_tmp/catpotion-orange-hourglass-srti-backup-20261007/test_srti_tools.py)
- [PluginHistory/Evidence/addons_tmp/catpotion-row-order-backup-20261007/Core.lua](../../PluginHistory/Evidence/addons_tmp/catpotion-row-order-backup-20261007/Core.lua)
- [PluginHistory/Evidence/addons_tmp/catpotion-row-order-backup-20261007/Settings.lua](../../PluginHistory/Evidence/addons_tmp/catpotion-row-order-backup-20261007/Settings.lua)
- [PluginHistory/Evidence/addons_tmp/catpotion-row-order-backup-20261007/Window.lua](../../PluginHistory/Evidence/addons_tmp/catpotion-row-order-backup-20261007/Window.lua)
- [PluginHistory/Evidence/addons_tmp/catpotion-shortcut-backup-20261007/ChatBar.lua](../../PluginHistory/Evidence/addons_tmp/catpotion-shortcut-backup-20261007/ChatBar.lua)
- [PluginHistory/Evidence/addons_tmp/catpotion-shortcut-backup-20261007/Window.lua](../../PluginHistory/Evidence/addons_tmp/catpotion-shortcut-backup-20261007/Window.lua)
- [PluginHistory/Evidence/addons_tmp/catpotion-wormholes-backup-20261007/Core.lua](../../PluginHistory/Evidence/addons_tmp/catpotion-wormholes-backup-20261007/Core.lua)
- [PluginHistory/Evidence/addons_tmp/catpotion-wormholes-backup-20261007/Settings.lua](../../PluginHistory/Evidence/addons_tmp/catpotion-wormholes-backup-20261007/Settings.lua)
- [PluginHistory/Evidence/addons_tmp/catpotion-wormholes-backup-20261007/Window.lua](../../PluginHistory/Evidence/addons_tmp/catpotion-wormholes-backup-20261007/Window.lua)
- [PluginHistory/Evidence/addons_tmp/catpotion_data.py](../../PluginHistory/Evidence/addons_tmp/catpotion_data.py)

- [Interface/AddOns/CatPotion/README.md](../../Interface/AddOns/CatPotion/README.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。

---

[返回插件修改记录](README.md)

</details>
