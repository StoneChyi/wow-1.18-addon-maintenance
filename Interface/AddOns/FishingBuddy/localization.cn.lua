-- 默认为美式英语

FishingTranslations["zhCN"] = {
   NAME = "钓鱼助手",
   DESCRIPTION1 = "记录你钓到的鱼",
   DESCRIPTION2 = "并管理你的钓鱼装备",
   DESCRIPTION = "#DESCRIPTION1# #DESCRIPTION2#",

   ID = "FishingBuddy",

   WINDOW_TITLE = "#NAME# v#VERSION#",
   FISHINGTEXTURE = "Interface\\Icons\\Trade_Fishing",

   -- 标签名称和提示
   LOCATIONS_INFO = "显示钓鱼位置信息",
   LOCATIONS_TAB = "位置",
   OUTFITS_INFO = "选择钓鱼时的装备",
   OUTFITS_TAB = "装备",
   OPTIONS_INFO = "设置 #NAME# 选项",
   OPTIONS_TAB = "选项",
   TRACKING_INFO = "显示 #NAME# 的周期性钓鱼信息",
   TRACKING_TAB = "追踪",

   POINT = "点",
   POINTS = "点数",

   RAW = "新鲜的",
   FISH = "鱼",

   BOBBER_NAME = "鱼漂",
   FISHINGSKILL = "钓鱼",
   HELP = "帮助",
   SWITCH = "切换",
   IMPORT = "导入",
   TRACK = "追踪",
   NOTRACK = "停止追踪",
   TRACKING = "追踪中",
   UPDATEDB = "更新数据库",
   FORCE = "强制执行",

   SCHOOL = "鱼群",  -- 例如 'Oily Blackmouth School'
   FLOATING_WRECKAGE = "漂浮的残骸",
   FLOATING_DEBRIS = "漂浮的碎片",
   ELEM_WATER = "元素之水",
   OIL_SPILL = "油污",

   ADD = "添加",
   REPLACE = "替换",
   UPDATE = "更新",
   CURRENT = "当前",
   RESET = "重置",
   CLEANUP = "清理",
   CHECK = "检查",
   NOW = "现在",

   NOREALM = "未知领域",

   WATCHER = "观察者",
   WATCHER_LOCK = "锁定",
   WATCHER_UNLOCK = "解锁",

   UNKNOWN = "未知",
   WEEKLY = "每周",
   HOURLY = "每小时",

   OFFSET_LABEL_TEXT = "偏移量：",
   KEYS_LABEL_TEXT = "修饰键：",
   KEYS_NONE_TEXT = "无",
   KEYS_SHIFT_TEXT = "Shift",
   KEYS_CTRL_TEXT = "Ctrl",
   KEYS_ALT_TEXT = "Alt",

   SHOWFISHIES = "显示鱼",
   SHOWFISHIES_INFO = "按鱼的类型显示钓鱼历史。",

   SHOWLOCATIONS = "位置",
   SHOWLOCATIONS_INFO = "按钓鱼地点显示钓鱼历史。",

   SWITCHOUTFIT = "切换装备",
   SWITCHOUTFIT_INFO = "在钓鱼装备和之前穿的装备之间切换。",

   -- 选项名称和提示
   CONFIG_SHOWNEWFISHIES_ONOFF   = "显示新鱼",
   CONFIG_SHOWNEWFISHIES_INFO    = "当你在当前位置钓到新鱼时，在聊天区域显示一条消息。",
   CONFIG_FISHWATCH_ONOFF        = "鱼观察器",
   CONFIG_FISHWATCH_INFO	 	 = "在当前位置显示已钓到的鱼的文本覆盖。",
   CONFIG_FISHWATCHONLY_ONOFF    = "仅在钓鱼时",
   CONFIG_FISHWATCHONLY_INFO	 = "仅在实际钓鱼时观察钓到的鱼。",
   CONFIG_FISHWATCHSKILL_ONOFF   = "当前技能",
   CONFIG_FISHWATCHSKILL_INFO	 = "在鱼观察区域显示当前钓鱼技能和修改器。",
   CONFIG_FISHWATCHZONE_ONOFF    = "当前区域",
   CONFIG_FISHWATCHZONE_INFO	 = "在鱼观察区域显示当前区域。",
   CONFIG_FISHWATCHPERCENT_ONOFF = "显示百分比",
   CONFIG_FISHWATCHPERCENT_INFO	 = "在观察显示中显示每种鱼的百分比。",
   CONFIG_SUITUPFIRST_ONOFF      = "先穿装备",
   CONFIG_SUITUPFIRST_INFO       = "按下绑定键时，如果没有穿钓鱼装备，则穿上。",
   CONFIG_EASYCAST_ONOFF	 = "简单抛竿",
   CONFIG_EASYCAST_INFO		 = "如果启用，当你装备了鱼竿并且右键点击时，会自动投掷鱼线。",
   CONFIG_EASYLURES_ONOFF	 = "自动上饵(需勾选简易抛竿)",
   CONFIG_EASYLURES_INFO	 = "如果启用，在开始钓鱼时会自动为鱼竿上饵。",
   CONFIG_ONLYMINE_ONOFF	 = "仅限装备鱼竿",
   CONFIG_ONLYMINE_INFO		 = "如果启用，简单抛竿只会检查你的装备中的鱼竿（即不会搜索所有可能的鱼竿）。",
   CONFIG_MOUSEFISHING_ONOFF	 = "鼠标钓鱼",
   CONFIG_MOUSEFISHING_INFO	     = "如果启用，左键点击抛出鱼线，右键点击拾取浮标。",
   CONFIG_SHOWLOCATIONZONES_ONOFF	= "显示区域",
   CONFIG_SHOWLOCATIONZONES_INFO	= "显示区域和子区域。",
   CONFIG_SORTBYPERCENT_ONOFF	= "按数量排序",
   CONFIG_SORTBYPERCENT_INFO	= "按钓到的鱼的数量排序，而不是按名称排序。",
   CONFIG_STVTIMER_ONOFF		= "钓鱼大赛计时器",
   CONFIG_STVTIMER_INFO		= "如果启用，显示钓鱼大赛的开始倒计时和剩余时间。",
   CONFIG_STVPOOLSONLY_ONOFF	= "仅在鱼群中投掷",
   CONFIG_STVPOOLSONLY_INFO	= "如果启用，只有当光标悬停在钓鱼点上时，才会启用简单抛竿。",
   CONFIG_USEBUTTONHOLE_ONOFF	= "使用 ButtonHole",
   CONFIG_USEBUTTONHOLE_INFO	= "如果启用，ButtonHole 插件将控制小地图按钮。下次登录时生效。",
   CONFIG_USEGATHERER_ONOFF	= "使用 Gatherer",
   CONFIG_USEGATHERER_INFO	= "如果启用，#NAME# 将通知 Gatherer 钓鱼点。",

   CONFIG_SKILL_INFO		= "装备技能加成。",
   CONFIG_SKILL_TEXT		= "钓鱼技能：",
   CONFIG_STYLISH_INFO		= "风格评分，灵感来自 WoW 论坛中 Draznar 的钓鱼 FAQ。",
   CONFIG_STYLISH_TEXT		= "风格：",

   CONFIG_OUTFITTER_TEXT      = "装备技能加成：%s\r\nDraznar 风格评分：%d ",

   CLICKTOSWITCH_ONOFF	        = "点击切换",
   CLICKTOSWITCH_INFO	        = "如果启用，左键点击切换装备，否则打开 Fishing Buddy 窗口。",

   LEFTCLICKTODRAG = "左键点击拖动",
   RIGHTCLICKFORMENU = "右键点击打开菜单",
   WATCHERCLICKHELP = "#LEFTCLICKTODRAG#\n#RIGHTCLICKFORMENU#",

   MINIMAPBUTTONPLACEMENT = "按钮位置",
   MINIMAPBUTTONPLACEMENTTOOLTIP = "允许你在小地图周围移动 #NAME# 图标",
   CONFIG_MINIMAPBUTTON_ONOFF	= "显示小地图图标",
   CONFIG_MINIMAPBUTTON_INFO	= "在小地图上显示 #NAME# 图标。",

   CONFIG_ENHANCESOUNDS_ONOFF      = "增强钓鱼音效",
   CONFIG_ENHANCESOUNDS_INFO       = "最大化音量并最小化环境音量，使浮标的声音在钓鱼时更明显。",

   TRACKINGFRAME = "追踪框架",
   TRACKINGFRAME_RIGHTCLICK = "右键点击绘制鱼的图表",
   TRACKINGFRAME_LEFTCLICK = "左键点击选择要追踪的鱼",
   TRACKINGFRAME_CLICKS = "#TRACKINGFRAME_RIGHTCLICK#",

   TRACKFISHHOURLY = "每小时追踪这条鱼",
   TRACKFISHWEEKLY = "每周追踪这条鱼",
   HIDEINWATCHER = "在观察器中显示这条鱼",

   -- 消息
   COMPATIBLE_SWITCHER = "未找到兼容的装备切换器。",
   TOOMANYFISHERMEN = "你安装了多个简单投掷插件。",
   FAILEDINIT = "初始化失败。",
   IMPORTMSG = "导入 '%s' 数据库。",
   NOIMPORTMSG = "未找到 Impp、DataFish 或 FishInfo2 数据库。",
   ADDFISHIEMSG = "将 %s 添加到位置 %s。",
   ADDSCHOOLMSG = "将 '%s' 添加到位置 %s。",
   CURSORBUSYMSG = "光标忙碌，无法切换！",
   NOOUTFITDEFINED = "你的钓鱼装备中没有物品。",
   NODATAMSG = "没有钓鱼数据。",
   TRACKINGMSG = "正在追踪 '%s' %s。",
   NOTRACKERRMSG = "无法移除默认周期鱼。",
   NOTRACKMSG = "移除周期鱼 '%s'。",
   POLEALREADYEQUIPPED = "你已经装备了钓鱼竿。",
   CANTSWITCHBACK = "你已经移除了钓鱼装备。",
   CLEANUP_NONEMSG = "没有旧设置。",
   CLEANUP_WILLMSG = "剩余旧设置 |c#RED#%s|r：%s。",
   CLEANUP_DONEMSG = "已移除 |c#RED#%s|r 的旧设置：%s。",
   CLEANUP_NOOLDMSG = "玩家 |c#GREEN#%s|r 没有旧设置。",
   NONEAVAILABLE_MSG = "无可用",
   UPDATEDB_MSG = "更新了 %d 条鱼的名称。",

   MINIMUMSKILL = "最低技能：%d",
   NOTLINKABLE = "<物品不可链接>",
   CAUGHTTHISMANY = "钓到 %d",
   CAUGHTTHISTOTAL = "总计 %d",
   FISHTYPES = "鱼的种类：%d",

   DASH = " -- ",
   FISHCAUGHT = "%d %s",
   TIMETOGO = "大赛开始倒计时：%d:%02d",
   TIMELEFT = "大赛结束倒计时：%d:%02d",
   FATLADYSINGS = "|c#RED#大赛结束|r (%d:%02d 剩余)",
   RIGGLE_BASSBAIT = "^Riggle Bassbait .*: .*! (.*) .*!$",

   STVZONENAME = "荆棘谷",

   TOOLTIP_HINT = "提示：",
   TOOLTIP_HINTSWITCH = "点击切换装备",
   TOOLTIP_HINTTOGGLE = "点击显示 #NAME# 窗口。",

   -- 追踪框架的月份
   ABBREV_JANUARY = "一月",
   ABBREV_APRIL = "四月",
   ABBREV_JULY = "七月",
   ABBREV_OCTOBER = "十月",
   ABBREV_DECEMBER = "十二月",

   -- 键绑定支持
   BINDING_HEADER_FISHINGBUDDY_BINDINGS = "#NAME#",
   BINDING_NAME_FISHINGBUDDY_TOGGLE = "切换 #NAME# 窗口",
   BINDING_NAME_FISHINGBUDDY_SWITCH = "切换钓鱼装备",
   BINDING_NAME_FISHINGBUDDY_GOFISHING = "穿上装备并钓鱼",

   BINDING_NAME_TOGGLEFISHINGBUDDY_LOC = "切换 #NAME# 位置面板",
   BINDING_NAME_TOGGLEFISHINGBUDDY_OUT = "切换 #NAME# 装备面板",
   BINDING_NAME_TOGGLEFISHINGBUDDY_TRK = "切换 #NAME# 追踪面板",
   BINDING_NAME_TOGGLEFISHINGBUDDY_OPT = "切换 #NAME# 选项面板",
};

FishingTranslations["zhCN"].IMPORT_HELP = {
      "|c#GREEN#/fb #IMPORT#|r",
      "    导入 Impp 的 fishinfo 或 FishInfo2 数据。",
};
FishingTranslations["zhCN"].SWITCH_HELP = {
      "|c#GREEN#/fb #SWITCH#|r",
      "    切换装备（如果安装了 OutfitDisplayFrame 或 Outfitter）。",
};
FishingTranslations["zhCN"].WATCHER_HELP = {
      "|c#GREEN#/fb #WATCHER#|r [|c#GREEN##WATCHER_LOCK#|r 或 |c#GREEN##WATCHER_UNLOCK#|r 或 |c#GREEN##RESET#|r]",
      "    解锁观察器以移动窗口，",
      "    锁定以停止，重置以恢复。",
};
FishingTranslations["zhCN"].CURRENT_HELP = {
   "|c#GREEN#/fb #CURRENT# #RESET#|r",
   "    重置当前会话中钓到的鱼。",
};
FishingTranslations["zhCN"].UPDATEDB_HELP = {
   "|c#GREEN#/fb #UPDATEDB# [#FORCE#]|r",
   "    尝试查找我们尚未知道的所有鱼的名称。",
   "    会尝试跳过可能使你从服务器断开连接的“稀有”鱼——使用 '#FORCE#' 选项可以覆盖此检查。",
};
FishingTranslations["zhCN"].CLEANUP_HELP = {
      "|c#GREEN#/fb #CLEANUP#|r [|c#GREEN#f#CHECK#|r 或 |c#GREEN##NOW#|r]",
      "    清理旧设置。|c#GREEN##CHECK#|r 列出将被 |c#GREEN##NOW#|r 删除的设置。",
};
FishingTranslations["zhCN"].TRACKING_HELP = {
      "|c#GREEN#/fb #TRACK#|r [|c#GREEN##HOURLY#|r 或 |c#GREEN##WEEKLY#|r] |c#PURPLE#<鱼链接>|r",
      "    追踪指定鱼的捕获时间（需要 Shift 点击链接）",
      "|c#GREEN#/fb #NOTRACK#|r |c#PURPLE#<鱼链接>|r",
      "    从追踪器中移除指定的鱼（需要 Shift 点击链接）",
      "|c#GREEN#/fb #TRACKING#|r",
      "    显示追踪的鱼的捕获时间（显示效果不佳）",
};

FishingTranslations["zhCN"].PRE_HELP = {
      "你可以使用 |c#GREEN#/fishingbuddy|r 或 |c#GREEN#/fb|r 来执行所有命令",
      "|c#GREEN#/fb|r：单独使用时，切换 Fishing Buddy 窗口",
      "|c#GREEN#/fb #HELP#|r：显示此帮助信息",
};
FishingTranslations["zhCN"].POST_HELP = {
      "你可以在“键绑定”窗口中将窗口切换和装备切换命令绑定到键上。",
};

FishingTranslations["zhCN"].HELPMSG = {
      "@PRE_HELP",
      "@SWITCH_HELP",
      "@WATCHER_HELP",
      "@CURRENT_HELP",
      "@CLEANUP_HELP",
      "@IMPORT_HELP",
      "@TRACKING_HELP",
      "@UPDATEDB_HELP",
      " ",
      "@POST_HELP",
};