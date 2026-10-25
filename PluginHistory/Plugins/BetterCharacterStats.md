# BetterCharacterStats 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/BetterCharacterStats.md)

## 插件概况

- 插件：`BetterCharacterStats`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

2026-10-25 核对：10 月 24 日原包有功能更新；现用实现保持不变，详情见本页最新差异记录。


保持角色属性面板布局稳定，并与观察、换天赋功能协调。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

<a id="change-BetterCharacterStats-20261025-01"></a>

### 2026-10-25｜10 月 24 日原包三版本差异核对（未部署）

- 记录编号：`BetterCharacterStats-20261025-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户提供 10 月 24 日插件包，要求与 10 月 16 日旧原包及当前个人版对比。
- 修改内容：仅核对并记录，未更新插件。新包变化：新增 BCS_GearStat.lua 共享装备文本快照；用负时间戳修正缓存失效；新增吸血、法穿、套装破甲、术士镇压命中、属性栏重置及空表保护。
- 当前个人版：已修正缓存失效；圣骑士近战优先、狂热按技能每层值与层数修正，另有独立预设、布局与同轮扫描复用。
- 涉及文件：`BCS_GearStat.lua`、`BCS_PropertiesPanel.lua`、`BetterCharacterStats.lua`、`BetterCharacterStats.toc`、`Localization.lua`、`helper.lua`。
- 关联功能与处理：共享扫描有价值，但不同缓存生命周期需重审；保留近战急速、狂热、套装激活过滤和个人布局。
- 检查结果：逐文件字节及 SHA-256、三方关系与机械合并冲突核对；整批新包变更 Lua 186/187 可编译，GoubayuHeal 原 UI 超过 200 局部变量；可编译文件嵌套函数未超 32 upvalue。相关 TOC/XML 没有新增缺失引用。另运行 BCS 缓存、治疗 UI 编译与 ShaguDPS 兜底受控检查；具体结果与限制见[整批对照报告](../Research/三版本插件对比-20261016-20261024-20261025.md)和[逐文件清单](../Research/三版本插件对比-20261016-20261024-20261025.json)。
- 游戏验收与未确认：本次未部署、未真实游戏或多人验收；既有个人改动归属及证据状态不变，不将原包功能记作本项目新增。

<a id="change-BetterCharacterStats-20261018-01"></a>

### 2026-10-18｜10 月 16 日包与当前个人版差异核对（未部署）

- 记录编号：`BetterCharacterStats-20261018-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户提供 10 月 16 日新包，要求沿用旧包/当前个人版/新包三方逻辑核对。
- 修改内容：只检查并记录，没有更新插件。原包变化：缓存 TTL 改 300 秒，新增事件失效；目标是减少角色面板重扫。
- 当前个人版：已有事件失效、精确急速/刷新、独立属性预设和布局增强。
- 涉及文件：`BetterCharacterStats.lua`、`helper.lua`。
- 关联功能与处理：人工合并；两文件各 1 处冲突；新方案的失效边界已复现问题，不能只把 TTL 改大。
- 检查结果：本次逐文件字节/指纹及三方关系核对；原包相关 Lua 2 个，其中 2 个通过 Lua 5.1 语法检查。完整 helper 的缓存边界与失效组合已受控复现；不能只增大 TTL。 三份来源完成前再次校验未变；[完整报告](../Research/三版本插件对比-20261010-20261016-20261018.md)及[逐文件结果](../Research/三版本插件对比-20261010-20261016-20261018.json)。
- 游戏验收与未确认：本次为差异核对，未合并部署，未进行游戏内加载、界面或多人验收；文本无冲突不代表运行兼容。原维护状态和历史作者归属不作改变。

现有依据尚不能拆分成日期可靠的逐次记录；下方保留早期汇总，不以本次整理日期代替修改日期。

## 早期历史汇总与维护依据

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

保持角色属性面板布局稳定，并与观察、换天赋功能协调。

### 记录中的修改

- 职业默认方案、自定义属性与独立显示选项；统一面板锚点、开关及角色/观察窗口打开行为。
- 与 StatCompare、S_ItemTip 协调布局和扫描复用，避免反复打开角色面板时重复刷新。
- BrainwasherPro 天赋应用期间使用静默同步，减少整界面重载和动作条重复应用。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [BCS_PropertiesPanel.lua](../../Interface/AddOns/BetterCharacterStats/BCS_PropertiesPanel.lua)
- [BetterCharacterStats.lua](../../Interface/AddOns/BetterCharacterStats/BetterCharacterStats.lua)
- [BetterCharacterStats.xml](../../Interface/AddOns/BetterCharacterStats/BetterCharacterStats.xml)
- [helper.lua](../../Interface/AddOns/BetterCharacterStats/helper.lua)

### 关联插件

[StatCompare](StatCompare.md)、[S_ItemTip](S_ItemTip.md)、[BrainwasherPro](BrainwasherPro.md)。更新时同时检查对应入口与数据口径。

### 已回退方案及更新注意

几轮全局刷新/缓存试验已回退，不能把每个阶段补丁都叠加；各插件配置仍独立。

### 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

### 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/BetterCharacterStats)
- [Interface/AddOns/BetterCharacterStats/.workbuddy/memory/2026-08-16.md](../../Interface/AddOns/BetterCharacterStats/.workbuddy/memory/2026-08-16.md)
- [Interface/AddOns/BetterCharacterStats/.workbuddy/memory/2026-09-12.md](../../Interface/AddOns/BetterCharacterStats/.workbuddy/memory/2026-09-12.md)
- [Interface/AddOns/BetterCharacterStats/.workbuddy/memory/MEMORY.md](../../Interface/AddOns/BetterCharacterStats/.workbuddy/memory/MEMORY.md)
- [PluginHistory/Evidence/addons_tmp/talent-panel-actionbar-change-notes.md](../../PluginHistory/Evidence/addons_tmp/talent-panel-actionbar-change-notes.md)
- [PluginHistory/Evidence/addons_tmp/character-bcs-scan-backup-20261006/README.md](../../PluginHistory/Evidence/addons_tmp/character-bcs-scan-backup-20261006/README.md)
- [PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json](../../PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json)
- [PluginHistory/Evidence/reports/20261006/适配指南草稿.md](../../PluginHistory/Evidence/reports/20261006/%E9%80%82%E9%85%8D%E6%8C%87%E5%8D%97%E8%8D%89%E7%A8%BF.md)
- [PluginHistory/Evidence/legacy-20261006/Docs/Files/BetterCharacterStats](../../PluginHistory/Evidence/legacy-20261006/Docs/Files/BetterCharacterStats)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。

---

[返回插件修改记录](README.md)
