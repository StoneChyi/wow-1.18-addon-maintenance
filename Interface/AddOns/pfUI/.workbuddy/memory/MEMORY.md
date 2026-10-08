# pfUI / WoW 1.12 Turtle（SuperWoW + Nampower v4.6.1）开发守则

> 只放长期不变量；细节见 `memory/YYYY-MM-DD.md`，可复用流程见 `~/.workbuddy/skills/`
> （`wow-112-api-compat` / `pfui-*` / `wow112-*`）。

## Lua 5.0（最高优先）
- 禁 `#`（`table.getn`）、`//`、goto、二元 `%`（`math.mod`）。
  ⚠️ **string.match/gmatch 修正（2026-09-29 实证）**：旧结论"string 表无 match/gmatch"对本客户端**过严**——buff.lua GetSepList、actionbar 监控导入导出、gui 配置面板大量在用且实测正常。写新代码用 `string.find` 捕获仍最稳，但**不要把在用的 gmatch 当 bug 去"修"**。`math.pow`（share.lua）本客户端 5.0 可用，但 fengari 5.3 离线仿真会炸——要仿真的文件用 `^` 代替。
- ⛔ 生产代码只能用 **5.0 与 5.3 的公共子集**（离线仿真是 fengari = 5.3）：`math.pow` 在 5.3 **已移除**
  ⇒ 幂运算一律用 `^`（5.0/5.3 都有）。`math.mod` / `table.getn` 由仿真桩补丁，可放心用。
- `x:Foo and …` 非法 → `(x.Foo and x:Foo()) or nil` 或 `pcall(x.Foo, x, …)`。
- ⛔ **一个语法错 = 整文件静默不加载**（先看 `Logs\FrameXML.log`）→ 改完必跑语法检查
  （luaparse 5.1；脚本在 `C:\Users\Administrator\.workbuddy\binaries\node\workspace\` 下的 check*.js，
  pfUI\.workbuddy 里**没有** check_lua5.js（2026-09-29 实证）；最稳是一行内联
  `node -e "require('luaparse').parse(src,{luaVersion:'5.1'})"`）+ upvalue 检查（上限 32；工具数值低估，只看"同一函数前后是否上升"）。
- ⛔ **变量大小写笔误 = 条件恒 nil 走错分支**（2026-09-18 Trainer.lua 实例：`CurrentOnEnterScript` vs `currentOnEnterScript` ⇒ 永远走 else，把 pfUI 的 Minimap OnEnter/OnLeave 整个覆盖掉）。复验 grep 时把大小写当检查点。
- ⛔ **跨插件抢占 frame 脚本**：后加载/晚事件（VARIABLES_LOADED 晚于所有 ADDON_LOADED）方用 `SetScript` 会整体覆盖先注册方——必须链式（GetScript 存 prev，再闭包先调 prev）；pfUI 全局 `HookScript` 就是链式安全版。
- ⛔ 大文件核心闭包常年贴线 → 新代码**净增 0 upvalue**（挂已有表字段，别加文件级 local）。libdebuff 的 OnEvent 闭包现为 **30**。
- ⛔ `Edit` 会"报 success 却没改" → 每处改动 grep 点名复验。
- ⛔ bash 工具常整环境损坏（PATH 被剥空）→ 用 PowerShell + 绝对路径 node 跑脚本，输出 `Set-Content -Encoding UTF8` 落盘再 Read
  （`*>`/`Out-File` 是 UTF-16）；沙箱 sim 会把文件级 local 变全局。

## 客户端 API 差异（细节全在 skill `wow-112-api-compat`）
- ⛔ 最容易再犯的几条：隐藏/未布局 frame 的 `GetLeft/Top/Right/Bottom/Center`、`GetStringWidth/Height` 全 nil
  （测量只在 `OnShow` 后）；两套索引语义（`GetUnitField` 原始槽位 vs 原生紧凑索引）混用必出 `A B A B` 重复图标；
  FontString 缺 `SetWidth` = 宽度 0 → 逐字换行；宽度偏小 → 省略号截断（`120m`→`10…`）→ 按**字号**给
  `font*3.2` + `SetNonSpaceWrap(false)`（详见 skill 第 10 条）。
- ⛔ `UnitBuff/UnitDebuff` 只对 `"player"` 有效 → 读任意单位光环只有 `GetUnitField(guid,"aura")`
  （1-32 buff / 33-48 debuff，**带空洞**，取不到只跳过本槽、绝不 break）。
- ⛔ `GetPoint()` 不可信、永不喂 `SetPoint`（读用 `GetLeft/Top/…`）；`L["debuffs"]` 是「名称→时长」表、不是语义表。
- ⛔⛔ **凡是"会随战斗状态翻转"的条件都不能直接当判据**（目标框「溢出 debuff」归类同理）：16 槽全满这种
  门槛必须做成**单调闩锁**（`libdebuff.overflowLatch`，只置位不清位）—— 瞬时门槛随 DoT 到期翻转
  ⇒ 同一批图标在 buff 行/debuff 行之间**整批跑动**。停用开关 `/libdebugstats overflow always|never|auto`
  （存 `debugStats.overflowMode`，已是热函数 upvalue ⇒ 零 upvalue）。
- ⛔⛔ **"33-48 满才溢出"这个前提是错的**：日志里 debuff 槽只占 **14/16** 而 aura 1-3 已是 DoT
  ⇒ 溢出后客户端**不会把 debuff 搬回 33-48**，33-48 里的 DoT 到期只留空洞 ⇒ **数组位置不是可靠的增益/减益判据**。
- ⛔⛔ **`GetUnitField(guid,"auraFlags")` 已解出（2026-09-14，三份快照逐槽零误差）**：
  它是 **6 个 uint32**，每块 8 槽 × 4bit（**每字节 2 槽、低半在前**、块内小端）——所以**必须按槽解码**
  （`libdebuff.GetSlotFlag`：块=`floor((slot-1)/8)+1`、字节=`floor(((slot-1)%8)/2)`、半字节看 `(slot-1)%2`）。
  **直接 `aflags[slot]` 拿到的是"第 slot 个块"（8 个槽挤在一个数里）⇒ 判据永远不可能命中** —— 这是"标志位
  判据装了没效果"的真因。**位义：0x8 = 减益**（减益区 16 槽全 0x8；确定友好的 命令战旗 = 0x5，故 0x8 不是"占用"标记）。
  默认开（`/libdebugstats flagbit 0` 关、reload 回默认），**不写判定表**（槽级恒定，无需闩锁、不污染单调结论）。
- ⛔ 判据现状：① `slotOwnership` ② 学习判定表 ③ **极性（实测无效：50+ 法术全是"无字段"，
  `GetSpellRec` 不暴露正负极性，DLL 里的 `positive/negative` 串不是法术记录字段）** ④ 名字库（弱证据）。
- ⛔ **诊断命令取地图必须带单位**：`GetDebuffSlotMap(guid)` 不带 unitstr ⇒ 命中"无溢出版"缓存 ⇒
  Display 列表会缺掉溢出槽，看起来像"显示层没算出来"（2026-09-14 就这么误读过一次日志）。
- ⛔ **归类必须只有一个出口**：显示层与诊断都走 `libdebuff:ClassifyAuraSlot(guid,auraSlot,spellId,overflowPossible,auraFlag)`；
  诊断里**必须分别打**「归类结论」与「显示层会不会剔除（`IsBuffSlotDebuff`）」—— 前者 DEBUFF 而后者"不剔除"
  说明是**管道问题**（缓存/索引/调用点），前者就是 buff 才说明**判据不足**，两种修法完全不同。
- ⛔ `auraFlags` / `GetSpellRecField` 这类**运行期写入的配置值**必须有 `type(x)=="number"` 守卫：
  非数字参与除法/格式化会直接抛错（仿真桩的 mock `__index` 会把任意键喂成 function，正好逼出这个真缺陷）。
- 坐标：`GetLeft` 等是"自身单位"，**UI 单位 = 自身单位 × GetScale()**；检测缓存**仅数据完整才缓存** + 进服延迟一拍；
  `SlashCmdList` 按 `func(msg)` 调（不是全局 `arg1`）。

## Nampower v4.6.1（权威 = NampowerAPI.lua）
- 事件：`BUFF/DEBUFF_ADDED|REMOVED|UPDATED_SELF|OTHER`、`AURA_CAST_ON_SELF|OTHER`、`SPELL_GO_SELF|OTHER`
  （**命中后**触发，带 numHit / numMissed / targetGuid，是最好的"生效信号"）。
- ⛔ 本地计时修正都用 SPELL_GO 命中作信号（重挂不发 DEBUFF_ADDED）：**刷新型** `startTime = now`（`RefreshTrapEffect`）；
  **消耗型** `startTime -= n`（`CutAuraTime`，燃烧扣献祭 3s）。**只动 startTime、不改 duration** → 所有
  `(startTime + duration) - now` 读取点自动全生效（含进度环）。三处表**独立**同步：`ownDebuffs` / `allAuraCasts` / `objectsByGuid`。
- ⛔ `GetUnitField` 一次调用 = 一整份 48 项表 → 循环外用 `GetAuraSnapshot` 透传（32× → 1×），别用 TTL 缓存。
- ⛔ legacy 路径（`libdebuff.objects` + `CHAT_MSG_*` 英文匹配）已**静默失效**（显示走 ownDebuffs）→ 别再往里加逻辑。
- ⛔ `BUFF_/DEBUFF_ADDED_OTHER` 的**事件名按「光环落在哪个数组」派生**（`DEBUFF_*` 的 raw 槽位注释写死 32-47）⇒
  落进 buff 区的溢出 debuff 发的是 `BUFF_ADDED_OTHER`，而 libdebuff **没注册它** ⇒ `slotOwnership` 对溢出槽
  **恒为空**（别再从"补事件"方向找权威证据）。

## 解锁 / 位置 / GUI / 姓名板
- `C.position` 存档**永远赢**代码布局；改存档前**必须完全退出游戏**（`/reload` 会写回覆盖）。
- `pfUI:UpdateConfig` 只补缺失键、**永不覆盖已有值** → 改默认值对现网角色不生效，先查 `WTF/…/SavedVariables/pfUI.lua`。
- ⛔ **配置上限 ≠ 池上限**：`debufflimit/bufflimit` 设 >32 须同步放开 `unitframes.lua` 图标池 `for i=1, 32`。
- ⛔⛔ **拖动期间一次 `SetPoint` 都不能调**（打断 StartMoving → 模块粘死）→ 拖动中只画参考线，松手才绝对定位。
- 姓名板边框色判定链（`nameplates.lua ~L1906`，前项命中即短路）：outcombatstate → unitcolors._custom → targethighlight
  → outfriendly/neutral/enemy → border.color；边框宽 `"-1"` = 回退 3px，关闭是 `"0"`。
- ⛔ tooltip 能量条显隐**只在 OnShow** 做 → 单位→招牌/物品切换常**不重触发** ⇒ 残留旧蓝条；
  守门须按「首行文本签名」在 OnUpdate 校正，**只收不放**（禁用 GetUnit 反查：玩家行有颜色码）。

## 项目习惯
- 改动前备份为**同目录** `<file>.<yyyyMMdd_HHmmss>.<主题>.bak`（不是 backup/ 子目录）；命令/注册行改后 grep 验唯一。
- 给用户留**运行期开关**二分定位（如 `/libdebugstats start`）；「看不见」先**量最亮值**；API 存在性一律诊断实测。
- ⛔ **字段"长度对不上槽数"就是打包**：Nampower 把多个槽塞进一个整数（`auraFlags` = 6×uint32，每块 8 槽×4bit），
  按槽直接索引必错。先数长度（48 槽却只有 6 个键 ⇒ 打包），再按日志里的**真实占用**反推解码模型并写成回归用例。
- ⛔ upvalue 已满的大文件里，**诊断命令内可以加 local**（Lua 上限 200 个），只有**引用文件级 local** 才 +1 upvalue
  —— 需要用到时走 `pfUI.api.<模块>` 而不是文件级 local。
