# CatPotion 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/CatPotion.md)

## 插件概况

- 插件：`CatPotion`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

2026-10-25 核对：10 月 24 日原包有功能更新；现用实现保持不变，详情见本页最新差异记录。

2026-10-18 已合并部署：完整保留个人多窗口、快捷入口、排序/拖拽预览、各类消耗品、共享/GCD 与毒药计时。只加入神圣巫师之油计时文本识别和计时亮度修复；重复的布局、设置及显示版本采用个人版。 真实游戏验收待补充。

扩展常用物品，并完善多配置窗口和使用反馈。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

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
