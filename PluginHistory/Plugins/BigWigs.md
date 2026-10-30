# BigWigs 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/BigWigs.md)

## 插件概况

- 分类：经过版本迭代或修改的插件。

- 插件：`BigWigs`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

2026-10-30 合入竖行条方向/残条/队列/拥挤、减速等级去重、计时条保护和明确首领增量；竖行文字补有效字体模板。炼金术士只取“你”归一与宠物事件，旧通信保持，木喉小怪同步文件保持原字节。 [本轮记录](#change-BigWigs-20261030-02)。

2026-10-25 已合并部署：合入首领触发/同步、本地化修复、九类语音和相关资源；BugFamily 实际文件不存在，删除旧缺失加载入口；其他个人使用文件保留。


2026-10-18 已合并部署：合入法师缺少旧施法库时的保护；保留已有首领提醒、竖条、集合 BUFF 联动与全部其他文件。 真实游戏验收待补充。

适配乌龟服首领、中文日志以及竖行计时条。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

<a id="change-BigWigs-20261030-02"></a>

### 2026-10-30｜保留个人核心合入 10 月 29 日明确增量（已部署）

- 记录编号：`BigWigs-20261030-02`
- 记录类型：更新合并
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户授权合并明确值得更新的部分，要求保留个人核心与优化方向，不确定项后续逐项确认。
- 修改内容：合入竖行条方向/残条/队列/拥挤、减速等级去重、计时条保护和明确首领增量；竖行文字补有效字体模板。炼金术士只取“你”归一与宠物事件，旧通信保持，木喉小怪同步文件保持原字节。
- 涉及文件：`Core.lua`、`Plugins/Bars.lua`、`Plugins/VerticalBars.lua`、`Raids/BWL/Alchemists.lua`、`Raids/BWL/Broodlord.lua`、`Raids/BWL/Ebonroc.lua`、`Raids/BWL/Ezzel.lua`等 12 项文件；完整变化见[实施记录](../Research/10月29日包保留个人核心合并实施-20261030.md)和[指纹清单](../Research/10月29日包保留个人核心合并实施-20261030.json)。
- 检查结果：整批 72 个变更 Lua 真实 Lua 5.0.3 编译通过，TOC/XML 无新增缺失，20 组新行为回归通过；部署后洗脑器 209×2、StatCompare 层级 36 项、S_ItemTip 85 项及共享属性/旧无双完整 UI 回归通过。严格字体模拟覆盖配置字体失败、隐藏和复用；完整源库存等于更新前加 74 项明确变化。
- 关联功能与保留：独立复核已修正 BigWigs 固定 sync 节流吞第二目标、吸收显示新键迁移两项问题。原通信/统计口径及所有未明确变更的个人文件保持；DLL 与账号角色设置不改。
- 游戏验收与未确认：尚未游戏验收；需完整退出重进加载新增卡片/皮肤，事件、显示、实际性能和配置迁移待游戏核对。 后续单独确认清单见整批实施记录。
- 替代关系：本条说明本轮实际部署或明确暂缓结果；前一条仅评估记录和更早部署/回退证据全部保留。前置评估中的同步“分隔符修复”定性及 Lua 5.1 词法边界由本轮实际验证补充纠正。

<a id="change-BigWigs-20261030-01"></a>

### 2026-10-30｜10 月 29 日插件包更新评估（未部署）

- 记录编号：`BigWigs-20261030-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户提供 10 月 29 日插件包，要求区分真正更新及值得覆盖/结合到个人版的内容。
- 修改内容：仅核对并补充说明，未修改或部署现用插件。竖行条名称方向、短残条/拥挤/淘汰顺序、计时条保护及黑翼/木喉触发同步有更新；14 项候选当前等于旧包。新计时与日志待游戏核对。
- 涉及文件：`BigWigs.toc`、`Core.lua`、`Plugins/Bars.lua`、`Plugins/VerticalBars.lua`、`Raids/BWL/Alchemists.lua`、`Raids/BWL/Broodlord.lua`、`Raids/BWL/Ebonroc.lua`、`Raids/BWL/Ezzel.lua`等 14 项候选文件；完整指纹与关系见报告。
- 检查结果：新旧包逐路径/大小/SHA-256 与当前版对照，旧包完整匹配上轮库存；本插件建议为“优先迁入明确增量”。整批 106 个变更 Lua 中 105 个通过 Lua 5.1 编译且嵌套闭包不超 32 upvalue，ATSW 继承词法项及 GoubayuHeal 原 UI 问题单独记录，TOC/XML 无新增缺失。字体、几何与前置解析受控结果及适用范围见[完整评估](../Research/10月29日插件包更新评估-20261030.md)和[逐文件证据](../Research/10月29日插件包更新评估-20261030.json)。
- 游戏验收与未确认：未进行游戏验收或配置迁移；本次 Lua 5.0 程序无法启动，仅完成上述 Lua 5.1 及闭包检查。模拟不代表真实客户端已验证。
- 关联与保留：个人代码、DLL、皮肤及账号设置保持原样；本次建议未取代任何已部署/回退记录，也未改变维护归属和分类。

<a id="change-BigWigs-20261025-02"></a>

### 2026-10-25｜合入 10 月 24 日包并保留个人功能（已部署）

- 记录编号：`BigWigs-20261025-02`
- 记录类型：更新合并
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户要求结合明确更新、保留核心个人功能，不确定项等待确认；另明确同意治疗预读改按键与超级宏改角色独立，属性统计继续暂缓。
- 修改内容：合入首领触发/同步、本地化修复、九类语音和相关资源；BugFamily 实际文件不存在，删除旧缺失加载入口；其他个人使用文件保留。
- 涉及文件：`BigWigs.toc`、`Core.lua`、`Plugins/Proximity.lua`、`Plugins/Sound.lua`、`Raids/AQ40/Sentinels.lua`、`Raids/Karazhan/Anomalus.lua`、`Raids/MC/BaronGeddon.lua`、`Raids/MC/Thaurissan.lua`、`Raids/Naxxramas/Loatheb.lua`、`Raids/Naxxramas/Razuvious.lua` 等，完整路径见部署清单。
- 关联功能与保留：参见[整批实施记录](../Research/10月24日包合并实施-20261025.md)，所有未变及个人独有路径保留；不夹带 DLL 或账号设置。
- 检查结果：逐文件原始字节、语法/闭包与加载引用检查通过。 整批 176 个变更 Lua 与 32 upvalue 检查通过，TOC/XML 无新增缺失；现用目录与审查候选逐字节一致。[部署清单](../Research/10月24日包合并实施-20261025.json)保存文件指纹和限制。
- 游戏验收与未确认：尚未真实游戏验收；预读/宏迁移/服务器事件与各职业操作仍待实机确认，受控模拟不等同游戏验收。
- 替代关系：本条记录跟随本日差异核对，旧记录保持原有核对时状态；本次仍保留的未确认项目见整批报告。

<a id="change-BigWigs-20261025-01"></a>

### 2026-10-25｜10 月 24 日原包三版本差异核对（未部署）

- 记录编号：`BigWigs-20261025-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户提供 10 月 24 日插件包，要求与 10 月 16 日旧原包及当前个人版对比。
- 修改内容：仅核对并记录，未更新插件。新包变化：木喉等首领补充分摊、转火、换阶段、恐惧等九类语音及独立开关；修正中文区域/绿龙模块、炸弹“你”误报、跨语言标记同步、部分日志通道与扫描缓存；TOC 加载 Selenaxx、移除 BugFamily 入口。
- 当前个人版：本批变更的运行文件均与 16 日原包相同；其他个人使用文件保留。
- 涉及文件：`BigWigs.toc`、`Core.lua`、`Plugins/Proximity.lua`、`Plugins/Sound.lua`、`Raids/AQ40/Sentinels.lua`、`Raids/Karazhan/Anomalus.lua`、`Raids/MC/BaronGeddon.lua`、`Raids/MC/Thaurissan.lua`、`Raids/Naxxramas/Loatheb.lua`、`Raids/Naxxramas/Razuvious.lua`、`Raids/Other/Emeriss.lua`、`Raids/Other/Lethon.lua` 等 34 个代码/资源/加载文件。
- 关联功能与处理：更新包含 9 个新增声音资源；部分木喉触发文本仍标注待实测，移除 BugFamily 入口需确认意图。
- 检查结果：逐文件字节及 SHA-256、三方关系与机械合并冲突核对；整批新包变更 Lua 186/187 可编译，GoubayuHeal 原 UI 超过 200 局部变量；可编译文件嵌套函数未超 32 upvalue。相关 TOC/XML 没有新增缺失引用。另运行 BCS 缓存、治疗 UI 编译与 ShaguDPS 兜底受控检查；具体结果与限制见[整批对照报告](../Research/三版本插件对比-20261016-20261024-20261025.md)和[逐文件清单](../Research/三版本插件对比-20261016-20261024-20261025.json)。
- 游戏验收与未确认：本次未部署、未真实游戏或多人验收；既有个人改动归属及证据状态不变，不将原包功能记作本项目新增。

<a id="change-BigWigs-20261018-02"></a>

### 2026-10-18｜合入 10 月 16 日包并保留个人功能（已部署）

- 记录编号：`BigWigs-20261018-02`
- 记录类型：更新合并
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户授权除三个指定插件外更新新包，并要求个人功能完整保留、重复功能优先个人实现。
- 修改内容：合入法师缺少旧施法库时的保护；保留已有首领提醒、竖条、集合 BUFF 联动与全部其他文件。
- 涉及文件：`Plugins/CommonAuras.lua`。
- 关联功能：详见[整批实施记录](../Research/10月16日包合并实施-20261018.md)；关联个人扩展、皮肤和其他未更新文件保留。
- 检查结果：Lua 语法/闭包与既有聊天条/同步回归通过。 现用目录与审查后的候选逐字节一致；[逐文件清单](../Research/10月16日包合并实施-20261018.json)保存校验和、保留范围与限制。
- 游戏验收与未确认：本次尚未游戏实测，语法与受控测试不等同于真实客户端验收；更新前可用标签 `before/package-20261016-20261018` 回退。
- 替代关系：本条在前一条差异核对之后实施，只更新当前摘要，不改写当时“未部署”的核对记录。此前个人修改作者与最早日期不作追认。

<a id="change-BigWigs-20261018-01"></a>

### 2026-10-18｜10 月 16 日包与当前个人版差异核对（未部署）

- 记录编号：`BigWigs-20261018-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户提供 10 月 16 日新包，要求沿用旧包/当前个人版/新包三方逻辑核对。
- 修改内容：只检查并记录，没有更新插件。原包变化：仅 CommonAuras 增加法师缺旧库时的保护，不中断模块启用。
- 当前个人版：功能文件同 10/10；此前 !Libs 已补回旧库。
- 涉及文件：`Plugins/CommonAuras.lua`。
- 关联功能与处理：可提取单文件；属于缺库兜底，不是新的首领提醒包。
- 检查结果：本次逐文件字节/指纹及三方关系核对；原包相关 Lua 1 个，其中 1 个通过 Lua 5.1 语法检查。 三份来源完成前再次校验未变；[完整报告](../Research/三版本插件对比-20261010-20261016-20261018.md)及[逐文件结果](../Research/三版本插件对比-20261010-20261016-20261018.json)。
- 游戏验收与未确认：本次为差异核对，未合并部署，未进行游戏内加载、界面或多人验收；文本无冲突不代表运行兼容。原维护状态和历史作者归属不作改变。

<a id="change-BigWigs-20261012-01"></a>

### 2026-10-12｜迁入 10 月 10 日包（已部署）

- 记录编号：`BigWigs-20261012-01`
- 记录类型：更新合并
- 游戏验收：待游戏验收
- 对应提交：[f5eee32](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/f5eee321230abae57ce1efd914c0e94fc9be17ed)


- 目的与处理：更新集合刷 BUFF 语音/命令、竖条点击通报及首领提醒，保留已有阶段备份。
- 主要文件：`Plugins/Pulltimer.lua`、`Plugins/Sound.lua`、`Plugins/VerticalBars.lua`、`Raids/AQ20/Guardians.lua`、`Raids/AQ20/Kurinaxx.lua`、`Raids/BWL/Broodlord.lua`、`Raids/BWL/Vaelastrasz.lua`、`Raids/Karazhan/ClawlordHowlfang.lua`、`Raids/Karazhan/KaraTrash.lua`、`Raids/Karazhan/Mephistroth.lua`、`Raids/MC/AncientCoreHound.lua`、`Raids/MC/Thaurissan.lua`、`Raids/Naxxramas/Anubrekhan.lua`、`Raids/Naxxramas/Gluth.lua`、`Raids/Naxxramas/Horsemen.lua`、`Raids/Naxxramas/Razuvious.lua`、`Raids/Naxxramas/SpiderTrash.lua`、`Raids/TMH/Partath.lua`、`Raids/TMH/Rotgrowl.lua`、`Raids/TMH/TimbermawTrash.lua`、`Raids/TMH/Ursol.lua`。
- 依据：[实施记录](../Research/插件更新实施-20261012.md)及[逐文件校验](../Research/插件更新实施-20261012.json)；更新前标签 `before/package-update-20261012`。
- 验证：本次 74 个 Lua 语法、7 个 XML 与 TOC/XML 文件引用核对通过；新增库初始化、聊天条/BigWigs、字体前置条件和金额修复见关联检查，HealComm/NotGrid 106 组行为通过。现用文件与已审查候选逐字节一致。
- 未确认：尚未做真实 1.12 游戏验收；具体多人通信、首领战斗、邮件操作或界面行为按实施记录列出的范围继续验证。

<a id="change-BigWigs-20261011-01"></a>

### 2026-10-11｜两包更新与个人版三方核对（未部署）

- 记录编号：`BigWigs-20261011-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：[0b5c895](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/0b5c8959ca36a914bb144edc25225506adddbf67)


- 目的与证据：按用户补充的 10 月 5 日包，对照 10 月 10 日包和当前个人版；详见[三方核对报告](../Research/三方插件更新核对-20261005-20261010-20261011.md)。不据文件相等推断作者或最早来源。
- 两包变化：21 个 Lua 更新：集合刷 BUFF、竖行条通报、自身中文日志锚定、帕萨斯/腐嚎/木喉小怪/乌索尔提醒。
- 个人版处理：21 个待更新文件当前均等于旧包；未发现额外独立个人功能文件差异，既有定制内容已出现在旧包。可按明确文件迁移，战斗与同步待验收。
- 验证与未确认：本次只核对原始字节/差异及文本试算；新包本次改变或新增的 75 个 Lua 全部通过 Lua 5.1 语法检查。未修改本插件功能，未部署候选，真实 1.12 加载、界面和多人行为待后续验收。


## 早期历史汇总与维护依据

<details>
<summary>展开早期原始说明与证据（不是当前问题或优化清单）</summary>

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

适配乌龟服首领、中文日志以及竖行计时条。

### 记录中的修改

- 新增或调整木喉要塞提里奥克等首领模块；修正完整首领名、中文技能名、%s/%t 目标 token 和标点导致的标记失败。
- 加入 VerticalBars 竖行条，处理等待区排序；屏蔽原条时保留护盾、狂暴、减益等必须显示的特殊计时条。
- 世界首领冷却增加双状态检测并修正重复击杀误报；Threat.Enable 和版本查询增加空值兼容。
- 修正奈法利安猎人/盗贼等中文职业点名、首领菜单翻译和拉格纳罗斯坦克提醒刷屏。
- 对自身日志使用明确身份归一与锚定，避免名字含“你”时全团误报；涉及卡拉赞、木喉要塞和其他团本。
- CommonAuras 增加奴役恶魔与大恶魔叛变计时，修正换宠清理；Comm 支持小队同步。
- 佩罗萨恩净化火焰、魔网观察者光束、阿诺玛鲁斯过载等增加或修正喊话/声音提醒。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [Plugins/Comm.lua](../../Interface/AddOns/BigWigs/Plugins/Comm.lua)
- [Plugins/CommonAuras.lua](../../Interface/AddOns/BigWigs/Plugins/CommonAuras.lua)
- [Plugins/Threat.lua](../../Interface/AddOns/BigWigs/Plugins/Threat.lua)
- [Plugins/Version.lua](../../Interface/AddOns/BigWigs/Plugins/Version.lua)
- [Plugins/VerticalBars.lua](../../Interface/AddOns/BigWigs/Plugins/VerticalBars.lua)
- [Plugins/WorldBossCooldown.lua](../../Interface/AddOns/BigWigs/Plugins/WorldBossCooldown.lua)
- [Raids/BWL/Nefarian.lua](../../Interface/AddOns/BigWigs/Raids/BWL/Nefarian.lua)
- [Raids/Karazhan/Anomalus.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/Anomalus.lua)
- [Raids/Karazhan/BroodQueenAraxxna.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/BroodQueenAraxxna.lua)
- [Raids/Karazhan/ChessFight.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/ChessFight.lua)
- [Raids/Karazhan/ClawlordHowlfang.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/ClawlordHowlfang.lua)
- [Raids/Karazhan/DarkRiderChampion.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/DarkRiderChampion.lua)
- [Raids/Karazhan/EchoOfMedivh.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/EchoOfMedivh.lua)
- [Raids/Karazhan/Grizikil.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/Grizikil.lua)
- [Raids/Karazhan/Incantagos.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/Incantagos.lua)
- [Raids/Karazhan/KaraTrash.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/KaraTrash.lua)
- [Raids/Karazhan/KeeperGnarlmoon.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/KeeperGnarlmoon.lua)
- [Raids/Karazhan/Kruul.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/Kruul.lua)
- [Raids/Karazhan/LordBlackwaldII.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/LordBlackwaldII.lua)
- [Raids/Karazhan/Mephistroth.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/Mephistroth.lua)
- [Raids/Karazhan/Moroes.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/Moroes.lua)
- [Raids/Karazhan/PhantomServant.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/PhantomServant.lua)
- [Raids/Karazhan/Rupturan.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/Rupturan.lua)
- [Raids/Karazhan/SanvTasdal.lua](../../Interface/AddOns/BigWigs/Raids/Karazhan/SanvTasdal.lua)
- [Raids/MC/Ragnaros.lua](../../Interface/AddOns/BigWigs/Raids/MC/Ragnaros.lua)
- [Raids/TMH/Karrsh.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Karrsh.lua)
- [Raids/TMH/Kronn.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Kronn.lua)
- [Raids/TMH/Loktanag.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Loktanag.lua)
- [Raids/TMH/Ormanos.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Ormanos.lua)
- [Raids/TMH/Partath.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Partath.lua)
- [Raids/TMH/Perotharn.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Perotharn.lua)
- [Raids/TMH/Rotgrowl.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Rotgrowl.lua)
- [Raids/TMH/Selenaxx.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Selenaxx.lua)
- [Raids/TMH/TimbermawTrash.lua](../../Interface/AddOns/BigWigs/Raids/TMH/TimbermawTrash.lua)
- [Raids/TMH/Trioch.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Trioch.lua)
- [Raids/TMH/Ursol.lua](../../Interface/AddOns/BigWigs/Raids/TMH/Ursol.lua)

### 已回退方案及更新注意

只迁移有实际用途的最终触发规则；不要重用旧的时间戳换宠旁路，也不要把无法解析的字面 token 当玩家名。日期笔记比长期备忘更能反映最终调整。

### 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

### 待补充

首领模块数量较多，各场战斗的最终实测情况请按需补充。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/BigWigs)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-08-21.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-08-21.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-08-25.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-08-25.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-08-28.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-08-28.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-01.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-01.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-02.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-02.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-04.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-04.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-08.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-08.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-09.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-09.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-13.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-13.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-15.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-15.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-17.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-17.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-18.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-18.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-19.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-19.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-23.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-23.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-24.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-24.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-28.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-28.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-29.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-09-29.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-10-02.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-10-02.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/2026-10-03.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/2026-10-03.md)
- [Interface/AddOns/BigWigs/.workbuddy/memory/MEMORY.md](../../Interface/AddOns/BigWigs/.workbuddy/memory/MEMORY.md)
- [Interface/AddOns/BigWigs/Raids/BWL/Ezzel.lua.20260918125911.bak](../../Interface/AddOns/BigWigs/Raids/BWL/Ezzel.lua.20260918125911.bak)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。


---

[返回插件修改记录](README.md)

</details>
