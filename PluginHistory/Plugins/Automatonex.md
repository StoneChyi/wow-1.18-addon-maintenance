# Automatonex 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/Automatonex.md)

## 插件概况

- 分类：经过版本迭代或修改的插件。

- 插件：`Automatonex`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

2026-10-31 第二部分拾取优化：LootBOP托管时交由pfUI确认，独立回退保留；AutoNeed按原任务校验确认，SuperWoW停用清理轮询并保护Shift模式。43项专项离线回归及Lua5.0编译通过；本轮客户端未运行，待游戏验收。

2026-10-31 第一部分组队优化完成：接收邀请统一黑白名单优先级及延迟失效，发出邀请共用权限/容量/去重；四个模块原配置与独立开关保留，pfUI收拢为两个设置页。离线行为回归通过，当前客户端页面复核通过，真实组队动作待用户验收。

2026-10-31 Tooltip 改为 pfUI 共享提示的数据提供者；ExpBar 与 InterPlayerLink 在托管时停止重复事件／挂接，独有功能、原存档及独立回退保留。待游戏验收。

2026-10-31 已移除旧窗口嵌入，设置改用 pfUI 原生控件，原命令和动态选项更新转入统一界面；原功能回调、存档、商人单一执行与独立回退保留。引擎目录仍需加载；待游戏验收。

2026-10-30 合入 AutoDB 别名分发/输入保护/不写历史，开锁技能与已锁判断、标记 elapsed 类型保护、清空关键字确认；不导入历史文本清理。AutoNeed、RandomMount、喊话和世界 BUFF 原字节保留。 [本轮记录](#change-Automatonex-20261030-02)。

2026-10-25 已合并部署：合入多件掉落队列和团队拾取确认开关；保留 31 个四选项、“不选择=-1”及随机坐骑增强；补充停用取消队列和过期掷骰恢复。


完善模块配置、物品监控及与其他界面的协作。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

<a id="change-Automatonex-20261031-05"></a>

### 2026-10-31｜统一拾取绑定确认并修复掷骰与SuperWoW拾取生命周期

- 记录编号：`Automatonex-20261031-05`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：LootBOP与pfUI单人确认重叠；绑定/掷骰固定点击Popup1可能误点；SuperWoW停用未撤轮询，pfUI扫尸体绕过Shift模式。
- 修改内容：LootBOP用运行标记与pfUI交接监听，原独立/组队规则和DB保留；按槽/link/会话/实际原生弹窗确认，手动隐藏、清槽、关闭、新会话、停用及交接使旧任务失效。独立回退改用已有AceEvent，不再造弹窗或依赖C_Timer。
- 掷骰：AutoNeed按roll ID/type/link/当前规则/剩余时间排队，复核来源后ConfirmLootRoll，监听取消和世界切换；手动隐藏使任务失效，不触碰其他弹窗。31个四选项、默认/个人名单、CheckItem原字节保留。
- SuperWoW：显式运行态，仅成功读写SetAutoloot才接管；停用清轮询且条件恢复原值，停用编辑只保存，模式切换复用框体、键态变化才写入。三模式方向保留，修正Shift文案并说明quickloot反转。
- 主要文件：Modules/LootBOP.lua、AutoNeed.lua、Superwow.lua；新增test_pfui_loot_confirmation.py、test_automaton_loot_rolls.py、test_automaton_superwow_loot.py，关联pfUI宿主测试。
- 检查结果：绑定18项、掷骰15项、SuperWoW10项、宿主21项及持久化7项通过；目录原选项覆盖未丢失，五个关联生产Lua文件原生5.0.3编译通过。记录的反例验证与界面读写见实施清单。
- 未确认与方案：本轮客户端未运行，真实拾取/掷骰及quickloot方向待验收；第三方延迟/改造弹窗失去身份时留手动。ShiQu与MasterLootRemind未改，强制分配的目标/本人重复风险另列后续独立修复。未手工写WTF或包含DLL改动。
- 关联：[pfUI](pfUI.md#change-pfUI-20261031-13)、[逐项内容、原因及后续方案](../Research/自动化逐步优化与验收-20261031.md)。

<a id="change-Automatonex-20261031-04"></a>

### 2026-10-31｜统一组队邀请决策与发送并保留原模块配置

- 记录编号：`Automatonex-20261031-04`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：Group与StrangerDecline可能对同一邀请分别接受/拒绝；Invite与invall可能重复邀请。旧55秒任务、普通开关注销黑名单事件、invall事件拼写/区域比较/旧Lua接口存在具体问题。
- 修改内容：Group.lua提供一个incomingInvites事件接收者，采用显式运行态避免Core保存状态晚于生命周期造成误判。黑名单优先、好友/公会按Group设置接受、陌生白名单只放行；Loner继续处理公会与签名，普通拒绝开关不撤销黑名单事件。
- 延迟保护：先等待原生弹窗出现，再以代次、来源名字、本地化邀请文本、弹窗实例及当前规则校验；新邀请、取消、手动响应、弹窗隐藏、组队变化、世界切换及停用均使旧任务失效。保留原55秒选择，两个旧任务ID也清理。
- 发出邀请：共享权限、容量和1秒同目标重复分发去重。名单先于转团；Invite开启时invall密语也使用其名单，Invite关闭后invall独立。自定义名单大小写修正；原关键字Lua模式保留，错误模式不再中断事件。
- invall：修正ZONE_CHANGED_NEW_AREA与区域判断、去掉string.match；新增说话/大喊/密语、仅冬幕谷及升助理开关。默认不限区域保持旧实际行为，升助理保留原模块意愿但仅团长可执行；未自动开启任何模块。修正发出/接受邀请及白名单说明的混淆。
- 桥接：旧Automaton:SelectModule在托管时转入pfUI对应组合页；退出托管调用原函数。原DB命名空间、名单、角色/账号开关和常用菜单隐藏均保留。
- 主要文件：Modules/Group.lua、Loner.lua、Invite.lua、1invall.lua、PfUIBridge.lua；新增接收17项/发出10项专项测试，关联pfUI组合页与宿主测试。
- 检查结果：修改的生产代码原生Lua5.0.3编译通过；接收17项、发出10项、宿主20项、持久化7项、组合页/启动/原生控件/API及商人交接9项通过。53页仍覆盖55个非商人原模块的388项原选项与257次值读回。旧业务初始化边界保留。
- 实机范围：代理/reload后通过旧StrangerDecline ID打开邀请处理，再切邀请玩家，确认原子组选项可显示；只读核实邀请模板为%s邀请你加入队伍。未发送实际邀请、踢人或升助理，未为测试修改用户名单/开关。
- 未确认与方案：第三方改写弹窗将退回手动；公会异步名单、转团异步与其他语言系统消息需后续针对性验证/适配。详细修改原因、风险及逐阶段方案见[实施与验收清单](../Research/自动化逐步优化与验收-20261031.md)。保留旧独立窗口供关闭托管回退，未手工改WTF或夹带DLL。

<a id="change-Automatonex-20261031-03"></a>

### 2026-10-31｜将提示数据、经验统计和角色链接交接给pfUI原生流程

- 记录编号：`Automatonex-20261031-03`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户要求在保留独有功能前提下做实际深度融合，不能只把设置入口搬到pfUI。依据见[本轮排查](../Research/pfUI功能重叠与深度融合-20261031.md)。
- 提示：删除重复包装提示方法及重复布局挂接，保留抗性护甲、伤害攻速、声望、采集、愿望、印象、宠物与法术ID等数据函数；pfUI托管时按统一上下文调用。战斗Shift、光标大小、框体观察与启停保持；独立模式惰性安装一套可失活回调，反复开关不累积。物品ID托管设置归pfUI，原db不覆盖供独立回退。
- 经验：托管时停止原条及事件，OnEnable不得复活第二套统计；原reset命令指向当前原生条位置，旧位置存档保持。所有显示统计并入pfUI原经验条与提示，旧引擎只用于退出托管后的原配置回退。
- 角色链接：托管时不再挂接SetItemRef，统一由pfUI处理，并保留PlayerLinkEnhance的独有动作优先级；原回退解析移除Lua5.0没有的string.match依赖。
- 桥接：允许融合模块映射原生开关，同时保留原始启停意愿。Tooltip独有启停继续使用原模块；旧菜单隐藏状态不被当成停用。
- 涉及文件：`Modules/Tooltip.lua`、`Modules/ExpBar.lua`、`Modules/InterPlayerLink.lua`、`PfUIBridge.lua`及关联pfUI源码／回归测试。
- 检查结果：经验10项、角色链接10项、宿主17项、商人19项及交接9项通过；提示共享流程、全部15个原生开关和范围写回通过。涉及Lua原生5.0编译通过，提示完整受控测试也在真实Lua5.0执行通过；未游戏实测。
- 边界：仍需保留Automatonex目录启用。Bagshui、NotGrid、Cooline、任务自动化等根据当前配置属互补职责，不为减少目录数强制删除。未改原WTF保存文件。
- 关联：[pfUI](pfUI.md)、[PlayerLinkEnhance](PlayerLinkEnhance.md)。

<a id="change-Automatonex-20261031-02"></a>

### 2026-10-31｜移除旧窗口嵌入并接入pfUI原生选项

- 记录编号：`Automatonex-20261031-02`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户要求保留功能同时深度融合 pfUI 原生界面，不接受将原工具箱窗口直接嵌入。
- 修改内容：PfUIBridge 移除旧窗口的 Attach/Detach、父窗口与缩放改写，原命令转入 pfUI 原生设置；原模块动态 RegisterOptions 与 RefreshModuleSettings 通知原生页刷新。独立窗口保留原位置、缩放和正常回退路径。
- 功能保留：Repair/Sell 执行权交接、原始启停意愿和规则存档不变；原模块回调仍是设置写入入口。动态更新商人原选项时保留退出托管后的完整选项，防止重新注册复活重复执行。模块隐藏不等于停用，角色／账号范围和排序可在新页管理。
- 涉及文件：`Interface/AddOns/Automatonex/PfUIBridge.lua`；关联 pfUI automation、automation_options、gui 及对应测试。原各功能模块的业务代码本轮未修改。
- 检查结果：桥接和关联pfUI共4个Lua文件通过原生Lua5.0.3编译；宿主16项、商人交接9项与商人执行19项回归通过，实际原生页面＋渲染器＋CreateConfig联合检查通过。真实AutoNeed的31个选择器、AutoShout物品插入/频道/间隔通过；覆盖动态选项重注册、范围迁移、原名单和启停意愿保留、独立回退以及无重复执行。离线模拟不能代替实际游戏操作。
- 替代关系：替代 [上一版的窗口嵌入层](#change-Automatonex-20261031-01)，商人统一执行及数据回退机制保留。旧 Core 标题引用保持兼容，但不再用于嵌入。
- 未确认事项：待游戏验收原生设置、实际命令跳转、动态列表和独立回退。Automatonex 继续作为功能引擎加载，不删除原目录或账号角色设置。

<a id="change-Automatonex-20261031-01"></a>

### 2026-10-31｜接入pfUI统一管理并释放重复商人执行

- 记录编号：`Automatonex-20261031-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户要求 pfUI 统一修理/售卖并保存已有规则，同时统一管理整个工具箱，减少重复执行与分散设置。
- 修改内容：TOC 末段加载 PfUIBridge.lua；桥接复用原模块引擎，将完整原面板嵌入 pfUI，/auto 转向统一页面，原菜单排序、隐藏状态、原功能设置与保存范围继续可用。Core.lua 仅补充标题控件引用供宿主隐藏/恢复，不重写原模块功能。
- 商人接管：pfUI 规则导入完成且旧模块初始化结束后，通过运行时占用状态停止 Repair/Sell；不使用会污染 AceDB 的持久禁用表冒充临时暂停。模块重新 OnEnable 也不得复活第二套商人事件；原选项和缓存顺序同时映射到统一商人设置，防止编辑已不生效的旧名单。退出托管先撤 pfUI 执行权，随后仅恢复原本启用的旧模块及完整原选项。
- 队列修复：Sell.lua 的 OnDisable 现在停止局部售卖计时器、清空待售队列与计时，避免停用或移交后仍售卖旧槽位。
- 数据和边界：原 SavedVariables、旧角色/账号禁用意愿与原名单保持。pfUI 按角色保存一次合并后的名单与选择。原引擎目录仍需加载；本轮没有把所有代码移进 pfUI，也未关闭仅部分相似但有独有功能的模块。退出统一管理恢复工具箱原开关，pfUI 商人服务暂停；原工具箱未开启的功能不会被自动开启。
- 涉及文件：`Interface/AddOns/Automatonex/Automatonex.toc`、`PfUIBridge.lua`、`Core.lua`、`Modules/Sell.lua`；关联 pfUI automation/autovendor 和三项新增测试文件。
- 检查结果：商人19项、真实旧模块与桥接联合9组、管理界面与生命周期12组通过；覆盖双加载/事件顺序、未就绪不接管、重复接管、旧队列清理、回退次序、未启用模块保持关闭、旧名单/禁用表不变、GUI晚加载/重建/小屏与严格字体失败。既有随机坐骑30组和AutoNeed选择器/内置规则/异步队列检查通过；相关5个Lua文件原生Lua5.0.3编译、维护索引与覆盖链接检查通过。底层仍为受控模拟，未游戏实测。
- 游戏验收与未确认：/reload 后检查统一页完整选项、/auto、商人名单与单一执行、临时关闭托管和恢复。原存档未由离线工具改写；已有 dlls.txt/perf_boost.dll 变化不碰、不夹带。
- 关联：[pfUI记录](pfUI.md#change-pfUI-20261031-02)；[商人回归](../../Tools/tests/test_pfui_autovendor_merge.py)、[联合回归](../../Tools/tests/test_pfui_automation_integration.py)、[界面回归](../../Tools/tests/test_pfui_automation_host.py)。

<a id="change-Automatonex-20261030-02"></a>

### 2026-10-30｜保留个人核心合入 10 月 29 日明确增量（已部署）

- 记录编号：`Automatonex-20261030-02`
- 记录类型：更新合并
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户授权合并明确值得更新的部分，要求保留个人核心与优化方向，不确定项后续逐项确认。
- 修改内容：合入 AutoDB 别名分发/输入保护/不写历史，开锁技能与已锁判断、标记 elapsed 类型保护、清空关键字确认；不导入历史文本清理。AutoNeed、RandomMount、喊话和世界 BUFF 原字节保留。
- 涉及文件：`Modules/AutoDB.lua`、`Modules/TSTargetMark.lua`、`Modules/Unlock.lua`、`Plubics/CleanChat/CleanChat.lua`；完整变化见[实施记录](../Research/10月29日包保留个人核心合并实施-20261030.md)和[指纹清单](../Research/10月29日包保留个人核心合并实施-20261030.json)。
- 检查结果：整批 72 个变更 Lua 真实 Lua 5.0.3 编译通过，TOC/XML 无新增缺失，20 组新行为回归通过；部署后洗脑器 209×2、StatCompare 层级 36 项、S_ItemTip 85 项及共享属性/旧无双完整 UI 回归通过。严格字体模拟覆盖配置字体失败、隐藏和复用；完整源库存等于更新前加 74 项明确变化。
- 关联功能与保留：独立复核已修正 BigWigs 固定 sync 节流吞第二目标、吸收显示新键迁移两项问题。原通信/统计口径及所有未明确变更的个人文件保持；DLL 与账号角色设置不改。
- 游戏验收与未确认：尚未游戏验收；需完整退出重进加载新增卡片/皮肤，事件、显示、实际性能和配置迁移待游戏核对。 后续单独确认清单见整批实施记录。
- 替代关系：本条说明本轮实际部署或明确暂缓结果；前一条仅评估记录和更早部署/回退证据全部保留。前置评估中的同步“分隔符修复”定性及 Lua 5.1 词法边界由本轮实际验证补充纠正。

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
