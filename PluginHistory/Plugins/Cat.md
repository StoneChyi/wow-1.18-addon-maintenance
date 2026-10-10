# Cat 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

完善圣骑士输出/坦克逻辑、配置与界面。

## 记录中的修改

- 惩戒第五方案加入神圣打击三层及主圣印选择；设置与执行逻辑保持一致。
- 修正防骑审判后补圣印、奉献、无圣印处理及不同圣印优先级，避免审判后丢失循环状态。
- 防骑低法力阈值、种族技能优先级及配置保存；角色间不复用错误缓存。
- 设置置前、标题对齐、图标去边框与 pfUI 皮肤协作。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [CatEvent-Paladin.lua](../../Interface/AddOns/Cat/CatEvent-Paladin.lua)
- [PaladinCJ.lua](../../Interface/AddOns/Cat/PaladinCJ.lua)
- [PaladinHeal.lua](../../Interface/AddOns/Cat/PaladinHeal.lua)
- [PaladinMeleeHeal.lua](../../Interface/AddOns/Cat/PaladinMeleeHeal.lua)
- [PaladinTank.lua](../../Interface/AddOns/Cat/PaladinTank.lua)
- [UI/CatUI-PaladinSeal.lua](../../Interface/AddOns/Cat/UI/CatUI-PaladinSeal.lua)
- [UI/Settings-Common.lua](../../Interface/AddOns/Cat/UI/Settings-Common.lua)
- [UI/Settings-Menu.lua](../../Interface/AddOns/Cat/UI/Settings-Menu.lua)
- [UI/Settings-PaladinCJ.lua](../../Interface/AddOns/Cat/UI/Settings-PaladinCJ.lua)
- [UI/Settings-PaladinHeal.lua](../../Interface/AddOns/Cat/UI/Settings-PaladinHeal.lua)
- [UI/Settings-PaladinMeleeHeal.lua](../../Interface/AddOns/Cat/UI/Settings-PaladinMeleeHeal.lua)
- [UI/Settings-PaladinTank.lua](../../Interface/AddOns/Cat/UI/Settings-PaladinTank.lua)

## 关联插件

[pfUI-addonskinner](pfUI-addonskinner.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

Cat 与 Cat2 是不同插件，不能互换执行器或配置；审判后补印按最终备份核对，保留配套贴图。

## 验证与范围

来源中有语法检查、模拟或用户反馈时，结果仅对应当时的版本与环境；不据此认定当前版本已完成游戏验收。本次仅核对历史、文件存在与文档链接，没有运行或修改插件功能。

## 待补充

暂无发现会妨碍本页摘要的明确缺项。仍欢迎补充未被笔记覆盖的早期修改、实际游戏验收和个人保留需求。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/Cat)
- [PluginHistory/Evidence/CatBackups/20261007-judgement-reseal/manifest.json](../../PluginHistory/Evidence/CatBackups/20261007-judgement-reseal/manifest.json)
- [PluginHistory/Evidence/CatBackups/20261007-settings-front/manifest.json](../../PluginHistory/Evidence/CatBackups/20261007-settings-front/manifest.json)
- [PluginHistory/Evidence/CatBackups/20261006-borderless-icons/manifest.json](../../PluginHistory/Evidence/CatBackups/20261006-borderless-icons/manifest.json)
- [PluginHistory/Evidence/CatBackups/20261006-header-alignment/manifest.json](../../PluginHistory/Evidence/CatBackups/20261006-header-alignment/manifest.json)
- [PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json](../../PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json)
- [PluginHistory/Evidence/reports/20261006/适配指南草稿.md](../../PluginHistory/Evidence/reports/20261006/%E9%80%82%E9%85%8D%E6%8C%87%E5%8D%97%E8%8D%89%E7%A8%BF.md)
- [PluginHistory/Evidence/legacy-20261006/Docs/Files/Cat](../../PluginHistory/Evidence/legacy-20261006/Docs/Files/Cat)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。


## 2026-10-11：审判控制面板增加惩戒输出技能按钮

### 目的与实际修改

- 将奉献图标上移至审判图标行；在其正下方、圣印行右侧增加惩戒输出技能按钮，保持原面板尺寸和无边框样式。
- 左键向后、右键向前循环“关闭、只用神圣打击、主用神圣打击（均衡）、主用十字军打击（均衡）、只用十字军打击、主用神圣打击（三层狂热）”。六种状态分别使用不同内置图标和短标签，悬停显示完整方案及当前配置编号；关闭时调暗。
- 直接复用惩戒的 `Strike`、`Strike_Value` 字段，与惩戒设置中的开关、五挡滑条双向同步。跟随最近使用的惩戒宏配置或打开的惩戒设置配置；防骑宏不切换该惩戒配置，不修改防骑输出循环。其余惩戒配置互不覆盖。
- 修正惩戒执行器未读取 `Strike` 开关的问题：关闭输出技能后不再执行神圣打击/十字军打击；中低优先级奉献与驱邪术不会因打击技能就绪而被错误阻塞。原五种方案内部逻辑未改。
- 字体通过 `GameFontNormal` 模板先初始化，再尝试指定字体；指定字体加载失败时仍有模板后备。外观刷新复用现有亮度恢复流程，不重置圣印、审判或奉献选择。

### 本次文件与关联功能

- [审判控制界面](../../Interface/AddOns/Cat/UI/CatUI-PaladinSeal.lua)：按钮、布局、方案图标及惩戒配置同步。
- [惩戒设置](../../Interface/AddOns/Cat/UI/Settings-PaladinCJ.lua)：打击开关/滑条的定向刷新及反向通知。
- [惩戒执行器](../../Interface/AddOns/Cat/PaladinCJ.lua)：落实输出技能开关。
- [回归检查](../../Tools/tests/test_cat_strike_control.py)：使用 Lua 5.1 执行实际界面、设置和惩戒宏，复用 [字体前置条件检查](../../Tools/tests/wow112_fontstring_mock.lua)。运行需要本机已有的 Lupa Lua 5.1 依赖。
- 兼容现有 [pfUI-addonskinner](pfUI-addonskinner.md) 的无边框与选中亮度回调，本次未修改其代码。没有新增 SavedVariables、贴图资源或设置版本迁移。

### 真实验证与未确认事项

- Lua 5.1 语法检查通过；实际模块的六状态正反切换、图标区分、布局坐标、设置双向更新、三套配置隔离和保存数据重载模拟通过。
- 外观模拟覆盖透明度、缩放、pfUI 皮肤回调、初次未加载设置及关闭状态；字体检查要求未初始化的 `FontString:SetText` 失败，并实际注入指定字体 `SetFont` 失败验证模板后备。
- 实际惩戒宏模拟验证五种方案的启用/关闭、三层狂热刷新，以及关闭打击后中低优先级奉献、驱邪术继续执行。
- 维护说明链接检查与 `git -c core.whitespace=cr-at-eol diff --check` 通过；Lua 文件保留 UTF-8、无 BOM、CRLF，维护说明保留原有 LF 换行。
- 尚未在真实 1.12 游戏客户端验收；图标辨识、皮肤下最终显示和战斗操作手感需用户 `/reload` 后确认。模拟通过不代表已经完成实战验收。
