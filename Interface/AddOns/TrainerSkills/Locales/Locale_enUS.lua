--Trainerskills by Razzer (http://wow.pchjaelp.dk)
--If you translate this pleace mail me a copy of this file and i'll put it up with the next version =)

TRAINERSKILLS_VERSIONNUMBER = "2.1.8";
--Colors
TRAINERSKILLS_GREEN_FONT_COLOR_CODE = "|cff00FF00";
TRAINERSKILLS_FONT_COLOR_CODE_CLOSE = "|r";

--Keybinding
BINDING_HEADER_TRAINERSKILLS = "TrainerSkills 快捷键";
BINDING_NAME_TOGGLETRAINERSKILLS = "切换 TrainerSkills";

--UI strings
TRAINERSKILLS_FRAME_TITLE = "TrainerSkills 版本 "..TRAINERSKILLS_VERSIONNUMBER;
TRAINERSKILLS_MYADDONS_DESCRIPTION = "从任何位置打开训练师框架";
TRAINERSKILLS_CHOOSE_TRAINER = "选择训练师";
TRAINERSKILLS_TRAINER_DROPDOWN = "训练师";
TRAINERSKILLS_CHARACTER_DROPDOWN = "选择角色";
TRAINERSKILLS_CHARACTER_DROPDOWN_FIRST_ENTRY = "选择一个角色";
TRAINERSKILLS_CHARACTER_DROPDOWN_ON = "已激活"; --e.g. Huntelly <on> Aszune
TRAINERSKILLS_FILTER_DROPDOWN = "仅显示:";
TRAINERSKILLS_DELETE_BUTTON_CONFIRM = "删除"; --Selected trainer is added after this string

--Chat output
TRAINERSKILLS_NOTIFICATION_ON = "TrainerSkills: 通知打开";
TRAINERSKILLS_NOTIFICATION_OFF = "TrainerSkills: 通知关闭";

TRAINERSKILLS_CHAT_HELP_LINE1 = "使用 /ts 或 /TrainerSkills 或者设定一个快捷键打开TrainerSkills框架";
TRAINERSKILLS_CHAT_HELP_LINE2 = TRAINERSKILLS_GREEN_FONT_COLOR_CODE.."/ts reset"..TRAINERSKILLS_FONT_COLOR_CODE_CLOSE.." - TrainerSkills 将清除所有收集到的数据,你的这个角色";
TRAINERSKILLS_CHAT_HELP_LINE3 = TRAINERSKILLS_GREEN_FONT_COLOR_CODE.."/ts delete trainerType <trainer>"..TRAINERSKILLS_FONT_COLOR_CODE_CLOSE.." - 如: /ts delete trainerType expert leatherworker - 将从当前角色删除该训练师";
TRAINERSKILLS_CHAT_HELP_LINE4 = TRAINERSKILLS_GREEN_FONT_COLOR_CODE.."/ts delete <character> "..TRAINERSKILLS_CHARACTER_DROPDOWN_ON.." <realm>"..TRAINERSKILLS_FONT_COLOR_CODE_CLOSE.." - 如: /ts delete Buller "..TRAINERSKILLS_CHARACTER_DROPDOWN_ON.." Aszune - TrainerSkills将删除该角色";
TRAINERSKILLS_CHAT_HELP_LINE5 = TRAINERSKILLS_GREEN_FONT_COLOR_CODE.."/ts delete selected"..TRAINERSKILLS_FONT_COLOR_CODE_CLOSE.." - 将删除选定的训练师";
TRAINERSKILLS_CHAT_HELP_LINE6 = TRAINERSKILLS_GREEN_FONT_COLOR_CODE.."/ts notify"..TRAINERSKILLS_FONT_COLOR_CODE_CLOSE.." - 这会从TS切换通知(关于可用的新技能) 开或关";
TRAINERSKILLS_CHAT_HELP_LINE7 = TRAINERSKILLS_GREEN_FONT_COLOR_CODE.."/ts cleanUp"..TRAINERSKILLS_FONT_COLOR_CODE_CLOSE.." - 这会如果你使用的早于1.9.1 版本trainerskills删除冗余数据";

TRAINERSKILLS_CHAT_DELETE_DROPPED_TRAINER = TRAINERSKILLS_GREEN_FONT_COLOR_CODE.."TrainerSkills: 请手动删除你不适合的训练师."..TRAINERSKILLS_FONT_COLOR_CODE_CLOSE;
TRAINERSKILLS_CHAT_LOADED = TRAINERSKILLS_GREEN_FONT_COLOR_CODE.."Razzer's TrainerSkills 版本 "..TRAINERSKILLS_VERSIONNUMBER.." 加载. 使用 /ts help 或 /trainerSkills help 查看更多信息 ,此插件由60addons汉化"..TRAINERSKILLS_FONT_COLOR_CODE_CLOSE;
TRAINERSKILLS_CHAT_CORUPT_DATA = "数据已被删除. 请再次访问训练师以获取数据.";
TRAINERSKILLS_CHAT_CHAR_DELETED = "数据库已清除"; --User input is added after this string.
TRAINERSKILLS_CHAT_CHAR_NOT_FOUND = "没有发现 TrainerSkills"; --User input added in front of string.
TRAINERSKILLS_CAHT_TRAINER_DELETED = "已经从这个角色删除"; --User input added in front of string.
TRAINERSKILLS_CHAT_TRAINER_NOT_FOUND = "对这个角色没有被发现"; --User input in front of string
TRAINERSKILLS_CHAT_CLEANUP = "删除条目"; --Number is added in front of string
TRAINERSKILLS_CHAT_CHAR_CLEARED = "已清除该角色的数据库";
TRAINERSKILLS_CHAT_NEW_LEARNABLE_SKILL = "你现在可以学习了:"; --Skill name is added after this sting
TRAINERSKILLS_CHAT_NEW_LERANABLE_SKILL_FROM = "从"; --Trainertype added after this string

--Tooltips
TRAINERSKILLS_TRAINER_NAMES = "训练师名字和位置";
TRAINERSKILLS_CHARACTER_LEVEL = "角色等级:";
TRAINERSKILLS_CHARACTER_INFO = "角色信息:";
TRAINERSKILLS_IN = "在"; --Used in the trainer names and location tooltip (Bubber <in> Stormwind)
TRAINERSKILLS_DELETE_BUTTON = "删除选定的训练师";

--Start added in version 1.9.5
	--Chat outputs
TRAINERSKILLS_CHAT_TOTAL_TRAIN_COST = "总成本:"; --Total cost for learning new avaiable skills
TRAINERSKILLS_CHAT_TOTAL_TRAIN_COST_EXPLANATION = "成本可能会有所不同，因为声望"; --Added to the total cost line
	--Tooltips
TRAINERSKILLS_TT_TOTAL_TRAIN_COST = "总计 "..TRAINERSKILLS_GREEN_FONT_COLOR_CODE.."可获得的"..TRAINERSKILLS_FONT_COLOR_CODE_CLOSE.." 技能:";
TRAINERSKILLS_TT_UNAVAILABLE_TOTAL_COST = "总计 "..RED_FONT_COLOR_CODE.."不可用的"..TRAINERSKILLS_FONT_COLOR_CODE_CLOSE.." 技能:";
TRAINERSKILLS_TT_COST_STUFF = "成本"; --Headline for the tooltip by the moneylabel in the TS frame
--End added in version 1.9.5

--Start added in version 1.9.7
    --Tooltips
TRAINERSKILLS_MINIMAP_BUTTON = "TrainerSkills";
    --Chat outputs
TRAINERSKILLS_MINIMAP_BUTTON_OFF = "TrainerSkills：小地图按钮已关闭";
TRAINERSKILLS_MINIMAP_BUTTON_ON = "TrainerSkills：小地图按钮已打开";
TRAINERSKILLS_CHAT_HELP_LINE8 = TRAINERSKILLS_GREEN_FONT_COLOR_CODE.."/ts mmb"..TRAINERSKILLS_FONT_COLOR_CODE_CLOSE.." - 切换小地图按钮";
--End added in version 1.9.7

--Start added in version 2.0.1
    --Chat outputs
TRAINERSKILLS_MINIMAP_BUTTON_MOVEABLE_ON = "TrainerSkills：小地图按钮现在可移动";
TRAINERSKILLS_MINIMAP_BUTTON_MOVEABLE_OFF = "TrainerSkills：小地图按钮不再可移动";
TRAINERSKILLS_CHAT_HELP_LINE9 = TRAINERSKILLS_GREEN_FONT_COLOR_CODE.."/ts mmbMov"..TRAINERSKILLS_FONT_COLOR_CODE_CLOSE.." - 切换可移动小地图按钮的功能";
	--Config panel
TRAINERSKILLS_CONFIG_HEADER = "TrainerSkills设置";
TRAINERSKILLS_OPEN_CONFIG = "设置";
TRAINERSKILLSCONFIG_CB_NOTIFY_LABEL = "启用通知";
TRAINERSKILLSCONFIG_CB_NOTIFY_TOOLTIP = "在聊天窗口中显示可以学习的新技能\n";
TRAINERSKILLSCONFIG_CB_MINIMAPBUTTON_LABEL = "显示小地图按钮";
TRAINERSKILLSCONFIG_CB_MINIMAPBUTTON_TOOLTIP = "使TrainerSkills按钮显示在小地图上";
TRAINERSKILLSCONFIG_CB_MINIMAPBUTTONMOVEABLE_LABEL = "允许移动小地图按钮";
TRAINERSKILLSCONFIG_CB_MINIMAPBUTTONMOVEABLE_TOOLTIP = "允许拖动小地图按钮到其他位置\n";
TRAINERSKILLSCONFIG_CB_GRAPTOOLTIPS_LABEL = "保存技能提示";
TRAINERSKILLSCONFIG_CB_GRAPTOOLTIPS_TOOLTIP = "当鼠标指向TrainerSkills框架中的技能图标时显示提示";
TRAINERSKILLSCONFIG_CB_GRAPDESCRIPTION_LABEL = "保存技能描述";
TRAINERSKILLSCONFIG_CB_GRAPDESCRIPTION_TOOLTIP = "";
TRAINERSKILLSCONFIG_CB_GRABNPCNAMESANDLOCATIONS_LABEL = "保存NPC名称和位置";
TRAINERSKILLSCONFIG_CB_GRABNPCNAMESANDLOCATIONS_TOOLTIP = "当鼠标指向下拉菜单中的训练师时显示提示\n包括名称和位置";
TRAINERSKILLSCONFIG_CB_SAVEPLAYERSKILLS_LABEL = "保存玩家技能进度";
TRAINERSKILLSCONFIG_CB_SAVEPLAYERSKILLS_TOOLTIP = "当鼠标指向下拉菜单中的角色时显示玩家技能提示\n包括技能进度";
TRAINERSKILLS_CONFIG_PURGE_BUTTON = "清除数据";
TRAINERSKILLS_CONFIG_PURGE_TOOLTIP = "删除未选择的所有数据";
--End added in version 2.0.1

--Start added in version 2.0.3
TRAINERSKILLS_CHAT_ALL_GREY_DEL = "该训练师的所有技能都已变灰，而且您选择不保存灰色技能。请手动删除该训练师的数据。";
--End added in version 2.0.3

--start added in version 2.0.4
TRAINERSKILLS_CHAT_COMPLEATERESET = "所有数据已清除。重新初始化中...";
TRAINERSKILLS_CHAT_HELP_LINE10 = TRAINERSKILLS_GREEN_FONT_COLOR_CODE.."/ts completeReset"..TRAINERSKILLS_FONT_COLOR_CODE_CLOSE.." - 完全清除所有TS数据！（谨慎操作，不可逆转！）";
--end added in version 2.0.4

--start added in version 2.1.0
TRAINERSKILLSCONFIG_CB_TRAINERFILTER_LABEL = "在训练师处保存过滤设置";
TRAINERSKILLSCONFIG_CB_TRAINERFILTER_TOOLTIP = "保存您的过滤设置，包括是否显示训练师处的可学/不可学/已学技能，这样下次访问训练师时将使用相同的过滤设置。";
TRAINERSKILLS_TITAN_MENU = "TrainerSkills（右侧）";
--end added in version 2.1.0

--Start added in version 2.1.3
TRAINERSKILLS_DELETE_CHARACTER_BUTTON = "删除所选角色";
--end
