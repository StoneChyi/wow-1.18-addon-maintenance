# PallyPower 项目长期笔记

## 校验工具链（重要）
- luaparse（Node）对本目录带 BOM/中文注释的 .lua 会报内部错 `Cannot read properties of undefined (reading 'range')`，**不可用**；连未改动的备份文件也报错。
- 可靠方案：fengari（真 Lua VM，位于 `C:/Users/Administrator/.workbuddy/binaries/node/workspace/node_modules`，需 NODE_PATH）`luaL_loadbuffer` 语法校验，先 `replace(/^\uFEFF/,'')` 剥离 UTF-8 BOM 再解析，否则报 `unexpected symbol near '<\239>'`。注意 `to_luastring` 在 fengari 主模块（`fengari.to_luastring`），`luaL_loadbuffer` 在 `fengari.lauxlib` 子模块。
- **现成校验脚本**：`.workbuddy/lua_check.js`（fengari 语法校验，收文件列表参数）；`.workbuddy/sim_solo.js`（单人模式整文件仿真，含 WoW API 桩 + mkframe frame 桩，40 条断言，改 UpdateUI/SoloBar 相关代码后可直接改场景复跑）。XML 校验：Python `xml.etree.ElementTree.parse`。
- fengari 仿真注意：Lua 5.3 严格 `%d` 拒绝浮点（游戏 5.0 会截断）→ 桩里包装 string.format 对含 %d 的 fmt 做 floor；`table.getn`/`unpack`/`GetLocale` 都要桩。

## 项目约定
- 修改 `PallyPower.lua` / `PallyPower.xml` 前，先复制到 `backup/` 加时间戳后缀。
- 原版图标备份在 `D:\MHTUI 整合包（26.6.28日更新）\Interface\AddOns\PallyPower\Icons\`（含 Pet.tga）。

## 2026-09-27 职业图标
- 职业图标已全部换为 ShaguDPS 同款图集 `Icons\classicons.blp` + SetTexCoord（坐标抄自 ShaguDPS window.lua classIcons 表）。
- **图集含宠物爪印图标**（用户确认）：实际为 512x512 DXT5、8x8 网格每格 64px（ShaguDPS 注释写 256 是错的，坐标归一化后通用）。爪印位于 r3c1，坐标 `{0.125, 0.247, 0.375, 0.498}`（亮绿色，最亮像素 198,255,198）。
- class 9（宠物）也从图集取，`Icons\Pet.tga` 已删除（原版备份仍在 MHTUI 整合包）。
- 核心入口：`PallyPower_SetClassIcon(tex, class)`（lua ~69 行）；表头在 `PallyPower_OnLoad`，BuffBar 行在 `PallyPower_UpdateUI`。
- 职业顺序：0战士 1盗贼 2牧师 3德鲁伊 4骑士 5猎人 6法师 7术士 8萨满 9宠物。
- 图集共 17 个非空格子：9 职业 + 宠物爪印 + 7 个未知内容（r0c4、r2c2、r2c3、r3c0、r3c2、r3c3 等，如后续要加图标可再解码定位）。

## 2026-09-28 单人模式（v1.075 → 09-29 重构 v1.077，完全照抄 D:\HolyHope）
- **UI 已改为 HolyHope 宝珠式**：中央宝珠（Button `PallyPowerSoloBar` 58x58，NormalTexture=`UI\Symbol32.tga`）+ 6 个环形按钮（`PallyPowerSoloBarButton1..6` 40x40，parent=宝珠，布局偏移照抄：力量(17,42)/智慧(-17,42)/拯救(-42,17)/光明(42,17)/王者(42,-17)/庇护(-42,-17)）。 HolyHope 的 64 个自定义 tga 贴图已复制到 `PallyPower\UI\`。
- **交互（HolyHope 式）**：点宝珠左键切换「小祝福(10分钟)/大祝福(30分钟)」组——按钮贴图 Might.tga↔MightUp.tga（高亮=+2 后缀）同步换、未学的组隐藏按钮（`PP_PerUser.soloGreater` 0/1，默认小祝福组，不随 10/30 分钟全局选项影响）；点按钮直接施放最高等级（有友方目标给目标、否则给自己，敌对目标 ClearTarget→施放→TargetLastTarget 恢复）；拖宝珠移动；右键宝珠开主窗口（替代 HolyHope 的炉石）；tooltip 用 `GameTooltip:SetSpell(spellId, BOOKTYPE_SPELL)` 显示真实法术提示。无着色/倒计时（HolyHope 无此功能）。
- **v1.080 符印环 / 战斗红珠（v1.086 现行）**：`PallyPower_Solo_UpdateOrbTexture()`——**战斗中（PLAYER_REGEN_DISABLED/ENABLED → `PP_SoloInCombat`）整珠换红色 `HolyHopeC.tga`**；脱战按 `AllPallys[player]["symbols"]`（ScanInventory 统计的王者符印数）换 Symbol0..32.tga，**每 10 个一段、32 段封顶**（320 满环、0 空环，换算照抄 HolyHope）。SoloBar_Update 开头调用。**注意：v1.083/1.084 的战斗血量环（含染红、中心 HPText 百分比）已应用户要求在 v1.086 整体撤回，勿再恢复**。
- **v1.081 滚轮缩放**：`PallyPowerSoloBar_OnMouseWheel(delta)` 每 0.1 一格、0.5~2.0 限幅，临时设 `PallyPower.FrameToScale` 后调 `PallyPower_ScaleFrame`（保持左上角不动 + 存 scalesolo）；宝珠与环形按钮模板都 EnableMouseWheel。**⚠️ 2026-09-29 修正（v1.088）**：1.12 XML OnMouseWheel 脚本里滚轮值是 **`arg1`（上滚 +1 / 下滚 -1），没有全局 `delta`**——旧记录"用全局 delta"是错的，导致 delta 恒 nil、`if delta and delta > 0` 永不成立，两个方向都走缩小分支（用户实测"只会缩小不会放大"）。XML 两处已改为 `PallyPowerSoloBar_OnMouseWheel(arg1)`。
- 显示条件：无队伍/团队且是圣骑士且 PP_PerUser.solomode==1（默认开，/pp solo 切换）；PLAYER_LOGIN 补 soloGreater/scalesolo/solomode/soloForce 缺键。**v1.085 soloForce（强制单人祝福，默认 0）**：开启后组队/进团宝珠也显示——激活判定统一走 `PP_Solo_IsActive(force)`（BuffBar 让位用 force=false 严格判定；SoloBar_Update 用 force=true），强制模式下组队时 BuffBar 照常显示、仅宝珠额外出现；选项面板 `$parentSoloForce` 勾选框（y=-175）。
- 核心入口：`PP_SOLO_SLOTS`（id/偏移/贴图表）、`PallyPower_SoloBar_Update`（UpdateUI 末尾调用）、`PallyPowerSoloButton_OnClick`、宝珠 OnUpdate 驱动扫描。
- 关键函数语义：btn.spellToCast=法术书索引、btn.trackId=LastCast 键前缀（小祝福=LesserBlessingMap 映射 id 6..11）、btn.duration=600/1800。
- **注意**：早期 v1.075 的竖排 SoloBar（Solo1..6 行式按钮、着色倒计时）已废弃删除，相关代码/断言不要复用；仿真脚本 sim_solo.js 已按宝珠式重写（47 断言）。
- **v1.078 补倒计时 / v1.079 修残留 / v1.087 真实剩余时间**：环形按钮模板加 OVERLAY FontString `$parentTime`（BOTTOM 居中）；`PallyPower_SoloBar_Update` 每次刷新——**必须先确认 buff 在身**（`CurrentBuffs[4]["player"][slot.id]`，小/大祝福折叠同 id）：剩余时间优先 `PP_Solo_ScanPlayerBuffTimeLeft()[slot.id]`（**v1.087：GetPlayerBuff/GetPlayerBuffTexture/GetPlayerBuffTimeLeft 扫自身真实 buff 剩余，手动加的也能显示**），无则 LastCast[trackId..4]，再无显示「已加」、buff 不在身一律空（v1.079 教训：只看 LastCast 会残留）；tooltip（SetSpell 后）附加剩余时间行，同样优先真实时间。FormatTime 为 floor 取整、分钟不补零（1799→"29:59"、300→"5:00"）。

## 2026-09-29 主界面「10分钟祝福」勾选框（v1.087）
- 需求：小号练级组队时，主分配界面（`PallyPowerFrame`，即截图的格子窗口）直接勾选刷 10 分钟小祝福。
- **新增**：主窗口 `$parentOptions` 按钮后 `TenMinBlessingMainChk` 勾选框（BOTTOMLEFT 8,5，标签 `PALLYPOWER_TENMIN_SHORT`="10分钟祝福"）→ OnClick `PallyPower_ToggleTenMinBlessing()`：翻转 TenMinuteBlessingOn/TenMinBlessing → SwapIcons → **PallyPower_ScanSpells() 重扫（免 ReloadUI，AllPallys[player]=RankInfo 重赋）** → UpdateUI，两勾选框（主界面 + 选项面板 `TenMinBlessingChk`）互相同步。
- **既有机制（勿重造）**：TenMinBlessing=true 时 ScanSpells 把 0..5 扫成不带"强效"前缀的小祝福（左键即小祝福）；false 时扫强效。右键格子恒为施放小祝福（`PallyPower_CastLesserBlessing`，LesserBlessingMap 0..5→6..11）。`TenMinuteBlessingOn` 是 SavedVariablesPerCharacter（.toc 第 8 行）。格子 tooltip 按 TenMinBlessing 分支显示时长。
- 备份 backup/*.20260929_tenmin；fengari 语法 OK + XML OK。**踩坑**：Edit 工具可能出现"锚点/内容写错仍报成功"，XML 编辑后必须 Grep+Read 核实实际落点。

## Lua 5.0 复用表 concat 崩溃（2026-09-29 修复，通用坑）
- **Lua 5.0 把键置 nil 不重置表内部长度**（getn/concat 用 setn 存储值）→ 复用表"清空+重插"后 concat 必报 "table contains non-strings"。`PP_WipeTable` 已补 `if table.setn then table.setn(t,0) end`（fengari 5.3 无 setn，guard 跳过）。以后任何"清空复用表"都要走 PP_WipeTable，不要手写置 nil。
- tooltip 名单拼接统一走 `PP_SafeConcat`（过滤非 string/number）；`stats["name"]` 可能 nil，填充一律 `or member` 兜底。备份 backup/PallyPower.lua.20260929_fix_concat。（注：此修复当时漏 bump 版本号，实际随 v1.088 一同生效。）

## v1.088 滚轮只缩不放修复（2026-09-29）
- 现象：宝珠上滚轮只会缩小不会放大。根因：XML OnMouseWheel 传了不存在的全局 `delta`（恒 nil）→ 上滚分支 `delta > 0` 永不成立，双向都缩小。
- 修复：PallyPower.xml 行 164（环形按钮模板）+ 行 728（宝珠）改传 `arg1`；Lua 端函数签名不变（上滚 +1 → 放大 0.1）。备份 backup/*.20260929_wheel；XML ElementTree 校验 OK。**教训：1.12 XML 事件处理器一律用 arg1..argN，不要想当然用 TBC 以后的 `delta` 全局名；原版代码 PallyPowerGridButton_OnMouseWheel 就是 arg1 == -1 判下滚。**

## BLP 解码要点（本项目实测）
- 本图集 BLP2 头：compression=1、alphaDepth=2、alphaEnc=8 → 实际按 **DXT5** 解码才正确（DXT1/DXT3 解出全 64 格有内容=错误）。判定依据：mip0 size=262144=512x512 → 16 字节/块 → DXT3/5；DXT3 解码 64 格全满，DXT5 解出稀疏 17 格=合理。
- 可复用解码脚本思路在 2026-09-27 日报对应会话中验证过（纯 Python 无 PIL 可跑）。
