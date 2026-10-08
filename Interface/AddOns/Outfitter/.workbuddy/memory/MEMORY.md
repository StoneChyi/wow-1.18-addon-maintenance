# Outfitter（乌龟服定制版）长期备忘

## 0. 铁律与教训
- ⛔ **Outfitter.lua:3889 `GetItemInfo(vItemCode)` 裸数字 ID 保持原样**。改传 itemlink 后返回 nil，全插件换装失效（用户明令不动）。
- ⚠️ **"写而不读"存档 bug（2026-09-09 用户实报）**：新增设置字段必须 **SaveSettings + LoadSettings 成对**——`QueueDelays` 曾只写不读，设好的延迟重登即丢。改设置项时逐个比对 SaveSettings 的 17 个字段与 LoadSettings 的读回段。
- ⚠️ **隐藏回弹 bug**：存档 `Slots={}` 被判为"从未配置"会回弹默认两饰品；用 `SlotsConfigured` 标记区分"从未配置"与"主动全部取消"。
- 扩展 frame 事件：`GetScript` 保存 + `SetScript` 改实例 handler，勿 wrap 全局函数。
- 自定义框禁 TOOLTIP 层（GameTooltip 保留层，同层被按钮盖住）；QuickSwap 弹出框/栏位条 = HIGH。

## 1. 皮肤（全部外置 pfui-skin.lua，Outfitter.lua 无 pfUI 代码）
- 就绪检查 `pfUI.api + pfUI.env.C`；触发：ADDON_LOADED("Outfitter") / PLAYER_LOGIN / **此后任意 ADDON_LOADED 重试**（outfitterLoaded 守卫防过早引用 nil；ApplySkin 全幂等守卫），成功才注销。新角色首登时序不稳，单次就绪检查会整场无皮肤 → 残留经典框（2026-09-05 实锤）。不走 pfUI:RegisterSkin。
- **CreateBackdrop 后必须把自身经典 SetBackdrop 颜色置透明**（双步缺一不可），否则金边残留。
- 懒创建窗口（排队设置窗）皮肤 = 全局 `OutfitterQuickSwap_QueueCfgSkin(pFrame)`，建窗末尾调用（幂等）。
- 勾选框 `skin_qs_checkbox`：backdrop 零外扩贴合 + 勾选贴图内缩 2px + **恢复 SetHitRectInsets**（Opt -140 / Cfg -60）。布局数字：开关 y=-46 起节距 20、说明行 y=-172、网格节距 22 起始 desc+18 列偏移 ×84，与窗高联动别单改。
- 装备槽/弹出按钮：创建期 `CreateBorder` 分流（pfUI → `SkinButtonPFUI`：TexCoord .08 + CreateBackdrop 细边；否则 UI-Quickslot2 外扩 11px）。按钮懒创建 → 创建期 + pfui-skin 兜底循环（Slot/Item 1..40）双通道；品质色 `SetBorderColor` 双通道。
- QuickSlots 弹框（27 槽）：32 个 `Back*` 按命名 `SetTexture(nil)` 显式清（StripTextures 清不掉 layer0，见 §4）；按钮清 Normal/Pushed + `Border:Hide()` + TexCoord .08 + `pcall(CreateBackdrop)`；品质色 `ParseQualityColor` 逐字符 hex（Lua5.0 无 tonumber("0x..")）；**OnShow 用 GetScript+SetScript 包装重刷**（ContainerFrame_Update 会重 Show Border），`_pfQSOnShowWrapped` 防重入。
- OutfitterQuickSwapFrame：`ApplyPanelStyle` 双通道（有 backdrop 切 Show/Hide，无则经典底着色）。**LoadSettings 新角色早退分支也必须调它**，且 CheckFirstTrinket Show 前补调——否则新号首登自动弹出带整套经典外观（背景框+关闭按钮残留，2026-09-05 修复）。

## 2. QuickSwap 布局（勿踩）
- **底边锚定铁律**：栏位条创建处一次 `BOTTOMLEFT(vFrame,8,8)` + `BOTTOMRIGHT(-8,8)` 永不重锚；`UpdateLayout` 只 SetHeight（精简 vBarHeight+10 / 普通 +38，宽 vBarWidth+16）。本客户端对 bar 的 SetPoint **静默失效**，MoveFrame 亦无效，只有 SetHeight 可靠。
- `gQS_ColsPerRow=100` 单行不换行；拖拽 OnMouseUp 调 `ReanchorFrame()`（StopMovingOrSizing 留 TOPLEFT 锚）。
- **坐标单位**：GetLeft/SetPoint 偏移同单位，物理 = 偏移×scale；存档存原值**不做换算**；LoadSettings 先 SetScale 后 SetPoint；SetScale 重锚补偿必须 IsShown() 守卫（隐藏框 GetLeft 非 nil）；越界自愈用物理空间判定。历史事故：补偿复利膨胀 → "位置不保存"。
- 滚轮缩放 0.5-2.0 步进 5% 左下角不动；Popup 父级是 UIParent → SetScale 里同步其缩放 + 自接滚轮（**1.12 滚轮冒泡走父链**：只开 EnableMouseWheel 不开 EnableMouse，不吞点击）。

## 3. 功能与设置（存 `gOutfitter_Settings.QuickSwap`）
- 设置项：`Slots`（空表=默认饰品1/2）、`Scale`、`X/Y`、`Locked`、`PausedSlots[部位名]`、`ShowHotKeys`、`HiddenItems[物品名]`、`Queues[部位名]`、`QueueDelays[物品名]`（秒）、`QueuePriorities[物品名]`（2026-09-07：优先物品一就绪立即换上使用，不受就绪保持/延迟保护约束；当前装备=就绪优先物品时保持防互跳）。排查"面板不见"先查 X/Y 越界。
- 右键菜单两项（自动排队设置… / 锁定）；1.12 光标菜单 = UIDropDownMenuTemplate + displayMode="MENU" + initialize + ToggleDropDownMenu(1,nil,f,"cursor",0,0)，勾选项 checked+isNotRadio。
- 快捷键：槽 Alt+右键=暂停该部位排队（角标红 1,.5,.5）；弹出物品 Alt+左键=入/出队、Alt+右键=屏蔽 HiddenItems（灰化 SetVertexColor 0.45，**禁 SetDesaturated**）、Ctrl+左键=排队延迟窗。
- 自动排队（TrinketMenuQueue 模式）：1s 节流，冷却剩余 >30s → 换背包第一个就绪物品；就绪不换回（防抖动）；战斗转 `gQS_CombatQueue` 脱战换。**QueueDelays**：触发后经过时间 <delay 且剩余>30s 不换下（保护 buff，原版 Stats[id].delay 同款）。
- 排队设置窗 `OutfitterQuickSwapQueueCfg`（懒创建、ESC 关、Alt 增删时开着同步）：部位下拉（只列有排队的）→ 顶/上/下/底排序按钮（remove+insert+选中跟随，无选中/到边禁用）→ 物品列表（品质色+选中条）→ 延迟输入框（0-300，0=清）+ **优先勾选框**（QueuePriorities，2026-09-07）+ 暂停勾选框。高度 = max(列表底,按钮列底)+50；空队列隐藏按钮列 = listTop+80；>10 行不显示（未做滚动）。品质色：短链接提 ID→pcall GetItemInfo→GetItemQualityColor。
- 按键绑定：Bindings.xml + `BINDING_NAME_` 全局；HotKey 字体 NumberFontNormalSmallGray（GetFont()==nil 兜底 SetFont）；`ReflectKeyBindings()` 在 RebuildBar 末尾/开关点击/UPDATE_BINDINGS。
- 换装核心 `DoEquip` = PickupContainerItem + PickupInventoryItem；失败图标置灰 + 0.75s 强刷。
- **双手/副手互斥**（2026-09-04）：`UseContainerItem`（右键路径）引擎自动卸双手；`Pickup*`（拖拽路径）不腾手 → 拒绝+粘光标。副手唯一槽物品（IsOffHandOnlyItem）走 UseContainerItem；单手武器走 `ResolveHandConflict` 手动腾手（装副手+主手双手→卸主手；装双手+副手有货→卸副手）。配套 IsTwoHandLink / FindEmptyBagSlot（复用 Outfitter_GetEmptyBagSlot，跳过专业包）/ UnequipToBag（Outfitter.lua:3496 同款）。

## 4. 1.12 客户端陷阱
- **layer0 BACKGROUND 纹理**：`GetRegions()` 不返回，StripTextures 清不掉 → 按命名 `SetTexture(nil)` 显式清；残留纹理会吞点击。
- **pfUI 皮肤下 `SetDesaturated(1)` 让贴图消失**（棕色空块）→ 灰化一律 SetVertexColor。
- GetItemInfo 返回布局缺 reqLevel 整体前移（equipLoc 第 8、texture 第 9）→ **不硬编索引**，扫描 `^INVTYPE_` / `^Interface\\`；名字 `string.match(link,"%[(.-)%]")`（短链接可靠）；全部 pcall 包裹。
- Lua5.0：无 `%`（math.mod）、无 `#`（table.getn）、SetScript 回调不传 self、`break;` 合法。
- **Button 无 SetNormalFontObject/SetHighlightFontObject/SetDisabledFontObject**（TBC 才有，实测 nil 报错）：文字 CreateFontString 自建（SetAllPoints+SetText+SetTextColor），变灰手动 SetTextColor；`SetHighlightTexture` 可用。慎用一切 TBC 新增控件方法，拿不准就 pcall 或查库内其他 1.12 插件。
- 自定义 Button 的自定义字段（Tip 等）必须创建期赋值；`a .. b or ""` 优先级 = (a..b) or ""；1.12 `UIDropDownMenu_SetText` 参数序 (text, dropdown) 需 frame 对象，pcall 包裹。

## 5. 校验
- `.workbuddy/check_lua.js`（luaparse；Node 22.22.2-2 + `NODE_PATH=...\binaries\node\workspace\node_modules`；可传多个文件，默认查全部主 lua）。
- luaparse 用 luaVersion 5.1；解析前把 `\bbreak\s*;` 归一成 break（其报错信息无 "break" 字样，误匹配会放弃整个文件）。
