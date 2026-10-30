# pfUI-addonskinner 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/pfUI-addonskinner.md)

## 插件概况

- 分类：经过版本迭代或修改的插件。

- 插件：`pfUI-addonskinner`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

2026-10-30 仅完成 10 月 29 日包差异评估，未部署；建议与检查限制见[本轮记录](#change-pfUI-addonskinner-20261030-01)。

无双皮肤已随 WushuangLoot 回退至 10 月 24 日包更新前的个人使用版；其余已合入皮肤、加载清理与洗脑装置反馈继续保留。本次仅恢复 skins/WushuangLoot.lua，不整目录回退。

## 逐次修改记录

<a id="change-pfUI-addonskinner-20261030-01"></a>

### 2026-10-30｜10 月 29 日插件包更新评估（未部署）

- 记录编号：`pfUI-addonskinner-20261030-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户提供 10 月 29 日插件包，要求区分真正更新及值得覆盖/结合到个人版的内容。
- 修改内容：仅核对并补充说明，未修改或部署现用插件。新增 diminfo 设置窗口皮肤和 StatCompare 设置页皮肤；保留现用 diminfo 本体及洗脑器/Cat/PallyPower/无双个人皮肤。StatCompare 皮肤机械合并无冲突，仍需层级/复用验证。
- 涉及文件：`pfUI-addonskinner.toc`、`skins/StatCompare.lua`、`skins/diminfo.lua`；完整指纹与关系见报告。
- 检查结果：新旧包逐路径/大小/SHA-256 与当前版对照，旧包完整匹配上轮库存；本插件建议为“可合并外观增量”。整批 106 个变更 Lua 中 105 个通过 Lua 5.1 编译且嵌套闭包不超 32 upvalue，ATSW 继承词法项及 GoubayuHeal 原 UI 问题单独记录，TOC/XML 无新增缺失。字体、几何与前置解析受控结果及适用范围见[完整评估](../Research/10月29日插件包更新评估-20261030.md)和[逐文件证据](../Research/10月29日插件包更新评估-20261030.json)。
- 游戏验收与未确认：未进行游戏验收或配置迁移；本次 Lua 5.0 程序无法启动，仅完成上述 Lua 5.1 及闭包检查。模拟不代表真实客户端已验证。
- 关联与保留：个人代码、DLL、皮肤及账号设置保持原样；本次建议未取代任何已部署/回退记录，也未改变维护归属和分类。

<a id="change-pfUI-addonskinner-20261025-03"></a>

### 2026-10-25｜配套恢复无双更新前个人皮肤

- 记录编号：`pfUI-addonskinner-20261025-03`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户要求旧 wsloot DLL 和无双新功能一起退回此前个人版。
- 修改内容：仅将 skins/WushuangLoot.lua 恢复至个人提交 976538accd9a1f235c8f9c0406b283a9da458fce 的原字节；撤回本轮无双动态分类、勾选和新增皮肤逻辑，配合旧版 1.6。
- 涉及文件：`skins/WushuangLoot.lua`；未回退 pfUI-addonskinner.toc 或其他皮肤。
- 关联功能：WushuangLoot 面板、分类与输入框。[回退报告](../Research/wsloot与无双个人版回退-20261025.md)记录完整范围和本地备份。
- 检查结果：皮肤源文件与指定旧提交逐字节一致，Lua 编译通过；配套无双本体严格字体/设置开关模拟通过。没有执行真实 pfUI 皮肤显示或游戏验收。
- 游戏验收与未确认：游戏内皮肤显示、交互与启动体验待用户实测。
- 替代关系：仅撤回本日 02 记录中的无双皮肤部分，保留其他部分及历史依据。


<a id="change-pfUI-addonskinner-20261025-02"></a>

### 2026-10-25｜合入 10 月 24 日包并保留个人功能（已部署）

- 记录编号：`pfUI-addonskinner-20261025-02`
- 记录类型：更新合并
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户要求结合明确更新、保留核心个人功能，不确定项等待确认；另明确同意治疗预读改按键与超级宏改角色独立，属性统计继续暂缓。
- 修改内容：合入无双动态复选框、勾选/字体/输入框皮肤及缺失加载入口清理；保留个人附加皮肤与洗脑装置反馈。
- 涉及文件：`pfUI-addonskinner.toc`、`skins/WushuangLoot.lua`。
- 关联功能与保留：参见[整批实施记录](../Research/10月24日包合并实施-20261025.md)，所有未变及个人独有路径保留；不夹带 DLL 或账号设置。
- 检查结果：逐文件原始字节、语法/闭包与加载引用检查通过。 整批 176 个变更 Lua 与 32 upvalue 检查通过，TOC/XML 无新增缺失；现用目录与审查候选逐字节一致。[部署清单](../Research/10月24日包合并实施-20261025.json)保存文件指纹和限制。
- 游戏验收与未确认：尚未真实游戏验收；预读/宏迁移/服务器事件与各职业操作仍待实机确认，受控模拟不等同游戏验收。
- 替代关系：本条记录跟随本日差异核对，旧记录保持原有核对时状态；本次仍保留的未确认项目见整批报告。

<a id="change-pfUI-addonskinner-20261025-01"></a>

### 2026-10-25｜10 月 24 日原包三版本差异核对（未部署）

- 记录编号：`pfUI-addonskinner-20261025-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户提供 10 月 24 日插件包，要求与 10 月 16 日旧原包及当前个人版对比。
- 修改内容：仅核对并记录，未更新插件。新包变化：无双皮肤适配新增剥皮、勾选状态、字体、输入框与可选滑块；移除 BookStore/GearMenu/TrinketMenu/DoTimer/SpecialTalentUI/Locale zh 等加载入口。
- 当前个人版：保留个人皮肤扩展及 BrainwasherPro 按钮反馈；变更文件可机械合并。
- 涉及文件：`pfUI-addonskinner.toc`、`skins/WushuangLoot.lua`。
- 关联功能与处理：与 WushuangLoot 配套审查；保留个人额外皮肤，不能整目录替换。
- 检查结果：逐文件字节及 SHA-256、三方关系与机械合并冲突核对；整批新包变更 Lua 186/187 可编译，GoubayuHeal 原 UI 超过 200 局部变量；可编译文件嵌套函数未超 32 upvalue。相关 TOC/XML 没有新增缺失引用。另运行 BCS 缓存、治疗 UI 编译与 ShaguDPS 兜底受控检查；具体结果与限制见[整批对照报告](../Research/三版本插件对比-20261016-20261024-20261025.md)和[逐文件清单](../Research/三版本插件对比-20261016-20261024-20261025.json)。
- 游戏验收与未确认：本次未部署、未真实游戏或多人验收；既有个人改动归属及证据状态不变，不将原包功能记作本项目新增。

<a id="change-pfUI-addonskinner-20261014-01"></a>

### 2026-10-14｜洗脑装置按钮悬停和按压反馈

- 记录编号：`pfUI-addonskinner-20261014-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[7979897](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/79798974f795a95c9a5feab2ccf846d409198d01)


- 目的：原皮肤清除了按钮原生背景，但插件悬停逻辑继续修改已移除的背景，导致鼠标移入时无法辨认按钮。
- 主要文件：`Interface/AddOns/pfUI-addonskinner/skins/BrainwasherPro.lua`；关联 `BrainwasherPro/BrainwasherPro.lua` 的层级和统一深色布局。
- 修改：使用 pfUI 的 SetHighlight 更新实际子背景边框，并用1.12 Button原生高亮/按下纹理提供金色反馈，关闭按钮使用红色反馈。保留点击回调；重复美化识别关闭按钮、图标和模板按钮，避免清掉编辑器图标或累积文字。关闭符号先通过 GameFontNormalSmall 模板初始化字体，指定字体文件失败时仍可显示。
- 验证：`Tools/tests/test_brainwasher_ui.py` 运行实际插件创建逻辑、皮肤、pfUI SetHighlight / SkinButton / StripTextures，并使用严格 FontString 契约：未初始化字体的 SetText必须失败，模拟 FRIZQT__.TTF 字体失败；两种旧风格值各209项检查通过。未新增逐帧回调或外部素材依赖。皮肤文件保留原 UTF-8 无BOM/LF。
- 未确认事项：鼠标实际视觉效果、点击命中和窗口重叠需在游戏内重载后验收；模拟通过不代表游戏已确认。

## 早期历史汇总与维护依据

<details>
<summary>展开早期原始说明与证据（不是当前问题或优化清单）</summary>

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

让定制功能及动态窗口沿用 pfUI 外观。

### 记录中的修改

- Cat、PallyPower、StatCompare 的新增控件、图标及布局适配。
- RaidCheck 懒创建/复用控件皮肤、祝福面板、坦克高级窗口和任务分配窗口支持。
- TrainerSkills 的折叠图标、设置窗口与拖动，Tmog 的动态选中边框、页签/预览皮肤处理。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [skins/Cat.lua](../../Interface/AddOns/pfUI-addonskinner/skins/Cat.lua)
- [skins/PallyPower.lua](../../Interface/AddOns/pfUI-addonskinner/skins/PallyPower.lua)
- [skins/RaidCheck.lua](../../Interface/AddOns/pfUI-addonskinner/skins/RaidCheck.lua)
- [skins/StatCompare.lua](../../Interface/AddOns/pfUI-addonskinner/skins/StatCompare.lua)
- [skins/Tmog.lua](../../Interface/AddOns/pfUI-addonskinner/skins/Tmog.lua)
- [skins/TrainerSkills.lua](../../Interface/AddOns/pfUI-addonskinner/skins/TrainerSkills.lua)

### 关联插件

[Cat](Cat.md)、[PallyPower](PallyPower.md)、[StatCompare](StatCompare.md)、[RaidCheck](RaidCheck.md)、[TrainerSkills](TrainerSkills.md)、[Tmog](Tmog.md)。更新时同时检查对应入口与数据口径。

### 已回退方案及更新注意

TrainerSkills/Tmog 的这些记录属于皮肤层，不直接证明其主插件逻辑被本项目修改；动态控件需等创建后再套皮肤。

### 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

### 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/pfUI-addonskinner)
- [Interface/AddOns/pfUI-addonskinner/.workbuddy/memory/2026-09-27.md](../../Interface/AddOns/pfUI-addonskinner/.workbuddy/memory/2026-09-27.md)
- [Interface/AddOns/pfUI-addonskinner/.workbuddy/memory/2026-09-28.md](../../Interface/AddOns/pfUI-addonskinner/.workbuddy/memory/2026-09-28.md)
- [Interface/AddOns/pfUI-addonskinner/.workbuddy/memory/2026-09-29.md](../../Interface/AddOns/pfUI-addonskinner/.workbuddy/memory/2026-09-29.md)
- [Interface/AddOns/pfUI-addonskinner/.workbuddy/memory/2026-09-30.md](../../Interface/AddOns/pfUI-addonskinner/.workbuddy/memory/2026-09-30.md)
- [Interface/AddOns/pfUI-addonskinner/.workbuddy/memory/2026-10-02.md](../../Interface/AddOns/pfUI-addonskinner/.workbuddy/memory/2026-10-02.md)
- [PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json](../../PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json)
- [PluginHistory/Evidence/reports/20261006/适配指南草稿.md](../../PluginHistory/Evidence/reports/20261006/%E9%80%82%E9%85%8D%E6%8C%87%E5%8D%97%E8%8D%89%E7%A8%BF.md)
- [PluginHistory/Evidence/legacy-20261006/Docs/Files/pfUI-addonskinner](../../PluginHistory/Evidence/legacy-20261006/Docs/Files/pfUI-addonskinner)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。


---

[返回插件修改记录](README.md)

</details>
