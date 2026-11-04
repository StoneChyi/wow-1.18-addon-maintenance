# aux-addon 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/aux-addon.md)

## 插件概况

- 分类：经过版本迭代或修改的插件。

- 插件：`aux-addon`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

2026-11-04：融合扫描统计、热路径缓存、浏览控件冻结/精确恢复、只读价格抽样和已拍卖超时保护，记住用户选择的上架时长。默认保持完整扫描、客户端节流、卖家完整度等待及历史记录。/aux throttle显式切换快速查询；/aux sample默认关闭，开启后只读采样至少20种有效非本人价格；跨页计数、进度封顶、有限重试与超时中止，避免强行接受旧页。保留自动购买/竞标及负充能数量归一，不引入每3页强制全量GC。 见[本次记录](#change-aux-addon-20261104-01)。

## 逐次修改记录

<a id="change-aux-addon-20261104-01"></a>

### 2026-11-04｜融合11月03日包并保留个人版核心

- 记录编号：`aux-addon-20261104-01`
- 记录类型：更新合并
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户要求除末三项外继续融合，同时删除重复的独立材质插件；保留个人版核心及优化。
- 修改内容：融合扫描统计、热路径缓存、浏览控件冻结/精确恢复、只读价格抽样和已拍卖超时保护，记住用户选择的上架时长。默认保持完整扫描、客户端节流、卖家完整度等待及历史记录。/aux throttle显式切换快速查询；/aux sample默认关闭，开启后只读采样至少20种有效非本人价格；跨页计数、进度封顶、有限重试与超时中止，避免强行接受旧页。保留自动购买/竞标及负充能数量归一，不引入每3页强制全量GC。
- 主要文件：`core/scan.lua`、`core/slash.lua`、`tabs/auctions/core.lua`、`tabs/post/core.lua`；贴图及删除范围见逐文件清单。
- 检查结果：31个本次Lua由真实Lua5.0.3编译、3个XML良构通过；16组融合专项、真实Lua5.0拍卖7场景/52断言、自动化58模块416选项/250回调读回及原生接口、共享属性/头像隔离、属性面板36项与治疗职责回归通过。均为离线检查，未作游戏验收。 全库库存与更新前加本次142项变化完全一致，其他插件和根运行组件原字节保留。
- 关联功能：[本次实施与保留范围](../Research/11月03日包第二阶段融合与材质归并-20261104.md)。
- 未确认事项：完整重启后核对存档、渲染、事件与服务器响应；WIM尚未消费新版静默接口，不声称已实现其静默弹窗联动。原作者、版权、许可保留，个人维护署名为StoneChyi & Codex。

<a id="change-aux-addon-20261102-01"></a>

### 2026-11-02｜补记个人版维护署名，保留原作者与许可

- 记录编号：`aux-addon-20261102-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户确认以 `StoneChyi & Codex` 统一标识现有个人版与后续插件维护。
- 修改内容：根 TOC 新增 `X-Maintained-By` 和限定个人修改范围的 `X-Maintenance-Scope`；现有 Notes／本地化 Notes 保留原文并追加可见维护署名，无 Notes 时新增。原作者、版权、许可证和早期修改归属继续按既有证据保留。本条只记录当日 metadata 维护，不代表重新实现早期功能。
- 涉及文件：[aux-addon.toc](../../Interface/AddOns/aux-addon/aux-addon.toc)。
- 检查结果：9 项署名字节与幂等检查通过；本插件 TOC 与操作前 Git 字节的预期增量编辑完全一致，加载文件与顺序、BOM、既有编码和行尾保留；未进行游戏内插件列表显示验收。
- 关联说明：[统一维护署名规范](../MaintenanceAttribution.md)、[本次补记清单](../Research/插件维护署名-20261102.json)。

<a id="change-aux-addon-20261025-01"></a>

### 2026-10-25｜10 月 24 日原包三版本差异核对（未部署）

- 记录编号：`aux-addon-20261025-01`
- 记录类型：差异核对
- 游戏验收：不适用（说明或停用记录）
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户提供 10 月 24 日插件包，要求与 10 月 16 日旧原包及当前个人版对比。
- 修改内容：仅核对并记录，未更新插件。新包变化：只删除优化说明文档。
- 当前个人版：运行文件与旧包相同。
- 涉及文件：备份/说明文件（见逐文件清单）。
- 关联功能与处理：无运行功能更新。
- 检查结果：逐文件字节及 SHA-256、三方关系与机械合并冲突核对；整批新包变更 Lua 186/187 可编译，GoubayuHeal 原 UI 超过 200 局部变量；可编译文件嵌套函数未超 32 upvalue。相关 TOC/XML 没有新增缺失引用。另运行 BCS 缓存、治疗 UI 编译与 ShaguDPS 兜底受控检查；具体结果与限制见[整批对照报告](../Research/三版本插件对比-20261016-20261024-20261025.md)和[逐文件清单](../Research/三版本插件对比-20261016-20261024-20261025.json)。
- 游戏验收与未确认：本次未部署、未真实游戏或多人验收；既有个人改动归属及证据状态不变，不将原包功能记作本项目新增。

现有依据尚不能拆分成日期可靠的逐次记录；下方保留早期汇总，不以本次整理日期代替修改日期。

## 早期历史汇总与维护依据

<details>
<summary>展开早期原始说明与证据（不是当前问题或优化清单）</summary>

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

修正充能物品上架，并减少扫描和重复查询。

### 记录中的修改

- SuperWoW 返回负数充能时，物品数量按一瓶处理，剩余次数单独保留；修正上架滑条、保管费/单价和 Shift 提示计价。
- 扫描逻辑引入批量历史更新，并设置扫描等待阈值；搜索、定价缓存及临时表复用记录在优化报告。
- ChatThrottleLib 调用增加异常保护及限频诊断，用于处理 Invalid escape 报错。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [core/history.lua](../../Interface/AddOns/aux-addon/core/history.lua)
- [core/pricing_cache.lua](../../Interface/AddOns/aux-addon/core/pricing_cache.lua)
- [core/scan.lua](../../Interface/AddOns/aux-addon/core/scan.lua)
- [core/search_cache.lua](../../Interface/AddOns/aux-addon/core/search_cache.lua)
- [core/tooltip.lua](../../Interface/AddOns/aux-addon/core/tooltip.lua)
- [libs/ChatThrottleLib.lua](../../Interface/AddOns/aux-addon/libs/ChatThrottleLib.lua)
- [tabs/post/core.lua](../../Interface/AddOns/aux-addon/tabs/post/core.lua)
- [util.lua](../../Interface/AddOns/aux-addon/util.lua)
- [util/info.lua](../../Interface/AddOns/aux-addon/util/info.lua)
- [util/temptable.lua](../../Interface/AddOns/aux-addon/util/temptable.lua)

### 关联插件

[OneBag](OneBag.md)。更新时同时检查对应入口与数据口径。

### 已回退方案及更新注意

OPTIMIZATION_SUMMARY 中的百分比性能收益没有可复核基准，不作为已测量结果；ChatThrottleLib 异常保护不证明原始消息一定来自 aux-addon。

### 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

### 待补充

缓存与扫描优化的真实游戏收益、异常消息根源仍待补充。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/aux-addon)
- [Interface/AddOns/aux-addon/.workbuddy/memory/2026-09-28.md](../../Interface/AddOns/aux-addon/.workbuddy/memory/2026-09-28.md)
- [Interface/AddOns/aux-addon/OPTIMIZATION_SUMMARY.md](../../Interface/AddOns/aux-addon/OPTIMIZATION_SUMMARY.md)
- [Interface/AddOns/OneBag/.workbuddy/memory/2026-09-23.md](../../Interface/AddOns/OneBag/.workbuddy/memory/2026-09-23.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。

---

[返回插件修改记录](README.md)

</details>
