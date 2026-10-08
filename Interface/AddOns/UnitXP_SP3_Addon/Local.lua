-- Sunelegy adds localization to UnitXP SP3
-- Sunelegy 制作本地化文件

local L = {};

if (GetLocale() == "zhCN") then
    -- 简体中文翻译
    L["UnitXP SP3 is running"] = "UnitXP SP3 已运行";
    
    -- 按键绑定
    L["BINDING_HEADER_UNITXPSP3TARGETING"] = "UnitXP SP3 目标选择功能";
    L["BINDING_NAME_UNITXPSP3NEARESTENEMY"] = "最近的敌人";
    L["BINDING_NAME_UNITXPSP3TARGETMOSTHP"] = "生命值最高的敌人";
    L["BINDING_NAME_UNITXPSP3WORLDBOSS"] = "世界首领";
    L["BINDING_NAME_UNITXPSP3NEXTMARKER"] = "下一个标记";
    L["BINDING_NAME_UNITXPSP3PREVIOUSMARKER"] = "上一个标记";
    L["BINDING_NAME_UNITXPSP3NEXTENEMY"] = "下一个敌人";
    L["BINDING_NAME_UNITXPSP3PREVIOUSENEMY"] = "上一个敌人";
    L["BINDING_NAME_UNITXPSP3NEXTMELEE"] = "下一个敌人（优先近战）";
    L["BINDING_NAME_UNITXPSP3PREVIOUSMELEE"] = "上一个敌人（优先近战）";
    L["BINDING_HEADER_UNITXPSP3UTILITIES"] = "UnitXP SP3 辅助功能";
    L["BINDING_NAME_UNITXPSP3RAISECAMERA"] = "抬高视角";
    L["BINDING_NAME_UNITXPSP3LOWERCAMERA"] = "降低视角";
    L["BINDING_NAME_UNITXPSP3LEFTCAMERA"] = "左移视角";
    L["BINDING_NAME_UNITXPSP3RIGHTCAMERA"] = "右移视角";
    L["BINDING_NAME_UNITXPSP3RESETCAMERA"] = "重置视角";
    L["BINDING_NAME_UNITXPSP3TOGGLEMODERNNAMEPLATEDISTANCE"] = "切换姓名板遮挡检测";
    L["BINDING_NAME_UNITXPSP3TOGGLEPRIORITIZETARGETNAMEPLATE"] = "切换目标姓名板优先";
    L["BINDING_NAME_UNITXPSP3TOGGLEPRIORITIZEMARKEDNAMEPLATE"] = "切换标记姓名板优先";
    L["BINDING_HEADER_UNITXPSP3MARKS"] = "UnitXP SP3 标记功能";
    L["BINDING_NAME_UNITXPSP3MARKRED"] = "放置红色标记";
    L["BINDING_NAME_UNITXPSP3MARKYELLOW"] = "放置黄色标记";
    L["BINDING_NAME_UNITXPSP3MARKGREEN"] = "放置绿色标记";
    L["BINDING_NAME_UNITXPSP3MARKBLUE"] = "放置蓝色标记";
    L["BINDING_NAME_UNITXPSP3MARKPURPLE"] = "放置紫色标记";
    L["BINDING_NAME_UNITXPSP3MARKORANGE"] = "放置橙色标记";
    L["BINDING_NAME_UNITXPSP3MARKWHITE"] = "放置白色标记";
    L["BINDING_NAME_UNITXPSP3CLEARALLMARKS"] = "清除所有标记";

    -- UI控件文本
    L["Show Minimap Button"] = "显示小地图按钮";
    L["Proper Nameplates Occlusion"] = "启用姓名板遮挡检测";
    L["Prioritize Target Nameplate"] = "目标姓名板优先";
    L["Prioritize Marked Nameplate"] = "标记姓名板优先";
    L["Hide Healthy Nameplates"] = "仅显示战斗/受伤/PvP姓名板";
    L["Hide Critter Nameplates"] = "隐藏小动物姓名板";
    L["Show In-combat Nameplates Nearby"] = "附近战斗姓名板强制显示";
    L["Taskbar Notification"] = "任务栏图标闪烁提醒";
    L["System Sound Notification"] = "播放系统提示音";
    L["Perfect Screenshot"] = "高清截图";
    L["Pin Camera Height"] = "锁定视角高度";
    L["Keep Weather Clear"] = "强制晴朗天气";
    L["Anti-aliased Combat Text"] = "战斗文字抗锯齿";
    L["Hide EXP Text"] = "隐藏经验值提示";
    L["Self Health Bar"] = "个人资源条";
    L["Always show self health bar out of combat"] = "非战斗状态始终显示个人资源条";
    L["Close"] = "关闭";
    L["Reset Camera"] = "重置视角";
    L["Raise Camera"] = "抬高视角";
    L["Lower Camera"] = "降低视角";
    L["CamPitch Up"] = "视角上倾";
    L["CamPitch Down"] = "视角下移";
    L["Left Player"] = "视角左移";
    L["Right Player"] = "视角右移";
    L["FPS Cap:"] = "帧数上限：";
    L["Background:"] = "后台帧数上限：";
    L["Size:"] = "造成伤害字号：";
    L["Other Size:"] = "其他字号：";
    L["Elevation:"] = "高度：";
    L["Font:"] = "字体：";
    L["UnitXP Service Pack 3"] = "UnitXP SP3 设置";
    L["Targeting functions could be accessed via Key Bindings Menu"] = "目标选择功能可通过按键绑定菜单使用";

    -- 提示信息
    L["Toggle visibility of the minimap button"] = "切换小地图按钮的可见性";
    L["Nameplates would also check camera's line of sight in addition to distance"] = "姓名板除了检测距离外，也会检测视野遮挡";
    L["Other nameplates would disappear when a target is selected"] = "选中目标时其他姓名板会消失";
    L["Need Proper Nameplates Occlusion to be also enabled"] = "需要同时启用姓名板遮挡检测";
    L["Other nameplates would disappear when some nameplates are raid-marked"] = "当有团队标记的单位时，其他姓名板会隐藏";
    L["Aside from prioritized nameplates, only those in-combat/damaged/PvP-flagged nameplates would be shown"] = "除了优先显示的姓名板外，仅显示战斗中/受伤/被PvP标记的单位姓名板";
    L["Aside from prioritized nameplates, only those in-combat critters would have nameplates"] = "除优先显示的姓名板外，仅在战斗中的小动物会显示姓名板";
    L["In-combat nameplates in small range would be shown regardless of occlusion"] = "在小范围内的战斗姓名板即使被遮挡也会显示";
    L["Flash operating system's taskbar icon when the game requires attention"] = "当游戏有提醒时，在系统任务栏闪烁图标";
    L["When the game is in background/minimized"] = "当游戏处于后台或最小化时生效";
    L["Play operating system's default sound when the game requires attention"] = "当游戏有提醒时，播放系统默认提示音";
    L["Generate PNG screenshot"] = "生成 PNG 格式截图";
    L["In-game screenshots would be in larger PNG files instead of JPEG files"] = "游戏内截图将使用大尺寸 PNG 文件格式替代传统 JPEG";
    L["Camera would keep its height during shapeshifting"] = "变形或形态切换时保持视角高度不变";
    L["This would fix FPS-drop during bad weather at the cost of losing weather particles visual"] = "可减少恶劣天气导致的掉帧，但会失去天气粒子特效";
    L["Toggling the switch would influence the next weather event but not the current one"] = "切换此选项只会影响下次天气变化，不会改变当前天气";
    L["Alternative style for floating combat text"] = "浮动战斗文字美化（减少锯齿）";
    L["It requires d3dx9_43.dll which is from DirectX End-User Runtimes"] = "需安装 d3dx9_43.dll（DirectX End-User Runtimes）";
    L["Don't show that purple message when gaining experience point"] = "在获得经验时，不显示紫色的经验值获取文字";
    L["Some people don't like it..."] = "少部分玩家可能不喜欢经验值刷屏";

    -- 输入框提示
    L["Adjust combat text font size"] = "设置造成伤害字号";
    L["Adjust damage text font size"] = "设置伤害文字字号";
    L["Adjust other text font size"] = "设置其他文字字号";
    L["Range from 10 to 99. Press Enter to confirm"] = "范围：10~99，回车确认";
    L["Raise or lower combat text on enemies"] = "设置战斗文字垂直偏移";
    L["Range from 0 to 256. Press Enter to confirm"] = "范围：0~256，回车确认";
    L["Change the font of combat text"] = "更改战斗文字字体";
    L["Input a font name in operating system. Press Enter to confirm"] = "输入操作系统中的字体名称，回车确认";
    L["Limit frames-per-second to the specific value"] = "前台帧数上限";
    L["Zero means no limit. Press Enter to confirm"] = "0 = 不限制，回车确认";
    L["Limit background-frames-per-second to the specific value"] = "后台帧数上限";

    -- 系统消息
    L["UnitXP Service Pack 3 is loaded"] = "UnitXP SP3 模组已加载。";
    L["It was built on"] = "构建于";
    L["UnitXP Service Pack 3 didn't load properly"] = "UnitXP SP3 模组未正确加载。";
    L["UnitXP_SP3.dll failed to execute"] = "UnitXP_SP3.dll 无法执行";
    L["You might need to update UnitXP_SP3.dll to support this method"] = "你可能需要更新 UnitXP_SP3.dll 来支持此功能。";
    L["UnitXP_SP3 floating combat text debug"] = "UnitXP SP3 浮动战斗文字 debug";
    L["Party full"] = "队伍已满";
    L["Battlefield is ready"] = "战场已就绪";
    L["LFT found group or role check start or somehow player left queue"] = "LFT找到队伍或开始职责检查或玩家离开队列";
    L["Aura Count: "] = "光环数量：";
    L[". SpellID="] = ". 技能ID=";
    L[", Stack="] = "，层数=";
    L["No auras found or unit not found"] = "未找到光环或单位不存在";
    L["No raid permission, cannot set mark"] = "没有团队权限，无法设置标记";
    L["No raid permission, cannot clear marks"] = "没有团队权限，无法清除标记";
else
    -- English (enUS) - Default
    L["UnitXP SP3 is running"] = "UnitXP SP3 is running";
    
    -- Binding headers and names
    L["BINDING_HEADER_UNITXPSP3TARGETING"] = "UnitXP SP3 Targeting Functions";
    L["BINDING_NAME_UNITXPSP3NEARESTENEMY"] = "Nearest Enemy";
    L["BINDING_NAME_UNITXPSP3TARGETMOSTHP"] = "The enemy with most HP";
    L["BINDING_NAME_UNITXPSP3WORLDBOSS"] = "World Boss";
    L["BINDING_NAME_UNITXPSP3NEXTMARKER"] = "Next Target Marker";
    L["BINDING_NAME_UNITXPSP3PREVIOUSMARKER"] = "Previous Target Marker";
    L["BINDING_NAME_UNITXPSP3NEXTENEMY"] = "Next Enemy";
    L["BINDING_NAME_UNITXPSP3PREVIOUSENEMY"] = "Previous Enemy";
    L["BINDING_NAME_UNITXPSP3NEXTMELEE"] = "Next Enemy Prioritizing Melee";
    L["BINDING_NAME_UNITXPSP3PREVIOUSMELEE"] = "Previous Enemy Prioritizing Melee";
    L["BINDING_HEADER_UNITXPSP3UTILITIES"] = "UnitXP SP3 Utilities";
    L["BINDING_NAME_UNITXPSP3RAISECAMERA"] = "Raise Camera";
    L["BINDING_NAME_UNITXPSP3LOWERCAMERA"] = "Lower Camera";
    L["BINDING_NAME_UNITXPSP3LEFTCAMERA"] = "Left Camera";
    L["BINDING_NAME_UNITXPSP3RIGHTCAMERA"] = "Right Camera";
    L["BINDING_NAME_UNITXPSP3RESETCAMERA"] = "Reset Camera";
    L["BINDING_NAME_UNITXPSP3TOGGLEMODERNNAMEPLATEDISTANCE"] = "Toggle Proper Nameplates Behavior";
    L["BINDING_NAME_UNITXPSP3TOGGLEPRIORITIZETARGETNAMEPLATE"] = "Toggle Prioritize Target Nameplate";
    L["BINDING_NAME_UNITXPSP3TOGGLEPRIORITIZEMARKEDNAMEPLATE"] = "Toggle Prioritize Marked Nameplate";
    L["BINDING_HEADER_UNITXPSP3MARKS"] = "UnitXP SP3 Marks";
    L["BINDING_NAME_UNITXPSP3MARKRED"] = "Place Red Mark";
    L["BINDING_NAME_UNITXPSP3MARKYELLOW"] = "Place Yellow Mark";
    L["BINDING_NAME_UNITXPSP3MARKGREEN"] = "Place Green Mark";
    L["BINDING_NAME_UNITXPSP3MARKBLUE"] = "Place Blue Mark";
    L["BINDING_NAME_UNITXPSP3MARKPURPLE"] = "Place Purple Mark";
    L["BINDING_NAME_UNITXPSP3MARKORANGE"] = "Place Orange Mark";
    L["BINDING_NAME_UNITXPSP3MARKWHITE"] = "Place White Mark";
    L["BINDING_NAME_UNITXPSP3CLEARALLMARKS"] = "Clear All Marks";
    
    -- UI elements
    L["Show Minimap Button"] = "Show Minimap Button";
    L["Proper Nameplates Occlusion"] = "Proper Nameplates Occlusion";
    L["Prioritize Target Nameplate"] = "Prioritize Target Nameplate";
    L["Prioritize Marked Nameplate"] = "Prioritize Marked Nameplate";
    L["Hide Healthy Nameplates"] = "Hide Healthy Nameplates";
    L["Hide Critter Nameplates"] = "Hide Critter Nameplates";
    L["Show In-combat Nameplates Nearby"] = "Show In-combat Nameplates Nearby";
    L["Taskbar Notification"] = "Taskbar Notification";
    L["System Sound Notification"] = "System Sound Notification";
    L["Perfect Screenshot"] = "Perfect Screenshot";
    L["Pin Camera Height"] = "Pin Camera Height";
    L["Keep Weather Clear"] = "Keep Weather Clear";
    L["Anti-aliased Combat Text"] = "Anti-aliased Combat Text";
    L["Hide EXP Text"] = "Hide EXP Text";
    L["Self Health Bar"] = "Personal Resource Bar";
    L["Always show self health bar out of combat"] = "Always show personal resource bar out of combat";
    L["Close"] = "Close";
    L["Reset Camera"] = "Reset Camera";
    L["Raise Camera"] = "Raise Camera";
    L["Lower Camera"] = "Lower Camera";
    L["CamPitch Up"] = "CamPitch Up";
    L["CamPitch Down"] = "CamPitch Down";
    L["Left Player"] = "Left Player";
    L["Right Player"] = "Right Player";
    L["FPS Cap:"] = "FPS Cap:";
    L["Background:"] = "Background:";
    L["Size:"] = "Damage Size:";
    L["Other Size:"] = "Other Size:";
    L["Elevation:"] = "Elevation:";
    L["Font:"] = "Font:";
    L["UnitXP Service Pack 3"] = "UnitXP Service Pack 3";
    L["Targeting functions could be accessed via Key Bindings Menu"] = "Targeting functions could be accessed via Key Bindings Menu";
    
    -- Tooltips
    L["Toggle visibility of the minimap button"] = "Toggle visibility of the minimap button";
    L["Nameplates would also check camera's line of sight in addition to distance"] = "Nameplates would also check camera's line of sight in addition to distance";
    L["Other nameplates would disappear when a target is selected"] = "Other nameplates would disappear when a target is selected";
    L["Need Proper Nameplates Occlusion to be also enabled"] = "Need Proper Nameplates Occlusion to be also enabled";
    L["Other nameplates would disappear when some nameplates are raid-marked"] = "Other nameplates would disappear when some nameplates are raid-marked";
    L["Aside from prioritized nameplates, only those in-combat/damaged/PvP-flagged nameplates would be shown"] = "Aside from prioritized nameplates, only those in-combat/damaged/PvP-flagged nameplates would be shown";
    L["Aside from prioritized nameplates, only those in-combat critters would have nameplates"] = "Aside from prioritized nameplates, only those in-combat critters would have nameplates";
    L["In-combat nameplates in small range would be shown regardless of occlusion"] = "In-combat nameplates in small range would be shown regardless of occlusion";
    L["Flash operating system's taskbar icon when the game requires attention"] = "Flash operating system's taskbar icon when the game requires attention";
    L["When the game is in background/minimized"] = "When the game is in background/minimized";
    L["Play operating system's default sound when the game requires attention"] = "Play operating system's default sound when the game requires attention";
    L["Generate PNG screenshot"] = "Generate PNG screenshot";
    L["In-game screenshots would be in larger PNG files instead of JPEG files"] = "In-game screenshots would be in larger PNG files instead of JPEG files";
    L["Camera would keep its height during shapeshifting"] = "Camera would keep its height during shapeshifting";
    L["This would fix FPS-drop during bad weather at the cost of losing weather particles visual"] = "This would fix FPS-drop during bad weather at the cost of losing weather particles visual";
    L["Toggling the switch would influence the next weather event but not the current one"] = "Toggling the switch would influence the next weather event but not the current one";
    L["Alternative style for floating combat text"] = "Alternative style for floating combat text";
    L["It requires d3dx9_43.dll which is from DirectX End-User Runtimes"] = "It requires d3dx9_43.dll which is from DirectX End-User Runtimes";
    L["Don't show that purple message when gaining experience point"] = "Don't show that purple message when gaining experience point";
    L["Some people don't like it..."] = "Some people don't like it...";
    
    -- EditBox tooltips
    L["Adjust combat text font size"] = "Adjust combat text font size";
    L["Adjust damage text font size"] = "Adjust damage text font size";
    L["Adjust other text font size"] = "Adjust other text font size";
    L["Range from 10 to 99. Press Enter to confirm"] = "Range from 10 to 99. Press Enter to confirm";
    L["Raise or lower combat text on enemies"] = "Raise or lower combat text on enemies";
    L["Range from 0 to 256. Press Enter to confirm"] = "Range from 0 to 256. Press Enter to confirm";
    L["Change the font of combat text"] = "Change the font of combat text";
    L["Input a font name in operating system. Press Enter to confirm"] = "Input a font name in operating system. Press Enter to confirm";
    L["Limit frames-per-second to the specific value"] = "Limit frames-per-second to the specific value";
    L["Zero means no limit. Press Enter to confirm"] = "Zero means no limit. Press Enter to confirm";
    L["Limit background-frames-per-second to the specific value"] = "Limit background-frames-per-second to the specific value";
    
    -- Messages
    L["UnitXP Service Pack 3 is loaded"] = "UnitXP Service Pack 3 is loaded";
    L["It was built on"] = "It was built on";
    L["UnitXP Service Pack 3 didn't load properly"] = "UnitXP Service Pack 3 didn't load properly";
    L["UnitXP_SP3.dll failed to execute"] = "UnitXP_SP3.dll failed to execute";
    L["You might need to update UnitXP_SP3.dll to support this method"] = "You might need to update UnitXP_SP3.dll to support this method";
    L["UnitXP_SP3 floating combat text debug"] = "UnitXP SP3 floating combat text debug";
    L["Party full"] = "Party full";
    L["Battlefield is ready"] = "Battlefield is ready";
    L["LFT found group or role check start or somehow player left queue"] = "LFT found group or role check start or somehow player left queue";
    L["Aura Count: "] = "Aura Count: ";
    L[". SpellID="] = ". SpellID=";
    L[", Stack="] = ", Stack=";
    L["No auras found or unit not found"] = "No auras found or unit not found";
    L["No raid permission, cannot set mark"] = "No raid permission, cannot set mark";
    L["No raid permission, cannot clear marks"] = "No raid permission, cannot clear marks";
end

-- 缺失键时回退返回键名本身，避免 nil 拼接报错
setmetatable(L, {__index = function(t, k) return k; end});

UNITXPSP3_LOCALE = L;