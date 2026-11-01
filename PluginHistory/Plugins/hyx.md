# hyx 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/hyx.md)

## 插件概况

- 分类：经过版本迭代或修改的插件。

- 插件：`hyx`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

2026-11-02：现用显示名改为净界驱散 PureDispel 2.0.0；保留hyx目录/xinDB兼容，采用pfUI统一上下双区，各自滚动。旧双锚点方案已被本条替代，旧源码与原团本数据保留。

保留双列表界面，按实际职业能力驱散并浏览完整名单。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

<a id="change-hyx-20261102-01"></a>

### 2026-11-02｜净界驱散2.0：pfUI上下双区、名单流程及低重复刷新

- 记录编号：`hyx-20261102-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户要求统一pfUI风格、可/暂不可驱散同时可见、独立滚动，简化优先/忽略流程并降低资源开销；维护署名明确为StoneChyi & Codex。
- 修改内容：新增PureDispelUI，20个目标行复用、上下固定高度、独立滚轮/Shift首尾、屏幕高度适配、背景/边框独立alpha与字体失败后备；单例目标菜单、外点关闭、懒建设置/名单/规则/手册，左键驱散、右键菜单、中键选中，可选右键也驱散。
- 修改内容：本队/长期优先与忽略、忽略恢复入口、按来源恢复与单步撤销；本队规则绑定角色/服务器，确认离队后清除并作废撤销；保留原长期名单、减益与职业/团本规则，优先不解除忽略或绕过整人禁驱。修复行更新时悬停旧提示和页脚3像素重叠。
- 修改内容：共用扫描，复用队列/候选对象，无变化不重绘，隐藏时零名单/距离/Tooltip扫描；规则允许时少读非必要减益名字；未知名字时停止本轮目标推荐，避免绕过禁驱。保留九职业/宠物能力、距离/视线、GCD/真冷却、法力判断和施法前复查。
- 涉及文件：[引擎](../../Interface/AddOns/hyx/XinDispel.lua)、[新界面](../../Interface/AddOns/hyx/PureDispelUI.lua)、[原手册数据](../../Interface/AddOns/hyx/RaidData.lua)、[TOC](../../Interface/AddOns/hyx/hyx.toc)、[使用说明](../../Interface/AddOns/hyx/README.md)、[行为检查](../../Tools/tests/test_puredispel.py)、[严格模拟](../../Tools/tests/puredispel_wow112_mock.lua)、[资源比较](../../Tools/tests/benchmark_puredispel.py)。旧hyx.lua保留原字节，TOC不再加载。
- 检查结果：37组行为检查通过，包含全部按需页面、SetFont全部失败后备、队伍/角色边界、过期按压/菜单/tooltip、透明度、滚动和旧配置迁移；真实Lua5.0编译器通过3个实际加载Lua文件。原手册表逐字节保持，S_ChatBar入口集成检查通过。模拟不代替游戏验收。
- 资源依据：[固定40人模拟调用比较](../Research/PureDispel-2.0.0-资源检查-20261102.json)；100次不变扫描中读名32000→4000、可见文字更新2000→0、贴图更新900→0，目标行80→20。只代表该模拟情景的调用次数，不代表真实CPU、FPS或内存降幅；完整禁驱规则需要更多读名检查。
- 未确认事项：本轮没有运行中的游戏客户端；实际中文排版、鼠标滚轮、DLL定向/宠物施法及真实CPU/内存待验收。同角色离线换队缺少可靠队伍ID，可能无法自动辨别；可在名单管理清除本队规则。长期规则的原账号级保存语义保留。
- 关联功能：[S_ChatBar入口](S_ChatBar.md#change-S_ChatBar-20261102-02)；[统一署名规范](../MaintenanceAttribution.md)。新增TOC维护metadata和插件列表Notes署名，原Author与许可保留。

现有依据尚不能拆分成日期可靠的逐次记录；下方保留早期汇总，不以本次整理日期代替修改日期。

## 早期历史汇总与维护依据

<details>
<summary>展开早期原始说明与证据（不是当前问题或优化清单）</summary>

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

保留双列表界面，按实际职业能力驱散并浏览完整名单。

### 记录中的修改

- 新增 XinDispel.lua，按技能书识别九职业可用友方驱散，支持简繁中英文；术士读取宠物吞噬魔法。
- 可/不可驱散两列保留完整目标集合，滚轮、Shift 滚轮和页码提示浏览；优先/黑名单与锚点保存。
- 点击时再次校验目标、减益和技能；处理视线、距离、法力、冷却及过期名单。
- UnitXP、SuperWoW、Nampower 可用时协作，缺失/错误时安全降级；没有替换 DLL。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [XinDispel.lua](../../Interface/AddOns/hyx/XinDispel.lua)
- [hyx.lua](../../Interface/AddOns/hyx/hyx.lua)
- [hyx.toc](../../Interface/AddOns/hyx/hyx.toc)

### 已回退方案及更新注意

全职业识别不代表所有职业都有驱散能力；未加入敌方增益驱散或全团宠物扫描。

### 验证与范围

阶段报告记录 14 组 Lua 模拟检查通过，明确没有真实客户端实测；本次未重新运行。

### 待补充

游戏内滚动、中文布局、定向施法及术士宠物行为待验收。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/hyx)
- [PluginHistory/Evidence/reports/hyx-全职业驱散与滚轮列表-20261008.md](../../PluginHistory/Evidence/reports/hyx-%E5%85%A8%E8%81%8C%E4%B8%9A%E9%A9%B1%E6%95%A3%E4%B8%8E%E6%BB%9A%E8%BD%AE%E5%88%97%E8%A1%A8-20261008.md)
- [PluginHistory/Evidence/CodexBackups/hyx/20261008-155425/hyx.lua](../../PluginHistory/Evidence/CodexBackups/hyx/20261008-155425/hyx.lua)
- [PluginHistory/Evidence/CodexBackups/hyx/20261008-155425/hyx.toc](../../PluginHistory/Evidence/CodexBackups/hyx/20261008-155425/hyx.toc)
- [PluginHistory/Evidence/CodexBackups/hyx/20261008-160930-c4a下bar/ChatBar.lua](../../PluginHistory/Evidence/CodexBackups/hyx/20261008-160930-c4a%E4%B8%8Bbar/ChatBar.lua)
- [PluginHistory/Evidence/CodexBackups/hyx/20261008-160930-c4a下bar/XinDispel.lua](../../PluginHistory/Evidence/CodexBackups/hyx/20261008-160930-c4a%E4%B8%8Bbar/XinDispel.lua)
- [PluginHistory/Evidence/CodexBackups/hyx/20261008-161523-settings-close/hyx.lua](../../PluginHistory/Evidence/CodexBackups/hyx/20261008-161523-settings-close/hyx.lua)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。

---

[返回插件修改记录](README.md)

</details>
