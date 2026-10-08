# BetterCharacterStats 项目长期笔记

## 架构要点

- **按需计算（on-demand）机制**：`helper.lua` 顶部 `local BCS_GET_ON_DEMAND = 1`。
  所有重量级取值函数（`GetHitRating` / `GetRangedHitRating` / `GetSpellHitRating` /
  `GetRangedCritChance` / `GetSpellCritChance` / `GetSpellPower` / `GetHealingPower` /
  `GetManaRegen` / `GetHaste` / `GetOnlyGearArmor` / `GetBlockValue`）开头统一门控：
  仅当 `BCSConfig["DropdownLeft"]` 或 `BCSConfig["DropdownRight"]`（= C 面板当前选中分页）
  命中对应分类时才真正扫描计算，否则 `return 0`。
- **绕过开关**：`BCS.ForceCalculate`（2026-09-12 引入）。独立消费者（浮动面板）在构建显示内容期间
  临时置 true 即可无视 C 面板分页取到真实数值。门控条件写作
  `if BCS_GET_ON_DEMAND and not BCS.ForceCalculate then`，新增取值函数时请沿用该写法。
- 缓存：`BCS_USE_CACHE = 1`，各取值函数缓存 1~2 秒（`GET_*_TIME` 时间戳），绕过门控不会造成逐帧重算。
- **浮动面板**：`BCS_PropertiesPanel.lua` 内 `P.frame`，显示配置来自 `BCSConfig.PropertiesPanel.displayConfig`
  （物理/法系/治疗/猎人/混伤/防御/自定义），与 C 面板左右下拉完全独立。设置入口 `/mb`，`/mb custom` 直接进自定义。
- **⛔ 浮动面板 `P.frame` 刻意不做任何皮肤、也不做高度自适应**（2026-09-12 用户反馈后回退）：
  用户要的是「纯描边文字直接浮在画面上」。pfUI 侧（`pfUI/modules/thirdparty-vanilla.lua` 的 BCS 钩子）
  曾给它套 pfUI 底板 + 28px 职业色标题条 + 包装 `P.UpdateDisplay` 做高度自适应（`30 + 行数*16 + 8`），
  已**整段移除**——现在这份 BCS 加载 pfUI 与否，`P.frame` 外观都一样。
  → 别再加底板（加了就是在文字后面露一块深色方块，用户明确不要）；也**别做按内容行数 SetHeight**：
  `P.frame` 锚点是 `CENTER`，而 title/details 锚在 frame 的 `TOPLEFT/TOP`（-10 / -30），
  改高度会按中心对称伸缩 → **整块文字上下漂移**（行数一变跳一下）。
  title/details 的字体与锚点不受 pfUI 侧影响，可以自由改。
  （2026-09-12 加 + 同日回退，细节见 pfUI/.workbuddy/memory/2026-09-12.md）
- **⚠️ `/mb` 两个配置窗口的外观（底板/按钮/字体/勾选框）同样由 pfUI 侧接管**（2026-09-12）：
  `P.mainFrame`（「属性面板」）与 `P.customFrame`（「自定义属性」）在 pfUI 的 BCS 钩子里被套上
  pfUI 底板 + 阴影、所有子按钮走 `CreateBackdrop + SetHighlight`、关闭按钮的暴雪最小化图标换成
  `pfUI.media["img:close"]`、FontString 全部换成 `pfUI.font_default`（**保留原字号**）。
  标题条**刻意不加**（职业色 20% 半透明条在明亮场景就是一条发白横带，2026-09-12 用户否掉）：
  BCS 自绘的灰条被 `StripTextures` 藏掉，标题文字直接压在窗口底板上。
  → 改这两个窗口的按钮文案/字号没问题（钩子只换字体族）；
  但**别改关闭按钮的贴图**（钩子靠 `GetTexture()=="Interface\Buttons\UI-Panel-MinimizeButton-Up"` 认它），
  也**别删 `P.customRows` / `P.customSpeedRow` / `P.mainFrame` / `P.customFrame` 这些对外字段**
  （钩子靠它们遍历）。另：勾选行是 customFrame 的子按钮，钩子靠先打 `pfBCSSkin` 标记来避免被当成普通按钮套整行边框；
  BCS 不加载 pfUI 时两个窗口回到原生灰底形态。
- **⚠️ 勾选框（`customRows` 每行的 `row.box`）已被 pfUI 侧接管**（2026-09-12）：
  钩子在行上加了 `BACKGROUND` 底色 + 4 条 `BOTTOM` 层 1px 边（手绘 pfUI 方框），并**包装了 `row.box:SetTexture`** ——
  `Interface\Buttons\UI-CheckBox-Up` 会被吞成 `nil`（未勾选时改由 pfUI 方框表示），**其它参数原样透传**。
  行上的 `UI-CheckBox-Highlight` 悬停光晕也被摘掉（悬停反馈只剩 `OnEnter` 的文字变金色）。
  → 所以：**`-Up` 贴图在本插件里已经不可见了**，不要再拿它当「未勾选」的视觉标记；
  想再换外观（比如勾选时给方框上色）就在 `Refresh()` 里改**文字颜色**或另加贴图，别指望 `-Up`。
  BCS 侧 `box` 的 14×14 / `SetPoint("LEFT", 0, 0)` 几何是钩子画方框的基准，**改尺寸要两边一起改**。
- **属性注册表（2026-09-12，自定义勾选窗口）**：文件级 `PROPERTY_LIST`（22 项，每项 `key`/`label`/`get`）
  是唯一的属性清单；`PRESET_KEYS` 定义 6 个预设的 key 序列（与旧版硬编码输出逐项一致）。
  **数组顺序 = 勾选窗口行优先阅读顺序 = 悬浮窗显示顺序，第一个勾选项为大字标题行**。
  `P:GetSelectedKeys()` 返回当前生效 key 序列（预设走 `PRESET_KEYS`，自定义按注册表过滤勾选表）；
  `P:GetPropertyText(key)` 带 `pcall` 兜底取显示串。`BuildBody` / `GetPropertiesForChat` 共用这条链路，
  新增属性只需往 `PROPERTY_LIST` 加一项 + 可选加进 `PRESET_KEYS`。
  勾选表存 `BCSConfig.PropertiesPanel.customProps`（`key → true`，`speed` 控制移速行）。
- **⛔ 不要在文件加载期读写 SavedVariables**：勾选行等 UI 元素在文件作用域创建时，`displayConfig` 还是 nil、
  `BCSConfig` 可能未就绪，此时调 `EnsureCustomProps()` 会用兜底种子污染配置。UI 外观统一延迟到
  窗口显示前（`P:RefreshCustomRows()`）刷新。仿真里有「加载期不得创建 customProps」断言防回归。
- **「角色面板」开关**（2026-09-12）：`BCSConfig.PropertiesPanel.characterPanelEnabled`（默认 true）。
  设为 false 时 `BCS:ApplyCharacterPanelState()` 会隐藏 `BetterCharacterAttributesFrame`、
  交还 `BCS.PAPERDOLL_EVENTS`（= OnLoad 里从 PaperDollFrame 注销的那 8 个事件）给 PaperDollFrame、
  并显示暴雪原生 `CharacterAttributesFrame`；`BCS:OnEvent` / `BCS:UpdateStats` 会直接 return（省掉整轮扫描）。
  PaperDollFrame 的 OnShow 被**链式接管**（保存原脚本 → 先调原脚本 → 再 `SyncCharacterPanelContent()`），
  保证每次按 C 的最终状态与开关一致。UI 入口：浮动面板「?」左边的按钮 / `/mb panel`。
  ⚠️ 尚未在客户端实测：原生 `CharacterAttributesFrame` 的位置与内容（FrameXML 在 MPQ 内读不到）。
- **浮动面板的刷新节流**（2026-09-12）：三个常量在 `BCS_PropertiesPanel.lua` 顶部
  ——`FAST_TICK = 0.2`（移速行）、`MIN_BODY_REFRESH = 1`（重建最小间隔）、`MAX_BODY_REFRESH = 5`（兜底间隔，秒）。
  分层：`P:BuildBody()` 重建属性内容（重量级，走节流）；`P:GetDisplayLines()` 判定是否重建并每次拼接移速行；
  事件只 `P:MarkDirty()`；`P:RefreshNow()` 供用户主动操作立即生效。
  `P:UpdateDisplay()` 的排版被 `appliedAlign` 守卫，只有首次/改对齐时才重设锚点。
- **⚠️ 本客户端 `SetScript("OnEvent", ...)` 回调不传参**（香草约定，事件名/参数只在全局 `event`/`arg1`）。
  新写事件处理请用 `function(self, event, arg1) if not event then event = _G.event; arg1 = _G.arg1 end ... end`
  这种双约定兼容写法，否则回调静默不工作（不报错，最难查）。
- **`GetSpellIndex`** 带 600 秒缓存（`self.spellIndexCache`），`GetSpellCastTime` 每次新建 GameTooltip。
- 大量装备属性靠扫描 `BCS_Tooltip`（隐藏 GameTooltip）逐行正则匹配中文字串，串在 `Localization.lua` 的
  `L_*` 表里；改文案时要同步正则。

## 约定

- 改 `.lua` 前先在 `backup/` 生成 `文件名.YYYYMMDD_HHMMSS` 时间戳备份。
- 改完用 luaparse（`node_modules/luaparse`，luaVersion 5.1）做语法校验。
- 涉及刷新频率/事件响应的改动，用 fengari 离线仿真跑一遍（虚拟时钟 + 手写 ticker 注册表），
  参考 `wow112-addon-lua-sim` 技能与 `node/workspace/sim_bcs_panel_0912.js` 的写法。
- **同一个文件不要在同一条消息里发多个编辑**：后一个编辑基于旧快照写回，会把前一个改动吞掉
  （表现：工具都报成功，但文件里只剩最后一处改动）。串行做，或先合并成一次编辑。
- 仿真桩里凡是被测代码按**全局名**引用的 frame（`PaperDollFrame` / `CharacterAttributesFrame` / `UIParent` …）
  必须写成 `X = CreateFrame(...)` 直接赋全局；否则代码里的 `if X and X:Method()` 或
  `pcall(function() X:Method() end)` 会把缺失静默吞掉，断言失败却毫无报错。
