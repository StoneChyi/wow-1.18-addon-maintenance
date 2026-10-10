# 全部插件修改说明

本索引按初始化核对基准中的 **105 个插件目录**逐一建档，整理于 2026-10-09。原先已有零散报告的插件也统一归入独立页面。

已找到维护记录 **46 个**；可核对备份差异但来源待确认 **1 个**；仅确认关联皮肤适配 **2 个**；尚未确认个人修改 **56 个**。这不是“105 个均已修改”的结论。

初始化内容为历史总结；后续实际维护按真实日期记录在各插件页，当前状态统计更新至 2026-10-11。日期/长期笔记存在返工时，优先保留较晚的明确决定，撤回项单列；没有记录的内容等待补充。历史笔记中提到其他客户端路径的，不自动认定也修改了当前安装。

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
| [Bagshui](Bagshui.md) | 有维护记录 | v3.2 单轮实测隐藏归组显著降低首次迁移，首次同步 62.96/67.48 ms；保留完整功能，待多轮与操作验收。 |
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
| [Cooline](Cooline.md) | 有维护记录 | 短冷却优先，支持 30 分钟；共享打击冷却归并、居中分行、设置预览与雾蓝灰外观，并修复字体报错。 |
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
| [Flyout](Flyout.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [GoubayuHeal](GoubayuHeal.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [HideOutdoorWorldState](HideOutdoorWorldState.md) | 有维护记录 | 已移除：2026-10-10 用户确认不再需要并主动删除；保留历史说明。 |
| [HolyHope](HolyHope.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Interact](Interact.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [LoseControl](LoseControl.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Meeting](Meeting.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [ModernMapMarkers](ModernMapMarkers.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [ModifiedPowerAuras](ModifiedPowerAuras.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [MySlash](MySlash.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
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
| [TurtleMail](TurtleMail.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Turtle_General](Turtle_General.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [Turtle_GroupUI](Turtle_GroupUI.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [UnitXP_SP3_Addon](UnitXP_SP3_Addon.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
| [WIM](WIM.md) | 有维护记录 | 保持私聊界面可见，同时避免收到消息抢按键。 |
| [WushuangLoot](WushuangLoot.md) | 有维护记录 | 保留个人交互外观，适配 DLL 和可调速度。 |
| [XyTracker](XyTracker.md) | 尚未确认个人修改 | 等待确认是否有个人修改 |
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

## 今后如何维护

每次修改同时更新对应插件页，记录目的、涉及文件、关联插件、真实验证结果和未完成事项，再与本次负责的文件一起提交。不要把“功能本来就有”改写成“本次新增”；用户确认无个人修改时明确写出确认日期。

新增插件时增加说明页与 maintenance-index.json；状态有变化时同步索引。原 addon-catalog.json、baseline-files.json 和 Evidence 保存初始化与历史证据，不为匹配新摘要而改写。

本次检索覆盖：初始化索引、legacy 文件级差异/撤回清单、后续维护报告和备份、24 个插件内的 .workbuddy/memory 笔记、Cat2 开发说明、已有 Git 维护提交，以及 WIM/diminfo/pfUI 相关维护聊天完成报告。未枚举所有聊天，因此“尚未确认”不是无修改证明。
