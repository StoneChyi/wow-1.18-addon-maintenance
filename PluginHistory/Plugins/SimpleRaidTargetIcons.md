# SimpleRaidTargetIcons 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

完善标记条生命显示、团队工具和透明图标。

## 记录中的修改

- 增加血条/百分比、短姓名、掉血黄色缓冲区、三档宽度和猎人印记开关；兼容不同布局、缩放及反向排列。
- 增加就位、倒数、清标、重置副本、设置等工具，各自开关及左右位置；重置含游戏确认和权限检查。
- 接入去外描边的透明图集，保存原图，标记条、侧边和圆环保持一致。
- 修正 Banana 初始化前 OnUpdate 扫描、重复加载事件和旧禁用配置；GUID 保存/还原支持 SuperWoW。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [Banana.lua](../../Interface/AddOns/SimpleRaidTargetIcons/Banana.lua)
- [Banana.xml](../../Interface/AddOns/SimpleRaidTargetIcons/Banana.xml)
- [IconTextures.lua](../../Interface/AddOns/SimpleRaidTargetIcons/IconTextures.lua)
- [RaidTools.lua](../../Interface/AddOns/SimpleRaidTargetIcons/RaidTools.lua)
- [SimpleRaidTargetIcons.lua](../../Interface/AddOns/SimpleRaidTargetIcons/SimpleRaidTargetIcons.lua)
- [SimpleRaidTargetIcons.toc](../../Interface/AddOns/SimpleRaidTargetIcons/SimpleRaidTargetIcons.toc)
- [img/srti_icons_borderless.png](../../Interface/AddOns/SimpleRaidTargetIcons/img/srti_icons_borderless.png)
- [img/srti_icons_borderless.tga](../../Interface/AddOns/SimpleRaidTargetIcons/img/srti_icons_borderless.tga)

## 关联插件

[S_ChatBar](S_ChatBar.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

原标记 GUID 不保证跨副本重置还原；PNG 与客户端 TGA、图集坐标必须配套。

## 验证与范围

维护报告记录 Lua/XML、素材透明通道/坐标和多组客户端模拟通过；明确没有运行中游戏实测。本次未重新执行。

## 待补充

服务器就位/重置响应、实际血条和缩放效果待游戏确认。

## 2026-10-10：清除全部标记时的骷髅血条修复

- 目的：修复点击“清”后，骷髅下方短暂显示玩家血条的问题；Alt+左键清标共用同一修复。
- 原因：旧逻辑依次将八个团队标记转到玩家身上，最后留下骷髅，等后续刷新再取消；血条扫描先于取消执行，将玩家误当成骷髅目标。
- 主要文件：[Banana.lua](../../Interface/AddOns/SimpleRaidTargetIcons/Banana.lua)。清标结束立即取消玩家标记并刷新显示；后续重试先清标再扫描，等待服务器同步时忽略玩家及其 party/raid、SuperWoW mark 单位别名上的临时标记。插件内主动设置新团队标记时停止旧清标重试，避免刚设置的标记被清掉。
- 关联功能：“清”按钮、Alt+左键清标、普通客户端单位扫描、SuperWoW mark1–mark8 扫描、目标血条与姓名显示。真实标记目标仍按实际血量刷新；已保存的标记记录不受影响。
- 验证：[新增回归脚本](../../Tools/tests/test_srti_clear_marks.py) 在旧代码上检测到缺少立即取消标记；修复后 10 组行为检查通过，覆盖普通客户端/SuperWoW、即时/延迟同步、按钮/Alt 入口、八个标记清除、最后一轮重试、真实骷髅血量变化及主动重新标记。[原有完整回归脚本](../../PluginHistory/Evidence/addons_tmp/test_srti_tools.py) 对当前插件执行通过，包括 Lua/XML、启动初始化、血条掉血/死亡/消失、短姓名、左右布局、猎人印记开关、权限/倒数/保存还原与聊天栏入口。
- 未确认事项：本次为 Lua 5.1 客户端模拟，尚未在运行中的游戏里确认服务器响应和实际画面；游戏内需 `/reload` 后验证。

## 2026-10-12：新增组队分配方式按钮

- 目的：在标记条旁直接看清队伍 / 团队当前的物品分配方式，无需先打开菜单。
- 主要文件：[RaidTools.lua](../../Interface/AddOns/SimpleRaidTargetIcons/RaidTools.lua)。新增默认开启的分配方式按钮，以两行文字显示“分配方式”及完整模式名称，并用颜色区分自由拾取、轮流拾取、队长分配、队伍拾取、需求优先；未收到有效模式时显示“等待同步”。悬停说明分配规则，左键在本地聊天窗口显示当前模式。
- 显隐与布局：单人隐藏，加入队伍或团队后自动显示，退队立即隐藏并收回占位；遵循插件总开关及队伍 / 团队显示设置。设置页增加“分配方式（组队显示）”独立开关、左右位置选择，支持“工具全部放左 / 右侧”、五种布局、反向排列和原有缩放。设置页高度相应扩展，避免新增选项挤压下方控件。
- 关联功能与接口：沿用已有工具布局及刷新；读取 1.12 `GetLootMethod()` 的首返回值，并监听 `PARTY_LOOT_METHOD_CHANGED`、`PARTY_MEMBERS_CHANGED`、`RAID_ROSTER_UPDATE`、`PLAYER_ENTERING_WORLD`，同时保留现有定时刷新作同步补充。接口及事件用法核对本机 11200 插件 Bagshui 的 GameInfo 与 pfUI；不依赖现代客户端接口。按钮不更改分配设置，点击不会向队伍 / 团队发送消息。
- 字体：工具按钮及血条文本先继承内置 `GameFontNormal` 模板，再尝试设置字体，确保新按钮、隐藏控件、血条和短姓名在字体加载失败时仍有有效后备。
- 验证：[分配按钮回归脚本](../../Tools/tests/test_srti_loot_mode.py) 的 12 组 Lua 5.1 检查通过，覆盖五种模式、初始化、事件 / 定时更新、组队 / 团队 / 退队、旧设置迁移、独立与总开关、20 种布局 / 左右组合、三档缩放、设置预览及复用；使用[严格字体模拟](../../Tools/tests/wow112_fontstring_mock.lua)，确认未初始化字体的 `SetText` 会失败，并在 `SetFont` 失败条件下验证回退、模式变化及血条 / 姓名写入。原有完整 Lua/XML、血条、布局、猎人印记、聊天栏等回归，以及清标修复 10 组检查均通过。
- 未确认事项：以上为客户端模拟检查；尚未在运行中的乌龟服游戏里验收实际画面和服务器分配事件。需 `/reload` 后组队查看，不能以模拟结果代替游戏验收。

## 2026-10-12 补充：工具具体位置与紧凑分配切换

- 用户反馈：上一版分配方式显示已达到效果，但按钮偏宽，且不能点击切换；同时要求工具可以选择同侧第 1、2 等具体位置。
- 主要文件：[RaidTools.lua](../../Interface/AddOns/SimpleRaidTargetIcons/RaidTools.lua)。就位、倒数、分配、存 / 还原、清标、重置、设置七项工具均增加“第几位”菜单，按所在侧由标记向外排列，第 1 位最靠近标记。移动一侧工具不改变另一侧的相对顺序；隐藏工具不占实际位置，重新启用后按保存顺序参与排列。单人时仍可预设分配按钮组队后的顺序，其他工具当前位置不计入隐藏的分配按钮。
- 配置与迁移：新顺序保存在原有配置表的新字段 `BANANA_CONFIG.TOOL_ORDER` 中，继续使用原左右设置；缺失、重复、未知顺序项会补齐 / 去重。恢复默认会重置顺序，左右批量按钮保留相对顺序。设置页扩宽以并排放置左右和具体位置选择，不挤压原有文字。
- 分配按钮：宽度从 82 缩为普通工具的 36，移除两行标题，改用“自由 / 轮流 / 队分 / 队拾 / 需求”及原有颜色，悬停查看完整名称和规则。左键打开五种分配方式菜单，当前模式打勾；普通成员仅可查看，切换项置灰。选择“队长分配”后再选择分配者，团队名单每页 10 人，支持 40 人团队及翻页 / 返回。
- 切换校验：提交前重新核对队长 / 团长权限及所选成员姓名，防止菜单打开后身份或名单变化导致误操作；退队或关闭工具时关闭所属分配菜单。显示继续读取游戏实际模式，不把尚未被服务器确认的请求提前显示为生效。
- 1.12 接口：核对本机 PlayerLinkEnhance、Automatonex 的 `SetLootMethod(method)` / `SetLootMethod("master", name)` 用法，及 pfUI、Bagshui 的原生下拉菜单、`keepShownOnClick`、32 项上限与菜单缓存处理。新控件使用原生有效字体模板，分配文本保留内置字体后备。
- 验证：[扩展回归脚本](../../Tools/tests/test_srti_loot_mode.py) 的 18 组 Lua 5.1 行为检查通过，覆盖紧凑模式、旧显示与开关路径、切换权限 / 服务器延迟、名单变化、40 人分页、20 种布局 / 侧别下各工具第 1 / 2 / 末位移动、隐藏补位、另一侧顺序保留、重建模拟环境后的顺序加载、异常顺序修复及恢复默认。菜单模拟保留 1.12 缓存和 32 项限制，字体模拟会拒绝未初始化的 `SetText`，并在字体设置失败时覆盖控件创建、预览、隐藏与复用。原有完整 Lua/XML、血条 / 布局 / 猎人 / 聊天栏回归及清标 10 组检查通过。
- 未确认事项：本次新增排序、菜单实际画面与服务器切换结果尚未在运行中的游戏验收；需 `/reload` 后打开 `/srti` 调整各项左右与第几位，并在拥有权限的队伍 / 团队中检查分配切换。模拟通过不表示已完成游戏实测。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/SimpleRaidTargetIcons)
- [PluginHistory/Evidence/reports/SimpleRaidTargetIcons-20261007.md](../../PluginHistory/Evidence/reports/SimpleRaidTargetIcons-20261007.md)
- [PluginHistory/Evidence/reports/SimpleRaidTargetIcons-borderless-icons-20261007.md](../../PluginHistory/Evidence/reports/SimpleRaidTargetIcons-borderless-icons-20261007.md)
- [PluginHistory/Evidence/reports/CatPotion-魔法橘子沙漏与标记报错修复-20261007.md](../../PluginHistory/Evidence/reports/CatPotion-%E9%AD%94%E6%B3%95%E6%A9%98%E5%AD%90%E6%B2%99%E6%BC%8F%E4%B8%8E%E6%A0%87%E8%AE%B0%E6%8A%A5%E9%94%99%E4%BF%AE%E5%A4%8D-20261007.md)
- [PluginHistory/Evidence/addons_tmp/srti-borderless-backup-20261007/Banana.lua](../../PluginHistory/Evidence/addons_tmp/srti-borderless-backup-20261007/Banana.lua)
- [PluginHistory/Evidence/addons_tmp/srti-borderless-backup-20261007/SimpleRaidTargetIcons.lua](../../PluginHistory/Evidence/addons_tmp/srti-borderless-backup-20261007/SimpleRaidTargetIcons.lua)
- [PluginHistory/Evidence/addons_tmp/srti-borderless-backup-20261007/SimpleRaidTargetIcons.toc](../../PluginHistory/Evidence/addons_tmp/srti-borderless-backup-20261007/SimpleRaidTargetIcons.toc)
- [PluginHistory/Evidence/addons_tmp/srti-layout-health-backup-20261007/Banana.lua](../../PluginHistory/Evidence/addons_tmp/srti-layout-health-backup-20261007/Banana.lua)
- [PluginHistory/Evidence/addons_tmp/srti-layout-health-backup-20261007/RaidTools.lua](../../PluginHistory/Evidence/addons_tmp/srti-layout-health-backup-20261007/RaidTools.lua)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/ChatBar.lua](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/ChatBar.lua)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Banana.lua](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Banana.lua)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Banana.xml](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Banana.xml)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/BananaConfig.xml](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/BananaConfig.xml)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Bindings.xml](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Bindings.xml)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Localization.lua](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Localization.lua)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/SimpleRaidTargetIcons.lua](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/SimpleRaidTargetIcons.lua)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/SimpleRaidTargetIcons.toc](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/SimpleRaidTargetIcons.toc)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/helper_version.ini](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/helper_version.ini)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/SRTIGlow.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/SRTIGlow.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/SRTIRing.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/SRTIRing.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/blank.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/blank.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/cross.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/cross.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/diamond.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/diamond.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/huntermark.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/huntermark.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/moon.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/moon.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/nipple.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/nipple.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/skull.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/skull.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/square.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/square.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/srti_mark.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/srti_mark.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/srti_save.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/srti_save.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/star.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/star.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/triangle.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/triangle.tga)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
