# TankBuddyEnh 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/TankBuddyEnh.md)

## 插件概况

- 插件：`TankBuddyEnh`
- 维护状态：**有维护记录**
- 记录整理：2026-10-15；仅整理说明，不代表当日重新修改或验收插件。

## 当前维护摘要

完善坦克公告开关、技能识别及设置界面。

逐次记录包含曾采用的中间方案；后续修改会注明替代关系。早期摘要仅作历史依据，当前行为优先核对较晚的明确记录和现用源码。

## 逐次修改记录

现有依据尚不能拆分成日期可靠的逐次记录；下方保留早期汇总，不以本次整理日期代替修改日期。

## 早期历史汇总与维护依据

以下保留原页的整理说明、早期摘要、待补充项与证据；其中“本次”“当前”等表述属于原记录语境。

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

### 修改目的

完善坦克公告开关、技能识别及设置界面。

### 记录中的修改

- 设置页签和秒数输入优化；战士招架/躲闪等事件匹配具体技能公告。
- 威胁公告按通用时间窗口控制，YELL 关闭可以保存，默认频道只在首次建表时设置。
- 以 tooltip 扫描替代不存在的 GetPlayerBuffName，按 buff 索引取消效果。
- 修正“全部移除”展开输入框后与防御姿态行重叠。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

### 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [TankBuddyEnh.lua](../../Interface/AddOns/TankBuddyEnh/TankBuddyEnh.lua)
- [TankBuddyEnh.xml](../../Interface/AddOns/TankBuddyEnh/TankBuddyEnh.xml)

### 已回退方案及更新注意

不能恢复每次登录强开 YELL 或绕过威胁窗口的早期兜底。

### 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

### 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

### 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/TankBuddyEnh)
- [Interface/AddOns/TankBuddyEnh/.workbuddy/memory/2026-08-26.md](../../Interface/AddOns/TankBuddyEnh/.workbuddy/memory/2026-08-26.md)
- [Interface/AddOns/TankBuddyEnh/.workbuddy/memory/2026-08-28.md](../../Interface/AddOns/TankBuddyEnh/.workbuddy/memory/2026-08-28.md)
- [Interface/AddOns/TankBuddyEnh/.workbuddy/memory/2026-09-02.md](../../Interface/AddOns/TankBuddyEnh/.workbuddy/memory/2026-09-02.md)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。

---

[返回插件修改记录](README.md)
