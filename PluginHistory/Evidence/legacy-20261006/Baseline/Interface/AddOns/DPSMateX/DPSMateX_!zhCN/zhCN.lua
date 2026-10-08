--Sunelegy汉化修复
local DPSMateX = DPSMateX

if (GetLocale() == "zhCN") then
	DPSMateX.L["name"] = "DPSMateX输出助手"
	DPSMateX.L["popup"] = "你需要重置DPSMateX数据吗?"
	DPSMateX.L["memory"] = "DPSMateX收集了大量数据，储存数据的过程可能会让您屏幕卡帧。请问您是否需要重置DPSMateX?"
	DPSMateX.L["accept"] = "接受"
	DPSMateX.L["decline"] = "拒绝"
	DPSMateX.L["thorough"] = "彻底"
	DPSMateX.L["total"] = "总体"
	DPSMateX.L["current"] = "当前"
	DPSMateX.L["cancel"] = "取消"
	DPSMateX.L["report"] = "报告"
	DPSMateX.L["reportfor"] = "报告 "
	 
	-- Abilities
	DPSMateX.L["vanish"] = "消失"
	DPSMateX.L["feigndeath"] = "假死"
	DPSMateX.L["divineintervention"] = "神圣干涉"
	DPSMateX.L["stealth"] = "潜行"
	 
	-- Evaluation frame
	DPSMateX.L["procs"] = "触发"
	DPSMateX.L["procstooltip"] = "选择需要在线形图中显示的触发效果."
	DPSMateX.L["absorbsby"] = "吸收--"
	DPSMateX.L["absorbstakenby"] = "被吸收--"
	DPSMateX.L["aurasof"] = "光环-"
	DPSMateX.L["BUDEBU"] = {"Buffs", "Debuffs"}
	DPSMateX.L["castsof"] = "施法来自--"
	DPSMateX.L["sunderarmorof"] = "破甲来自--"
	DPSMateX.L["bname"] = "姓名"
	DPSMateX.L["count"] = "倒数"
	DPSMateX.L["uptime"] = "持续时间"
	DPSMateX.L["chance"] = "机会"
	DPSMateX.L["ccbreakerof"] = "控制失效--"
	DPSMateX.L["time"] = "时间"
	DPSMateX.L["cbt"] = "Beta测试关闭"
	DPSMateX.L["ability"] = "技能"
	DPSMateX.L["target"] = "目标"
	DPSMateX.L["diseasecuredby"] = "解除疾病施法来自--"
	DPSMateX.L["diseasecuredof"] = "疾病被解除--"
	DPSMateX.L["poisoncuredby"] = "解除中毒施法来自--"
	DPSMateX.L["poisoncuredof"] = "解除中毒--"
	DPSMateX.L["dmgdoneby"] = "造成伤害--"
	DPSMateX.L["dmgtakenby"] = "受到伤害--"
	DPSMateX.L["dmgtakensum"] = "造成伤害总量"
	DPSMateX.L["dmgdonesum"] = "受到伤害总量"
	DPSMateX.L["deathsof"] = "死亡--"
	DPSMateX.L["cause"] = "诅咒"
	DPSMateX.L["type"] = "种类"
	DPSMateX.L["healin"] = "治疗在未来--"
	DPSMateX.L["damagein"] = "伤害在未来--"
	DPSMateX.L["decursesby"] = "解除诅咒施法来自--"
	DPSMateX.L["decursesreceivedby"] = "诅咒被解除--"
	DPSMateX.L["dispelsby"] = "驱散施法来自--"
	DPSMateX.L["dispelsreceivedby"] = "被驱散--"
	DPSMateX.L["block"] = "格挡"
	DPSMateX.L["crush"] = "碾压"
	DPSMateX.L["hit"] = "命中"
	DPSMateX.L["average"] = "平均"
	DPSMateX.L["min"] = "最小值"
	DPSMateX.L["max"] = "最大值"
	DPSMateX.L["crit"] = "暴击"
	DPSMateX.L["miss"] = "未命中"
	DPSMateX.L["parry"] = "招架"
	DPSMateX.L["dodge"] = "躲闪"
	DPSMateX.L["resist"] = "抵抗"
	DPSMateX.L["glance"] = "偏斜"
	DPSMateX.L["effhealdoneby"] = "有效治疗来自--"
	DPSMateX.L["effhealtakenby"] = "受到有效治疗--"
	DPSMateX.L["failsof"] = "失误--"
	DPSMateX.L["victim"] = "击杀"
	DPSMateX.L["ffby"] = "队友误伤来自--"
	DPSMateX.L["healdoneby"] = "治疗来自--"
	DPSMateX.L["habby"] = "治疗和吸收来自--"
	DPSMateX.L["healtakenby"] = "受到治疗--"
	DPSMateX.L["interruptsby"] = "打断来自"
	DPSMateX.L["magicliftby"] = "魔法施加来自--"
	DPSMateX.L["magicliftof"] = "受到魔法施加--"
	DPSMateX.L["overhealby"] = "过量治疗来自--"
	DPSMateX.L["procsof"] = "触发--"
	 
	-- Menu
	DPSMateX.L["mdps"] = "显示DPS统计."
	DPSMateX.L["mdmg"] = "显示伤害统计."
	DPSMateX.L["mdmgtaken"] = "显示受到伤害统计."
	DPSMateX.L["medd"] = "显示敌人伤害统计."
	DPSMateX.L["medt"] = "显示敌人受到伤害统计."
	DPSMateX.L["mhealing"] = "显示有效治疗统计."
	DPSMateX.L["mhab"] = "显示吸收造成有效治疗统计."
	DPSMateX.L["mhealingtaken"] = "显示受到治疗统计."
	DPSMateX.L["moverhealing"] = "显示过量治疗统计."
	DPSMateX.L["minterrupts"] = "显示打断统计."
	DPSMateX.L["mdeaths"] = "显示死亡统计."
	DPSMateX.L["mdispels"] = "显示驱散统计."
	DPSMateX.L["totalmode"] = "设置为总计模式."
	DPSMateX.L["currentmode"] = "设置为当前模式."
	DPSMateX.L["reportsegment"] = "报告这段数据."
	DPSMateX.L["resetdesc"] = "重置DPSMateX."
	DPSMateX.L["newsegment"] = "新段数据"
	DPSMateX.L["newsegmentdesc"] = "开始新段数据."
	DPSMateX.L["removesegment"] = "删除数据段"
	DPSMateX.L["removesegmentdesc"] = "删除一条数据段."
	DPSMateX.L["lockdesc"] = "锁定DPSMateX界面."
	DPSMateX.L["hidewindowdesc"] = "隐藏DPSMateX界面."
	DPSMateX.L["showwindowdesc"] = "显示DPSMateX界面."
	DPSMateX.L["configframe"] = "打开配置界面."
	DPSMateX.L["testmodedesc"] = "切换测试模式."
	DPSMateX.L["filterdesc"] = "筛选选项."
	DPSMateX.L["switchdesc"] = "切换模式"
	DPSMateX.L["mcurrent"] = "当前战斗"
	DPSMateX.L["mrealtime"] = "创建实时图表"
	DPSMateX.L["mrealtimedesc"] = '创建实时图表，此功能占用大量系统资源.'
	DPSMateX.L["damagedone"] = "造成伤害"
	DPSMateX.L["realtimedmgdone"] = '选择此界面中相应的造成伤害.'
	DPSMateX.L["realtimedmgtaken"] = '选择此界面中相应的受到伤害.'
	DPSMateX.L["realtimehealing"] = '选择此界面中相应的总治疗.'
	DPSMateX.L["realtimeehealing"] = '选择此界面中相应的有效治疗.'
	DPSMateX.L["showAll"] = "显示全部"
	DPSMateX.L["showAllDesc"] = '点击，显示所有界面'
	DPSMateX.L["hideAll"] = "隐藏全部"
	DPSMateX.L["hideAllDesc"] = '点击，隐藏所有界面'
	DPSMateX.L["showwindow"] = "显示窗口"
	DPSMateX.L["hidewindow"] = "隐藏窗口"
	DPSMateX.L["unlock"] = "解锁窗口"
	DPSMateX.L["config"] = "配置"
	DPSMateX.L["reportdesc"] = "报告细节"
	DPSMateX.L["whisper"] = "密语"
	DPSMateX.L["whisperdesc"] = "对某人密语"
	DPSMateX.L["classes"] = "职业"
	DPSMateX.L["classesdesc"] = "选择职业"
	DPSMateX.L["warrior"] = "战士"
	DPSMateX.L["rogue"] = "盗贼"
	DPSMateX.L["warlock"] = "术士"
	DPSMateX.L["mage"] = "法师"
	DPSMateX.L["paladin"] = "圣骑士"
	DPSMateX.L["shaman"] = "萨满祭司"
	DPSMateX.L["priest"] = "牧师"
	DPSMateX.L["druid"] = "德鲁伊"
	DPSMateX.L["hunter"] = "猎人"
	DPSMateX.L["warriordesc"] = "显示战士"
	DPSMateX.L["roguedesc"] = "显示盗贼"
	DPSMateX.L["warlockdesc"] = "显示术士"
	DPSMateX.L["magedesc"] = "显示法师"
	DPSMateX.L["paladindesc"] = "显示圣骑士"
	DPSMateX.L["shamandesc"] = "显示萨满祭司"
	DPSMateX.L["priestdesc"] = "显示牧师"
	DPSMateX.L["druiddesc"] = "显示德鲁伊"
	DPSMateX.L["hunterdesc"] = "显示猎人"
	DPSMateX.L["certainnames"] = "几个名字"
	DPSMateX.L["certainnamesdesc"] = '分离-- "," 例如: Shino,'
	DPSMateX.L["grouponly"] = "仅队友"
	DPSMateX.L["grouponlydesc"] = "只显示队友数据"
	 
	-- Config menu
	DPSMateX.L["slider"] = "条数"
	DPSMateX.L["slidertooltip"] = "移动来设定报告条数."
	DPSMateX.L["editboxtitle"] = "密语目标"
	DPSMateX.L["editboxtooltip"] = "输入需要报告目标的名字."
	DPSMateX.L["channel"] = "频道"
	DPSMateX.L["channeltooltip"] = "选择你需要报告的频道."
	DPSMateX.L["close"] = "关闭"
	DPSMateX.L["minimapleft"] = "左键拖动来移动图标."
	DPSMateX.L["minimapright"] = "右键打开菜单."
	DPSMateX.L["window"] = "窗口设置"
	DPSMateX.L["bars"] = "数据条设置"
	DPSMateX.L["titlebar"] = "标题栏设置"
	DPSMateX.L["content"] = "显示窗设置"
	DPSMateX.L["modeswitching"] = "正在切换模式"
	DPSMateX.L["dataresets"] = "数据重置"
	DPSMateX.L["generaloptions"] = "通用选项"
	DPSMateX.L["columns"] = "窗口内容"
	DPSMateX.L["tooltips"] = "鼠标浮窗"
	DPSMateX.L["broadcasting"] = "技能通报"
	DPSMateX.L["about"] = "关于"
	DPSMateX.L["createwindow"] = "创建窗口"
	DPSMateX.L["createwindowtooltip"] = "输入窗口名字."
	DPSMateX.L["submit"] = "创建"
	DPSMateX.L["submitTooltip"] = "点击创建窗口."
	DPSMateX.L["availwindows"] = "可用窗口"
	DPSMateX.L["availwindowsTooltip"] = "选择一个窗口."
	DPSMateX.L["lock"] = "锁定窗口"
	DPSMateX.L["testmode"] = "测试模式"
	DPSMateX.L["barfont"] = "字体"
	DPSMateX.L["barfontTooltip"] = "选择字体."
	DPSMateX.L["barfontsize"] = "字号"
	DPSMateX.L["barfontsizeTooltip"] = "移动来修改字号."
	DPSMateX.L["barfontflags"] = "字体效果"
	DPSMateX.L["barfontflagsTooltip"] = "选择字体效果."
	DPSMateX.L["bartexture"] = "材质"
	DPSMateX.L["bartextureTooltip"] = "选择材质."
	DPSMateX.L["barspacing"] = "条间隔"
	DPSMateX.L["barspacingTooltip"] = "移动来修改条间隔."
	DPSMateX.L["barheight"] = "条高度"
	DPSMateX.L["barheightTooltip"] = "移动来修改条高度."
	DPSMateX.L["classicons"] = "职业图标"
	DPSMateX.L["ranks"] = "排名"
	DPSMateX.L["mode"] = "模式"
	DPSMateX.L["modes"] = "模块选择"
	DPSMateX.L["reset"] = "重置"
	DPSMateX.L["sync"] = "同步"
	DPSMateX.L["bgcolor"] = "背景颜色"
	DPSMateX.L["fontcolor"] = "字体颜色"
	DPSMateX.L["fontcolorTooltip"] = "点击选择字体颜色."
	DPSMateX.L["bgcolorTooltip"] = "点击选择背景颜色."
	DPSMateX.L["scale"] = "比例"
	DPSMateX.L["scaleTooltip"] = "移动来修改界面比例."
	DPSMateX.L["opacity"] = "透明度"
	DPSMateX.L["opacityTooltip"] = "移动来修改界面透明度."
	DPSMateX.L["bgtex"] = "背景材质"
	DPSMateX.L["bgtexTooltip"] = "修改界面材质."
	DPSMateX.L["enterworldinstance"] = "世界/副本"
	DPSMateX.L["enterworldinstanceTooltip"] = "当进入世界或副本时重置."
	DPSMateX.L["joinparty"] = "加入小队"
	DPSMateX.L["joinpartyTooltip"] = "当加入小队时重置."
	DPSMateX.L["leavingparty"] = "离开队伍"
	DPSMateX.L["leavingpartyTooltip"] = "当离开队伍时重置."
	DPSMateX.L["partymemberchanged"] = "队伍成员改变"
	DPSMateX.L["partymemberchangedTooltip"] = "当队伍成员改变时重置."
	DPSMateX.L["minimap"] = "显示小地图图标"
	DPSMateX.L["showtotal"] = "显示总计"
	DPSMateX.L["solo"] = "不在队伍时隐藏"
	DPSMateX.L["combat"] = "战斗时隐藏"
	DPSMateX.L["bossfights"] = "仅保存Boss战数据"
	DPSMateX.L["pvp"] = "PvP时隐藏"
	DPSMateX.L["disable"] = "隐藏时禁用"
	DPSMateX.L["mergepets"] = "融合宠物数据"
	DPSMateX.L["collectgarbage"] = "快速垃圾回收"
	DPSMateX.L["numberformat"] = "数字格式"
	DPSMateX.L["numberformatTooltip"] = "控制数字显示格式."
	DPSMateX.L["segments"] = "数据段"
	DPSMateX.L["segmentsTooltip"] = "移动来提高收集数据段，此操作会造成游戏延时!!!"
	DPSMateX.L["enable"] = "启用"
	DPSMateX.L["damage"] = "伤害量"
	DPSMateX.L["percent"] = "百分比"
	DPSMateX.L["dps"] = "每秒伤害"
	DPSMateX.L["edps"] = "EDPS每秒有效伤害"
	DPSMateX.L["dtps"] = "DTPS每秒承受伤害"
	DPSMateX.L["edtps"] = "EDTPS每秒承受有效伤害"
	DPSMateX.L["healing"] = "治疗量"
	DPSMateX.L["hps"] = "每秒治疗量"
	DPSMateX.L["ehps"] = "EHPS每秒有效治疗"
	DPSMateX.L["etps"] = "ETPS每秒有效仇恨"
	DPSMateX.L["damagetaken"] = "受到伤害"
	DPSMateX.L["enemydamagedone"] = "敌人造成伤害"
	DPSMateX.L["enemydamagetaken"] = "敌人受到伤害"
	DPSMateX.L["absorbs"] = "吸收"
	DPSMateX.L["absorbstaken"] = "接受吸收量"
	DPSMateX.L["amount"] = "次数"
	DPSMateX.L["dispelsreceived"] = "受到驱散"
	DPSMateX.L["decurses"] = "解除诅咒"
	DPSMateX.L["decursesreceived"] = "受到解除诅咒"
	DPSMateX.L["curedisease"] = "解除疾病"
	DPSMateX.L["curepoison"] = "解除中毒"
	DPSMateX.L["liftmagic"] = "解除魔法"
	DPSMateX.L["aurasgained"] = "获得光环"
	DPSMateX.L["auraslost"] = "失去光环"
	DPSMateX.L["aurauptime"] = "光环持续时间"
	DPSMateX.L["friendlyfire"] = "友方误伤"
	DPSMateX.L["procs"] = "触发"
	DPSMateX.L["liftmagicreceived"] = "受到解除魔法"
	DPSMateX.L["curepoisonreceived"] = "受到解除中毒"
	DPSMateX.L["curediseasereceived"] = "受到解除疾病"
	DPSMateX.L["effectivehealing"] = "有效治疗"
	DPSMateX.L["effectivehps"] = "HPS每秒有效治疗"
	DPSMateX.L["effectivehealingtaken"] = "受到有效治疗"
	DPSMateX.L["healingandabsorbs"] = "治疗和吸收"
	DPSMateX.L["healingtaken"] = "受到治疗"
	DPSMateX.L["overhealing"] = "过量治疗"
	DPSMateX.L["interrupts"] = "打断"
	DPSMateX.L["deaths"] = "死亡"
	DPSMateX.L["dispels"] = "驱散"
	DPSMateX.L["threat"] = "仇恨"
	DPSMateX.L["tps"] = "每秒仇恨"
	DPSMateX.L["fails"] = "失误"
	DPSMateX.L["cat"] = "种类"
	DPSMateX.L["ccbreaker"] = "控制失效"
	DPSMateX.L["subviewrows"] = "浮窗数据行数"
	DPSMateX.L["subviewrowsTooltip"] = "移动来调整浮窗内的数据显示行数."
	DPSMateX.L["TooltipPositionDropDown"] = "鼠标浮窗位置"
	DPSMateX.L["TooltipPositionDropDownTooltip"] = "选择鼠标指向后，显示数据的浮窗位置."
	DPSMateX.L["whatisdpsmatex"] = "DPSMateX是什么?"
	DPSMateX.L["whatisdpsmatexText"] = "DPSMateX是一款战斗分析插件.可以用详细的数据来评定玩家的游戏表现."
	DPSMateX.L["whocreateddpsmatex"] = "谁制作了DPSMateX?"
	DPSMateX.L["whocreateddpsmatexText"] = "DPSMateX由Shino制作"
	DPSMateX.L["thanksto"] = "感谢以下贡献者:"
	DPSMateX.L["thankstoText"] = "Sunelegy - 汉化修复"
	DPSMateX.L["remove"] = "删除"
	DPSMateX.L["removeTooltip"] = "点击来删除选择窗口."
	DPSMateX.L["copy"] = "复制"
	DPSMateX.L["copyTooltip"] = "点击来复制配置到选择窗口."
	DPSMateX.L["configto"] = "复制配置到:"
	DPSMateX.L["configtoTooltip"] = "选择你要配置的窗口."
	DPSMateX.L["configfrom"] = "复制配置由--:"
	DPSMateX.L["configfromTooltip"] = "选择你想要复制配置到的窗口."
	DPSMateX.L["reset"] = "重置"
	DPSMateX.L["syncrequest"] = "同步重置请求"
	DPSMateX.L["syncrequesttooltip"] = "同步重置请求出现时会发生什么？"
	DPSMateX.L["dataresetslogout"] = "退出游戏重置请求"
	DPSMateX.L["dataresetslogouttooltip"] = "退出游戏重置"
	DPSMateX.L["enabledisable"] = "启用/禁用"
	DPSMateX.L["bgbarcolor"] = "背景条颜色"
	DPSMateX.L["bgbarcolorTooltip"] = "点击来选择背景条颜色."
	DPSMateX.L["displayoptions"] = "显示选项"
	DPSMateX.L["filter"] = "玩家选择"
	DPSMateX.L["raidleader"] = "团长选项"
	DPSMateX.L["bgOpacityTooltip"] = "调整背景透明度."
	DPSMateX.L["bgOpacity"] = "背景透明度"
	DPSMateX.L["casts"] = "施法"
	DPSMateX.L["sunderarmor"] = "破甲"
	DPSMateX.L["locktooltip"] = "选择此项来锁定界面."
	DPSMateX.L["testmodetooltip"] = "选择此项来激活测试模式."
	DPSMateX.L["classiconstooltip"] = "选择此项来显示职业图标在状态条上."
	DPSMateX.L["rankstooltip"] = "选择此项来显示排名位置."
	DPSMateX.L["enabletitlebartooltip"] = "选择此项来启用题目条."
	DPSMateX.L["buttonshowtooltip"] = "选择此项来显示图标在题目条上."
	DPSMateX.L["minimaptooltip"] = "选择此项来显示小地图图标."
	DPSMateX.L["showtotaltooltip"] = "选择此项来获得一条额外的数据条来显示总计数据."
	DPSMateX.L["solotooltip"] = "当你不在队伍的时候，选择此项来隐藏界面，."
	DPSMateX.L["combattooltip"] = "当你进入战斗的时候，选择此项来隐藏界面，."
	DPSMateX.L["bossfightstooltip"] = "选择此项来只保存Boss战数据."
	DPSMateX.L["pvptooltip"] = "当你进入战场的时候，选择此项来隐藏界面."
	DPSMateX.L["disabletooltip"] = "当界面隐藏的时候，选择此项来禁用数据收集."
	DPSMateX.L["mergepetstooltip"] = "选择此项来融合宠物伤害."
	DPSMateX.L["collectgarbagetooltip"] = "快速垃圾回收，减轻卡顿."
	DPSMateX.L["showtooltips"] = "启用鼠标浮窗"
	DPSMateX.L["showtooltipsTooltip"] = "选择此项来启用鼠标浮窗."
	DPSMateX.L["informativetooltips"] = "浮窗详细数据"
	DPSMateX.L["informativetooltipsTooltip"] = "选择此项来让浮窗内显示更多数据细节."
	DPSMateX.L["shownmodes"] = "启用的模块"
	DPSMateX.L["hiddenmodes"] = "禁用的模块"
	DPSMateX.L["moveleftTooltip"] = "点击将该模块移入显示列表."
	DPSMateX.L["moverightTooltip"] = "点击将该模块移入隐藏列表."
	DPSMateX.L["helloworld"] = "Hello World!"
	DPSMateX.L["helloworldTooltip"] = "返回同步频道的玩家列表."
	DPSMateX.L["enablebroadcasting"] = "选择此项来启用以下广播选项."
	DPSMateX.L["useraidwarning"] = "团队通知频道"
	DPSMateX.L["useraidwarningTooltip"] = "选择此项会将信息发送在团队通知频道(RW)，不选默认发送在团队频道."
	DPSMateX.L["relevantcds"] = "相关技能CD"
	DPSMateX.L["relevantcdsTooltip"] = "选择此项来广播相关技能CD，例如盾墙."
	DPSMateX.L["ress"] = "复活"
	DPSMateX.L["ressTooltip"] = "选择此项来广播玩家是否接受了复活."
	DPSMateX.L["killingblows"] = "致命一击"
	DPSMateX.L["killingblowsTooltip"] = "选择此项来广播玩家是否死于致命一击."
	DPSMateX.L["failsTooltip"] = "选择此项来广播玩家是否失误(友方误伤/受到伤害/受到Debuff)."
	DPSMateX.L["framesavailable"] = "以下的界面是可用的，如果没有显示请输入/config."
	DPSMateX.L["slashabout"] = "|c3ffddd80About:|r Sunelegy乌龟服定制版."
	DPSMateX.L["slashusage"] = "|c3ffddd80Usage:|r /dps {lock|unlock|show|hide|config}"
	DPSMateX.L["slashlock"] = "|c3ffddd80- lock:|r 锁定窗口."
	DPSMateX.L["slashunlock"] = "|c3ffddd80- unlock:|r 解锁窗口."
	DPSMateX.L["slashshowAll"] = "|c3ffddd80- showAll:|r 显示所有窗口."
	DPSMateX.L["slashhideAll"] = "|c3ffddd80- hideAll:|r 隐藏所有窗口."
	DPSMateX.L["slashshow"] = "|c3ffddd80- show {name}:|r 显示以下名字的窗口: {name}."
	DPSMateX.L["slashhide"] = "|c3ffddd80- hide {name}:|r 隐藏以下名字的窗口: {name}."
	DPSMateX.L["slashconfig"] = "|c3ffddd80- config:|r 打开配置菜单."
	DPSMateX.L["bccdo"] = function(who, what) return who.." 获得 "..what end
	DPSMateX.L["bccdt"] = function(who, what) return who.." 的 "..what.." 消失" end
	DPSMateX.L["bcress"] = function(who, what) return what.." 被复活，来自-- "..who end
	DPSMateX.L["bckb"] = function(who, what, with, value) return who.." 被击杀，来自-- "..what.."s "..with.." ("..value.." 伤害)" end
	DPSMateX.L["bcfailo"] = function(what, who, value, with) return "失误: "..what.." 友方误伤 "..who.." "..value.." 伤害 "..with end
	DPSMateX.L["bcfailt"] = function(who, with) return "失误: "..who.." 被折磨 "..with end
	DPSMateX.L["bcfailth"] = function(who, value, with, what) return "失误: "..who.." 遭受 "..value.." 伤害来自 "..with.." 由 "..what end
	DPSMateX.L["syncreseterror"] = "当同步模式启动时，DPSMateX不能重置."
	DPSMateX.L["resetnotofficererror"] = "你不是队长或者你没有A!"
	DPSMateX.L["findusererror"] = "找不到这个用户!"
	DPSMateX.L["yes"] = "是"
	DPSMateX.L["no"] = "否"
	DPSMateX.L["ask"] = "问"
	DPSMateX.L["normal"] = "正常"
	DPSMateX.L["condensed"] = "扼要的"
	DPSMateX.L["default"] = "默认"
	DPSMateX.L["topright"] = "右上"
	DPSMateX.L["topleft"] = "左上"
	DPSMateX.L["left"] = "左"
	DPSMateX.L["top"] = "上"
	DPSMateX.L["gchannel"] = {[1]="Raid",[2]="Party",[3]="Say",[4]="Officer",[5]="Guild"}
	DPSMateX.L["nodetailserror"] = "没有可以报告的细节."
	DPSMateX.L["reportof"] = "报告--"
	DPSMateX.L["opendetails"] = "打开细节"
	DPSMateX.L["reportdetails"] = "报告这名用户的细节."
	DPSMateX.L["fdetailsfor"] = "战斗细节--"
	DPSMateX.L["removesegmentof"] = "删除数据段"
	DPSMateX.L["lockedallw"] = "锁定所有窗口."
	DPSMateX.L["unlockedallw"] = "解锁所有窗口."
	DPSMateX.L["leftclickopend"] = "左键点击来打开细节."
	DPSMateX.L["rightclickopenm"] = "右键点击来打开菜单."
	DPSMateX.L["hide"] = "隐藏"
	DPSMateX.L["show"] = "显示"
	DPSMateX.L["rcchangemode"] = "右键点击来切换统计模式."
	DPSMateX.L["segment"] = "时间选择"
	DPSMateX.L["sync"] = "同步"
	DPSMateX.L["alliance"] = "联盟"
	DPSMateX.L["horde"] = "部落"
	DPSMateX.L["unknown"] = "未知目标"
	DPSMateX.L["Blessing of the Holy Spring"] = "圣泉祝福"
	DPSMateX.L["votestartederror"] = "投票已经开始!"
	DPSMateX.L["votefailederror"] = "重置投票失败!"
	DPSMateX.L["votesuccess"] = "重置投票成功!DPSMateX已经成功重置数据"
	DPSMateX.L["disease"] = "疾病"
	DPSMateX.L["magic"] = "魔法"
	DPSMateX.L["curse"] = "诅咒"
	DPSMateX.L["poison"] = "中毒"
	DPSMateX.L["physical"] = "物理"
	DPSMateX.L["debufftaken"] = "受到Debuff"
	DPSMateX.L["buffs"] = "Buffs"
	DPSMateX.L["debuffs"] = "Debuffs"
	 
	DPSMateX.L["mc"] = "熔火之心"
	DPSMateX.L["bwl"] = "黑翼之巢"
	DPSMateX.L["ony"] = "奥妮克希亚的巢穴"
	DPSMateX.L["zg"] = "祖尔格拉布"
	DPSMateX.L["aq401"] = "安其拉废墟"
	DPSMateX.L["aq20"] = "安其拉神庙"
	DPSMateX.L["aq402"] = "安其拉"
	DPSMateX.L["naxx"] = "纳克萨玛斯"
	DPSMateX.L["azs"] = "艾萨拉"
	DPSMateX.L["bl"] = "诅咒之地"
	DPSMateX.L["dw"] = "暮色森林"
	DPSMateX.L["hintl"] = "辛特兰"
	DPSMateX.L["ash"] = "灰谷"
	DPSMateX.L["fe"] = "菲拉斯"
	
	DPSMateX.L["switchgraphsdesc"] = "切换图像"
	DPSMateX.L["switchindividualsdesc"] = "个人/总计"
	DPSMateX.L["OHPS"] = "OHPS每秒过量治疗"
	DPSMateX.L["OHealingTaken"] = "受到过量治疗"
	DPSMateX.L["eohps"] = "EOHPS"
	DPSMateX.L["ohealtakenby"] = "受到过量治疗来自"
	DPSMateX.L["friendlyfiretaken"] = "受到友方误伤"
	DPSMateX.L["fftby"] = "受到友方误伤来自"
	DPSMateX.L["poisoncleansingtotem"] = "清毒图腾"
	DPSMateX.L["threatdoneby"] = "制造仇恨来自"
	DPSMateX.L["periodic"] = "(周期的)"
	DPSMateX.L["reportchannel"] = {[1]=DPSMateX.L["whisper"],[2]="Raid",[3]="Party",[4]="Say",[5]="Officer",[6]="Guild"}
	DPSMateX.L["raid"] = "团队"
	DPSMateX.L["activity"] = "激活: "
	DPSMateX.L["of"] = "--"
	DPSMateX.L["comparewith"] = "对比和"
	DPSMateX.L["comparewithdesc"] = "选择一个和此玩家对比的玩家."
	DPSMateX.L["targetscale"] = "评定界面比例"
	DPSMateX.L["targetscaleTooltip"] = "修改评定界面比例."
	DPSMateX.L["eddsum"] = "敌人伤害总计"
	DPSMateX.L["edtsum"] = "敌人受到伤害总计"
	DPSMateX.L["ehpssum"] = "有效治疗总计"
	DPSMateX.L["tehealing"] = "有效治疗"
	DPSMateX.L["hpssum"] = "治疗总计"
	DPSMateX.L["thealing"] = "治疗"
	DPSMateX.L["ohpssum"] = "过量治疗总计"
	DPSMateX.L["tohealing"] = "过量治疗"
	DPSMateX.L["tehealingtaken"] = "受到有效治疗"
	DPSMateX.L["ehpstsum"] = "受到有效治疗总计"
	DPSMateX.L["thealingtaken"] = "受到治疗"
	DPSMateX.L["hpstsum"] = "受到治疗总计"
	DPSMateX.L["tohealingtaken"] = "受到过量治疗"
	DPSMateX.L["ohpstsum"] = "受到过量治疗总计"
	DPSMateX.L["habsum"] = "治疗和吸收总计"
	DPSMateX.L["threatdone"] = "制造仇恨"
	DPSMateX.L["threatsum"] = "制造仇恨总计"
	DPSMateX.L["ffsum"] = "友方误伤总计"
	DPSMateX.L["fftsum"] = "受到友方误伤总计"
	DPSMateX.L["over"] = "超过"
	DPSMateX.L["lastability"] = "最后三次命中"
	DPSMateX.L["deathssum"] = "死亡总计"
	DPSMateX.L["victim"] = "见证"
	DPSMateX.L["deathhistory"] = "死亡历史"
	DPSMateX.L["intersum"] = "打断总计"
	DPSMateX.L["dispelssum"] = "驱散总计"
	DPSMateX.L["dispels"] = "驱散"
	DPSMateX.L["decursessum"] = "解除诅咒总计"
	DPSMateX.L["liftmagicsum"] = "剩余魔法总计"
	DPSMateX.L["curediseasesum"] = "驱散疾病总计"
	DPSMateX.L["curepoisonsum"] = "驱散中毒总计"
	DPSMateX.L["ccbreakersum"] = "控制失效总计"
	DPSMateX.L["failssum"] = "失误总计"
	DPSMateX.L["AutoAttack"] = "自动攻击"
	DPSMateX.L["AutoAttackOffhand"] = "自动攻击(副手)"
	DPSMateX.L["AutoShot"] = "自动射击"
	DPSMateX.L["castssum"] = "施法总计"
	DPSMateX.L["sunderarmorsum"] = "施法总计"
	DPSMateX.L["procssum"] = "触发总计"
	DPSMateX.L["aurassum"] = "光环总计"
	DPSMateX.L["absorbssum"] = "吸收总计"
	DPSMateX.L["absorbeddmg"] = "吸收"
	DPSMateX.L["absorbstakensum"] = "受到吸收总计"
	DPSMateX.L["activity"] = "激活"
	DPSMateX.L["Environment"] = "环境"
	
	DPSMateX.L["cbtdisplay"] = "禁用Beta测试显示"
	DPSMateX.L["disablebarbg"] = "禁用背景"
	DPSMateX.L["disablebarbgtooltip"] = "禁用所有未完成数据条的背景."
	DPSMateX.L["totalbaropacity"] = "总数据条的透明度"
	DPSMateX.L["totalbaropacitytooltip"] = "调整总数据条透明度."
	DPSMateX.L["abortvote"] = "中止重置命令.团队和A有权中止重置命令，如果你操作够快的话."
	DPSMateX.L["resetaborted"] = "重置命令被中止，重置命令将有20秒的冷却时间."
	
	DPSMateX.L["vreset"] = "重置"
	DPSMateX.L["vdreset"] = "不要重置"
	DPSMateX.L["togglereportframe"] = "切换报告界面"
	DPSMateX.L["toggleframes"] = "切换界面"
	DPSMateX.L["resetdpsmatex"] = "重置DPSMateX"
	DPSMateX.L["columnstooltip"] = "选择后将在数据条显示此项信息."
	DPSMateX.L["commas"] = "逗号"
	DPSMateX.L["versionisold"] = "您的DPSMateX版本过期，请更新！DPSMateX只同步最新版本."
	DPSMateX.L["rezz"] = "复活"
	DPSMateX.L["rezzof"] = "复活--"
	DPSMateX.L["rezzsum"] = "复活总计"
	DPSMateX.L["activity"] = "激活"
	DPSMateX.L["cbtdisplay"] = "禁用Beta测试显示"
	DPSMateX.L["semicondensed"] = "半-扼要的"
	DPSMateX.L["loginhide"] = "登入游戏时隐藏"
	DPSMateX.L["borderOpacityTooltip"] = "调整边框透明度."
	DPSMateX.L["borderOpacity"] = "边框透明度"
	DPSMateX.L["bordertextureTooltip"] = "选择边框材质."
	DPSMateX.L["bordertexture"] = "边框材质"
	DPSMateX.L["borderstrataTooltip"] = "选择边框层，会让边框变成背景或者前景."
	DPSMateX.L["borderstrata"] = "边框层"
	DPSMateX.L["bordercolor"] = "边框颜色"
	DPSMateX.L["bordercolorTooltip"] = "调整边框颜色."
	DPSMateX.L["reportdelaytooltip"] = "添加延迟以防止在某些服务器无法发送信息到聊天框."
	DPSMateX.L["delay"] = "Delay"
	
	DPSMateX.L["tttop"] = "前"
	DPSMateX.L["ttdamage"] = "伤害"
	DPSMateX.L["tthealing"] = "治疗"
	DPSMateX.L["ttpet"] = "宠物"
	DPSMateX.L["ttpet2"] = "宠物:"
	DPSMateX.L["ttabilities"] = "技能"
	DPSMateX.L["ttattacked"] = "目标输出"
	DPSMateX.L["tthealed"] = "被治疗"
	DPSMateX.L["ttinterrupt"] = "打断"
	DPSMateX.L["ttinterrupted"] = "被打断"
	DPSMateX.L["ttdispelled"] = "被驱散"
	DPSMateX.L["ttabsorbed"] = "被吸收"
	DPSMateX.L["ttabsorb"] = "吸收"
	DPSMateX.L["ttthreat"] = "仇恨"
	DPSMateX.L["Character Name Change"] = "更改角色名称"
	
	--wjf add
	DPSMateX.L["Remove Curse"] = "解除诅咒"
	DPSMateX.L["Cleanse"] = "清洁术"
	DPSMateX.L["Remove Lesser Curse"] = "解除次级诅咒"
	DPSMateX.L["Purify"] = "纯净术"
	DPSMateX.L["Dispel Magic"] = "驱散魔法"
	DPSMateX.L["Abolish Poison"] = "驱毒术"
	DPSMateX.L["Abolish Disease"] = "驱除疾病"
	DPSMateX.L["Devour Magic"] = "吞噬魔法"
	DPSMateX.L["Cure Disease"] = "祛病术"
	DPSMateX.L["Poison Cleansing Totem"] = "清毒图腾"
	DPSMateX.L["Cure Poison"] = "消毒术"
	DPSMateX.L["Disease Cleansing Totem"] = "祛病图腾"
	DPSMateX.L["Purge"] = "净化术"
	-- Potion
	DPSMateX.L["Powerful Anti-Venom"] = "强效抗毒药剂"
	DPSMateX.L["Restoration"] = "恢复"
	DPSMateX.L["Purification"] = "净化"
	DPSMateX.L["Purification Potion"] = "净化药水"
	DPSMateX.L["Restorative Potion"] = "滋补药剂"
	DPSMateX.L["Elixir of Poison Resistance"] = "抗毒药水"
	--proc
	DPSMateX.L["Earthstrike"] = "大地之击"
	DPSMateX.L["Juju Flurry"] = "魂能之速"
	DPSMateX.L["Holy Strength"] = "神圣力量"
	DPSMateX.L["Ephemeral Power"] = "短暂强力"
	DPSMateX.L["Chromatic Infusion"] = "多彩能量"
	DPSMateX.L["Brittle Armor"] = "脆弱护甲"
	DPSMateX.L["Unstable Power"] = "能量无常"
	DPSMateX.L["Zandalarian Hero Medallion"] = "充沛之力"
	DPSMateX.L["Ascendance"] = "优越"
	DPSMateX.L["Essence of Sapphiron"] = "萨菲隆的精华"
	DPSMateX.L["Hand of Justice"] = "正义之手"
	DPSMateX.L["Sword Specialization"] = "剑类武器专精"
	DPSMateX.L["Bonereaver's Edge"] = "削骨之刃"
	DPSMateX.L["Windfury Weapon"] = "风怒武器"
	DPSMateX.L["Windfury Totem"] = "风怒图腾"
	DPSMateX.L["Eternal Strike"] = "永恒打击"
	DPSMateX.L["Hack and Slash"] = "劈斩"
	DPSMateX.L["Fury of Forgewright"] = "铸铁之怒"
	DPSMateX.L["Flurry Axe"] = "风暴战斧"
	
	--kick
	-- Interrupts
	-- Rogue
	DPSMateX.L["Kick"] = "脚踢"
	-- Warrior
	DPSMateX.L["Pummel"] = "拳击"
	DPSMateX.L["Shield Bash"] = "盾击"
	-- Mage
	DPSMateX.L["Counterspell"] = "法术反制"
	-- Shaman
	DPSMateX.L["Earth Shock"] = "地震术"
	-- Priest
	DPSMateX.L["Silence"] = "沉默"
	-- Stuns
	-- Rogue
	DPSMateX.L["Gouge"] = "凿击"
	DPSMateX.L["Kidney Shot"] = "肾击"
	DPSMateX.L["Cheap Shot"] = "偷袭"
	-- Hunter
	DPSMateX.L["Scatter Shot"] = "驱散射击"
	DPSMateX.L["Improved Concussive Shot"] = "强化震荡射击"
	DPSMateX.L["Wyvern Sting"] = "翼龙钉刺"
	DPSMateX.L["Intimidation"] = "胁迫"
	-- Warrior
	DPSMateX.L["Charge Stun"] = "冲锋击昏"
	DPSMateX.L["Intercept Stun"] = "拦截昏迷"
	DPSMateX.L["Concussion Blow"] = "震荡猛击"
	-- Druid
	DPSMateX.L["Feral Charge"] = "野性冲锋"
	DPSMateX.L["Feral Charge Effect"] = "野性冲锋效果"
	DPSMateX.L["Bash"] = "重击"
	DPSMateX.L["Pounce"] = "突袭"
	-- Mage
	DPSMateX.L["Impact"] = "反制"
	-- Paladin
	DPSMateX.L["Repentance"] = "忏悔"
	DPSMateX.L["Hammer of Justice"] = "正义之锤"
	-- Warlock
	DPSMateX.L["Pyroclasm"] = "火焰冲撞"
	DPSMateX.L["Death Coil"] = "死亡缠绕"
	-- Priest
	DPSMateX.L["Blackout"] = "昏厥"
	-- General
	DPSMateX.L["Tidal Charm"] = "潮汐咒符"
	DPSMateX.L["Reckless Charge"] = "无畏冲锋"

	DPSMateX.IgnoredDamage = {
		["死亡骑士学员"] = 10000,
	}

	-- Updating preloaded configs
	local _G = getglobal
	local prestr = "DPSMateX_ConfigMenu_"
	-- Menu
	local substr = "Menu_"
	_G(prestr..substr.."Button1"):SetText(DPSMateX.L["window"])
	_G(prestr..substr.."Button2"):SetText(DPSMateX.L["dataresets"])
	_G(prestr..substr.."Button3"):SetText(DPSMateX.L["generaloptions"])
	_G(prestr..substr.."Button4"):SetText(DPSMateX.L["columns"])
	_G(prestr..substr.."Button5"):SetText(DPSMateX.L["tooltips"])
	_G(prestr..substr.."Button6"):SetText(DPSMateX.L["modes"])
	_G(prestr..substr.."Button7"):SetText(DPSMateX.L["raidleader"])
	_G(prestr..substr.."Button8"):SetText(DPSMateX.L["broadcasting"])
	_G(prestr..substr.."Button9"):SetText(DPSMateX.L["about"])
	
	-- Window
	substr = "Tab_Window_"
	_G(prestr..substr.."EditboxText"):SetText(DPSMateX.L["createwindow"])
	_G(prestr..substr.."Editbox").aide = DPSMateX.L["createwindowtooltip"]
	_G(prestr..substr.."SubmitText"):SetText(DPSMateX.L["submit"])
	_G(prestr..substr.."Submit").aide = DPSMateX.L["submitTooltip"]
	_G(prestr..substr.."Remove_Text"):SetText(DPSMateX.L["availwindows"])
	_G(prestr..substr.."Remove").aide = DPSMateX.L["availwindowsTooltip"]
	_G(prestr..substr.."ButtonRemoveText"):SetText(DPSMateX.L["remove"])
	_G(prestr..substr.."ButtonRemove").aide = DPSMateX.L["removeTooltip"]
	_G(prestr..substr.."ConfigFrom_Text"):SetText(DPSMateX.L["configfrom"])
	_G(prestr..substr.."ConfigFrom").aide = DPSMateX.L["configfromTooltip"]
	_G(prestr..substr.."ConfigTo_Text"):SetText(DPSMateX.L["configto"])
	_G(prestr..substr.."ConfigTo").aide = DPSMateX.L["configtoTooltip"]
	_G(prestr..substr.."ButtonCopyText"):SetText(DPSMateX.L["copy"])
	_G(prestr..substr.."ButtonCopy").aide = DPSMateX.L["copyTooltip"]
	_G(prestr..substr.."Lock_Title"):SetText(DPSMateX.L["lock"])
	_G(prestr..substr.."Lock").aide = DPSMateX.L["locktooltip"]
	_G(prestr..substr.."Testmode_Title"):SetText(DPSMateX.L["testmode"])
	_G(prestr..substr.."Testmode").aide = DPSMateX.L["testmodetooltip"]
	
	-- Bars
	substr = "Tab_Bars_"
	_G(prestr..substr.."BarFont_Text"):SetText(DPSMateX.L["barfont"])
	_G(prestr..substr.."BarFont").aide = DPSMateX.L["barfontTooltip"]
	_G(prestr..substr.."BarFontSizeText"):SetText(DPSMateX.L["barfontsize"])
	_G(prestr..substr.."BarFontSize").aide = DPSMateX.L["barfontsizeTooltip"]
	_G(prestr..substr.."BarFontFlag_Text"):SetText(DPSMateX.L["barfontflags"])
	_G(prestr..substr.."BarFontFlag").aide = DPSMateX.L["barfontflagsTooltip"]
	_G(prestr..substr.."BarTexture_Text"):SetText(DPSMateX.L["bartexture"])
	_G(prestr..substr.."BarTexture").aide = DPSMateX.L["bartextureTooltip"]
	_G(prestr..substr.."BarSpacingText"):SetText(DPSMateX.L["barspacing"])
	_G(prestr..substr.."BarSpacing").aide = DPSMateX.L["barspacingTooltip"]
	_G(prestr..substr.."BarHeightText"):SetText(DPSMateX.L["barheight"])
	_G(prestr..substr.."BarHeight").aide = DPSMateX.L["barheightTooltip"]
	_G(prestr..substr.."FontColor_Font"):SetText(DPSMateX.L["fontcolor"])
	_G(prestr..substr.."FontColor").aide = DPSMateX.L["fontcolorTooltip"]
	_G(prestr..substr.."BackgroundBarColor_Font"):SetText(DPSMateX.L["bgbarcolor"])
	_G(prestr..substr.."BackgroundBarColor").aide = DPSMateX.L["bgbarcolorTooltip"]
	_G(prestr..substr.."ClassIcons_Title"):SetText(DPSMateX.L["classicons"])
	_G(prestr..substr.."ClassIcons").aide = DPSMateX.L["classiconstooltip"]
	_G(prestr..substr.."Ranks_Title"):SetText(DPSMateX.L["ranks"])
	_G(prestr..substr.."Ranks").aide = DPSMateX.L["rankstooltip"]
	_G(prestr..substr.."DisableBG_Title"):SetText(DPSMateX.L["disablebarbg"])
	_G(prestr..substr.."DisableBG").aide = DPSMateX.L["disablebarbgtooltip"]
	_G(prestr..substr.."TotalAlphaText"):SetText(DPSMateX.L["totalbaropacity"])
	_G(prestr..substr.."TotalAlpha").aide = DPSMateX.L["totalbaropacitytooltip"]
	
	-- Titlebar
	substr = "Tab_TitleBar_"
	_G(prestr..substr.."Enable_Title"):SetText(DPSMateX.L["enable"])
	_G(prestr..substr.."Enable").aide = DPSMateX.L["enabletitlebartooltip"]
	_G(prestr..substr.."BarFont_Text"):SetText(DPSMateX.L["barfont"])
	_G(prestr..substr.."BarFont").aide = DPSMateX.L["barfontTooltip"]
	_G(prestr..substr.."BarFontSizeText"):SetText(DPSMateX.L["barfontsize"])
	_G(prestr..substr.."BarFontSize").aide = DPSMateX.L["barfontsizeTooltip"]
	_G(prestr..substr.."BarFontFlag_Text"):SetText(DPSMateX.L["barfontflags"])
	_G(prestr..substr.."BarFontFlag").aide = DPSMateX.L["barfontflagsTooltip"]
	_G(prestr..substr.."BarTexture_Text"):SetText(DPSMateX.L["bartexture"])
	_G(prestr..substr.."BarTexture").aide = DPSMateX.L["bartextureTooltip"]
	_G(prestr..substr.."BarHeightText"):SetText(DPSMateX.L["barheight"])
	_G(prestr..substr.."BarHeight").aide = DPSMateX.L["barheightTooltip"]
	_G(prestr..substr.."BGOpacityText"):SetText(DPSMateX.L["bgOpacity"])
	_G(prestr..substr.."BGOpacity").aide = DPSMateX.L["bgOpacityTooltip"]
	_G(prestr..substr.."BGColor_Font"):SetText(DPSMateX.L["bgcolor"])
	_G(prestr..substr.."BGColor").aide = DPSMateX.L["bgcolorTooltip"]
	_G(prestr..substr.."FontColor_Font"):SetText(DPSMateX.L["fontcolor"])
	_G(prestr..substr.."FontColor").aide = DPSMateX.L["fontcolorTooltip"]
	_G(prestr..substr.."Box1_Report_Title"):SetText(DPSMateX.L["report"])
	_G(prestr..substr.."Box1_Report").aide = DPSMateX.L["buttonshowtooltip"]
	_G(prestr..substr.."Box1_Mode_Title"):SetText(DPSMateX.L["mode"])
	_G(prestr..substr.."Box1_Mode").aide = DPSMateX.L["buttonshowtooltip"]
	_G(prestr..substr.."Box1_Reset_Title"):SetText(DPSMateX.L["reset"])
	_G(prestr..substr.."Box1_Reset").aide = DPSMateX.L["buttonshowtooltip"]
	_G(prestr..substr.."Box1_Config_Title"):SetText(DPSMateX.L["config"])
	_G(prestr..substr.."Box1_Config").aide = DPSMateX.L["buttonshowtooltip"]
	_G(prestr..substr.."Box1_Sync_Title"):SetText(DPSMateX.L["sync"])
	_G(prestr..substr.."Box1_Sync").aide = DPSMateX.L["buttonshowtooltip"]
	_G(prestr..substr.."Box1_Enable_Title"):SetText(DPSMateX.L["enabledisable"])
	_G(prestr..substr.."Box1_Enable").aide = DPSMateX.L["buttonshowtooltip"]
	_G(prestr..substr.."Box1_Filter_Title"):SetText(DPSMateX.L["filter"])
	_G(prestr..substr.."Box1_Filter").aide = DPSMateX.L["buttonshowtooltip"]
	_G(prestr..substr.."Box1_CBTDisplay_Title"):SetText(DPSMateX.L["cbtdisplay"])
	_G(prestr..substr.."Box1_CBTDisplay").aide = DPSMateX.L["buttonshowtooltip"]
	
	-- Tab content
	substr = "Tab_Content_"
	_G(prestr..substr.."BGDropDown_Text"):SetText(DPSMateX.L["bgtex"])
	_G(prestr..substr.."BGDropDown").aide = DPSMateX.L["bgtexTooltip"]
	_G(prestr..substr.."ScaleText"):SetText(DPSMateX.L["scale"])
	_G(prestr..substr.."Scale").aide = DPSMateX.L["scaleTooltip"]
	_G(prestr..substr.."OpacityText"):SetText(DPSMateX.L["opacity"])
	_G(prestr..substr.."Opacity").aide = DPSMateX.L["opacityTooltip"]
	_G(prestr..substr.."BGOpacityText"):SetText(DPSMateX.L["bgOpacity"])
	_G(prestr..substr.."BGOpacity").aide = DPSMateX.L["bgOpacityTooltip"]
	_G(prestr..substr.."BorderOpacityText"):SetText(DPSMateX.L["borderOpacity"])
	_G(prestr..substr.."BorderOpacity").aide = DPSMateX.L["borderOpacityTooltip"]
	_G(prestr..substr.."BGColor_Font"):SetText(DPSMateX.L["bgcolor"])
	_G(prestr..substr.."BGColor").aide = DPSMateX.L["bgcolorTooltip"]
	_G(prestr..substr.."NumberFormat_Text"):SetText(DPSMateX.L["numberformat"])
	_G(prestr..substr.."NumberFormat").aide = DPSMateX.L["numberformatTooltip"]
	_G(prestr..substr.."BorderTexture_Text"):SetText(DPSMateX.L["bordertexture"])
	_G(prestr..substr.."BorderTexture").aide = DPSMateX.L["bordertextureTooltip"]
	_G(prestr..substr.."BorderStrata_Text"):SetText(DPSMateX.L["borderstrata"])
	_G(prestr..substr.."BorderStrata").aide = DPSMateX.L["borderstrataTooltip"]
	_G(prestr..substr.."BorderColor_Font"):SetText(DPSMateX.L["bordercolor"])
	_G(prestr..substr.."BorderColor").aide = DPSMateX.L["bordercolorTooltip"]
	
	-- Tab Dataresets
	substr = "Tab_DataResets_"
	_G(prestr..substr.."EnteringWorld_Text"):SetText(DPSMateX.L["enterworldinstance"])
	_G(prestr..substr.."EnteringWorld").aide = DPSMateX.L["enterworldinstanceTooltip"]
	_G(prestr..substr.."JoinParty_Text"):SetText(DPSMateX.L["joinparty"])
	_G(prestr..substr.."JoinParty").aide = DPSMateX.L["joinpartyTooltip"]
	_G(prestr..substr.."PartyMemberChanged_Text"):SetText(DPSMateX.L["partymemberchanged"])
	_G(prestr..substr.."PartyMemberChanged").aide = DPSMateX.L["partymemberchangedTooltip"]
	_G(prestr..substr.."LeaveParty_Text"):SetText(DPSMateX.L["leavingparty"])
	_G(prestr..substr.."LeaveParty").aide = DPSMateX.L["leavingpartyTooltip"]
	_G(prestr..substr.."Sync_Text"):SetText(DPSMateX.L["syncrequest"])
	_G(prestr..substr.."Sync").aide = DPSMateX.L["syncrequesttooltip"]
	_G(prestr..substr.."Logout_Text"):SetText(DPSMateX.L["dataresetslogout"])
	_G(prestr..substr.."Logout").aide = DPSMateX.L["dataresetslogouttooltip"]
	
	-- Tab general options
	substr = "Tab_GeneralOptions_"
	_G(prestr..substr.."Minimap_Title"):SetText(DPSMateX.L["minimap"])
	_G(prestr..substr.."Minimap").aide = DPSMateX.L["minimaptooltip"]
	_G(prestr..substr.."Total_Title"):SetText(DPSMateX.L["showtotal"])
	_G(prestr..substr.."Total").aide = DPSMateX.L["showtotaltooltip"]
	_G(prestr..substr.."Solo_Title"):SetText(DPSMateX.L["solo"])
	_G(prestr..substr.."Solo").aide = DPSMateX.L["solotooltip"]
	_G(prestr..substr.."Combat_Title"):SetText(DPSMateX.L["combat"])
	_G(prestr..substr.."Combat").aide = DPSMateX.L["combattooltip"]
	_G(prestr..substr.."Login_Title"):SetText(DPSMateX.L["loginhide"])
	_G(prestr..substr.."Login").aide = DPSMateX.L["loginhidetooltip"]
	_G(prestr..substr.."BossFights_Title"):SetText(DPSMateX.L["bossfights"])
	_G(prestr..substr.."BossFights").aide = DPSMateX.L["bossfightstooltip"]
	_G(prestr..substr.."PVP_Title"):SetText(DPSMateX.L["pvp"])
	_G(prestr..substr.."PVP").aide = DPSMateX.L["pvptooltip"]
	_G(prestr..substr.."Disable_Title"):SetText(DPSMateX.L["disable"])
	_G(prestr..substr.."Disable").aide = DPSMateX.L["disabletooltip"]
	_G(prestr..substr.."MergePets_Title"):SetText(DPSMateX.L["mergepets"])
	_G(prestr..substr.."MergePets").aide = DPSMateX.L["mergepetstooltip"]
	_G(prestr..substr.."Collectgarbage_Title"):SetText(DPSMateX.L["collectgarbage"])
	_G(prestr..substr.."Collectgarbage").aide = DPSMateX.L["collectgarbagetooltip"]
	_G(prestr..substr.."SegmentsText"):SetText(DPSMateX.L["segments"])
	_G(prestr..substr.."Segments").aide = DPSMateX.L["segmentsTooltip"]
	_G(prestr..substr.."TargetScaleText"):SetText(DPSMateX.L["targetscale"])
	_G(prestr..substr.."TargetScale").aide = DPSMateX.L["targetscaleTooltip"]
	
	-- Tab Columns
	substr = "Tab_Columns_Child_"
	_G(prestr..substr.."DPS_Title"):SetText(DPSMateX.L["dps"])
	_G(prestr..substr.."Damage_Title"):SetText(DPSMateX.L["damage"])
	_G(prestr..substr.."DamageTaken_Title"):SetText(DPSMateX.L["damagetaken"])
	_G(prestr..substr.."DTPS_Title"):SetText(DPSMateX.L["dtps"])
	_G(prestr..substr.."EDD_Title"):SetText(DPSMateX.L["enemydamagedone"])
	_G(prestr..substr.."EDT_Title"):SetText(DPSMateX.L["enemydamagetaken"])
	_G(prestr..substr.."Healing_Title"):SetText(DPSMateX.L["healing"])
	_G(prestr..substr.."HealingTaken_Title"):SetText(DPSMateX.L["healingtaken"])
	_G(prestr..substr.."HPS_Title"):SetText(DPSMateX.L["hps"])
	_G(prestr..substr.."Overhealing_Title"):SetText(DPSMateX.L["overhealing"])
	_G(prestr..substr.."EffectiveHealing_Title"):SetText(DPSMateX.L["effectivehealing"])
	_G(prestr..substr.."EffectiveHealingTaken_Title"):SetText(DPSMateX.L["effectivehealingtaken"])
	_G(prestr..substr.."EffectiveHPS_Title"):SetText(DPSMateX.L["effectivehps"])
	_G(prestr..substr.."Absorbs_Title"):SetText(DPSMateX.L["absorbs"])
	_G(prestr..substr.."AbsorbsTaken_Title"):SetText(DPSMateX.L["absorbstaken"])
	_G(prestr..substr.."HAB_Title"):SetText(DPSMateX.L["healingandabsorbs"])
	_G(prestr..substr.."Deaths_Title"):SetText(DPSMateX.L["deaths"])
	_G(prestr..substr.."Interrupts_Title"):SetText(DPSMateX.L["interrupts"])
	_G(prestr..substr.."Dispels_Title"):SetText(DPSMateX.L["dispels"])
	_G(prestr..substr.."DispelsReceived_Title"):SetText(DPSMateX.L["dispelsreceived"])
	_G(prestr..substr.."Decurses_Title"):SetText(DPSMateX.L["decurses"])
	_G(prestr..substr.."DecursesReceived_Title"):SetText(DPSMateX.L["decursesreceived"])
	_G(prestr..substr.."Disease_Title"):SetText(DPSMateX.L["curedisease"])
	_G(prestr..substr.."DiseaseReceived_Title"):SetText(DPSMateX.L["curediseasereceived"])
	_G(prestr..substr.."Poison_Title"):SetText(DPSMateX.L["curepoison"])
	_G(prestr..substr.."PoisonReceived_Title"):SetText(DPSMateX.L["curepoisonreceived"])
	_G(prestr..substr.."Magic_Title"):SetText(DPSMateX.L["liftmagic"])
	_G(prestr..substr.."MagicReceived_Title"):SetText(DPSMateX.L["liftmagicreceived"])
	_G(prestr..substr.."AurasGained_Title"):SetText(DPSMateX.L["aurasgained"])
	_G(prestr..substr.."AurasLost_Title"):SetText(DPSMateX.L["auraslost"])
	_G(prestr..substr.."AuraUptime_Title"):SetText(DPSMateX.L["aurauptime"])
	_G(prestr..substr.."FriendlyFire_Title"):SetText(DPSMateX.L["friendlyfire"])
	_G(prestr..substr.."Procs_Title"):SetText(DPSMateX.L["procs"])
	_G(prestr..substr.."Casts_Title"):SetText(DPSMateX.L["casts"])
	_G(prestr..substr.."SunderArmor_Title"):SetText(DPSMateX.L["sunderarmor"])
	_G(prestr..substr.."Threat_Title"):SetText(DPSMateX.L["threat"])
	_G(prestr..substr.."TPS_Title"):SetText(DPSMateX.L["tps"])
	_G(prestr..substr.."Fails_Title"):SetText(DPSMateX.L["fails"])
	_G(prestr..substr.."CCBreaker_Title"):SetText(DPSMateX.L["ccbreaker"])
	_G(prestr..substr.."OHPS_Title"):SetText(DPSMateX.L["OHPS"])
	_G(prestr..substr.."OHealingTaken_Title"):SetText(DPSMateX.L["OHealingTaken"])
	_G(prestr..substr.."FriendlyFireTaken_Title"):SetText(DPSMateX.L["friendlyfiretaken"])
	
	-- Tab Tooltips
	substr = "Tab_Tooltips_"
	_G(prestr..substr.."Tooltips_Title"):SetText(DPSMateX.L["showtooltips"])
	_G(prestr..substr.."Tooltips").aide = DPSMateX.L["showtooltipsTooltip"]
	_G(prestr..substr.."InformativeTooltips_Title"):SetText(DPSMateX.L["informativetooltips"])
	_G(prestr..substr.."InformativeTooltips").aide = DPSMateX.L["informativetooltipsTooltip"]
	_G(prestr..substr.."RowsText"):SetText(DPSMateX.L["subviewrows"])
	_G(prestr..substr.."Rows").aide = DPSMateX.L["subviewrowsTooltip"]
	_G(prestr..substr.."Position_Text"):SetText(DPSMateX.L["TooltipPositionDropDown"])
	_G(prestr..substr.."Position").aide = DPSMateX.L["TooltipPositionDropDownTooltip"]
	
	-- Raidleader
	substr = "Tab_RaidLeader_"
	_G(prestr..substr.."HelloWorldText"):SetText("检测同步")
	_G(prestr..substr.."HelloWorld").aide = DPSMateX.L["helloworldTooltip"]
	
	-- Tab Broadcasting
	substr = "Tab_Broadcasting_"
	_G(prestr..substr.."Enable_Title"):SetText(DPSMateX.L["enable"])
	_G(prestr..substr.."Enable").aide = DPSMateX.L["enablebroadcasting"]
	_G(prestr..substr.."RaidWarning_Title"):SetText(DPSMateX.L["useraidwarning"])
	_G(prestr..substr.."RaidWarning").aide = DPSMateX.L["useraidwarningTooltip"]
	_G(prestr..substr.."Cooldowns_Title"):SetText(DPSMateX.L["relevantcds"])
	_G(prestr..substr.."Cooldowns").aide = DPSMateX.L["relevantcdsTooltip"]
	_G(prestr..substr.."Ress_Title"):SetText(DPSMateX.L["ress"])
	_G(prestr..substr.."Ress").aide = DPSMateX.L["ressTooltip"]
	_G(prestr..substr.."KillingBlows_Title"):SetText(DPSMateX.L["killingblows"])
	_G(prestr..substr.."KillingBlows").aide = DPSMateX.L["killingblowsTooltip"]
	_G(prestr..substr.."Fails_Title"):SetText(DPSMateX.L["fails"])
	_G(prestr..substr.."Fails").aide = DPSMateX.L["failsTooltip"]
	
	-- Tab About
	substr = "Tab_About_"
	_G(prestr..substr.."What_Title"):SetText(DPSMateX.L["whatisdpsmatex"])
	_G(prestr..substr.."What_Text"):SetText(DPSMateX.L["whatisdpsmatexText"])
	_G(prestr..substr.."Who_Title"):SetText(DPSMateX.L["whocreateddpsmatex"])
	_G(prestr..substr.."Who_Text"):SetText(DPSMateX.L["whocreateddpsmatexText"])
	_G(prestr..substr.."Thanks_Title"):SetText(DPSMateX.L["thanksto"])
	_G(prestr..substr.."Thanks_Text"):SetText(DPSMateX.L["thankstoText"])
	
	-- Damage done details
	DPSMateX_Details_DiagramLegend_Procs_Text:SetText(DPSMateX.L["procs"])
	DPSMateX_Details_LogDetails_Block:SetText(DPSMateX.L["block"])
	DPSMateX_Details_LogDetails_Glance:SetText(DPSMateX.L["glance"])
	DPSMateX_Details_LogDetails_Hit:SetText(DPSMateX.L["hit"])
	DPSMateX_Details_LogDetails_Amount:SetText(DPSMateX.L["amount"])
	DPSMateX_Details_LogDetails_Average:SetText(DPSMateX.L["average"])
	DPSMateX_Details_LogDetails_Min:SetText(DPSMateX.L["min"])
	DPSMateX_Details_LogDetails_Max:SetText(DPSMateX.L["max"])
	DPSMateX_Details_LogDetails_Crit:SetText(DPSMateX.L["crit"])
	DPSMateX_Details_LogDetails_Miss:SetText(DPSMateX.L["miss"])
	DPSMateX_Details_LogDetails_Parry:SetText(DPSMateX.L["parry"])
	DPSMateX_Details_LogDetails_Dodge:SetText(DPSMateX.L["dodge"])
	DPSMateX_Details_LogDetails_Resist:SetText(DPSMateX.L["resist"])
	
	DPSMateX_Details_CompareDamage_DiagramLegend_Procs_Text:SetText(DPSMateX.L["procs"])
	DPSMateX_Details_CompareDamage_LogDetails_Block:SetText(DPSMateX.L["block"])
	DPSMateX_Details_CompareDamage_LogDetails_Glance:SetText(DPSMateX.L["glance"])
	DPSMateX_Details_CompareDamage_LogDetails_Hit:SetText(DPSMateX.L["hit"])
	DPSMateX_Details_CompareDamage_LogDetails_Amount:SetText(DPSMateX.L["amount"])
	DPSMateX_Details_CompareDamage_LogDetails_Average:SetText(DPSMateX.L["average"])
	DPSMateX_Details_CompareDamage_LogDetails_Min:SetText(DPSMateX.L["min"])
	DPSMateX_Details_CompareDamage_LogDetails_Max:SetText(DPSMateX.L["max"])
	DPSMateX_Details_CompareDamage_LogDetails_Crit:SetText(DPSMateX.L["crit"])
	DPSMateX_Details_CompareDamage_LogDetails_Miss:SetText(DPSMateX.L["miss"])
	DPSMateX_Details_CompareDamage_LogDetails_Parry:SetText(DPSMateX.L["parry"])
	DPSMateX_Details_CompareDamage_LogDetails_Dodge:SetText(DPSMateX.L["dodge"])
	DPSMateX_Details_CompareDamage_LogDetails_Resist:SetText(DPSMateX.L["resist"])
	
	DPSMateX.Options.Options[1]["args"]["damage"] = {
		order = 20,
		type = 'toggle',
		name = DPSMateX.L["damage"],
		desc = DPSMateX.L["show"].." "..DPSMateX.L["damage"]..".",
		get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["damage"] end,
		set = function() DPSMateX.Options:ToggleDrewDrop(1, "damage", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
	}
	DPSMateX.Options.Options[1]["args"]["dps"] = {
		order = 10,
		type = 'toggle',
		name = DPSMateX.L["dps"],
		desc = DPSMateX.L["show"].." "..DPSMateX.L["dps"]..".",
		get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["dps"] end, -- Addons might conflicting here with dewdrop
		set = function() DPSMateX.Options:ToggleDrewDrop(1, "dps", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
	}
	
	-- Popups
	DPSMateX_PopUp_Text:SetText(DPSMateX.L["popup"])
	DPSMateX_PopUp_ThoroughText:SetText(DPSMateX.L["thorough"])
	DPSMateX_PopUp_TotalText:SetText(DPSMateX.L["total"])
	DPSMateX_PopUp_CurrentText:SetText(DPSMateX.L["current"])
	DPSMateX_PopUp_CancelText:SetText(DPSMateX.L["cancel"])
	DPSMateX_Vote_Text:SetText(DPSMateX.L["popup"])
	DPSMateX_Vote_AcceptText:SetText(DPSMateX.L["vreset"])
	DPSMateX_Vote_CancelText:SetText(DPSMateX.L["vdreset"])
	DPSMateX_Logout_Text:SetText(DPSMateX.L["memory"])
	DPSMateX_Logout_AcceptText:SetText(DPSMateX.L["accept"])
	DPSMateX_Logout_CancelText:SetText(DPSMateX.L["decline"])
	DPSMateX_Report_Text:SetText(DPSMateX.L["report"].." - "..DPSMateX.L["name"])
	DPSMateX_Report_Channel_Text:SetText(DPSMateX.L["channel"])
	DPSMateX_Report_Delay.aide = DPSMateX.L["reportdelaytooltip"]
	DPSMateX_Report_Delay_Title:SetText(DPSMateX.L["delay"])
	DPSMateX_Report_Editbox_Text:SetText(DPSMateX.L["editboxtitle"])
	DPSMateX_Report_ReportButton:SetText(DPSMateX.L["report"])
	
	
	DPSMateX.Options.Options[2]["args"]["total"]["name"] = DPSMateX.L["total"]
	DPSMateX.Options.Options[2]["args"]["total"]["desc"] = DPSMateX.L["totalmode"]
	DPSMateX.Options.Options[2]["args"]["currentFight"]["name"] = DPSMateX.L["mcurrent"]
	DPSMateX.Options.Options[2]["args"]["currentFight"]["desc"] = DPSMateX.L["currentmode"]
	DPSMateX.Options.Options[3]["args"]["test"]["name"] = DPSMateX.L["testmode"]
	DPSMateX.Options.Options[3]["args"]["test"]["desc"] = DPSMateX.L["testmodedesc"]
	DPSMateX.Options.Options[3]["args"]["report"]["name"] = DPSMateX.L["report"]
	DPSMateX.Options.Options[3]["args"]["report"]["desc"] = DPSMateX.L["reportsegment"]
	DPSMateX.Options.Options[3]["args"]["reset"]["name"] = DPSMateX.L["reset"]
	DPSMateX.Options.Options[3]["args"]["reset"]["desc"] = DPSMateX.L["resetdesc"]
	DPSMateX.Options.Options[3]["args"]["realtime"]["name"] = DPSMateX.L["mrealtime"]
	DPSMateX.Options.Options[3]["args"]["realtime"]["desc"] = DPSMateX.L["mrealtimedesc"]
	DPSMateX.Options.Options[3]["args"]["realtime"]["args"]["damage"]["name"] = DPSMateX.L["damagedone"]
	DPSMateX.Options.Options[3]["args"]["realtime"]["args"]["damage"]["desc"] = DPSMateX.L["realtimedmgdone"]
	DPSMateX.Options.Options[3]["args"]["realtime"]["args"]["dmgt"]["name"] = DPSMateX.L["damagetaken"]
	DPSMateX.Options.Options[3]["args"]["realtime"]["args"]["dmgt"]["desc"] = DPSMateX.L["realtimedmgtaken"]
	DPSMateX.Options.Options[3]["args"]["realtime"]["args"]["heal"]["name"] = DPSMateX.L["healing"]
	DPSMateX.Options.Options[3]["args"]["realtime"]["args"]["heal"]["desc"] = DPSMateX.L["realtimehealing"]
	DPSMateX.Options.Options[3]["args"]["realtime"]["args"]["eheal"]["name"] = DPSMateX.L["effectivehealing"]
	DPSMateX.Options.Options[3]["args"]["realtime"]["args"]["eheal"]["desc"] = DPSMateX.L["realtimeehealing"]
	DPSMateX.Options.Options[3]["args"]["startnewsegment"]["name"] = DPSMateX.L["newsegment"]
	DPSMateX.Options.Options[3]["args"]["startnewsegment"]["desc"] = DPSMateX.L["newsegmentdesc"]
	DPSMateX.Options.Options[3]["args"]["deletesegment"]["name"] = DPSMateX.L["removesegment"]
	DPSMateX.Options.Options[3]["args"]["deletesegment"]["desc"] = DPSMateX.L["removesegmentdesc"]
	DPSMateX.Options.Options[3]["args"]["showAll"]["name"] = DPSMateX.L["showAll"]
	DPSMateX.Options.Options[3]["args"]["showAll"]["desc"] = DPSMateX.L["showAllDesc"]
	DPSMateX.Options.Options[3]["args"]["hideAll"]["name"] = DPSMateX.L["hideAll"]
	DPSMateX.Options.Options[3]["args"]["hideAll"]["desc"] = DPSMateX.L["hideAllDesc"]
	DPSMateX.Options.Options[3]["args"]["showwindow"]["name"] = DPSMateX.L["showwindow"]
	DPSMateX.Options.Options[3]["args"]["showwindow"]["desc"] = DPSMateX.L["showwindowdesc"]
	DPSMateX.Options.Options[3]["args"]["hidewindow"]["name"] = DPSMateX.L["hidewindow"]
	DPSMateX.Options.Options[3]["args"]["hidewindow"]["desc"] = DPSMateX.L["hidewindowdesc"]
	DPSMateX.Options.Options[3]["args"]["lock"]["name"] = DPSMateX.L["lock"]
	DPSMateX.Options.Options[3]["args"]["lock"]["desc"] = DPSMateX.L["lockdesc"]
	DPSMateX.Options.Options[3]["args"]["unlock"]["name"] = DPSMateX.L["unlock"]
	DPSMateX.Options.Options[3]["args"]["unlock"]["desc"] = DPSMateX.L["unlock"]
	DPSMateX.Options.Options[3]["args"]["configure"]["name"] = DPSMateX.L["config"]
	DPSMateX.Options.Options[3]["args"]["configure"]["desc"] = DPSMateX.L["config"]
	DPSMateX.Options.Options[3]["args"]["close"]["name"] = DPSMateX.L["close"]
	DPSMateX.Options.Options[3]["args"]["close"]["desc"] = DPSMateX.L["close"]
	DPSMateX.Options.Options[4]["args"]["report"]["name"] = DPSMateX.L["report"]
	DPSMateX.Options.Options[4]["args"]["report"]["desc"] = DPSMateX.L["reportdesc"]
	DPSMateX.Options.Options[4]["args"]["report"]["args"]["whisper"]["name"] = DPSMateX.L["whisper"]
	DPSMateX.Options.Options[4]["args"]["report"]["args"]["whisper"]["desc"] = DPSMateX.L["whisperdesc"]
	DPSMateX.Options.Options[4]["args"]["compare"]["name"] = DPSMateX.L["comparewith"]
	DPSMateX.Options.Options[4]["args"]["compare"]["desc"] = DPSMateX.L["comparewithdesc"]
	DPSMateX.Options.Options[5]["args"]["classes"]["name"] = DPSMateX.L["classes"]
	DPSMateX.Options.Options[5]["args"]["classes"]["desc"] = DPSMateX.L["classesdesc"]
	DPSMateX.Options.Options[5]["args"]["classes"]["args"]["warrior"]["name"] = DPSMateX.L["warrior"]
	DPSMateX.Options.Options[5]["args"]["classes"]["args"]["warrior"]["desc"] = DPSMateX.L["warlockdesc"]
	DPSMateX.Options.Options[5]["args"]["classes"]["args"]["rogue"]["name"] = DPSMateX.L["rogue"]
	DPSMateX.Options.Options[5]["args"]["classes"]["args"]["rogue"]["desc"] = DPSMateX.L["roguedesc"]
	DPSMateX.Options.Options[5]["args"]["classes"]["args"]["priest"]["name"] = DPSMateX.L["priest"]
	DPSMateX.Options.Options[5]["args"]["classes"]["args"]["priest"]["desc"] = DPSMateX.L["priestdesc"]
	DPSMateX.Options.Options[5]["args"]["classes"]["args"]["hunter"]["name"] = DPSMateX.L["hunter"]
	DPSMateX.Options.Options[5]["args"]["classes"]["args"]["hunter"]["desc"] = DPSMateX.L["hunterdesc"]
	DPSMateX.Options.Options[5]["args"]["classes"]["args"]["druid"]["name"] = DPSMateX.L["druid"]
	DPSMateX.Options.Options[5]["args"]["classes"]["args"]["druid"]["desc"] = DPSMateX.L["druiddesc"]
	DPSMateX.Options.Options[5]["args"]["classes"]["args"]["mage"]["name"] = DPSMateX.L["mage"]
	DPSMateX.Options.Options[5]["args"]["classes"]["args"]["mage"]["desc"] = DPSMateX.L["magedesc"]
	DPSMateX.Options.Options[5]["args"]["classes"]["args"]["warlock"]["name"] = DPSMateX.L["warlock"]
	DPSMateX.Options.Options[5]["args"]["classes"]["args"]["warlock"]["desc"] = DPSMateX.L["warlockdesc"]
	DPSMateX.Options.Options[5]["args"]["classes"]["args"]["paladin"]["name"] = DPSMateX.L["paladin"]
	DPSMateX.Options.Options[5]["args"]["classes"]["args"]["paladin"]["desc"] = DPSMateX.L["paladindesc"]
	DPSMateX.Options.Options[5]["args"]["classes"]["args"]["shaman"]["name"] = DPSMateX.L["shaman"]
	DPSMateX.Options.Options[5]["args"]["classes"]["args"]["shaman"]["desc"] = DPSMateX.L["shamandesc"]
	DPSMateX.Options.Options[5]["args"]["people"]["name"] = DPSMateX.L["certainnames"]
	DPSMateX.Options.Options[5]["args"]["people"]["desc"] = DPSMateX.L["certainnamesdesc"]
	DPSMateX.Options.Options[5]["args"]["group"]["name"] = DPSMateX.L["grouponly"]
	DPSMateX.Options.Options[5]["args"]["group"]["desc"] = DPSMateX.L["grouponlydesc"]
end