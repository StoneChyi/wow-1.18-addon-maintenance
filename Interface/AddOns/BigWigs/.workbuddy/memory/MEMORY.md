# BigWigs (ElesionWoW "Golden" 定制 fork) 开发约定

## TMH / 自定义团本 boss 模块
- 模块声明必须用**完整单位名**：`BigWigs:ModuleDeclaration("完整boss名", "Timbermaw Hold")`，并 `module.enabletrigger = module.translatedName`（参考 Karrsh/Perotharn）。
- 原因：`CheckForEngage` 用 `UnitName("target") == module.enabletrigger` **精确**匹配（Core.lua:723），且 `module:ToString()` 返回模块名（=完整 boss 名），`CheckForBossDeath` 的 `UNITDIESOTHER` 分支靠它匹配击杀。名字写短了会导致模块**永不启用** + 击杀不检测。
- 战斗日志触发器可保留 boss 名的**子串**（如「提里奥克…」在「吞噬者提里奥克…」中仍能 `string.find` 命中），更稳。
- 标记玩家用 `GetAvailableRaidMark(nil,true)` + `SetRaidTargetForPlayer` + `RestorePreviousRaidTargetForPlayer`（还原到改前 mark，含 0 即清除）。
- 自标在 emote 里显示「你」→ `resolveName` 转本地名；覆盖默认 `CHAT_MSG_COMBAT_HOSTILE_DEATH` 时必须手动调用 `BigWigs:CheckForBossDeath(msg, self)` 保留 boss 击杀检测。

## CommonAuras 奴役恶魔 / 大恶魔叛变条（Plugins\CommonAuras.lua，2026-09-28/29 定稿）
- 奴役条：UnitDebuff 纹理扫描 + 2s 轮询（本服奴役增益日志是通道盲区，日志路径仅兜底）；仅本机显示（ShowEnslaveLocal/HideEnslaveLocal）。
- 召唤大恶魔（地狱火/恶魔卫士/末日守卫）自带同款奴役纹理 → 出条前必须过 `CheckEnslavePetGate()` 确定性闸门（直接看宠物身份；未解析=等待；真奴役=5s 内施放+换宠计数 petSeq 快照/递增）。**时间戳窗口+freshCast 旁路必有事件顺序竞态，已废除**。
- 叛变条随宠物位存在：UNIT_PET 开（CheckWarlockPet 0.5s，未解析 1s 重查×5）也必须在 UNIT_PET 停（三条 StopBar）。**每种开条都要同步回答"何时停"**；日志路径开条必须置 `enslaveActive` 让 UNIT_PET 停条覆盖所有来源。
- 细节与踩坑全过程见 `.workbuddy/memory/2026-09-28.md`、`2026-09-29.md`（23:37 用户确认实测通过）。

## 自定义 boss emote 的目标 token 坑（必看，已踩坑两次）
- 本 fork 部分自定义 boss emote，第一个目标名在日志里是**未被替换的字面 token**——**实测是 `%s` 而非 `%t`**（2026-09-18 截图确认：喊话显示「冰锥：%s 和 牙脱落大哥哥！ 被瞄准」），其余目标名正常。判 token 时必须 `%s`、`%t` 双判。
- **致命陷阱1**：`boss1~4` 单位框是 **TBC 才加入**的 token，在 1.12 / Turtle 1.12 客户端里 `UnitName("boss1")` 恒为 nil。只靠它解析**永远返回 nil**。这是 2026-09-15 提里奥克冰锥第一次修不好的根因。
- **致命陷阱2**：多目标正则（`(.+)和(.+)`）的最后一个捕获组会把**句末标点一起吃掉**（如「牙脱落大哥哥！」），名字带「！」→ `SetRaidTargetForPlayer` 打不上标记。所有捕获到的名字必须剥离尾部标点（`！ ! 。 ． . …`；Lua pattern 字符类不认多字节字符，逐后缀字节比较）。
- **正确解析**（参考 `Raids/Onyxia/Onyxia.lua:444` CheckTarget 的 1.12 写法）：token = boss 的当前目标，多级回退：
  1. `boss1~4` 框（仅 TBC/Turtle 1.17+ boss 占框时有效）；
  2. 玩家正瞄着 boss：`UnitName("target") == boss全名` 时取 `UnitName("targettarget")`；
  3. **扫描全团**：`UnitName("raid"..i.."target") == boss全名` 时取 `UnitName("raid"..i.."targettarget")`（兼容 `Raid` 大写写法）；小队用 `party`..i。
- 归一化函数 `normalizeTarget`（Trioch.lua）：token 双判 → 解析 boss 目标 → 剥标点 → `resolveName`（自标「你」→ `UnitName("player")`）；nil 时跳过标记、喊话用 `n1 or "?"` 兜底。冰锥与软泥两条标记路径都必须走它。

## 战斗日志 trigger 的贪婪匹配坑（必看）
- 多个 trigger 用 `victim = player or victim` 串联时，**贪婪的兜底 pattern 必须放最前面**，让精确 pattern 后执行去覆盖它。放最后会反向覆盖掉正确结果。
- 实例（`Raids\MC\Ragnaros.lua` `MeleeHitEvent`，2026-09-08 修）：`trigger_dodgeParry = "拉格纳罗斯击中(.+)"` 无尾部锚定，`(.+)` 贪婪吞掉整行 → victim 变成「你造成596点伤害。（194点被格挡）」。因伤害数字每拳不同，`victim ~= knownTank` 恒成立 → **每拳广播一次 newTank**，刷屏「…担任坦克」。zhCN 版比 enUS 版少了 `.-%.$` 尾部锚定才出问题。
- 排查同类刷屏：先看 `%s` 被 format 进去的内容是不是带了伤害数字/句号等动态尾巴。
- 中文日志里自己挨打是「你」，判 `string.lower(victim)=="you"` 对中文**无效**，必须同时判 `victim == L["you"]`。

## 「你」字面量泄漏 → 全团误报中招（必看）
- 中文战斗日志里「自己」是 `你受到了X效果的影响。`，「他人」是 `(.+)受到了X效果的影响。`。这两条 pattern **描述同一条自身日志**。
- 判据（可脚本化）：`stripLeading你(自身pattern) == stripCapture(他人pattern)` → 二者会同时命中同一条自身日志。
- **禁止**把这两个判断写成**并列的独立 `if`**：贪婪的 `(.+)` 会再捕获一次自身日志，捕到的正是字面量 **「你」**，被 `Sync` 广播成玩家名；接收端把它当自己 → **全团都以为中招**。必须用 `elseif` 隔断，或在分支内 `return`。
- 捕获到名字后**一律归一**：`if p == "你" or p == "you" then p = UnitName("player") end`（参考 ShaguDPS：身份只走 UnitName，绝不把日志文本里的字面量当玩家名）。
- **硬编码 `== "you"` 在中文客户端恒不成立** → 会把字面「你」当名字广播（计时条永不消失 / 漏报）。`you = "you"` 出现在 zhCN 块里（未翻译）同样致命 —— 用 `"你" or "you"` 双判最稳。
- 实例：`Raids\BWL\Broodlord.lua` `serrated`（2026-09-13 修）；同类排查器 `bw_audit_you2.js`。

## 「名字以'你'结尾」玩家误触发自身警报（2026-09-17 修，K40+TMH 全量）
- 变体：他人通道(PARTY/FRIENDLYPLAYER)日志「王你受到了X效果的影响」含子串「你受到了X…」→ 未锚定的**自身 trigger** 被 string.find 误命中，当成"自己"中招（错标人、错发个人警报）。
- 修法（学自参考版 D:\BigWigs）：所有以「你/You/Your」开头的自身 trigger 一律加 `^` 锚定（enUS+zhCN 都加）。fade 类「效果从你身上消失」天然安全（「从王你身上」不含「从你身上」）。
- 免疫：用 `msg == L[trigger]` 精确比较的模块（Brainwasher/Mindslayer/Skeram/Huhuran 等）无需改。
- 已修：Karrsh/Kronn/Perotharn/TimbermawTrash/Cthun/Fankriss/Defenders/Sentinels 共 8 文件；排查要点=看 trigger 是否 `string.find` 匹配 + 是否注册了 PARTY/FRIENDLYPLAYER/HOSTILEPLAYER 共享通道。
- 2026-09-24 卡拉赞补修 6 文件（玩家名「我爱你」触发皇后下跪全团误报）：ChessFight（3 trigger+魅惑之心自身分支）、Anomalus、EchoOfMedivh（2）、Kruul、SanvTasdal 各锚定 `^你…`；Mephistroth 的 shackleShatter trigger 无代码引用未动。
- 排查变体时注意：Edit 工具对中文行偶发匹配失败，用更短唯一子串重试；并行 Edit 同一文件会因竞争报 "not found"，需串行。

## zhCN 喊话 trigger 必须取「稳定核心子串」（必看，两例）
- 服内喊话文本经常改字/带错别字，zhCN 触发词**不要照抄整句前缀**（含称呼+标点），取去掉称呼后语义唯一的短语最稳。
- 实例1（2026-09-04，法师）：服内「你们也是法师？小心别玩火自焚......」→ 触发词去标点为「你们也是法师」。
- 实例2（2026-09-18，奈法利安猎/盗点名）：服内盗贼叫「**盗贼**」不叫「潜行者」；猎人句多一个「些」、「玩具枪」旧版错写成「玩具抢」→ 触发词改为 `躲躲藏藏` / `讨厌的玩具`，兼容多种变体。
- 排查口诀：截图里实际喊话 vs L 触发词逐字对比；差别常在称呼（盗贼/潜行者）、量词（那/那些）、错别字（枪/抢）、标点。
- 疑点备忘：Nefarian.lua 已有 phase2+Babble 职业名兜底却未兜住猎/盗漏报，再遇漏报优先查兜底分支（phase 状态 / BC 取值）。
- 本机 bash 的 cp/date/ls 部分失效（command not found），备份用 PowerShell Copy-Item，验证用 Glob/Read（PowerShell 不回显 stdout）。

## 菜单汉化机制：Babble-Boss zhCN 手工词条（必看）
- 菜单条目名 = `module.translatedName = BB:HasTranslation(bossName) and BB[bossName] or bossName`（Core.lua:1158）。自定义 boss 不在 Babble-Boss 里就显示英文。
- **新增自定义 boss / 战场模块时，必须同时往 `!Libs\Babble\Babble-Boss-2.2\Babble-Boss-2.2.lua` 补词条，且要补两处**：
  1. 基础（enUS）表：`["英文名"] = true,`（约 97-104 行，TurtleWOW 区段）——**漏了这步会登录报红**：AceLocale-2.2 严格校验 zhCN 的 key 必须先存在于基础表，否则 `Improper translation exists. "X" is likely misspelled for locale zhCN`，中断整个 Babble 加载 → BigWigs 主逻辑全挂（LoadOnDemand 里 `BigWigs` 全局为 nil 的连锁错误就是这么来的）。
  2. zhCN 表：`["英文名"] = "中文名";`（约 1773 行起；先例：Concavius=空卡维斯、Doctor Weavil=维维尔博士；可加 |CFF00FF00 色前缀）。
- 改名后模块注册名（translatedName）变中文：所有按**旧模块名**的 `GetModule/IsModuleActive/EnableModule/DisableModule/RebootModule` 引用要同步改；`BigWigs_RebootModule`（Core.lua:1424）会先过 BB 翻译再 GetModule，中文参数查不到词条会原样透传所以也能匹配；`bossSync`=声明名不受影响；AceDB namespace 随模块名变 → 该模块存档开关重置一次。
- luaparse 对 Babble-Boss-2.2.lua 整文件恒报 `Cannot read properties of undefined (reading 'range')`（改动前就失败，换版本无效），该文件不能用 luaparse 判语法，用括号配平对比验证（bw_check_balance.js）。

## 插件模块（Plugins/*.lua）开发要点
- **AceEvent-2.0 回调签名是 `(self, 参数...)`，不含事件名**（源码 `!Libs\Ace2\AceEvent-2.0` 里 `obj_method(obj, a1, ...)`）。写 `function Mod:OnX(event, msg)` 会让 `msg` 恒为 nil → `if not msg then return end` 静默失效、零报错。照抄能工作的模块（如 `Raids\*\*.lua` 的 `function module:Event(msg)`）。
- 同一处理器要兼容多路投递时：多事件注册 + 多参数逐个 `type(v)=="string"` 扫描。例：`CHAT_MSG_SYSTEM` 消息在 a1，`UI_ERROR_MESSAGE` 消息在 a2。
- 1.12 无 `C_Timer`：插件里定时刷新用 `self:ScheduleRepeatingEvent(id, func, delay, self)`（AceEvent-2.0 嵌入式方法，第 2 参是**函数**，参考 `Plugins\Proximity.lua:441`）。
- 非 boss 模块（无 `zonename`/`enabletrigger`）会在 `AceEvent_FullyInitialized` 里被自动启用。
- 世界 Boss 模块的击杀链：`Victory()`（Core.lua:501）会调 `BigWigsBossRecords:EndBossfight(self)` + `BigWigsWorldBossCooldown:EndBossfight(self)`；前提是 `module.zonename` 含 `Outdoor Raid Bosses Zone`（`Raids\Other\Kazzak.lua` 已补）。

## WorldBossCooldown 语义（Plugins\WorldBossCooldown.lua）
- 乌龟服世界 Boss 可重复击杀、一周只掉落一次 → **冷却按「掉落」计，不按「击杀」计**：`RecordKill` 若已有冷却期内记录则**不刷新时间**。
- 锁定提示「你绝对不允许从 X 处获得战利品，因为你拥有个人锁定权限！」→ 判 `LOCKOUT_WINDOW`（600s）内的写入是"本场战斗刚写的"并撤销，恢复战前记录；战前无记录则标 `[CD?] 时间不明`。
- `/bwcd` 面板；`/bwcd reset <Boss名|all>` 手动清记录（把历史误报的满 7 天记录重置）；`/bwcd debug` 打印锁定提示原文与解析名。
- 注意：客户端会**回写覆盖**被编辑过的 .lua（2026-09-04 / 09-09 各遇到一次，09-09 的改动整批丢失），改完必须 grep 验证落盘，必要时让用户关客户端再改。

## 竖行条与特殊条的 force 旁路约定（必看，2026-09-18/19）
- `Plugins\Bars.lua` `BigWigs_StartBar` 末参 `force`：为 true 时绕过「VerticalBars 启用则原版条一律 return」的全局拦截（~638 行）。
- **凡不经 `BigWigs_StartBar` 事件、直接方法调用 `BigWigsBars:BigWigs_StartBar(...)` 的特殊条，都必须传 `force=true`**，否则竖行条开启时被静默吞掉（竖行条自己也收不到，因为不走事件）：
  - HP 条（`BigWigs_StartHPBar`，血条式进度：佩罗萨恩吸收盾、Thaddius 费尔根/斯塔拉格、Thekal、Concavius）——已修（追加 `false, nil, nil, true`）；
  - Counter 计数条（`BigWigs_StartCounterBar`，进度计数非倒计时：Nefarian 龙人、Razorgore 蛋、Cthun 小眼、Viscidus 冰伤/戳/球、Hazzarah、Hakkar、Kelthuzad 锁链、Ragnaros 融化）——已修（追加 `nil, nil, nil, true`）。
- **竖行条不该收这些条**：HP/计数条是暂停的进度条，塞进倒计时时间轴语义错误；倒计时类（Bar/IntervalBar）走事件、竖行条正常接管。
- 对被拦/不存在的条调 CandyBar 方法（Set/Stop/Pause/SetText/SetFade/SetTimeFormat/Status）**安全**：CandyBar-2.0 所有方法都有 `if not handler then return end`，不会报错。
- 已知边界：战斗中 `/bwv` 切换会调 `BigWigsBars:StopAllBars()`，把活着的 HP/计数条一并停掉（下次触发才恢复）——低频 edge case，未修。
- **boss 条收条走模块 Disengage（2026-10-02）**：核心 `Disengage()` 广播 `BigWigs_StopBars(module)`（boss 击杀/团灭重置都走这里），竖行条条目记 `entry.module` 归属、收到后按模块清条——横条 `BigWigsBars:Disable` 同语义范本。CommonAuras 非 boss 模块永不 Disengage，奴役/叛变条不受影响。**删兜底前必须先补正确信号源，否则误伤换成漏收**。

## 调试 / 验证手段
- 语法：`luaparse` 通用脚本 `~/.workbuddy/binaries/node/workspace/bw_check_file.js <文件>`（结果写 `bw_syntax_report.txt`；旧的 `bw_check_syntax.js` 路径写死、不可用）。
- 仿真：fengari。世界 Boss CD 链路：`bw_sim_wbcd.js` + `bw_sim_wbcd_stub.lua` + `bw_sim_wbcd_tests.lua`，报告写 `bw_sim_wbcd_report.txt`。
- 本机 bash/PowerShell **不回显 stdout**，仿真结果必须写文件再用 Read 看。
- 改生产模块前先备份到 `BigWigs/backup/<名>.lua.<时间戳>.bak`。

## 兼容性
- 1.12 / Turtle 客户端 Lua 5.0：不用 `string.match`/`string.gmatch`/`!=`/`//`（`~=` 正确）；`string.find` 捕获可用。
