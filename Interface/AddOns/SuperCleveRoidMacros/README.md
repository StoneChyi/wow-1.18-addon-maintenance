# SuperCleveRoid Macros（SCRM）中文文档

增强型宏插件，适用于《魔兽世界》1.12.1（经典旧世 / 乌龟服 Turtle WoW），提供**动态图标提示**、**条件执行**和**扩展宏语法**。

- 条件数量：**355+**
- 命令数量：**68+**
- 兼容 18 个鼠标悬停单位框体插件、4 个宏/动作条插件

---

## 目录

- [环境要求](#环境要求)
- [安装](#安装)
- [快速开始](#快速开始)
- [命令列表](#命令列表)
- [条件参考](#条件参考)
- [进阶用法](#进阶用法)
- [配置命令说明](#配置命令说明)
- [功能模块](#功能模块)
- [兼容层与扩展](#兼容层与扩展)
- [鼠标悬停支持](#鼠标悬停支持)
- [其他插件集成](#其他插件集成)
- [Turtle WoW 特色机制](#turtle-wow-特色机制)
- [已知问题](#已知问题)
- [致谢](#致谢)

---

## 环境要求

| 依赖 | 必需 | 用途 |
|------|:----:|------|
| [Nampower](https://gitea.com/avitasia/nampower/releases)（v3.0.0+） | ✅ | 施法排队、DBC 数据、SPELL_START/GO/FAILED / SPELL_MISS / AURA_CAST / 伤害事件、自动攻击事件、GUID 扩展单位 token、UnitBuff/UnitDebuff spellID |
| [UnitXP_SP3](https://codeberg.org/konaka/UnitXP_SP3/releases) | ✅ | 距离测量、`[enemynum]` 敌人扫描、`[insight]` 视线检测、`@fov` 选目标 |

> 缺少依赖时插件仅打印警告（不卸载以免卡死），相关功能不可用。
>
> **SuperWoW 不再是功能依赖**：全插件已改用 Nampower API 实现（施法追踪、GUID 软施法、
> 扩展单位 token、aura spellID、名牌 GUID、mouseover 扩展等）。唯一保留的可选增强是
> `[mounted]`/`[indoor]` 条件——若加载了 SuperWoW（v3+）则用其 `IsMounted()`/`IsIndoors()`，
> 否则回退到 UnitXP/tooltip 扫描。

**推荐**：[me0wg4ming/pfUI](https://github.com/me0wg4ming/pfUI) 分支——含 SCRM 原生集成，条件宏的冷却/图标/提示显示最完整。

---

## 安装

1. 将 `SuperCleveRoidMacros` 文件夹放入 `Interface/AddOns/`
2. 安装上述两个必需插件
3. 进游戏后输入 `/cleveroid` 查看加载状态与配置

---

## 快速开始

### 基本语法

```lua
#showtooltip
/cast [mod:alt] 寒冰箭; [mod:ctrl] 火冲; 闪现术
```

- 条件写在 `[]` 中，用空格或逗号分隔
- 参数使用冒号：`[mod:alt]`、`[hp:>50]`
- 否定使用 `no` 前缀：`[nobuff]`、`[nomod:alt]`
- 目标使用 `@`：`[@mouseover,help]`、`[@party1,hp:<50]`、`[@focus,harm]`
- 带空格的技能名用引号 `"野性印记"` 或下划线 `野性_印记`
- 优先级分支用分号 `;`：从前到后第一个满足的条件执行

### 多值逻辑

| 语法 | 逻辑 | 示例 | 含义 |
|------|------|------|------|
| `[buff:X/Y]` | 或 | `[buff:恢复/回春]` | 有恢复**或**回春 |
| `[buff:X&Y]` | 与 | `[buff:耐力&野性印记]` | 同时有耐力和野性印记 |
| `[nobuff:X/Y]` | 都不 | `[nobuff:恢复/回春]` | 同时缺少恢复和回春 |
| `[nobuff:X&Y]` | 缺一 | `[nobuff:耐力&野性印记]` | 至少缺少一个 |

**德摩根定律**：否定会翻转运算符。`no` + `/`（或）→ 与（必须全部缺失）；`no` + `&`（与）→ 或（至少缺失一个）。

**多次出现 = 组之间是与关系**：`[mybuff:X/Y mybuff:Z]` →（有 X 或 Y）并且（有 Z）。

### 数值比较

| 写法 | 含义 |
|------|------|
| `[hp:>50]` | 生命值高于 50% |
| `[hp:>20&<50]` | 生命值在 20%~50% 之间（多比较） |
| `[buff:"名字"<5]` | 增益剩余时间少于 5 秒 |
| `[debuff:"名字">#3]` | 层数≥3（`#` 表示层数） |
| `[combo:>=4]` | 连击点≥4 |

### 施法时间/攻速公式（比较量引用技能时间与攻击速度）

数值比较位可以写**公式**代替数字。公式函数独立命名（`getcast`/`getchannel`/`getmh`/`getoh`/`getranged`），不与 `[casttime]`/`[channeltime]` 等条件名冲突。全部走 **Nampower 实时 API 主路径**（tooltip 字符串解析仅作一次性学习与兜底），按 **0.1s TTL 实时求值**——急速/装备变化实时生效。

**语法强制要求：公式比较值必须用 `"..."` 包裹**（如 `end<"getchannel(奥术飞弹)/6"`）。引号内的 `/` 是除号而非多值分隔符；未加引号的公式不会被识别（`/` 会按多值分隔符拆分）：

| 公式 | 含义 |
|------|------|
| `getcast(技能名)` | 该技能的**实时施法时间** = tooltip 基础值 × 当前施法速度修正（引导技返回其引导时长；瞬发=0） |
| `getchannel(技能名)` | 该技能的**实时引导总时长**（仅引导技；来自 `GetSpellDuration`，含时长类修正） |
| `getmh()` | 实时主手攻击速度（秒；`GetUnitField baseAttackTime`） |
| `getoh()` | 实时副手攻击速度（秒；无副手=nil） |
| `getranged()` | 实时远程攻击速度（秒；无远程=nil） |

以上函数用于**数值位**（加引号）。它们也有对应的**独立条件**（冒号语法，省略技能名时默认当前宏动作技能）：

| 条件 | 含义 | 示例 |
|------|------|------|
| `[getcast:...]` | 技能实时施法时间比较 | `[getcast:火球术>3]`、`[getcast:>3]`（当前动作技能） |
| `[getchannel:...]` | 技能实时引导时长比较 | `[getchannel:奥术飞弹<"getcast(火球术)"]` |
| `[getmh:...]` | 实时主手攻速比较 | `[getmh:>2.5]` |
| `[getoh:...]` | 实时副手攻速比较 | `[getoh:<1.0]` |
| `[getranged:...]` | 实时远程攻速比较 | `[getranged:>=2.0]` |

支持 `+ - * /` 四则运算与括号，可与数字混写：

```lua
/cast [channeltime:end<"getchannel(奥术飞弹)/6"] 火焰冲击   -- 引导剩余 < 奥术飞弹总引导/6 时打断施放
/cast [delay:>="getcast(火球术)*2"] 火球术                  -- 距上次施放 ≥ 2×火球术当前施法时间
/cast [getmh:>2.5] 英勇打击                                -- 主手攻速慢于 2.5s（换慢速武器场景）
/cast [getcast:>3] 奥术飞弹                                -- 当前动作技能施法时间 > 3s
```

说明：
- 公式在**每次比较时求值**（0.1s TTL 缓存内取实时值）；技能表**不做预扫描**——仅在公式引用到某技能时惰性学习一次（tooltip 解析一次性，之后走实时 API）
- 基础表存的是 tooltip 基础施法时间/引导时长；**急速修正按 0.1s TTL 实时乘算**，不写死在表里；攻速直接读 Nampower 单位字段（本身即实际值）
- 技能名支持带等级后缀（如 `getcast("火球术(等级 5)")`，经 `GetSpellSlotTypeIdForName` 按等级定位）
- 多重比较（`>` 与 `&` 链）中暂不支持公式，公式仅用于单一比较量
- 技能表查看/清空：`/cleveroid castinfo show <技能名>`、`/cleveroid castinfo clear`（清空后下次引用重新学习）

### 特殊前缀

| 前缀 | 示例 | 描述 |
|------|------|------|
| `!` | `!技能` | 仅当未激活时使用（防刷） |
| `?` | `[条件] ?技能` | 从图标提示中隐藏（仍执行动作） |
| `~` | `~光环` | 取消光环 |
| `--` | `/--cast 技能` | 屏蔽/注释该整行：把任意命令写成 `/--命令` 即临时禁用（调试宏用） |

---

## 命令列表

所有命令均支持条件判断（除非标注"无"）。

### 施法 / 宏命令

| 命令 | 条件 | 示例 | 描述 |
|------|:----:|------|------|
| `/cast` | ✓ | `/cast [mod:alt] 寒冰箭` | 施放法术（重写内置，支持条件/优先级/连击点注入） |
| `/use` | ✓ | `/use [hp:<30] 治疗药水` | 使用物品（名称/ID/栏位） |
| `/castsequence` | ✓ | `/castsequence 献祭, 暗影箭` | 按顺序施放法术序列 |
| `/castrandom` | ✓ | `/castrandom 火球术, 寒冰箭` | 随机施放一个技能 |
| `/userandom` | ✓ | `/userandom 治疗药水, 法力药水` | 随机使用一个物品 |
| `/castpet` | ✓ | `/castpet [combat] 爪击` | 施放宠物技能 |
| `/startattack` | ✓ | `/startattack [harm]` | 开始自动攻击 |
| `/attack` | ✓ | `/attack [harm]` | 开始自动攻击（等同 `/startattack`） |
| `/stopattack` | ✓ | `/stopattack` | 停止自动攻击 |
| `/autoshoot` | ✓ | `/autoshoot [combat]` | 开启自动射击（等同 `/cast !自动射击`） |
| `/shootattack` | ✓ | `/shootattack` | 开启射击（等同 `/cast !射击`） |
| `/stopshoot` | ✓ | `/stopshoot` | 关闭自动射击/射击 |
| `/stopcasting` | ✓ | `/stopcasting [mycc:沉默]` | 停止施法 |
| `/stopspelltarget` | ✓ | `/stopspelltarget` | 取消当前正在瞄准（等待选目标）的法术 |
| `/cancelaura` | ✓ | `/cancelaura [combat] 寒冰屏障` | 取消光环（别名：`/unbuff`） |
| `/unqueue` | ✓ | `/unqueue [mod:shift]` | 清理施法队列/状态并停止施法 |
| `/stopmacro` | ✓ | `/stopmacro [nocombat]` | 停止所有宏执行（含父宏） |
| `/skipmacro` | ✓ | `/skipmacro [nogroup]` | 仅停止当前子宏（父宏继续） |
| `/firstaction` | ✓ | `/firstaction [group]` | 优先模式：第一个成功的 `/cast` 后停止 |
| `/nofirstaction` | ✓ | `/nofirstaction` | 恢复多队列行为 |
| `/runmacro` | ✓ | `/runmacro 我的宏` | 按名称执行普通宏 |
| `/runsupermacro` | ✓ | `/runsupermacro 超级宏` | 执行超级宏（SuperMacro） |
| `/crmrun` | ✓ | `/crmrun /cast 技能A; /use 物品B` | 批量执行一串 `/` 命令 |
| `/sendmessage` | ✓ | `/sendmessage [combat] 奶我` | 条件满足时通过插件频道广播 |
| `/quickheal` | ✓ | `/quickheal [combat] party` | QuickHeal 智能治疗（别名：`/qh`） |
| `/rh` | ✓ | `/rh [hp:<50]` | Heart 治疗插件（模式 `mw`/`a`/`ms`） |

### 宠物命令

| 命令 | 条件 | 示例 | 描述 |
|------|:----:|------|------|
| `/petattack` | ✓ | `/petattack [harm]` | 宠物攻击 |
| `/petfollow` | ✓ | `/petfollow [nocombat]` | 宠物跟随 |
| `/petwait` | ✓ | `/petwait [mod:ctrl]` | 宠物等待 |
| `/petstay` | ✓ | `/petstay` | 宠物驻留 |
| `/petpassive` | ✓ | `/petpassive` | 宠物被动模式 |
| `/petdefensive` | ✓ | `/petdefensive` | 宠物防御模式 |
| `/petaggressive` | ✓ | `/petaggressive` | 宠物攻击模式 |
| `/petautocaston` | ✓ | `/petautocaston 爪击` | 开启宠物技能自动施放 |
| `/petautocastoff` | ✓ | `/petautocastoff 爪击` | 关闭宠物技能自动施放 |
| `/petautocasttoggle` | ✓ | `/petautocasttoggle 爪击` | 切换宠物技能自动施放 |
| `/petdismiss` | ✓ | `/petdismiss [nocombat]` | 解散野兽（经"解散野兽"技能实现） |
| `/feed` | ✓ | `/feed [pet] 肉` | 喂养宠物 |

### 装备命令

| 命令 | 条件 | 示例 | 描述 |
|------|:----:|------|------|
| `/equip` | ✓ | `/equip [nocombat] 钓鱼竿` | 装备物品 |
| `/equipmh` | ✓ | `/equipmh [nocombat] 匕首` | 装备到主手 |
| `/equipoh` | ✓ | `/equipoh [nocombat] 匕首` | 装备到副手 |
| `/equip11` | ✓ | `/equip11 戒指名` | 装备戒指 1 号槽 |
| `/equip12` | ✓ | `/equip12 戒指名` | 装备戒指 2 号槽 |
| `/equip13` | ✓ | `/equip13 [combat] 饰品` | 装备饰品 1 号槽 |
| `/equip14` | ✓ | `/equip14 饰品名` | 装备饰品 2 号槽 |
| `/equipslot` | ✓ | `/equipslot 16 匕首` | 装备到指定栏位 |
| `/switch` | ✓ | `/switch` | 切换主副手武器 |
| `/unshift` | ✓ | `/unshift [myhp:<30]` | 取消形态（别名：`/cancelform`） |
| `/applymain` | ✓ | `/applymain [nomhimbue] 速效毒药` | 主手涂毒/涂油 |
| `/applyoff` | ✓ | `/applyoff [noohimbue] 致残毒药` | 副手涂毒/涂油 |
| `/pickup` | ✓ | `/pickup 16` / `/pickup 致伤毒药` | 拿起装备栏/背包物品（上毒、磨刀石用） |
| `/unequip` | ✓ | `/unequip 1-10` / `/unequip 逐风者` | 卸下装备：支持栏位（`1` / `1,2,3` / `1-10`）、物品名、物品ID |
| `/clearequipqueue` | 无 | `/clearequipqueue` | 清空装备交换队列 |
| `/equipqueuestatus` | 无 | `/equipqueuestatus` | 显示装备队列状态 |

### 目标命令

| 命令 | 条件 | 示例 | 描述 |
|------|:----:|------|------|
| `/target` | ✓ | `/target [harm,nodead]` | 目标切换（重写内置，支持 UnitXP 3D 扫描） |
| `/cleartarget` | ✓ | `/cleartarget [dead]` | 清除目标 |
| `/retarget` | ✓ | `/retarget` | 清除无效目标，选择最近敌人 |
| `/assist` | ✓ | `/assist [harm]` | 协助目标的目标 |
| `/follow` | ✓ | `/follow [help]` | 跟随目标（支持 `[条件]`；可带名称，SuperWoW 下按名字跟随） |
| `/targetenemy` | ✓ | `/targetenemy` | 选择最近敌人 |
| `/targetenemyplayer` | ✓ | `/targetenemyplayer` | 选择最近敌对玩家 |
| `/targetfriend` | ✓ | `/targetfriend` | 选择最近友方 |
| `/targetfriendplayer` | ✓ | `/targetfriendplayer` | 选择最近友方玩家 |
| `/targetlasttarget` | ✓ | `/targetlasttarget` | 选择上一个目标（别名：`/lasttarget`） |
| `/targetlastenemy` | ✓ | `/targetlastenemy` | 选择上一个敌人（别名：`/lastenemy`） |
| `/targetlastfriend` | ✓ | `/targetlastfriend` | 选择上一个友方 |
| `/targetparty` | ✓ | `/targetparty` | 选择队伍成员 |
| `/targetraid` | ✓ | `/targetraid` | 选择团队成员 |
| `/targetexact` | ✓ | `/targetexact "奥妮克希亚"` | 精确名称匹配 |

### 辅助命令

| 命令 | 条件 | 示例 | 描述 |
|------|:----:|------|------|
| `/mount` | ✓ | `/mount [outdoor]` | 召唤坐骑 |
| `/dismount` | ✓ | `/dismount` | 取消坐骑 |
| `/changeactionbar` | ✓ | `/changeactionbar 2` | 切换动作条页 |
| `/swapactionbar` | ✓ | `/swapactionbar 1 2` | 交换动作条页 |
| `/settag` | ✓ | `/settag [combat] 我的标签` | 将满足条件的目标设为标签 |
| `/click` | ✓ | `/click StaticPopup1Button1` | 模拟点击有名字的 UI 按钮（1.12 无 `/click`，用 `Button:Click()` 实现；可加鼠标键 `1/2/3`） |
| `/threshold` | ✓ | `/threshold 3` / `/threshold` | 设置/显示拾取品质门槛（`2`=绿 `3`=蓝 `4`=紫…；1.12 无此命令，用 `SetLootThreshold` 实现） |
| `/rl` | 无 | `/rl` | 重载界面 |

### 调试命令

| 命令 | 条件 | 示例 | 描述 |
|------|:----:|------|------|
| `/combotrack` | 无 | `/combotrack show` | 连击点追踪调试（show/clear/debug） |
| `/macrocheck` | 无 | `/macrocheck all` | 宏语法检查（all 或指定宏名） |
| `/pfuicd` | 无 | `/pfuicd` | pfUI 冷却/行动调试开关 |
| `/cleveroid castinfo` | 无 | `/cleveroid castinfo scan` | 技能施法信息表维护（scan [refresh]/show <名>/clear），供施法时间公式使用 |
| `/cleveroid` | 无 | `/cleveroid` | 主配置入口（详见[配置命令说明](#配置命令说明)） |

### 优先宏评估

默认情况下所有 `/cast` 行都会评估，并可能通过 Nampower 排队。`/firstaction` 启用"第一个成功施法优先"模式：

```lua
/firstaction
/cast [myrawpower:>48] 撕碎        -- 优先区：只会执行一个
/cast [myrawpower:>40] 爪击
/nofirstaction
/cast 猛虎之怒                  -- 始终与上面并行评估
/startattack
```

`/firstaction [条件]` 支持条件；子宏（通过 `{宏名}` 调用）继承优先状态。

### UnitXP 3D 敌人扫描

`/target` 带上任何条件时，会自动使用 UnitXP 3D 扫描寻找视野内的敌人。例外：`[help]` 不包含 `[harm]` 时（只找友方）。如果未找到匹配，原始目标会被保留。

```lua
/target [name:奥妮克希亚]      -- 扫描精确名称
/target [nodead,harm]          -- 扫描活的敌人
/target [cc:stun]              -- 扫描被晕的敌人
```

---

## 条件参考

所有条件都支持 `no` 前缀否定（除非另有说明）。部分有语义对立：`help/harm`、`alive/dead`、`isplayer/isnpc`、`inrange/outrange`。

表格列说明：

- **否定** — 是否支持 `no` 前缀
- **多值** — 支持或（`/`）、与（`&`）或数值比较（`>`、`<`、`>=`、`<=`、`=`）
- **NP** — 最低 Nampower 版本要求
- **插件** — 所需或推荐的插件

### 玩家条件（检查玩家自己）

| 条件 | 描述 | 否定 | 多值 | 示例 | 插件 |
|------|------|:----:|:----:|------|------|
| `button`/`btn`（亦 `button1`~`button5`/`btn1`~`btn5`） | 鼠标按键（1=左 2=右 3=中 4/5=侧键）；兼容 Classic 冒号写法 | ✓ | — | `[button:2]` / `[btn1]` | |
| `cdgcd` | 技能/物品冷却剩余（含 GCD） | ✓ | ✓ | `[cdgcd:疾跑>0]` | |
| `channeled`/`chan` | 玩家正在引导 | ✓ | ✓ | `[channeled][channeled:奥术飞弹]` | |
| `checkcasting` | 没有在施法（可指定法术） | — | ✓ | `[checkcasting][checkcasting:寒冰箭]` | |
| `checkchanneled` | 没有在引导（可指定法术） | — | ✓ | `[checkchanneled][checkchanneled:唤醒]` | |
| `combat`/`ic`/`ooc` | 战斗中（默认玩家，可指定单位） | ✓ | ✓ | `[combat][combat:target]` | |
| `combo` | 连击点数 | ✓ | ✓ | `[combo:>=4]` | |
| `cooldown`/`cd` | 技能/物品冷却剩余（忽略 GCD） | ✓ | ✓ | `[cooldown:疾跑<5]` | |
| `druidmana` | 德鲁伊变身后的法力值 | — | ✓ | `[druidmana:>=500]` | |
| `equipped`/`eq`/`worn` | 已装备的物品或武器类型 | ✓ | ✓ | `[equipped:匕首/剑]` | |
| `actionbar`/`bar` | 当前动作条页 | ✓ | ✓ | `[actionbar:2][bar:1/3]` |
| `form`/`stance` | 形态或姿态序号 | ✓ | ✓ | `[form:1/3][stance:2]` | |
| `gcd` | GCD 活跃/剩余时间 | ✓ | ✓ | `[gcd][gcd:<1]` | |
| `group` | 玩家在队伍类型中 | ✓ | ✓ | `[group:party/raid]` | |
| `hastarget` | 玩家有目标 | — | — | `[hastarget]` | |
| `incominghit`/`ihit` | 受到的攻击类型/时间 | ✓ | ✓ | `[incominghit:碾压][noincominghit:暴击]` | v2.24 |
| `keydown` | 按键被按住 | ✓ | ✓ | `[keydown:f][keydown:空格/回车]` | v2.41 |
| `known` | 已知法术/天赋（可比较等级） | ✓ | ✓ | `[known:狂暴][known:寒冰箭>#2]` | |
| `lastswing` | 玩家近战攻击类型/时间 | ✓ | ✓ | `[lastswing:闪避][lastswing:<2]` | v2.24 |
| `mhimbue` | 主手有临时附魔 | ✓ | ✓ | `[mhimbue:速效_毒药<300][mhimbue:>#5]` | |
| `mod` | 功能键按下 | ✓ | ✓ | `[mod:alt/ctrl]` | |
| `moving`/`move`/`mv` | 移动中/速度百分比 | ✓ | ✓ | `[moving][moving:>100&<200]` | MonkeySpeed |
| `mybuff` | 玩家有增益（时间/层数） | ✓ | ✓ | `[mybuff:荆棘<5][nomybuff:野性印记]` | |
| `mybuffcapped` | 玩家增益栏满（32） | ✓ | — | `[mybuffcapped]` | v2.20 |
| `mybuffcount` | 玩家增益数量（含增益栏满后无可见槽的溢出增益） | ✓ | ✓ | `[mybuffcount:>15]` | |
| `mycc` | 玩家受控场效果 | ✓ | ✓ | `[mycc:stun/fear]` | |
| `mycombat` | 玩家自身在战斗（事件缓存） | ✓ | — | `[mycombat]` | |
| `mycasting` | 玩家正在施法 | ✓ | ✓ | `[mycasting][mycasting:寒冰箭]` | |
| `mycasttime` | 玩家施法计时（start/end） | ✓ | ✓ | `[mycasttime:end<0.5]` | |
| `mydebuff` | 玩家有该 debuff | ✓ | ✓ | `[mydebuff:致伤毒药]` | |
| `mydebuffcapped` | 玩家 debuff 栏满（16） | ✓ | — | `[mydebuffcapped]` | v2.20 |
| `mydispel` | 玩家有可驱散 debuff | ✓ | ✓ | `[mydispel:中毒]` | |
| `myhp` | 玩家血量百分比 | ✓ | ✓ | `[myhp:<30]` | |
| `myhplost` | 玩家已损失血量 | ✓ | ✓ | `[myhplost:>100]` | |
| `mylevel` | 玩家等级 | ✓ | ✓ | `[mylevel:>50]` | |
| `mypower` | 玩家能量百分比 | ✓ | ✓ | `[mypower:>50]` | |
| `mypowerlost` | 玩家已损失能量 | ✓ | ✓ | `[mypowerlost:>100]` | |
| `myrawhp` | 玩家血量绝对值 | ✓ | ✓ | `[myrawhp:<500]` | |
| `myrawpower` | 玩家能量绝对值 | ✓ | ✓ | `[myrawpower:<300]` | |
| `myunit` | 目标是我的召唤物 | ✓ | ✓ | `[myunit:水元素]` | |
| `nomct`/`mct` | 自身施法剩余时间（别名） | ✓ | ✓ | `[mct:<0.5]` | |
| `ohimbue` | 副手有临时附魔 | ✓ | ✓ | `[ohimbue:致伤毒药<300]` | |
| `power` | 目标能量百分比 | ✓ | ✓ | `[power:>50]` | |
| `powerlost` | 目标已损失能量 | ✓ | ✓ | `[powerlost:>100]` | |
| `resting` | 休息中 | ✓ | ✓ | `[resting]` | |
| `rooted` | 定身中 | ✓ | — | `[rooted]` | v2.36 |
| `selfcasttime` | 玩家自身施法剩余时间 | ✓ | ✓ | `[selfcasttime:<0.5]` | |
| `selfchanneltime` | 玩家自身引导剩余时间 | ✓ | ✓ | `[selfchanneltime:<0.5]` | |
| `selfcasting` | 玩家正在施法/引导 | ✓ | — | `[selfcasting]` | |
| `spec` | 当前天赋与保存套装匹配 | ✓ | ✓ | `[spec:1][spec:射击]` | |
| `spellcasttime`/`sct` | 技能总施法时间 | ✓ | ✓ | `[spellcasttime:>2][spellcasttime:寒冰箭>2]` | |
| `stat` | 玩家面板属性 | ✓ | ✓ | `[stat:敏捷>100]` | |
| `stealth`/`stl` | 潜行中 | ✓ | — | `[stealth]` | |
| `swimming`/`swim` | 游泳中 | ✓ | — | `[swimming]` | v2.36 |
| `targeting`/`tgt` | 目标瞄准指定单位 | ✓ | ✓ | `[targeting:tank]` | |

### 目标条件（检查当前目标）

| 条件 | 描述 | 否定 | 多值 | 示例 | 插件 |
|------|------|:----:|:----:|------|------|
| `addcheck` | ADD 安全检查（范围内未进战斗敌对） | — | ✓ | `[addcheck:5]` | |
| `alive` | 目标存活 | ✓ | — | `[alive]` | |
| `behind` | 玩家在目标背后 | ✓ | ✓ | `[behind][behind:>2]` | |
| `boss` | 目标是世界 Boss | ✓ | — | `[boss]` | |
| `buff` | 目标有该 buff | ✓ | ✓ | `[buff:力量祝福<5]` | |
| `buffcapped` | 目标 buff 栏满 | ✓ | — | `[buffcapped]` | |
| `casttime` | 目标施法剩余时间 | ✓ | ✓ | `[casttime:end<1]` | Nampower |
| `casting` | 目标正在施法 | ✓ | ✓ | `[casting:火球术]` | |
| `cc` | 目标受控场效果 | ✓ | ✓ | `[cc:stun/fear][cc:stun]` | |
| `class` | 目标是某职业 | ✓ | ✓ | `[class:战士/德鲁伊]` | |
| `cursive` | Cursive 精确 debuff 时间 | ✓ | ✓ | `[cursive:Rake>3]` | Cursive |
| `dead` | 目标死亡/灵魂 | ✓ | — | `[dead]` | |
| `deathtime` | 目标预计死亡时间 | — | ✓ | `[deathtime:<5]` | |
| `debuff` | 目标有该 debuff | ✓ | ✓ | `[debuff:破甲>#3]` | |
| `debuffcapped` | 目标 debuff 栏满 | ✓ | — | `[debuffcapped]` | |
| `dispel` | 目标有可驱散 debuff | ✓ | ✓ | `[dispel:魔法]` | |
| `distance`/`dist` | 距离比较/范围内计数 | ✓ | ✓ | `[distance:<30][distance:30>1]` | UnitXP |
| `enemynum` | 范围内敌人数量 | — | ✓ | `[enemynum:>3]` | UnitXP |
| `exists` | 目标存在 | ✓ | — | `[exists]` | |
| `facing` | 玩家面对目标 | ✓ | ✓ | `[facing][facing:>2]` | |
| `harm` | 目标是敌对可攻击 | ✓ | — | `[harm]` | |
| `help` | 目标是友方可协助 | ✓ | — | `[help]` | |
| `hp` | 目标血量百分比 | ✓ | ✓ | `[hp:<30][hp:>20&<50]` | |
| `hplost` | 目标已损失血量 | ✓ | ✓ | `[hplost:>100]` | |
| `immune` | 目标免疫该法术/伤害系 | ✓ | ✓ | `[immune:火球术][immune:fire]` | |
| `inrange` | 目标在指定法术射程内 | ✓ | ✓ | `[inrange:射击][inrange:多重射击>1]` | |
| `inscreen` | 目标在屏幕内 | ✓ | — | `[inscreen]` | UnitXP_SP3_X |
| `insight`/`los` | 目标在视线内 | ✓ | — | `[insight]` | UnitXP |
| `isnpc` | 目标不是玩家 | ✓ | — | `[isnpc]` | |
| `isplayer` | 目标是玩家 | ✓ | — | `[isplayer]` | |
| `istank` | pfUI 标记坦克 | ✓ | — | `[istank:focus]` | pfUI |
| `level` | 目标等级 | ✓ | ✓ | `[level:>50]` | |
| `mark` | 团队标记 | ✓ | ✓ | `[mark:skull][mark:star]` | |
| `meleerange`/`melee` | 目标在近战范围 | ✓ | ✓ | `[meleerange][meleerange:>2]` | |
| `member` | 目标在队伍/团队 | ✓ | — | `[member]` | |
| `mhremaining` | 主手挥击剩余时间 | — | ✓ | `[mhremaining:<0.5]` | |
| `mhstarted` | 主手挥击已进行时间 | — | ✓ | `[mhstarted:>0.5]` | |
| `mostwoundedgroup` | 受伤最重小队 | — | ✓ | `[mostwoundedgroup:lost500>=2]` | |
| `mounted` | 骑乘中 | ✓ | — | `[mounted]` | |
| `mydot` | 我施加的 DoT 剩余时间 | ✓ | ✓ | `[mydot:献祭<1.5]` | Cursive |
| `mydotcount` | 指定多 DoT 数量 | — | ✓ | `[mydotcount:献祭\|腐蚀>2]` | Cursive |
| `mytag` | 目标被我标记 | ✓ | — | `[mytag]` | |
| `mytargeting` | 我的目标正指向指定单位 | ✓ | ✓ | `[mytargeting:party1]` | |
| `name` | 目标名字匹配 | ✓ | ✓ | `[name:奥妮克希亚]` | |
| `nobuff` | 目标缺该 buff | — | ✓ | `[nobuff:力量祝福]` | |
| `nocursive` | 目标没有该 Cursive debuff | — | ✓ | `[nocursive:Rake]` | Cursive |
| `nodebuff` | 目标缺该 debuff | — | ✓ | `[nodebuff:精灵之火]` | |
| `nomydot` | 我的 DoT 缺失 | — | ✓ | `[nomydot:献祭]` | Cursive |
| `ohremaining` | 副手挥击剩余时间 | — | ✓ | `[ohremaining:<0.5]` | |
| `ohstarted` | 副手挥击已进行时间 | — | ✓ | `[ohstarted:>0.5]` | |
| `onenemytarget` | 攻击我的敌人数量 | ✓ | ✓ | `[onenemytarget:dst10>1]` | |
| `onspelltarget` | 有人对目标施法 | ✓ | ✓ | `[onspelltarget:火球术]` | |
| `othertag` | 目标被他人标记 | ✓ | — | `[othertag]` | |
| `outrange` | 目标超出法术射程 | ✓ | — | `[outrange:射击]` | |
| `owner` | 目标主人名字匹配 | ✓ | — | `[owner:名字]` | Nampower v2.41+ |
| `party` | 目标在队伍 | ✓ | ✓ | `[party:party1]` | |
| `playercontrolled` | 目标由玩家控制 | ✓ | — | `[playercontrolled]` | |
| `raid` | 目标在团队 | ✓ | ✓ | `[raid]` | |
| `rangedclip` | 施法不延迟自动射击 | ✓ | ✓ | `[rangedclip:瞄准射击>0.5]` | SP_SwingTimer |
| `rangedtimer`/`rtimer` | 远程自动射击进度% | ✓ | ✓ | `[rangedtimer:>80]` | SP_SwingTimer |
| `rawhp` | 目标血量绝对值 | ✓ | ✓ | `[rawhp:<500]` | |
| `rawpower` | 目标能量绝对值 | ✓ | ✓ | `[rawpower:>500]` | |
| `reactive`/`react` | 反应技能可用 | ✓ | — | `[reactive:压制]` | |
| `resisted` | 上次被目标抵抗 | ✓ | ✓ | `[resisted:full:献祭]` | |
| `samespell` | 动作与上次施法相同 | ✓ | — | `[samespell]` | |
| `slamclip` 系列 | 猛击平砍剪断窗口 | ✓ | ✓ | `[noslamclip]` | SP_SwingTimer |
| `spelltargetnum` | 对目标施法的单位数 | — | ✓ | `[spelltargetnum:>1][spelltargetnum:harm>2]` | |
| `swingtimer`/`stimer` | 平砍进度百分比 | ✓ | ✓ | `[swingtimer:>80]` | SP_SwingTimer |
| `tag` | 目标已被标记 | ✓ | — | `[tag]` | |
| `threat` | 玩家仇恨百分比 | ✓ | ✓ | `[threat:>80]` | TWThreat |
| `true target` | 设真正施法目标 | — | — | `[truetarget:cont]` | |
| `ttk` | 击杀时间 | ✓ | ✓ | `[ttk:<10]` | TimeToKill |
| `tte` | 到斩杀线时间 | ✓ | ✓ | `[tte:<5]` | TimeToKill |
| `type` | 目标生物类型 | ✓ | ✓ | `[type:亡灵/恶魔]` | |
| `usable` | 技能/物品可用 | ✓ | ✓ | `[usable:火球术][usable:治疗药水]` | |
| `woundednum` | 受伤成员数 | — | ✓ | `[woundednum:party2>30]` | |
| `zone` | 所在区域 | ✓ | ✓ | `[zone:暴风城]` | |

### 队伍 / 团队条件

| 条件 | 描述 | 否定 | 多值 | 示例 | 插件 |
|------|------|:----:|:----:|------|------|
| `group` | 玩家在队伍类型中 | ✓ | ✓ | `[group:party/raid]` | |
| `nogroup` | 玩家不处于队伍中 | — | ✓ | `[nogroup:raid]` | |
| `raidnum` | 团队范围内存活人数 | — | ✓ | `[raidnum:dst30>3]` | UnitXP |
| `partynum` | 队伍范围内存活人数 | — | ✓ | `[partynum:dst20>2]` | UnitXP |
| `mostwoundedgroup` | 受伤最重小队 | — | ✓ | `[mostwoundedgroup:lost500>=2]` | |

### 宠物条件

| 条件 | 描述 | 否定 | 多值 | 示例 | 插件 |
|------|------|:----:|:----:|------|------|
| `pet` | 有宠物/宠物类型 | ✓ | ✓ | `[pet][pet:猫科]` | |
| `petalive` | 宠物存活 | ✓ | — | `[petalive]` | |
| `petbuff` | 宠物有该 buff | ✓ | ✓ | `[petbuff:嗜血]` | |
| `petcc` | 宠物受控场 | ✓ | ✓ | `[petcc:stun/fear]` | |
| `petcd`/`petcooldown` | 宠物技能冷却 | ✓ | ✓ | `[petcd:Growl<5][petcd]` | |
| `petdebuff` | 宠物有该 debuff | ✓ | ✓ | `[petdebuff:破甲]` | |
| `petdead` | 宠物死亡 | ✓ | — | `[petdead]` | |
| `pethappiness` | 宠物快乐度 | — | ✓ | `[pethappiness:<50]` | |
| `pethp` | 宠物血量百分比 | — | ✓ | `[pethp:<30]` | |
| `pethplost` | 宠物损失血量 | — | ✓ | `[pethplost:>100]` | |
| `petknown` | 宠物已学会技能 | ✓ | ✓ | `[petknown:撕咬]` | |
| `petlevel` | 宠物等级 | — | ✓ | `[petlevel:>50]` | |
| `petpower` | 宠物能量百分比 | — | ✓ | `[petpower:>50]` | |
| `petpowerlost` | 宠物损失能量 | — | ✓ | `[petpowerlost:>100]` | |
| `petrawhp` | 宠物血量绝对值 | — | ✓ | `[petrawhp:<500]` | |
| `petrawpower` | 宠物能量绝对值 | — | ✓ | `[petrawpower:>500]` | |

### 物品 / 装备条件

| 条件 | 描述 | 否定 | 多值 | 示例 | 插件 |
|------|------|:----:|:----:|------|------|
| `durability` | 装备部位耐久% | — | ✓ | `[durability:Head<50]` | |
| `equipped`/`eq` | 已装备物品/武器类型 | ✓ | ✓ | `[equipped:匕首/剑]` | |
| `inbag` | 物品在背包/已装备 | ✓ | ✓ | `[inbag:治疗药水][inbag:梦境之尘<12]` | |
| `set` | 套装件数比较 | ✓ | ✓ | `[set:审判者战甲>=3]` | Reliquary |
| `setscan` | StatScanner 套装件数 | ✓ | ✓ | `[setscan:套装名>2]` | StatScanner |

### 战斗状态条件

| 条件 | 描述 | 否定 | 多值 | 示例 | 插件 |
|------|------|:----:|:----:|------|------|
| `bg` | 战场/竞技场中 | ✓ | — | `[bg]` | |
| `combat`/`ic`/`ooc` | 战斗/脱战 | ✓ | ✓ | `[combat][combat:target]` | |
| `cursor` | 光标上有拖拽物（物品/技能/宏图标） | ✓ | — | `[cursor][nocursor]` | 经 CursorHasItem/Spell/Macro 间接实现 |
| `dead` | 目标死亡 | ✓ | — | `[dead]` | |
| `bonusbar` | 临时动作条显示中（潜行/形态/姿态） | ✓ | ✓ | `[bonusbar][bonusbar:2]` | 经 BonusActionBarFrame:IsShown；`:n` 映射形态序号 |
| `flying` | 飞行中 | ✓ | — | `[flying]` | |
| `indoor` | 室内 | ✓ | — | `[indoor]` | SuperWoW/UnitXP；`indoors` 为正式服拼法别名 |
| `moving`/`mv` | 移动中/速度 | ✓ | ✓ | `[moving][moving:>100]` | MonkeySpeed |
| `outdoor` | 室外 | ✓ | — | `[outdoor]` | SuperWoW/UnitXP；`outdoors` 为正式服拼法别名 |
| `resting` | 休息中 | ✓ | — | `[resting]` | |
| `rooted` | 定身中 | ✓ | — | `[rooted]` | v2.36 |
| `stealth` | 潜行中 | ✓ | — | `[stealth]` | |
| `swimming` | 游泳中 | ✓ | — | `[swimming]` | v2.36 |

### 标记 / 集火条件

| 条件 | 描述 | 否定 | 多值 | 示例 |
|------|------|:----:|:----:|------|
| `gettag` | 读自定义标签 | ✓ | — | `[gettag:标签名]` |
| `mark` | 团队标记 | ✓ | ✓ | `[mark:skull][mark:star]` |
| `mytag` | 目标被我标记 | ✓ | — | `[mytag]` |
| `notarget` | 当前无选中目标 | — | — | `[notarget]` |
| `othertag` | 目标被他人标记 | ✓ | — | `[othertag]` |
| `tag` | 目标已被标记 | ✓ | — | `[tag]` |

### 其它 / 特殊条件

| 条件 | 描述 | 否定 | 多值 | 示例 | 插件 |
|------|------|:----:|:----:|------|------|
| `func` | 执行自定义条件函数 | ✓ | — | `[func:函数名]` | |
| `message` | 匹配玩家消息 | — | ✓ | `[message:治疗我]` | |
| `mpowa` | MPOWA 组激活 | ✓ | ✓ | `[mpowa:5][nompowa:1/2]` | MPOWA |
| `queuedspell`/`queued` | 有排队技能 | ✓ | ✓ | `[queuedspell:火球术]` | |

> **连发防护（结果确认门）**：`nobuff`/`nomybuff`/`nodebuff`/`nomydot`/`nocursive` 等"缺失"判定会检查结果确认门——施法出手后、命中/抵抗结果事件（SPELL_DAMAGE / AURA_CAST / SPELL_MISS）到达前的 0.1 秒窗口内挂起判定，避免 Nampower 排队机制连出两发。

---

## 进阶用法

### 条件宏示例

```lua
#showtooltip [known:超越之力]超越之力;[noknown:超越之力]灼热之痛
/cast [known:超越之力]超越之力
/cast [noknown:超越之力]灼热之痛
```

```lua
/cast [nomydot:献祭]献祭
/cast 暗影箭
```

### #show 元命令

`#show`（正式服语法）仅指定动作条图标，不指定悬浮提示内容（1.12 提示文本仍由游戏按宏名显示）。与 `#showtooltip`/`#showtooltips` 一样写在宏首行，支持带参数（技能/物品名或条件列表）；无参数时自动取宏内第一个动作的图标。

```lua
#show 火球术
/castsequence 火球术, 烈焰风暴
```

注意：`#showtooltip` 的图标与提示内容一致；`#show` 只影响图标（1.12 引擎限制）。

### 特殊单位目标

| 目标 | 说明 |
|------|------|
| `@cursor` | 鼠标指向 |
| `@none` | 正式服语法：中断自动自我施放、强制出现瞄准光标（目标型法术需手动选目标） |
| `@cursive` | Cursive 跟踪列表中第一个满足条件的单位 |
| `@mostwounded` / `@mostwoundedparty` / `@mostwoundedraid` | 掉血最多者 |
| `@filter` / `@filterparty` / `@filterraid` | 第一个满足条件者 |
| `@inherit` | 继承上次宏目标（`MacroTarget`） |
| `@focus` / `@focustarget` | 焦点目标 |
| `@fov`（别名 `@farthestinfov`） | 瞄准射击选目标：视野内**直线穿透最多敌人**的敌对目标；无结果则回退当前目标（需 UnitXP_SP3_X 版）。例：`/cast [@fov] 瞄准射击` |

| `@tar` / `@tartar` / `@mouse` / `@cur` / `@fo` | 依次为 `@target` / `@targettarget` / `@mouseover` / `@cursor` / `@focus` 的简写（当前目标 / 目标的目标 / 鼠标指向 / 鼠标位置 / 焦点） |

---

## 配置命令说明

输入 `/cleveroid` 查看当前设置与全部可用子命令。

### 基础配置

| 子命令 | 说明 |
|--------|------|
| `realtime 0\|1` | 强制实时更新（非事件驱动，1=开，增加 CPU 负载） |
| `refresh X` | 刷新频率（1–10 次/秒，默认 10） |
| `macrocheck 0\|1` | 启用/禁用宏语法检查器（默认 1） |
| `debug [0\|1]` | 切换学习/调试消息（不带参数则翻转） |
| `projectilespeed 10-40`（`ps`） | 远程技能弹道飞行速度（默认 25） |
| `fov [cone 2-10] [range]` | `@fov` 的视野锥与最大距离（默认 `2` / `41`） |
| `clip <1\|2\|3>` | 引导打断模式（默认 `2`）：`1`=不打断；`2`=仅"引导计时行"、且技能可施放时打断；`3`=条件通过即打断 |
| `overflowframe on\|off` | 启用/禁用玩家溢出增益框体 |
| `overflowtest` | 溢出框体测试模式 |
| `overflowreset` | 重置溢出框体位置 |
| `immunitylearn <0\|1>`（`ilearn`） | 免疫自动学习开关（默认 `0`=关，使用内置免疫表；`1`=开） |

> 引导打断仅作用于玩家施法（`/cast`、`/castsequence`、`/castrandom`），不影响 `/use` 与宠物；"明显不可能成功"（目标缺失/死亡/超范围）的行不打断。

### 学习 / 施法时长

| 子命令 | 说明 |
|--------|------|
| `learn <spellID> <duration>` | 手动设置技能持续时间 |
| `forget <spellID\|all>`（`unlearn`） | 遗忘已学习的技能时长 |

### 法术学校追踪

| 子命令 | 说明 |
|--------|------|
| `listschools`（`schools`） | 列出所有已学习法术学校 |
| `clearschools` | 清空法术学校数据 |

### 免疫追踪

| 子命令 | 说明 |
|--------|------|
| `listimmune [school]`（`immunelist`） | 列出免疫数据 |
| `clearimmune [school]` | 清空免疫数据 |
| `addimmune "<NPC>" <school> [buff]` | 手动添加免疫 |
| `removeimmune "<NPC>" <school>` | 移除免疫 |
| `listccimmune [type]`（`ccimmunelist`） | 列出 CC 免疫数据 |
| `clearccimmune [type]` | 清空 CC 免疫数据 |
| `addccimmune "<NPC>" <type> [buff]` | 添加 CC 免疫（stun/fear/root/silence/sleep/charm/polymorph/banish/horror/disorient/snare） |
| `removeccimmune "<NPC>" <type>` | 移除 CC 免疫 |

> 内置全量生物免疫表（伤害学派 + 控制），`[immune:火]` / `[cc:晕眩]` 等即时命中。
>
> **优先级**：手动添加（`addimmune`/`addccimmune`）与自动学习记录 > 内置表；无记录时才查内置表。`removeimmune` / `removeccimmune` 可覆盖（屏蔽）内置表条目。

### 连击点

| 子命令 | 说明 |
|--------|------|
| `combotrack`（`combo`） | 显示连击点追踪信息 |
| `comboclear` | 清空连击点追踪数据 |
| `combolearn`（`combodurations`） | 显示已学习的连击技能时长 |

### 天赋

| 子命令 | 说明 |
|--------|------|
| `talenttabs`（`tabs`） | 显示当前职业天赋页 ID |
| `listtab <tab>`（`tab`） | 列出指定天赋页全部天赋 |
| `talents`（`talent`） | 显示当前天赋等级 |
| `testtalent <spellID>`（`talenttest`） | 测试某技能的天赋修正值 |
| `talentsave <编号1-8> [套装名称]` | 保存当前天赋为套装 |
| `talentdelete <编号>`（`talentdel`） | 删除天赋套装 |
| `talentlist` | 列出已保存的天赋套装 |

### 事件宏（独立实现，无需 SuperMacro）

| 子命令 | 说明 |
|--------|------|
| `eventmacroadd 宏名 超级宏标记(0\|1) 事件1,事件2` | 注册事件宏（静默幂等：仅首次注册提示，重复执行不弹消息） |
| `eventmacrodel 宏名 超级宏标记 [事件1,事件2]` | 注销事件宏 |
| `eventmacrolist` | 列出已注册的事件宏 |

> 事件宏由插件内置的 EventMacros 扩展模块独立实现（`Extensions\EventMacros.lua`），
> 不再依赖 SuperMacro。普通宏经 CRM 执行链按宏名执行（支持条件语法与增强命令）；
> 超级宏标记为 1 时若 SuperMacro 在场则走其 `RunSuperMacro`（完整超级宏语义），
> 未安装 SuperMacro 时回退 CRM 执行链。事件注册为运行时状态，每次登录需重新注册
> （与 SuperMacro 原版行为一致）。未安装 SuperMacro 时本模块还会提供同名全局
> `RegisterEventMacro`/`UnregisterEventMacro`，保证既有初始化脚本无需改动。

### 调试

| 子命令 | 说明 |
|--------|------|
| `debuffdebug [spell]`（`debuff`/`trackdebug`） | 调试目标上的 debuff 追踪 |
| `tankdebug` | 调试 pfUI 坦克目标条件 |
| `auradebug`（`bufftracking`） | 调试全施法者光环时间追踪 |

### 扩展子命令（Cursive）

| 子命令 | 说明 |
|--------|------|
| `cursive list` | 列出自定义诅咒法术及状态 |
| `cursive add <spellID> <duration> [name]` | 添加自定义法术 |
| `cursive remove <spellID>` | 移除自定义法术 |
| `cursive inject` | 强制重新注入 |
| `cursive debugseal` | 扫描圣印 buff |

---

## 功能模块

| 模块 | 说明 |
|------|------|
| **连击点追踪** | 记录消耗 N 连击点的时长缩放技能（割裂/凿击/撕扯），支持 Carnage 天赋联动与持久学习 |
| **免疫数据库** | 自动学习 NPC 的伤害系免疫与 CC 免疫（DBC 权威），PVP 玩家目标永不记录；`[immune]`/`[cc]` 数据源 |
| **抵抗状态** | `SPELL_MISS_SELF` 记录完整/部分抵抗，`[resisted]`/`[noresisted]` 数据源 |
| **debuff 精确计时** | libdebuff 集成，与 pfUI 7.4.3+/7.6+ 深度共享，自动学习法术时长 |
| **三大索引** | `IndexSpells`（法术书）/ `IndexTalents`（天赋）/ `IndexItems`（背包/装备） |
| **宏解析缓存** | `ParseMacro`/`ParseMsg`/`GetParsedMsg`（FIFO 200），`UPDATE_MACROS` 全量重建 |
| **动作条追踪** | `GetActionTexture`（条件化图标）/ `GetActionCooldown`（冷却）/ `GetActionCount`（计数）三大 hook |
| **特殊单位解析** | `@cursor`/`@cursive`/`@mostwounded`/`@filter`/`@inherit`/`@focus`/`@fov` |
| **施法状态追踪** | `CurrentSpell` 维护 cast/channeled/GCD，0.1s 看门狗防卡死 |
| **战斗日志解析** | 统一派发 5 个解析器（debuff 时长/免疫/隐藏 CC/反应技能/抵抗） |
| **结果确认门** | 出手→命中/抵抗/AURA 落地事件驱动的防连发机制 |
| **延迟数据源** | `[delay]`/`[unitdelay]` 基于施法出手时刻的目标级延迟门 |

---

## 兼容层与扩展

### 兼容层（Compatibility）

| 模块 | 作用 |
|------|------|
| **Bongos** | Bongos 动作条适配：按钮全量刷新 + 冷却修复 |
| **pfUI** | 深度适配：libdebuff 集成、动作条冷却同步、`/use`/`/equip` 条件支持、条件化技能 API |
| **SuperMacro** | hook `RunLine` 逐行拦截 CRM 命令转发、宏起始清停止标志 |
| **UltimaMacros** | hook `UM_RunLine`/`UM_Run` + 动态图标刷新 |

### 扩展（Extensions）

| 模块 | 作用 |
|------|------|
| **MacroLengthWarn** | 宏长度警告（最大 261 字符，超长阻止保存） |
| **MacroErrorUI** | 宏错误检查 UI（错误汇总面板、出错行高亮、白名单 GUI） |
| **EventMacros** | 独立事件宏系统（`eventmacroadd/del/list`，无需 SuperMacro） |
| **OverflowBuffFrame** | 32+ buff 溢出显示（玩家/目标的服务器端溢出 buff） |
| **CursiveCustomSpells** | 向 Cursive 注入 200+ 自定义法术定义（含 darkHarvest 元字段） |
| **Tooltip\Generic** | 工具提示扫描中枢 + 索引中枢 |

---

## 鼠标悬停支持

通过统一的鼠标悬停来源优先级系统（单位框插件 > 原生 > 工具提示兜底）支持 `[@mouseover,...]`。支持插件：

pfUI · Grid · LunaUnitFrames（原生集成）· XPerl · CT_RaidAssist · CT_UnitFrames · DiscordUnitFrames · sRaidFrames · PerfectRaid · ag_UnitFrames · Blizzard 原生 · FocusFrame · GameTooltip 兜底 · EGD · NotGrid · Cursive DoT 条 · Dragonflight3 · DragonflightReloaded

---

## 其他插件集成

| 插件 | 集成点 |
|------|--------|
| **SP_SwingTimer** | `[swingtimer]`/`[rangedtimer]`/`[slamclip]` 系列 |
| **TWThreat** | `[threat]`/`[nothreat]`（解析 `TWTv4=` 威胁包） |
| **TimeToKill** | `[ttk]`/`[tte]`（未装时内置估算） |
| **QuickHeal** | `/quickheal`/`/qh` 智能治疗 |
| **Cursive** | `[cursive]`/`[mydot]`/`[nomydot]`/`[mydotcount]` 数据源 + 自定义法术注入 |
| **MonkeySpeed** | `[moving]` 速度判定（优先级：MonkeySpeed → Nampower PlayerIsMoving → 位置历史兜底） |
| **SuperMacro** | 兼容层 RunLine 拦截 |
| **pfUI** | 兼容层 + 鼠标悬停 + libdebuff 共享 |
| **Heart (Heal)** | `/rh` 快速治疗（mw/a/ms 模式） |
| **Reliquary** | `[set]` 套装件数按名查询 |
| **MPOWA** | `[mpowa]`/`[nompowa]` 组状态 |
| **StatScanner** | `[setscan]` 套装件数 |

---

## Turtle WoW 特色机制

1. **结果确认门（防连发）**：出手→命中/抵抗/AURA 落地事件驱动，解决无弹道瞬发技能的连出两发问题（纯事件驱动，无固定等待）
2. **双天赋切换即时刷新**：`SPELLS_CHANGED` 每次立即全量重建，`[known:X]` 天赋切换后立即生效
3. **PVP 免疫学习排除**：玩家目标永不写入免疫数据库
4. **32+ buff 溢出显示**：Turtle 服务器端 buff 溢出机制
5. **Aura 上限追踪**：`[buffcapped]`/`[debuffcapped]` 条件
6. **我方召唤物追踪**：`[myunit]` 条件
7. **坐骑模式支持**：Turtle 坐骑文本适配

---

## 已知问题

- 宏名必须唯一（不允许空名/重名/与技能名相同）
- 反应技能必须放在动作条上才能被检测
- debuff 剩余时间条件默认只对自己施加的 debuff 有效（除非 pfUI libdebuff 或 Cursive 提供数据）
- 宏行最大 261 字符（MacroLengthWarn 扩展防止崩溃）

---

## 致谢

基于 [CleverMacro](https://github.com/DanielAdolfsson/CleverMacro) 与 [Roid-Macros](https://github.com/DennisWG/Roid-Macros) 开发。

MIT License
