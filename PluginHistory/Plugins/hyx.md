# hyx 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/hyx.md)

## 插件概况

- 分类：经过版本迭代或修改的插件。

- 插件：`hyx`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

保留双列表界面，按实际职业能力驱散并浏览完整名单。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

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
