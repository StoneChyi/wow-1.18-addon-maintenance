# CatPotion 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/CatPotion.md)

## 插件概况

- 插件：`CatPotion`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

扩展常用物品，并完善多配置窗口和使用反馈。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

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
