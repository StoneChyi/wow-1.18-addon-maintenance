# StatCompare 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/StatCompare.md)

## 插件概况

- 插件：`StatCompare`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

2026-10-25 核对：10 月 24 日原包有功能更新；现用实现保持不变，详情见本页最新差异记录。


让属性比较面板与角色/观察窗口协调。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

<a id="change-StatCompare-20261025-01"></a>

### 2026-10-25｜10 月 24 日原包三版本差异核对（未部署）

- 记录编号：`StatCompare-20261025-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户提供 10 月 24 日插件包，要求与 10 月 16 日旧原包及当前个人版对比。
- 修改内容：仅核对并记录，未更新插件。新包变化：可复用 BCS GearStat 快照，出错退回内置扫描；法术命中引用 BCS 基础值加最高分系；头像增加递增重试/模型重建及节流；移除 XML 两项缺失脚本入口。
- 当前个人版：有个人窗口布局/层级、角色观察协调与扫描控制，尚未采用 16 日缓存方案。
- 涉及文件：`StatCompare.lua`、`StatCompare.xml`、`StatCompareChar/CharStats.lua`、`StatScanner.lua`。
- 关联功能与处理：依赖 BCS 的新采集层；3 文件有个人变化、2 文件冲突。最高分系法命不是每个系都享有，展示需区分；头像逻辑需游戏验收。
- 检查结果：逐文件字节及 SHA-256、三方关系与机械合并冲突核对；整批新包变更 Lua 186/187 可编译，GoubayuHeal 原 UI 超过 200 局部变量；可编译文件嵌套函数未超 32 upvalue。相关 TOC/XML 没有新增缺失引用。另运行 BCS 缓存、治疗 UI 编译与 ShaguDPS 兜底受控检查；具体结果与限制见[整批对照报告](../Research/三版本插件对比-20261016-20261024-20261025.md)和[逐文件清单](../Research/三版本插件对比-20261016-20261024-20261025.json)。
- 游戏验收与未确认：本次未部署、未真实游戏或多人验收；既有个人改动归属及证据状态不变，不将原包功能记作本项目新增。

<a id="change-StatCompare-20261018-01"></a>

### 2026-10-18｜10 月 16 日包与当前个人版差异核对（未部署）

- 记录编号：`StatCompare-20261018-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户提供 10 月 16 日新包，要求沿用旧包/当前个人版/新包三方逻辑核对。
- 修改内容：只检查并记录，没有更新插件。原包变化：装备和光环签名缓存；复用头像重试 Frame；自身属性框跟随 S_ItemTip。
- 当前个人版：自动/自由布局、按内容宽度、缓存/刷新、分面板头像处理与观察层级。
- 涉及文件：`StatCompare.lua`、`StatCompareBuff/BuffScanner.lua`、`StatScanner.lua`。
- 关联功能与处理：人工合并；主文件 4 处冲突；扫描文件可单独审查，避免覆盖自由布局与当前头像处理。
- 检查结果：本次逐文件字节/指纹及三方关系核对；原包相关 Lua 3 个，其中 3 个通过 Lua 5.1 语法检查。 三份来源完成前再次校验未变；[完整报告](../Research/三版本插件对比-20261010-20261016-20261018.md)及[逐文件结果](../Research/三版本插件对比-20261010-20261016-20261018.json)。
- 游戏验收与未确认：本次为差异核对，未合并部署，未进行游戏内加载、界面或多人验收；文本无冲突不代表运行兼容。原维护状态和历史作者归属不作改变。

<a id="change-StatCompare-20261013-01"></a>

### 2026-10-13｜修复观察目标属性面板被头像框架遮挡

- 记录编号：`StatCompare-20261013-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[1524afa](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/1524afa558990b2dc403a07bf2ef4fc9be187862)


- 目的：观察其他角色时，目标属性面板下部被 pfUI 自身头像、生命/法力条等 MEDIUM 层级控件覆盖；自身属性面板此前已有 HIGH 策略，目标属性面板遗漏。
- 主要文件：`Interface/AddOns/StatCompare/StatCompare.lua`；回归检查：`Tools/tests/test_statcompare_panel_strata.py`。
- 修改：`SCApplyPanelDisplayPolicy` 和自动布局的 `Attach` 均使用 `SCIsManagedPanel`，让目标与自身属性面板统一保持 HIGH。装备列表仍沿用根窗口层级；保留原有自动/自由布局、锚点、透明度、字体、属性口径及显示流程，不新增 Raise 或重复 Show。
- 关联功能：StatCompare 目标/自身属性比较，S_ItemTip 观察装备列表，以及 pfUI 单位框架；未修改这些关联插件文件。沿用现有 1.12 Frame 的 `GetFrameStrata` / `SetFrameStrata` 签名，没有新增客户端接口或 FontString。
- 验证：新增层级测试在修改前复现目标面板仍为 LOW 的断言失败，修改后通过 36 项检查，覆盖自动布局、自由拖动、重新打开、反复布局不重复写入，以及装备/单位框架不受影响。`addons_tmp/test_inspect_layout.py` 的 35 项布局/背景与 14 项 S_ItemTip 生命周期检查通过；`addons_tmp/test_character_open_fix.py` 的开窗、布局反馈及计时器回归通过；Lua 5.1 语法与 XML 解析通过。源文件 UTF-8 BOM 和原有混合换行按字节保留。
- 检查限制：旧 `addons_tmp/test_enchant_before_show.py` 因模拟 BCS 缺少 `GetDataGeneration` 中断；用 HEAD 中修改前的 StatCompare 文件运行也出现同样失败，未将其记为通过，也未在本次层级修复中修改附魔逻辑。
- 未确认事项：以上为模拟检查，尚未在实际 1.12 游戏中验收；需重载后观察其他角色，确认目标属性面板下部不再被头像框架覆盖。

## 早期历史汇总与维护依据

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

让属性比较面板与角色/观察窗口协调。

### 记录中的修改

- 统一锚点和打开/关闭行为，保留独立配置、属性预设与比较功能。
- 布局功能归并到主文件，PanelLayout.lua 为兼容占位。
- 与 BetterCharacterStats、S_ItemTip 共享协调点，减少重复扫描和界面冲突。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [PanelLayout.lua](../../Interface/AddOns/StatCompare/PanelLayout.lua)
- [SCOptions.lua](../../Interface/AddOns/StatCompare/SCOptions.lua)
- [StatCompare.lua](../../Interface/AddOns/StatCompare/StatCompare.lua)
- [StatCompare.toc](../../Interface/AddOns/StatCompare/StatCompare.toc)
- [StatCompare.xml](../../Interface/AddOns/StatCompare/StatCompare.xml)
- [StatScanner.lua](../../Interface/AddOns/StatCompare/StatScanner.lua)

### 关联插件

[BetterCharacterStats](BetterCharacterStats.md)、[S_ItemTip](S_ItemTip.md)、[pfUI-addonskinner](pfUI-addonskinner.md)。更新时同时检查对应入口与数据口径。

### 已回退方案及更新注意

StatScanner.lua 的扫描试改最终恢复到阶段快照，不能把撤销的跨插件全局刷新重新加入；PanelLayout 不应重复加载完整旧逻辑。

### 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

### 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/StatCompare)
- [PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json](../../PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json)
- [PluginHistory/Evidence/reports/20261006/适配指南草稿.md](../../PluginHistory/Evidence/reports/20261006/%E9%80%82%E9%85%8D%E6%8C%87%E5%8D%97%E8%8D%89%E7%A8%BF.md)
- [PluginHistory/Evidence/legacy-20261006/Docs/Files/StatCompare](../../PluginHistory/Evidence/legacy-20261006/Docs/Files/StatCompare)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。


---

[返回插件修改记录](README.md)
