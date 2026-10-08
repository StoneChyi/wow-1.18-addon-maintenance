if GetLocale() == "zhCN" then
	BINDING_NAME_CAST_EARTH_TOTEM = "施放大地图腾"
	BINDING_NAME_CAST_FIRE_TOTEM = "施放火焰图腾"
	BINDING_NAME_CAST_WATER_TOTEM = "施放水之图腾"
	BINDING_NAME_CAST_AIR_TOTEM = "施放空气图腾"
	
	-- ArchiTotem 按键绑定
	BINDING_HEADER_ARCHITOTEM = "ArchiTotem 图腾大师"
	BINDING_NAME_ARCHITOTEM_CASTALL = "一键召唤所有图腾"
	BINDING_NAME_ARCHITOTEM_RECALL = "召回所有图腾"
	BINDING_NAME_ARCHITOTEM_CASTEARTH = "召唤土系图腾"
	BINDING_NAME_ARCHITOTEM_CASTFIRE = "召唤火系图腾"
	BINDING_NAME_ARCHITOTEM_CASTWATER = "召唤水系图腾"
	BINDING_NAME_ARCHITOTEM_CASTAIR = "召唤风系图腾"
	BINDING_NAME_ARCHITOTEM_TOGGLESKIPEARTH = "切换跳过土系图腾"
	BINDING_NAME_ARCHITOTEM_TOGGLESKIPFIRE = "切换跳过火系图腾"
	BINDING_NAME_ARCHITOTEM_TOGGLESKIPWATER = "切换跳过水系图腾"
	BINDING_NAME_ARCHITOTEM_TOGGLESKIPAIR = "切换跳过风系图腾"
	BINDING_NAME_ARCHITOTEM_PRESET_PVE = "召唤PVE预设图腾"
	BINDING_NAME_ARCHITOTEM_PRESET_PVP = "召唤PVP预设图腾"
	BINDING_NAME_ARCHITOTEM_PRESET_RESIST = "召唤抗性预设图腾"
	BINDING_NAME_ARCHITOTEM_PRESET_CUSTOM = "召唤自定义预设图腾"
	
	ArchiTotemLocale = {
		["Earthbind Totem"] = "地缚图腾",
		["Tremor Totem"] = "战栗图腾",
		["Strength of Earth Totem"] = "大地之力图腾",
		["Stoneskin Totem"] = "石肤图腾",
		["Stoneclaw Totem"] = "石爪图腾",
		["Searing Totem"] = "灼热图腾",
		["Fire Nova Totem"] = "火焰新星图腾",
		["Magma Totem"] = "熔岩图腾",
		["Frost Resistance Totem"] = "抗寒图腾",
		["Flametongue Totem"] = "火舌图腾",
		["Mana Spring Totem"] = "法力之泉图腾",
		["Fire Resistance Totem"] = "抗火图腾",
		["Poison Cleansing Totem"] = "清毒图腾",
		["Disease Cleansing Totem"] = "祛病图腾",
		["Healing Stream Totem"] = "治疗之泉图腾",
		["Tranquil Air Totem"] = "宁静之风图腾",
		["Grounding Totem"] = "根基图腾",
		["Windfury Totem"] = "风怒图腾",
		["Grace of Air Totem"] = "风之优雅图腾",
		["Nature Resistance Totem"] = "自然抗性图腾",
		["Windwall Totem"] = "风墙图腾",
		["Sentry Totem"] = "岗哨图腾",
		["Call of the Elements"] = "元素召唤",
		["Totemic Recall"] = "图腾召回",
		
		["ver."] = "ver.",
		["loaded"] = "加载",
		["Earth totems shown: "] = "大地图腾显示: ",
		["Fire totems shown: "] = "火焰图腾显示: ",
		["Water totems shown: "] = "水之图腾显示: ",
		["Air totems shown: "] = "空气图腾显示: ",
		["Direction set to: Down"] = "方向设置到：下",
		["Direction set to: Up"] = "方向设置到：上",
		["Order set to: "] = "次序设置到: ",
		["Scale set to: "] = "大小设置到: ",
		["Showing all totems on mouseover"] = "鼠标悬停显示所有的图腾",
		["Showing only one element on mouseover"] = "在鼠标悬停显示只有一个元素",
		["Totems will move the the bottom line when cast"] = "施放图腾时会移动到按钮线",
		["Totems will stay where they are when cast"] = "施放图腾时停留在按钮线",
		["Timers are now turned on"] = "计时器现在打开",
		["Timers are now turned off"] = "计时器现在关闭",
		["Tooltips are now turned on"] = "鼠标提示现在打开",
		["Tooltips are now turned off"] = "鼠标提示现在关闭",
		["Debuging are now turned on"] = "调试模式现在打开",
		["Debuging are now turned off"] = "调试模式现在关闭",
		["Available commands:"] = "可用的命令:",
		["/at set <earth/fire/water/air> # - Sets the totems shown of that element to #."] = "/at set <earth/fire/water/air> # - 设置显示该元素的图腾 #.",
		["/at direction <up/down> - Set the direction totems pop up."] = "/at direction <up/down> - 设置弹出方向的图腾.",
		["/at order <element 1, element 2, element 3, element 4> - Sets the order of the totems, from left to right."] = "/at order <element 1, element 2, element 3, element 4> - 一键图腾的顺序，从左到右.",
		["/at scale # - Sets the scale of ArchiTotem, default is 1."] = "/at scale # - ArchiTotem 插件的大小, 默认 1.",
		["/at showall - Toggles show all mode, displaying all totems on mouseover."] = "/at showall - 切换显示模式，在鼠标经过时显示所有的图腾.",
		["/at bottomcast - Toggles moving totems to the bottom line when cast"] = "/at bottomcast - 施放图腾时移动到按钮",
		["/at timers - Toggles showing timers"] = "/at timers - 显示计时",
		["/at tooltip - Toggles showing tooltips"] = "/at tooltip - 显示鼠标提示",
		["/at debug - Toggles debuging"] = "/at debug - 显示调试",
		["Moving the bar:"] = "移动条:",
		["Ctrl-RightClick and Drag any of the main buttons"] = "Ctrl-右键拖动主条",
		["Ordering totems of same element:"] = "分类同种元素图腾:",
		["Ctrl-LeftClick any of the buttons"] = "Ctrl-左键任何按钮",
		["Unavailable command. Type /at for help."] = "不可用的命令. 使用 /at 给予帮助.",		
		["Elements must be written in english!"] = "元素必须用英文书写！",
		["Direction must be down or up!"] = "方向必须是向下或向上的！",
		["Scale must be a number!"] = "大小必须是数字！",
		["Specify scale"] = "指定大小",
		["Earth totems skip: ON"] = "大地图腾跳过：开启",
		["Earth totems skip: OFF"] = "大地图腾跳过：关闭",
		["Fire totems skip: ON"] = "火焰图腾跳过：开启",
		["Fire totems skip: OFF"] = "火焰图腾跳过：关闭",
		["Water totems skip: ON"] = "水之图腾跳过：开启",
		["Water totems skip: OFF"] = "水之图腾跳过：关闭",
		["Air totems skip: ON"] = "空气图腾跳过：开启",
		["Air totems skip: OFF"] = "空气图腾跳过：关闭",
		["右键点击切换跳过状态"] = "右键点击切换跳过状态",
		
		-- 预设相关
		["Available presets:"] = "可用预设:",
		["Preset saved: "] = "预设已保存: ",
		["Preset loaded: "] = "预设已加载: ",
		["Preset not found: "] = "未找到预设: ",
		["PVE"] = "PVE",
		["PVP"] = "PVP", 
		["Resist"] = "抗性",
		["Custom"] = "自定义",
		
		-- 一键图腾和召回命令
		["Cast all totems"] = "一键召唤所有图腾",
		["Recall all totems"] = "召回所有图腾",
		["UI refreshed"] = "UI已刷新",
		["Recall button shown"] = "召回按钮已显示",
		["Recall button hidden"] = "召回按钮已隐藏",
		["Preset manager button shown"] = "组合按钮已显示",
		["Preset manager button hidden"] = "组合按钮已隐藏",
		
		-- 图腾组合管理界面
		["Preset Manager"] = "图腾组合管理",
		["Current Totem Configuration"] = "当前图腾配置",
		["Save Current Configuration"] = "保存当前配置",
		["Available Preset Combinations"] = "可用预设组合",
		["Left click: Switch preset | Shift+Left click: Cast preset"] = "左键: 切换预设 | Shift+左键: 召唤预设",
		["Delete preset"] = "删除预设",
		["Cannot delete default preset"] = "无法删除默认预设",
		["Preset name already exists, will overwrite"] = "预设名称已存在，将覆盖原预设",
		["Please enter preset name"] = "请输入预设名称",
		["Preset deleted successfully"] = "预设删除成功",
		["UI refreshed successfully"] = "界面刷新成功",
		
		-- 首次使用提示
		["Welcome to ArchiTotem! PVE preset has been automatically applied"] = "欢迎使用图腾大师！已自动设置为PVE组合",
		["Use /at to see all commands, right click preset button to open manager"] = "使用 /at 查看所有命令，右键点击组合按钮打开管理界面",
	}
end