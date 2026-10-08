# Automatonex 项目长期记忆

## 配置存储分层（2026-09-05 起）

- `RegisterDB("AutomatonDB", "AutomatonDBChar")`：`db.profile` = 账号共享（模块自身设置、FuBar position、moduleScope）；`db.char` = 按角色（主页配置：searchText/uiScale/moduleOrder/hiddenModules/lastModule/themeColor/windowAlpha/moduleOrderVersion，经 migratedFromProfile 一次性迁移）。
- **模块启停保存范围可切**（主页开关，2026-09-07）：`GetModuleScope()` 返回 "char"（默认，db.char.disabledModules）/ "account"（db.raw.disabledModules[profile]，AceModuleCore 原生存储）。`IsModuleActive` 按范围分支读；`ToggleModuleActive` 包装在 account 模式跳过 char 落库（库原生写 raw）；`ApplyModuleScope` 切换时互拷当前状态（所见不变）+ 预标记播种。**OnInitialize 的 char→raw 同步只在 char 模式执行**，account 模式下 raw 就是存储本体。
- ⚠️ **"默认禁用"判断必须读声明原表 `ns.defaults.profile.disabled`，不能读合并视图 `ns.profile.disabled`**：旧机制消费 disabled 标记时曾把它写成 false 持久化进账号存档，AceDB 默认值只在键缺失时生效 → 合并视图永远返回存储的 false，遮住代码声明的 true，导致所有默认禁用模块在新角色上默认开启（2026-09-05 修复）。SetDisabledAsDefault 读 defaults 原表 + defaultDisabledSeeded（按角色）/ defaultDisabledSeededAccount（按账户）播种标记。
- 模块默认启停声明 = 各模块 RegisterDefaults 里的 `disabled = true/false`（2026-09-05 已按用户截图定稿：绿=启用 4 个翻转，红=禁用 14 个翻转）。
- ⚠️ **同一文件不要并行 Edit**（后写基于旧快照会静默覆盖先写，两次都报成功）；多次修改同一文件必须串行 + 每次 grep 校验。

## 主界面 UI 架构

- 主题色系统：11 预设（THEME_PRESETS），HSL 派生（MakeThemeShade 保持色相），`ApplyTheme(key)` 派生 THEME 各色阶并更新 FLAT 引用（同表引用使其它模块自动跟随）。**切换主题用 `RefreshThemeUI()` 原地刷新，禁止 RebuildMainWindow（残留孤儿 frame 导致拖动掉帧 + 位置跳动）**。
- 背景透明度：`SetWindowAlpha(v)` + `RefreshFrameColors` 递归重刷（ApplyFlatBackdrop 记录 _flatBg/_flatBorder 原始色）；hover/press 一律走 `SetBg`/`SetBorder` 包装（否则半透明下状态切换会变实）；WINDOW_ALPHA_MIN=0。主页滑块（0~100%）。
- 布局宽度：`GetSettingsPanelWidth(main)` 从窗口宽 660 推导（本客户端 GetWidth 对两点锚定 frame 不可靠）；行宽 = 面板宽 - 22（滚动区内边距+滚动条） - 10。
- 拖动性能：拖窗口时 `SetWindowContentVisible(false)` 隐藏两个滚动区内容；OnUpdate 一律按需挂载/卸载（`SetDragGhostTicking`），禁止常驻 OnUpdate。
- 滚动位置保持：`SaveScroll(key)`/`RestoreScroll(key, value)`（滑块名 = key gsub "Scroll$"→"Slider"）；主页原地刷新（勾选显示、切主题）必须包 Save/Restore，切模块才回顶。
- 主页行：统计行（总数/启用/禁用/隐藏）、主题色块、透明度滑块、模块启用保存（按角色/按账户）。
- 窗口 ESC：`UISpecialFrames` 只认**有名字的 frame**；关闭语义 = 隐藏窗口的，OnHide 里做恢复逻辑（如 CDSafe 面板关时恢复主窗口 `_hidMainWindow` 标记）。

## 模块状态（用户偏好）

- 副本重置计时（Boomtime）已翻新为扁平风格 + 标题栏 + 关闭按钮（关闭=按角色停用模块）+ ESC（UISpecialFrames + OnHide 同步停用，_stopping 守卫防递归）。
- 「聊天增强」= Plubics/CleanChat 的 CleanChat 模块（Automaton:NewModule）。
- 中文模块名速查：i人模式=Loner、强制拾取=shiqu、自动禁止移动=jtlk(LegionShackles)、组队密语邀请=Invite、组队自动进组=Group、组队自动跟随=Follow、自动显示飞行点旅馆=AutoDB、团队就位确认=Ready、团队拾取确认=LootBOP、美观经验条=ExpBar、技能与物品管理=Lern2Spell、战斗记录范围控制器=RangeController。

## 验证工具链

- ⚠️ **AceLocale-2.2 注册时双向比对语言表**：给模块的 L 表加新 key 时，enUS 和 zhCN 两个块必须**同时**加，否则加载报 "Improper translation exists"（报错行指向后注册的语言块）。
- ⚠️ **Git Bash 调 node.exe 时 NODE_PATH 必须是 Windows 路径**：用 `NODE_PATH="$(cygpath -w "$HOME/.workbuddy/binaries/node/workspace/node_modules")"`，/c/ 风格路径不识别（报 MODULE_NOT_FOUND，易误判为 luaparse 被清理）。

- 语法检查：`.workbuddy/lua_syntax_check.js`（luaparse；luaVersion 直接传 "5.1" 不是 "Lua 5.1"）；NODE_PATH 指向 `~/.workbuddy/binaries/node/workspace/node_modules`，node 用 `~/.workbuddy/binaries/node/versions/22.22.2-3/node.exe`（旧记的 -2 已不存在，以 ls 实测为准）。
- luaparse 对 jtlk.lua 有既有误报（"reading 'range'"），非真实语法错误。
- fengari 运行时仿真：Lua 5.3 需 shim `math.mod = math.fmod`、`table.getn`。
- ⚠️ 用户会清理 `backup/`、`.workbuddy/lua_syntax_check.js`、`.workbuddy/memory/` —— 使用前先 mkdir -p / 检查存在性。
