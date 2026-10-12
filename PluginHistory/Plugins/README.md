# 全部插件修改说明

本索引按初始化核对基准中的 **105 个插件目录**逐一建档，整理于 2026-10-09。原先已有零散报告的插件也统一归入独立页面。

已找到维护记录 **51 个**；可核对备份差异但来源待确认 **1 个**；仅确认关联皮肤适配 **2 个**；尚未确认个人修改 **51 个**。这不是“105 个均已修改”的结论。

初始化内容为历史总结；后续实际维护按真实日期记录在各插件页，当前状态统计更新至 2026-10-12。日期/长期笔记存在返工时，优先保留较晚的明确决定，撤回项单列；没有记录的内容等待补充。历史笔记中提到其他客户端路径的，不自动认定也修改了当前安装。

[集中补充入口](../待补充清单.md) · [维护方法](../README.md) · [机器可读索引](../maintenance-index.json)

本次核对基准：`4feabd85022b2e3afbd8c6aca6d94fe7765cf124`。完整初始化标签 `baseline/current-2026-10-08` 是个人使用版，逐文件阶段备份也不等于官方原版。修改说明和 Git 可以帮助人工迁移、回退，不能保证更新器不覆盖文件。

## 查找插件

| 插件 | 证据状态 | 修改目的 / 待确认范围 |
| --- | --- | --- |
| [!Libs](!Libs.md) | 有维护记录 | 补记共享词库差异，并修复 HealComm 群体治疗预估清理。 |
| [Accountant](Accountant.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [ActionBarProfiles](ActionBarProfiles.md) | 有维护记录 | 让天赋切换后动作条完整恢复，减少残留和无效重复加载。 |
| [AdvancedTradeSkillWindow2](AdvancedTradeSkillWindow2.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [ArchiTotem](ArchiTotem.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Atlas](Atlas.md) | 有维护记录 | 让木喉要塞地图编号与首领掉落保持一致。 |
| [AtlasLoot](AtlasLoot.md) | 有维护记录 | 修正地图掉落映射和愿望清单的本地化错误。 |
| [AtlasQuest](AtlasQuest.md) | 有备份差异，来源待确认 | 补记可核对的任务本地化差异。 |
| [AuldLangSyne](AuldLangSyne.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [AutoBar](AutoBar.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [AutoMarker](AutoMarker.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Automatonex](Automatonex.md) | 有维护记录 | 完善模块配置、物品监控及与其他界面的协作。 |
| [Bagshui](Bagshui.md) | 有维护记录 | 重构改为独立 QianKunBag，本体及账户目录保持原样；原 v3.2 改善和 B 键未复现记录保留。 |
| [BetterCharacterStats](BetterCharacterStats.md) | 有维护记录 | 保持角色属性面板布局稳定，并与观察、换天赋功能协调。 |
| [BigWigs](BigWigs.md) | 有维护记录 | 适配乌龟服首领、中文日志以及竖行计时条。 |
| [Blizzard_AuctionUI](Blizzard_AuctionUI.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Blizzard_BattlefieldMinimap](Blizzard_BattlefieldMinimap.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Blizzard_BindingUI](Blizzard_BindingUI.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Blizzard_CombatText](Blizzard_CombatText.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Blizzard_CraftUI](Blizzard_CraftUI.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Blizzard_GMSurveyUI](Blizzard_GMSurveyUI.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Blizzard_InspectUI](Blizzard_InspectUI.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Blizzard_MacroUI](Blizzard_MacroUI.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Blizzard_RaidUI](Blizzard_RaidUI.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Blizzard_TalentUI](Blizzard_TalentUI.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Blizzard_TradeSkillUI](Blizzard_TradeSkillUI.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Blizzard_TrainerUI](Blizzard_TrainerUI.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [BrainwasherPro](BrainwasherPro.md) | 有维护记录 | 切换天赋后可靠地恢复装备、动作条及属性面板。 |
| [BuffTool](BuffTool.md) | 有维护记录 | 简化本职业设置，并让移动模式可靠退出。 |
| [Capslock](Capslock.md) | 有维护记录 | 修正拉人名单的职业颜色。 |
| [Cat](Cat.md) | 有维护记录 | 完善圣骑士输出/坦克逻辑、配置与界面。 |
| [Cat2](Cat2.md) | 有维护记录 | 扩展流程编辑、配置调用和动作条入口。 |
| [CatPotion](CatPotion.md) | 有维护记录 | 扩展常用物品，并完善多配置窗口和使用反馈。 |
| [Cooline](Cooline.md) | 有维护记录 | 短冷却优先，支持 30 分钟；17 组共享技能候选按实际计时归并，修复圣盾/圣佑重复；居中分行、设置预览、雾蓝灰与字体保护。 |
| [Cryolysis](Cryolysis.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Cursive](Cursive.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [DPSMateX](DPSMateX.md) | 有维护记录 | 完善紧凑详情、统计界面及扩展模块入口。 |
| [DPSMateXEncounters](DPSMateXEncounters.md) | 有维护记录 | 提供 Boss/小怪战斗分类与可靠汇总。 |
| [DPSMateXExtend](DPSMateXExtend.md) | 有维护记录 | 让扩展统计详情参与 Boss/小怪汇总。 |
| [DPSMateXExtendMore](DPSMateXExtendMore.md) | 有维护记录 | 统一额外统计与汇总详情的口径。 |
| [DPSMateXInsights](DPSMateXInsights.md) | 有维护记录 | 增加独立的战斗洞察和详情模块。 |
| [EavesDrop](EavesDrop.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [ExtraResourceBars](ExtraResourceBars.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [EzPoison](EzPoison.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [FishingBuddy](FishingBuddy.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Flyout](Flyout.md) | 有维护记录 | 更新左键顺延选用可用条目及 1.12 UseAction 挂接回退。 |
| [GoubayuHeal](GoubayuHeal.md) | 有维护记录 | 更新瞬发人数限制、动作占用、迅捷治愈换目标及牧师驱病顺序。 |
| [HideOutdoorWorldState](HideOutdoorWorldState.md) | 有维护记录 | 已移除：2026-10-10 用户确认不再需要并主动删除；保留历史说明。 |
| [HolyHope](HolyHope.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Interact](Interact.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [LoseControl](LoseControl.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Meeting](Meeting.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [ModernMapMarkers](ModernMapMarkers.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [ModifiedPowerAuras](ModifiedPowerAuras.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [MySlash](MySlash.md) | 有维护记录 | 按新包删除 TT助手 /at 入口。 |
| [NotGrid](NotGrid.md) | 有维护记录 | 修复治疗祷言后预估条持续残留及死亡、满血后的旧显示。 |
| [OneBag](OneBag.md) | 有维护记录 | 解决整理卡灰、油类次数和拆分回归。 |
| [Outfitter](Outfitter.md) | 有维护记录 | 完善快速换装和天赋切换联动。 |
| [PallyPower](PallyPower.md) | 有维护记录 | 增加单人操作与个人祝福，同时修正团队目标判断。 |
| [PizzaWorldBuffs](PizzaWorldBuffs.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [PlayTurtle](PlayTurtle.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [PlayerLinkEnhance](PlayerLinkEnhance.md) | 有维护记录 | 让头像/玩家菜单更紧凑并减少互相干扰。 |
| [QuickHeal](QuickHeal.md) | 有维护记录 | 同步内置 HealComm 预估清理修复，保证库加载顺序兼容。 |
| [QuickReply](QuickReply.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [RaidCheck](RaidCheck.md) | 有维护记录 | 区分未检测成员，并增加团队分配工具。 |
| [Rinse](Rinse.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [STSMmayor](STSMmayor.md) | 有维护记录 | 精简盾牌/修理机器人界面并提高交互预判准确性。 |
| [S_ChatBar](S_ChatBar.md) | 有维护记录 | 集中进入定制插件并完善 Roll 和常用工具。 |
| [S_ItemTip](S_ItemTip.md) | 有维护记录 | 统一观察布局、属性扫描及图标显示。 |
| [S_WorldMap](S_WorldMap.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [ShaguDPS](ShaguDPS.md) | 有维护记录 | 增加标准坦克模式统计视图并给 pfUI 提供多目标仇恨。 |
| [ShaguScan](ShaguScan.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [SimpleRaidTargetIcons](SimpleRaidTargetIcons.md) | 有维护记录 | 完善标记条生命显示、团队工具和透明图标。 |
| [SpecialTalent](SpecialTalent.md) | 有维护记录 | 修复天赋方案翻页、拖动和 ESC 关闭。 |
| [SpiritSenseRec](SpiritSenseRec.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [StatCompare](StatCompare.md) | 有维护记录 | 让属性比较面板与角色/观察窗口协调。 |
| [SuperCleveRoidMacros](SuperCleveRoidMacros.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [SuperMacro](SuperMacro.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [TWThreat](TWThreat.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [TankBuddyEnh](TankBuddyEnh.md) | 有维护记录 | 完善坦克公告开关、技能识别及设置界面。 |
| [TianYan](TianYan.md) | 有维护记录 | 让怪物数量和战斗平均值更可靠。 |
| [Tmog](Tmog.md) | 仅确认关联皮肤适配 | 登记相关皮肤适配，等待确认主插件是否另有个人改动。 |
| [TrainerSkills](TrainerSkills.md) | 仅确认关联皮肤适配 | 登记相关皮肤适配，等待确认主插件是否另有个人改动。 |
| [TurtleMail](TurtleMail.md) | 有维护记录 | 迁入新包筛选、批量邮件、侧栏和皮肤；另修复正文金额缺省单位换算，增加金铜组合并按文本位置选择第一笔完整金额。 |
| [Turtle_General](Turtle_General.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Turtle_GroupUI](Turtle_GroupUI.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [UnitXP_SP3_Addon](UnitXP_SP3_Addon.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [WIM](WIM.md) | 有维护记录 | 保持私聊界面可见，同时避免收到消息抢按键。 |
| [WushuangLoot](WushuangLoot.md) | 有维护记录 | 保留个人交互外观，适配 DLL 和可调速度。 |
| [XyTracker](XyTracker.md) | 有维护记录 | 更新许愿权移交菜单、确认、权限判断及团队同步。 |
| [YGB_OTAlarm](YGB_OTAlarm.md) | 有维护记录 | 修正仇恨报警配置、计时与界面。 |
| [aux-addon](aux-addon.md) | 有维护记录 | 修正充能物品上架，并减少扫描和重复查询。 |
| [diminfo](diminfo.md) | 有维护记录 | 支持渐隐，并消除信息条空白处右键误触。 |
| [hyx](hyx.md) | 有维护记录 | 保留双列表界面，按实际职业能力驱散并浏览完整名单。 |
| [nampowersettings](nampowersettings.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [perfboostsettings](perfboostsettings.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [pfExtend](pfExtend.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [pfQuest](pfQuest.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [pfQuest-turtle](pfQuest-turtle.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [pfUI](pfUI.md) | 有维护记录 | 整合个人界面、监控和旧客户端兼容修改。 |
| [pfUI-CustomMedia](pfUI-CustomMedia.md) | 有维护记录 | 让材质可见、可预览并容易应用。 |
| [pfUI-addonskinner](pfUI-addonskinner.md) | 有维护记录 | 让定制功能及动态窗口沿用 pfUI 外观。 |
| [pfUI-eliteoverlay](pfUI-eliteoverlay.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [pfUI_ExtendedMerchant](pfUI_ExtendedMerchant.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [xNet](xNet.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |

## 初始化之后新增的插件

2026-10-11 新增 **1 个**独立插件，单独记在 maintenance-index.json 的 added_addons；上述历史 105 项及其状态统计不改写。

| 插件 | 证据状态 | 当前交付与待确认 |
| --- | --- | --- |
| [QianKunBag](QianKunBag.md) | 有维护记录 | 独立背包 0.1.0：基础分类/归类、增量刷新；原乾坤袋不动。受控检查通过，游戏验收待补充。 |

## 今后如何维护

每次修改同时更新对应插件页，记录目的、涉及文件、关联插件、真实验证结果和未完成事项，再与本次负责的文件一起提交。不要把“功能本来就有”改写成“本次新增”；用户确认无个人修改时明确写出确认日期。

新增插件时增加说明页与 maintenance-index.json；状态有变化时同步索引。原 addon-catalog.json、baseline-files.json 和 Evidence 保存初始化与历史证据，不为匹配新摘要而改写。

本次检索覆盖：初始化索引、legacy 文件级差异/撤回清单、后续维护报告和备份、24 个插件内的 .workbuddy/memory 笔记、Cat2 开发说明、已有 Git 维护提交，以及 WIM/diminfo/pfUI 相关维护聊天完成报告。未枚举所有聊天，因此“尚未确认”不是无修改证明。

## 2026-10-11 两包更新核对

2026-10-12 新增[三个版本并排对照表](../Research/三版本插件并排对照-20261012.md)，覆盖全部 105 个当前插件：26 个有功能差异、31 个仅当前版包含、48 个三份功能文件相同。只改说明展示，现用插件未更新。

新增用户提供的 10 月 5 日包作为文件对照；[三方核对报告](../Research/三方插件更新核对-20261005-20261010-20261011.md)确认，有维护记录的当前插件中 7 个有原包功能更新、14 个仅个人版差异、10 个功能文件三份相同、15 个两包未包含。本次只分析并补充说明，没有更新插件或改变证据状态；上述初始化清单及统计保持原样。

## 2026-10-12 选定插件更新已实施

[实施记录](../Research/插件更新实施-20261012.md)：更新 11 个插件，S_ItemTip 延期，14 个个人增强版及其他无功能更新插件保留；TurtleMail 先修复金额解析。五个此前无维护依据的插件本次有了新的真实更新记录，初始化目录清单和旧历史证据不作改写。

## 2026-10-12 S_ItemTip 后续合并已实施

此前延期的 S_ItemTip 现已单独完成个人版与 10 日优化合并并覆盖；[实施记录](../Research/S_ItemTip-合并实施-20261012.md)。保留个人面板和负充能修正，85 项受控检查通过，真实游戏验收待完成；此前 11 个插件的实施记录仍作为当时快照保留。
