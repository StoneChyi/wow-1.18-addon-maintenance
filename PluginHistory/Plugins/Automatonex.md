# Automatonex 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/Automatonex.md)

## 插件概况

- 分类：经过版本迭代或修改的插件。

- 插件：`Automatonex`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

2026-10-30 仅完成 10 月 29 日包差异评估，未部署；建议与检查限制见[本轮记录](#change-Automatonex-20261030-01)。

2026-10-25 已合并部署：合入多件掉落队列和团队拾取确认开关；保留 31 个四选项、“不选择=-1”及随机坐骑增强；补充停用取消队列和过期掷骰恢复。


完善模块配置、物品监控及与其他界面的协作。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

<a id="change-Automatonex-20261030-01"></a>

### 2026-10-30｜10 月 29 日插件包更新评估（未部署）

- 记录编号：`Automatonex-20261030-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户提供 10 月 29 日插件包，要求区分真正更新及值得覆盖/结合到个人版的内容。
- 修改内容：仅核对并补充说明，未修改或部署现用插件。优先 AutoDB 别名解析、开锁、标记 elapsed 保护及 CleanChat 清空确认；角色喊话配置迁移与世界 BUFF 校准分开验收。保留个人 AutoNeed、RandomMount；新 WIM 静默接口没有对应 WIM 消费代码。
- 涉及文件：`Automatonex.toc`、`Modules/AutoDB.lua`、`Modules/AutoShout.lua`、`Modules/TSTargetMark.lua`、`Modules/Unlock.lua`、`Modules/WorldBuffs.lua`、`Plubics/CleanChat/CleanChat.lua`；完整指纹与关系见报告。
- 检查结果：新旧包逐路径/大小/SHA-256 与当前版对照，旧包完整匹配上轮库存；本插件建议为“优先小范围修复”。整批 106 个变更 Lua 中 105 个通过 Lua 5.1 编译且嵌套闭包不超 32 upvalue，ATSW 继承词法项及 GoubayuHeal 原 UI 问题单独记录，TOC/XML 无新增缺失。字体、几何与前置解析受控结果及适用范围见[完整评估](../Research/10月29日插件包更新评估-20261030.md)和[逐文件证据](../Research/10月29日插件包更新评估-20261030.json)。
- 游戏验收与未确认：未进行游戏验收或配置迁移；本次 Lua 5.0 程序无法启动，仅完成上述 Lua 5.1 及闭包检查。模拟不代表真实客户端已验证。
- 关联与保留：个人代码、DLL、皮肤及账号设置保持原样；本次建议未取代任何已部署/回退记录，也未改变维护归属和分类。

<a id="change-Automatonex-20261025-02"></a>

### 2026-10-25｜合入 10 月 24 日包并保留个人功能（已部署）

- 记录编号：`Automatonex-20261025-02`
- 记录类型：更新合并
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户要求结合明确更新、保留核心个人功能，不确定项等待确认；另明确同意治疗预读改按键与超级宏改角色独立，属性统计继续暂缓。
- 修改内容：合入多件掉落队列和团队拾取确认开关；保留 31 个四选项、“不选择=-1”及随机坐骑增强；补充停用取消队列和过期掷骰恢复。
- 涉及文件：`Modules/AutoNeed.lua`、`Modules/LootBOP.lua`。
- 关联功能与保留：参见[整批实施记录](../Research/10月24日包合并实施-20261025.md)，所有未变及个人独有路径保留；不夹带 DLL 或账号设置。
- 检查结果：31 个设置、67 个内置物品四种选择/回退、保存设置、异步队列/停用/过期恢复检查通过。 整批 176 个变更 Lua 与 32 upvalue 检查通过，TOC/XML 无新增缺失；现用目录与审查候选逐字节一致。[部署清单](../Research/10月24日包合并实施-20261025.json)保存文件指纹和限制。
- 游戏验收与未确认：尚未真实游戏验收；预读/宏迁移/服务器事件与各职业操作仍待实机确认，受控模拟不等同游戏验收。
- 替代关系：本条记录跟随本日差异核对，旧记录保持原有核对时状态；本次仍保留的未确认项目见整批报告。

<a id="change-Automatonex-20261025-01"></a>

### 2026-10-25｜10 月 24 日原包三版本差异核对（未部署）

- 记录编号：`Automatonex-20261025-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户提供 10 月 24 日插件包，要求与 10 月 16 日旧原包及当前个人版对比。
- 修改内容：仅核对并记录，未更新插件。新包变化：多件掉落改为排队逐件掷骰和确认；增加队伍/团队内自动确认拾取的独立开关，默认关闭。
- 当前个人版：现用 AutoNeed 有独立差异；AutoNeed.lua 存在三方冲突，不能覆盖整模块。
- 涉及文件：`Modules/AutoNeed.lua`、`Modules/LootBOP.lua`。
- 关联功能与处理：保留个人 AutoNeed 改动后迁移队列；检查延迟回调与多件拾取。
- 检查结果：逐文件字节及 SHA-256、三方关系与机械合并冲突核对；整批新包变更 Lua 186/187 可编译，GoubayuHeal 原 UI 超过 200 局部变量；可编译文件嵌套函数未超 32 upvalue。相关 TOC/XML 没有新增缺失引用。另运行 BCS 缓存、治疗 UI 编译与 ShaguDPS 兜底受控检查；具体结果与限制见[整批对照报告](../Research/三版本插件对比-20261016-20261024-20261025.md)和[逐文件清单](../Research/三版本插件对比-20261016-20261024-20261025.json)。
- 游戏验收与未确认：本次未部署、未真实游戏或多人验收；既有个人改动归属及证据状态不变，不将原包功能记作本项目新增。

<a id="change-Automatonex-20261012-02"></a>

### 2026-10-12｜随机坐骑避免连续重复

- 记录编号：`Automatonex-20261012-02`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[2fc70d7](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/2fc70d72a08e712ecb8304d35abbe70bba36175e)


- 目的：有其他坐骑可选时，不连续抽中同一只；本次直接启用该规则，不增加额外配置开关。
- 主要文件：[Modules/RandomMount.lua](../../Interface/AddOns/Automatonex/Modules/RandomMount.lua)。先沿用普通/虫子坐骑分组、自定义合并和黑名单过滤，再在当前候选组中跳过上一只，从其余候选等概率抽取；只有一只候选时继续允许召唤，上一只不在当前候选组时全部候选照常参与。
- 保存与关联功能：在现有角色数据中保存 `lastMountName`，按名称而非位置比较，重载及法术书重排后仍生效。普通坐骑、安其拉虫子坐骑和仅剩虫子坐骑的兜底均使用相同规则；战斗、施法或无候选而提前退出时不改变记录。
- 验证：[Tools/tests/test_automaton_randommount.py](../../Tools/tests/test_automaton_randommount.py) 共 30 组 Lua 5.1 检查通过，包括原有 19 组识别/保存回归和新增 11 组：双坐骑连续切换、单坐骑兜底、上一只在三个不同位置时剩余候选的完整等概率映射、上一只不在候选中、提前退出、普通/虫子分组、黑名单变化、法术书重排、角色数据重载及自定义去重。
- 接口与范围：仅调整随机选择和角色记录，沿用现有 1.12 法术书/召唤接口，未新增客户端接口或 FontString。保留插件 UTF-8 无 BOM、LF 和无末尾换行；未直接修改账号/角色设置文件或其他插件。
- 未确认：尚未进入游戏验收连续召唤与重载效果。记录的是 `CastSpell` 正常返回后发出的召唤选择；客户端未提供本次实现所用的成功确认，因此即使召唤被游戏拒绝或随后取消，下一次仍避开这次抽中的坐骑（有其他候选时）。


<a id="change-Automatonex-20261012-01"></a>

### 2026-10-12｜随机坐骑识别及自定义保存修复

- 记录编号：`Automatonex-20261012-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[3d7cc5c](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/3d7cc5cae25d6dc0afad54365bf056b83e757664)


- 目的：修复自定义坐骑添加后失效，以及坐骑页中的部分坐骑漏识别。用户当日补充无法识别的实例为“黑马”，并确认坐骑均位于坐骑页；这是本次反馈，不回写早期历史。
- 主要文件：[Modules/RandomMount.lua](../../Interface/AddOns/Automatonex/Modules/RandomMount.lua)。旧扫描将 `GetSpellTabInfo` 的零基偏移当作首个法术序号，漏掉每页最后一项，还可能混入前页最后一个法术；现按 `offset + 1` 到 `offset + count` 扫描所有实际页面，移除固定 300 项兜底，并支持简体、繁体及英文坐骑页。
- 保存与调用：自定义列表及黑名单改存坐骑名称，调用前通过 `GetSpellName(index, BOOKTYPE_SPELL)` 重新取得当前法术书位置，再传给 `CastSpell(index, BOOKTYPE_SPELL)`。旧版保存位置序号，却在合并自定义列表时调用缺少书类型的 `GetSpellInfo`，导致查询失败；学习新法术或重排法术书也可能让旧序号失效。本次不再依赖该查询或 `GetNumSpellCount`、`string.trim` 扩展。
- 关联功能：按角色保存、自定义启用开关、黑名单添加/恢复/清空、列表显示、职业坐骑与骑乘乌龟兜底、安其拉虫子坐骑分类及召唤。成功添加自定义坐骑时启用自定义列表；去掉首尾空格并避免同名重复，手动关闭自定义开关仍保留已保存内容。
- 旧记录处理：首次有可识别坐骑时，能对应到当前坐骑的数字记录转为名称，并提示核对；无法确认的旧序号保留在列表中、提示重新添加，不参与自定义召唤或黑名单过滤。完成迁移后不再把残余序号随法术书变化重新解释。旧序号未记录原名称，若此前已经从一个坐骑错位到另一个坐骑，无法自动恢复原意，须核对自定义及移除列表；原本位于非坐骑页且无法确认身份的旧自定义记录也需按名称重加。
- 验证：[Tools/tests/test_automaton_randommount.py](../../Tools/tests/test_automaton_randommount.py) 通过 19 组 Lua 5.1 模拟检查，包括单项页、首尾边界、“黑马”、超过 300 个法术、三类页面名称、自定义与黑名单重载后序号变化、重复名称、旧记录迁移和延后迁移、未学会名称保留、职业/虫子坐骑、战斗/施法及临时查询失败。保存检查复用仓库 AceDB-2.0 的实际默认值合并与退出清理函数，并在全新 Lua 环境重载保存内容。旧版模块在相同的单项“黑马”召唤测试中失败，修复后通过。
- 接口与范围：依据本地 `!Libs/!MyLib/api/wowAPI.lua`、`pfUI/libs/libspell.lua` 的既有调用核对 1.12 法术书位置及书类型参数。未创建或修改 FontString，插件文件保留 UTF-8 无 BOM、LF 和原有无末尾换行；未修改账号/角色设置文件或其他插件。
- 未确认：尚未进入游戏确认该角色的实际“黑马”位置、重载后的存档写入和真实召唤结果，也未声称模拟等同游戏验收。重载后可用 `/rm list`、`/rm customlist` 和 `/rm excludelist` 核对；旧序号已错位且原名缺失时须重新添加或重建相应列表。


<a id="change-Automatonex-20261010-01"></a>

### 2026-10-10｜自动需求物品增加“不选择”

- 记录编号：`Automatonex-20261010-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：[d74b8b7](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/d74b8b7e088409a86431021eadd86e1c41453c7e)


- 目的：所有需求类型设置均提供“需求、贪婪、放弃、不选择”，允许单独保留物品的手动掷骰窗口。
- 主要文件：[Modules/AutoNeed.lua](../../Interface/AddOns/Automatonex/Modules/AutoNeed.lua)。补齐自定义物品默认类型、杂项、卡拉赞、祖尔格拉布、安其拉废墟/神殿、熔火之心和纳克萨玛斯共 28 个设置；原有 3 个品质设置继续支持“不选择”。
- 行为：沿用“不选择”的内部值 `-1`，在拾取事件入口拦截，不调用 `RollOnLoot`，不安排自动确认。明确匹配的自定义或分类设置仍优先于品质规则；“放弃”继续使用 `0` 自动放弃。现有默认值与已保存的角色设置不变。
- 关联功能：自定义物品添加时保存的需求类型、分类设置缺省时的全局回退、按品质自动需求、掷骰确认弹窗。未修改其他插件或账号/角色设置文件。
- 验证：[Tools/tests/test_automaton_autoneed.py](../../Tools/tests/test_automaton_autoneed.py) 使用 Lua 5.1 加载现用模块，通过 31 个设置的四选项读写、67 个内置物品的四种选择与全局回退、自定义物品优先级、紫蓝绿品质、自动确认与保存设置保留检查。插件 Lua 保留 UTF-8 无 BOM、CRLF 和原有文件末尾形式。
- 未确认：尚未进入游戏验收设置菜单、真实拾取窗口及与其他自动掷骰插件同时启用的行为。重载界面后将所需物品的需求类型改为“不选择”即可保留手动选择；本次不会自动更改现有选择。


## 早期历史汇总与维护依据

<details>
<summary>展开早期原始说明与证据（不是当前问题或优化清单）</summary>

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

完善模块配置、物品监控及与其他界面的协作。

### 记录中的修改

- 主页配置按角色保存；模块启停可选择按角色或按账户保存，修复默认禁用状态被旧存档遮蔽。
- 主题、背景透明度、搜索和滚动位置原地刷新，减少重建窗口导致的位置跳动和孤立框架。
- QuestItemBar 增加按角色保存的 itemID 监控、任务/监控物品独立开关、去重合计和无边框网格；锁定时隐藏底框。
- Plates 在副本及自定义位置隐藏玩家名字；AutoShout 修正按钮方向和提示；Tooltip 增加框架名称显示开关。
- Trainer 的小地图悬停脚本改为保留前一个处理器；superwow 模块与 pfUI 姓名板堆叠配置协调。
- Boomtime 计时窗口采用关闭按钮控制；后续笔记要求 ESC 不关闭它。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [Core.lua](../../Interface/AddOns/Automatonex/Core.lua)
- [Modules/AutoShout.lua](../../Interface/AddOns/Automatonex/Modules/AutoShout.lua)
- [Modules/Boomtime.lua](../../Interface/AddOns/Automatonex/Modules/Boomtime.lua)
- [Modules/Plates.lua](../../Interface/AddOns/Automatonex/Modules/Plates.lua)
- [Modules/QuestItemBar.lua](../../Interface/AddOns/Automatonex/Modules/QuestItemBar.lua)
- [Modules/Tooltip.lua](../../Interface/AddOns/Automatonex/Modules/Tooltip.lua)
- [Modules/Trainer.lua](../../Interface/AddOns/Automatonex/Modules/Trainer.lua)

### 关联插件

[pfUI](pfUI.md)。更新时同时检查对应入口与数据口径。

### 已回退方案及更新注意

“复制角色配置”功能当日已回退；自定义位置最初隐藏姓名板的实现已改为隐藏玩家名字；/qib、/qibdebug 已删除，不能按早期笔记重加。长期备忘与日期笔记冲突时优先较晚的明确决定。

### 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

### 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/Automatonex)
- [Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-07.md](../../Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-07.md)
- [Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-09.md](../../Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-09.md)
- [Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-12.md](../../Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-12.md)
- [Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-17.md](../../Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-17.md)
- [Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-27.md](../../Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-27.md)
- [Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-30.md](../../Interface/AddOns/Automatonex/.workbuddy/memory/2026-09-30.md)
- [Interface/AddOns/Automatonex/.workbuddy/memory/MEMORY.md](../../Interface/AddOns/Automatonex/.workbuddy/memory/MEMORY.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-08-28.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-08-28.md)
- [Interface/AddOns/pfUI/.workbuddy/memory/2026-09-18.md](../../Interface/AddOns/pfUI/.workbuddy/memory/2026-09-18.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。

---

[返回插件修改记录](README.md)

</details>
