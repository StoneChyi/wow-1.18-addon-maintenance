# S_ItemTip 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

统一观察布局、属性扫描及图标显示。

## 记录中的修改

- 观察框职业图标改为独立保存的 classicons.blp 及本地坐标表，不依赖 1.12 缺失的全局坐标。
- 与 BetterCharacterStats、StatCompare 协调观察窗口、宝石附魔显示和属性扫描。
- 修正角色窗口重复打开时物品评分/扫描刷新路径。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [Icons/classicons.blp](../../Interface/AddOns/S_ItemTip/Icons/classicons.blp)
- [InspectFrame.lua](../../Interface/AddOns/S_ItemTip/InspectFrame.lua)
- [InspectGemAndEnchant.lua](../../Interface/AddOns/S_ItemTip/InspectGemAndEnchant.lua)
- [ItemSocre.lua](../../Interface/AddOns/S_ItemTip/ItemSocre.lua)

## 关联插件

[BetterCharacterStats](BetterCharacterStats.md)、[StatCompare](StatCompare.md)、[RaidCheck](RaidCheck.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

ItemSocre.lua 的现有文件名拼写需保留；不能用旧文件整份覆盖新的附魔数据库。

## 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

## 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/S_ItemTip)
- [Interface/AddOns/S_ItemTip/.workbuddy/memory/2026-09-30.md](../../Interface/AddOns/S_ItemTip/.workbuddy/memory/2026-09-30.md)
- [PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json](../../PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json)
- [PluginHistory/Evidence/reports/20261006/适配指南草稿.md](../../PluginHistory/Evidence/reports/20261006/%E9%80%82%E9%85%8D%E6%8C%87%E5%8D%97%E8%8D%89%E7%A8%BF.md)
- [PluginHistory/Evidence/legacy-20261006/Docs/Files/S_ItemTip](../../PluginHistory/Evidence/legacy-20261006/Docs/Files/S_ItemTip)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。

## 2026-10-11 两包更新与个人版三方核对（未部署）

- 目的与证据：按用户补充的 10 月 5 日包，对照 10 月 10 日包和当前个人版；详见[三方核对报告](../Research/三方插件更新核对-20261005-20261010-20261011.md)。不据文件相等推断作者或最早来源。
- 两包变化：ItemSocre.lua 增加装等去重、权重/槽位常量、0.5 秒评分缓存、英文名反向索引和链接缓存；新包还删除旧包已有的 3 处负充能归一化。
- 个人版处理：与个人名称查询缓存的文本试算有 1 处冲突，需要人工合并；保留负充能处理及两包未变的 InspectFrame/InspectGemAndEnchant 个人布局与刷新修改。
- 验证与未确认：本次只核对原始字节/差异及文本试算；新包本次改变或新增的 75 个 Lua 全部通过 Lua 5.1 语法检查。未修改本插件功能，未部署候选，真实 1.12 加载、界面和多人行为待后续验收。

## 2026-10-12 10 月 10 日更新详细评估（未部署）

- 按用户要求重新逐项核对三份源码；新增[更新明细与冲突评估](../Research/S_ItemTip-10月10日更新与个人版冲突评估-20261012.md)及[原始文件校验与模拟结果](../Research/S_ItemTip-三版本代码核对-20261012.json)。新包仅 ItemSocre.lua 有运行代码更新，另有 4 个新增辅助文件；两份观察文件与数据库两包不变。
- 重新试算确认 ScanUnit 名称回查有 1 个文本冲突。个人按需缓存与新包全量反向索引需要统一；不能只删冲突标记后保留两套独立策略。
- 原始代码隔离模拟复现：新包删除 3 处负充能归一化；链接查询首次失败后不自动重试；同人不同单位标识的评分失效不联动；英文库源表替换后全量索引不更新。评分缓存可减少短时重复扫描，但收益未做真实游戏耗时测量。
- 实读当前英文库有 562 个重名名称，204 个名称对应不同装等；旧按需查询首个命中与新索引最后写入的策略不同，具体装备影响未游戏确认。当前观察布局、刷新节流及附魔图标准备路径继续保留。
- 验证：三份评分/观察/附魔观察源文件共 9 份通过 Lua 5.1 语法编译；评分、缓存及提示字段模拟通过。未进行界面绘制模拟、真实 1.12 游戏验收或插件部署；详细报告列明输入条件和未确认事项。

## 2026-10-12 合并与潜在问题修正方案（未实施）

- 按用户要求形成[个人版与 10 日包合并方案](../Research/S_ItemTip-个人版与10日包合并及修正方案-20261012.md)：以个人版为基础，迁入类型集合、共用提示、固定权重和修正后的短期评分/链接缓存，保留布局、附魔和负充能处理。
- 明确采用共用按需名称候选查询，替代新旧独立索引；精确 ID 优先，同名歧义不任意选取。失败查询允许重试，客户端资料回退扫描拟按帧预算执行，参数尚未验证。
- 计划对 InspectFrame.lua 做最小缓存/刷新衔接，必要时由 InspectGemAndEnchant.lua 透传强制刷新参数；保留自动/自由排列和基础更新 false 返回协议。复查指出已有观察名称映射、重复翻译函数定义及真正生效的 0.08 秒节流路径，避免合并时遗漏。
- 本次验证为源码与方案审查、说明链接检查；未修改插件、未生成或测试合并版、未做真实游戏验收。方案列明实施顺序、1.12 接口核对和行为验收门槛，未把拟定参数或修正效果写成已验证结果。

## 2026-10-12 合并修复已覆盖现用版

- 用户授权实施后，以个人版为基础合入 10 日包优化，已替换 ItemSocre.lua、InspectFrame.lua、InspectGemAndEnchant.lua；[实施记录](../Research/S_ItemTip-合并实施-20261012.md)及[逐文件校验](../Research/S_ItemTip-合并实施-20261012.json)。更新前标签 before/s-itemtip-merge-20261012，个人布局/创建/排列区域及其余 21 个文件保持原字节。
- 统一按需名称候选、同名消歧、评分与链接缓存失效；失败允许重试、回退查询分帧；保留三条负充能修正和评分公式。换装/观察刷新穿过一次节流，附魔包装透传强制刷新；/si cacheclear 可清手动原地更新的数据缓存。
- [85 项 Lua 5.1 受控检查](../../Tools/tests/test_s_itemtip_merge.py)在候选与部署后均通过，含评分、异步查询、缓存容量、钩子、字体失败、观察窗口和附魔图标。未完成真实 1.12 游戏验收，远端通知支持、实际画面和耗时仍待确认；未读写账号设置或 DLL。
