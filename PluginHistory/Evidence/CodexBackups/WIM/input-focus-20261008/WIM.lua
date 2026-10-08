WIM_VERSION = "1.3.2";

--联系人菜单依附跟踪（多窗口模式 ContactButton 使用，参考 D:\WIM）
WIM_ContactMenuAttachedTo = nil; --当前联系人列表盒子依附的聊天窗口（多窗口模式，由联系人按钮设置）

WIM_Windows = {};
WIM_EditBoxInFocus = nil;
WIM_NewMessageFlag = false;
WIM_NewMessageCount = 0;
WIM_Icon_TheMenu = nil;
WIM_Icon_UpdateInterval = .5;
WIM_CascadeStep = 0;
WIM_MaxMenuCount = 20;
WIM_ClassIcons = {};
WIM_ClassColors = {};
WIM_PlayerCache = {}
WIM_PlayerCacheQueue = {}
WIM_WhisperedTo = {}

WIM_AlreadyCheckedGuildRoster = false;

WIM_GuildList = {}; --[Not saved between sessions: Autopopulates from GUILD_ROSTER_UPDATE event
WIM_FriendList = {}; --[Not saved between sessions: Autopopulates from FRIENDLIST_SHOW & FRIENDLIST_UPDATE event
WIM_GuildOnline = {}; --公会成员在线状态表（WIM_LoadGuildList 刷新，联系人列表 O(1) 查询用）
WIM_FriendOnline = {}; --好友在线状态表（WIM_LoadFriendList 刷新，联系人列表 O(1) 查询用）

WIM_Alias = {};
WIM_Filters = nil;
	
WIM_ToggleWindow_Timer = 0;
WIM_ToggleWindow_Index = 1;

WIM_RecentList = {}; --[Not saved between sessions: Store's list of recent conversations.
	
WIM_History = {};
WIM_CacheHistory = {}; --历史记录暂存
WIM_NowShowWindow = ""; --单窗口模式：当前显示的联系人窗口
WIM_Data_DEFAULTS = {
	versionLastLoaded = "",
	showChangeLogOnNewVersion = true,
	enableWIM = true,
	iconPosition=337,
	showMiniMap=true,
	displayColors = {
		wispIn = {r=0.5607843137254902, g=0.03137254901960784, b=0.7607843137254902},
		wispOut = {r=1, g=0.07843137254901961, b=0.9882352941176471},
		sysMsg = {r=1, g=0.6627450980392157, b=0},
		errorMsg = {r=1, g=0, b=0},
		webAddress = {r=0, g=0, b=1},
	},
	fontSize = 12,
	windowSize = 1,
	windowAlpha = .8,
	supressWisps = true,
	keepFocus = false,
	keepFocusRested = false,
	popNew = true, --多窗口模式：收到私聊弹出对应窗口（原版默认）
	multiWindow = false, --单窗口切换模式（true=每个联系人独立窗口的多窗口模式）
	popUpdate = true,
	popOnSend = true,
	popCombat = false,
	autoFocus = false,
	playSoundWisp = true,
	showToolTips = true,
	sortAlpha = false,
	winSize = {
		width = 384,
		height = 256
	},
	winLoc = {
		left =242 ,
		top =775
	},
	winCascade = {
		enabled = true,
		direction = "downright"
	},
	miniFreeMoving = {
		enabled = false;
		left = 0,
		top = 0
	},
	characterInfo = {
		show = true,
		classIcon = true,
		details = true,
		classColor = true
	},
	showTimeStamps = true,
	showShortcutBar = true,
	enableAlias = true,
	enableFilter = true,
	aliasAsComment = true,
	enableHistory = true,
	historySettings = {
		recordEveryone = true,
		recordFriends = true,
		recordGuild = true,
		colorIn = {
				r=0.4705882352941176,
				g=0.4705882352941176,
				b=0.4705882352941176
		},
		colorOut = {
				r=0.7058823529411764,
				g=0.7058823529411764,
				b=0.7058823529411764
		},
		popWin = {
			enabled = true,
			count = 25
		},
		maxMsg = {
			enabled = true,
			count = 200
		},
		autoDelete = {
			enabled = true,
			days = 7
		}
	},
	showAFK = true,
	useEscape = true,
	hookWispParse = true,
	blockLowLevel = false,
	boxSide = "RIGHT",
};
--[initialize defualt values
WIM_Data = WIM_Data_DEFAULTS;

WIM_CascadeDirection = {
	up = {
		left = 0,
		top = 25
	},
	down = {
		left = 0,
		top = -25
	},
	left = {
		left = -50,
		top = 0
	},
	right = {
		left = 50,
		top = 0
	},
	upleft = {
		left = -50,
		top = 25
	},
	upright = {
		left = 50,
		top = 25
	},
	downleft = {
		left = -50,
		top = -25
	},
	downright = {
		left = 50,
		top = -25
	}
};

WIM_IconItems = { };

function WIM_OnLoad()
    SlashCmdList["WIM"] = WIM_SlashCommand;
    SLASH_WIM1 = "/wim";
    -- 初始化职业映射；1.12没有C_Timer，pfUI若后于WIM加载，VARIABLES_LOADED时还会再初始化一次
    if pfUI then
        WIM_InitClassProps()
    end
end


function WIM_Incoming(event)
	--[Events
	if(event == "VARIABLES_LOADED") then
		if(WIM_Data.enableWIM == nil) then WIM_Data.enableWIM = WIM_Data_DEFAULTS.enableWIM; end;
		if(WIM_Data.versionLastLoaded == nil) then WIM_Data.versionLastLoaded = ""; end;
		if(WIM_Data.showChangeLogOnNewVersion == nil) then WIM_Data.showChangeLogOnNewVersion = WIM_Data_DEFAULTS.showChangeLogOnNewVersion; end;
		if(WIM_Data.displayColors == nil) then WIM_Data.displayColors = WIM_Data_DEFAULTS.displayColors; end;
		if(WIM_Data.displayColors.sysMsg == nil) then WIM_Data.displayColors.sysMsg = WIM_Data_DEFAULTS.displayColors.sysMsg; end;
		if(WIM_Data.displayColors.errorMsg == nil) then WIM_Data.displayColors.errorMsg = WIM_Data_DEFAULTS.displayColors.errorMsg; end;
		if(WIM_Data.fontSize == nil) then WIM_Data.fontSize = WIM_Data_DEFAULTS.fontSize; end;
		if(WIM_Data.windowSize == nil) then WIM_Data.windowSize = WIM_Data_DEFAULTS.windowSize; end;
		if(WIM_Data.windowAlpha == nil) then WIM_Data.windowAlpha = WIM_Data_DEFAULTS.windowAlpha; end;
		if(WIM_Data.supressWisps == nil) then WIM_Data.supressWisps = WIM_Data_DEFAULTS.supressWisps; end;
		if(WIM_Data.keepFocus == nil) then WIM_Data.keepFocus = WIM_Data_DEFAULTS.keepFocus; end;
		if(WIM_Data.keepFocusRested == nil) then WIM_Data.keepFocusRested = WIM_Data_DEFAULTS.keepFocusRested; end;
		if(WIM_Data.popNew == nil) then WIM_Data.popNew = WIM_Data_DEFAULTS.popNew; end;
		if(WIM_Data.multiWindow == nil) then WIM_Data.multiWindow = WIM_Data_DEFAULTS.multiWindow; end; --窗口模式：多窗口/单窗口
		if(WIM_Data.popUpdate == nil) then WIM_Data.popUpdate = WIM_Data_DEFAULTS.popUpdate; end; --修正原来误赋给popNew
		if(WIM_Data.autoFocus == nil) then WIM_Data.autoFocus = WIM_Data_DEFAULTS.autoFocus; end;
		if(WIM_Data.playSoundWisp == nil) then WIM_Data.playSoundWisp = WIM_Data_DEFAULTS.playSoundWisp; end;
		if(WIM_Data.showToolTips == nil) then WIM_Data.showToolTips = WIM_Data_DEFAULTS.showToolTips; end;
		if(WIM_Data.sortAlpha == nil) then WIM_Data.sortAlpha = WIM_Data_DEFAULTS.sortAlpha; end;
		if(WIM_Data.winSize == nil) then WIM_Data.winSize = WIM_Data_DEFAULTS.winSize; end;
		if(WIM_Data.miniFreeMoving == nil) then WIM_Data.miniFreeMoving = WIM_Data_DEFAULTS.miniFreeMoving; end;
		if(WIM_Data.popCombat == nil) then WIM_Data.popCombat = WIM_Data_DEFAULTS.popCombat; end;
		if(WIM_Data.characterInfo == nil) then WIM_Data.characterInfo = WIM_Data_DEFAULTS.characterInfo; end;
		if(WIM_Data.showTimeStamps == nil) then WIM_Data.showTimeStamps = WIM_Data_DEFAULTS.showTimeStamps; end;
		if(WIM_Data.showShortcutBar == nil) then WIM_Data.showShortcutBar = WIM_Data_DEFAULTS.showShortcutBar; end;
		if(WIM_Data.enableAlias == nil) then WIM_Data.enableAlias = WIM_Data_DEFAULTS.enableAlias; end;
		if(WIM_Data.enableFilter == nil) then WIM_Data.enableFilter = WIM_Data_DEFAULTS.enableFilter; end;
		if(WIM_Data.aliasAsComment == nil) then WIM_Data.aliasAsComment = WIM_Data_DEFAULTS.aliasAsComment; end;
		if(WIM_Data.enableHistory == nil) then WIM_Data.enableHistory = WIM_Data_DEFAULTS.enableHistory; end;
		if(WIM_Data.historySettings == nil) then WIM_Data.historySettings = WIM_Data_DEFAULTS.historySettings; end;
		if(WIM_Data.winLoc == nil) then WIM_Data.winLoc = WIM_Data_DEFAULTS.winLoc; end;
		if(WIM_Data.winCascade == nil) then WIM_Data.winCascade = WIM_Data_DEFAULTS.winCascade; end;
		if(WIM_Data.popOnSend == nil) then WIM_Data.popOnSend = WIM_Data_DEFAULTS.popOnSend; end;
		if(WIM_Data.versionLastLoaded == nil) then WIM_Data.versionLastLoaded = WIM_Data_DEFAULTS.versionLastLoaded; end;
		if(WIM_Data.showAFK == nil) then WIM_Data.showAFK = WIM_Data_DEFAULTS.showAFK; end;
		if(WIM_Data.useEscape == nil) then WIM_Data.useEscape = WIM_Data_DEFAULTS.useEscape; end;
		if(WIM_Data.hookWispParse == nil) then WIM_Data.hookWispParse = WIM_Data_DEFAULTS.hookWispParse; end;
		if(WIM_Data.boxSide == nil) then WIM_Data.boxSide = WIM_Data_DEFAULTS.boxSide; end;
		
		if(WIM_Filters == nil) then
			WIM_LoadDefaultFilters();
		end
		
		ShowFriends(); --[update friend list
		if(IsInGuild()) then GuildRoster(); end; --[update guild roster
		
		ItemRefTooltip:SetFrameStrata("TOOLTIP");
		
		WIM_HistoryPurge();
		
		WIM_InitClassProps();
		
		WIM_SetWIM_Enabled(WIM_Data.enableWIM);
		
		if(WIM_VERSION ~= WIM_Data.versionLastLoaded) then
			WIM_Help:Show();
			--多窗口模式升级：一次性开启"接收私聊时弹出窗口"（旧存档可能存为 false）
			WIM_Data.popNew = true;
		end
		WIM_Data.versionLastLoaded = WIM_VERSION;
		
		if(WIM_Data.miniFreeMoving.enabled) then
			if(WIM_Data.showMiniMap == false) then
				WIM_IconFrame:Hide();
			else
				WIM_IconFrame:Show();
				WIM_IconFrame:SetFrameStrata("LOW");
				WIM_IconFrame:SetPoint("TOPLEFT", "UIParent", "BOTTOMLEFT",WIM_Data.miniFreeMoving.left,WIM_Data.miniFreeMoving.top);
			end
		else
			WIM_Icon_UpdatePosition();
		end
		
	elseif(event == "TRADE_SKILL_SHOW" or event == "CRAFT_SHOW") then
		--[hook tradeskill window functions
		WIM_HookTradeSkill();
	elseif(event == "GUILD_ROSTER_UPDATE") then
		WIM_LoadGuildList();
		WIM_AlreadyCheckedGuildRoster = true;
	elseif(event == "FRIENDLIST_SHOW" or event == "FRIENDLIST_UPDATE") then
		WIM_LoadFriendList();
	elseif(event == "ADDON_LOADED") then
		WIM_AddonDetectToHook(arg1);
		--新增未读计数初始化
		if arg1 == "WIM" then
			WIM_contact_Unread = WIM_contact_Unread or {}
			if WIM_History then
				for k,v in pairs(WIM_History) do
					if k and type(WIM_History[k]) == "table" then
						for i=1, table.getn(WIM_History[k]) do
							if WIM_History[k][i]["unread"] then
								if not WIM_contact_Unread[k] then WIM_contact_Unread[k] = 0 end
								WIM_contact_Unread[k] = WIM_contact_Unread[k]+WIM_History[k][i]["unread"]
							end
						end
					end
				end
			end
			UpdateUnreadBubble() --循环外统一刷一次（优化：原来每条历史都刷一次，历史多时登录白耗）
		end
	else
		if(WIM_AlreadyCheckedGuildRoster == false) then
			if(IsInGuild()) then GuildRoster(); end; --[update guild roster
		end
		WIM_ChatFrame_OnEvent(event);
	end
end

function WIM_PlayerCacheQueueEmpty()
	for _, info in WIM_PlayerCacheQueue do
		if info.attempts <= 5 then
			return false
		end
	end
	return true
end

function WIM_Update()
	if not WIM_LastWhoListUpdate or GetTime() - WIM_LastWhoListUpdate > 5 then
		for name, info in WIM_PlayerCacheQueue do
			if info.attempts <= 5 and not info.last_sent or GetTime() - info.last_sent > ldexp(2, info.attempts) then
				SendWho('n-"'..name..'"')
				info.last_sent = GetTime()
				info.attempts = info.attempts + 1
				return
			end
		end
	end
end

function WIM_WhoInfo(name, callback)
    -- 优先从pfUI的缓存中获取玩家信息
    if pfUI and pfUI_playerDB and pfUI_playerDB[name] then
        local pfData = pfUI_playerDB[name]
        -- 构造WIM所需的玩家信息结构（映射pfUI数据到WIM格式）
        local playerInfo = {
            level = pfData.level or 0,
            class = pfData.class and WIM_PfUIClassMap[pfData.class] or "", -- 假设pfUI存储的是本地化职业名，与WIM兼容
            guild = pfData.guild or "",
            race = pfData.race or ""
        }
        -- 更新WIM本地缓存
        WIM_PlayerCache[name] = playerInfo
        -- 持久化职业，供联系人列表染色（下线重登后仍有效）
        if playerInfo.class ~= "" then
            WIM_ContactClass = WIM_ContactClass or {}
            WIM_ContactClass[name] = playerInfo.class
        end
        -- 直接调用回调函数
        callback(playerInfo)
        return
    end

    -- 原有逻辑：如果WIM本地已有缓存，直接使用
    if WIM_PlayerCache[name] then
        callback(WIM_PlayerCache[name])
        return
    end

    -- 再尝试ShaguTweaks玩家库（同样持久化，登录即可用；只有职业/等级，没有公会/种族）
    if ShaguTweaks_cache and ShaguTweaks_cache["players"] and ShaguTweaks_cache["players"][name] then
        local stData = ShaguTweaks_cache["players"][name]
        if stData.class and WIM_PfUIClassMap and WIM_PfUIClassMap[stData.class] then
            local playerInfo = {
                level = stData.level or 0,
                class = WIM_PfUIClassMap[stData.class],
                guild = "",
                race = ""
            }
            WIM_PlayerCache[name] = playerInfo
            -- 持久化职业，供联系人列表染色（下线重登后仍有效）
            WIM_ContactClass = WIM_ContactClass or {}
            WIM_ContactClass[name] = playerInfo.class
            callback(playerInfo)
            return
        end
    end

    -- 都没有则加入who查询队列（原有逻辑）
    WIM_WhoScanInProgress = true
    SetWhoToUI(1)
    WIM_PlayerCacheQueue[name] = WIM_PlayerCacheQueue[name] or { callbacks = {} }
    WIM_PlayerCacheQueue[name].attempts = 0
    tinsert(WIM_PlayerCacheQueue[name].callbacks, callback)
end

local function playerCheck(player, k)
	if not WIM_Data.blockLowLevel then
		return k()
	end

	if WIM_WhisperedTo[player] then
		return k()
	end
	
	for i=1, GetNumFriends() do
		name = GetFriendInfo(i)
		if name == player then
			return k()
		end
	end

	for i=1, GetNumGuildMembers(true) do
		name = GetGuildRosterInfo(i)
		if name == player then
			return k()
		end
	end

	WIM_WhoInfo(player, function(info)
		if info.level >= 10 then
			return k()
		end
	end)
end

function WIM_ChatFrame_OnEvent(event)
	if( WIM_Data.enableWIM == false) then
		return;
	end
	local msg = "";
	if((event == "CHAT_MSG_AFK" or event == "CHAT_MSG_DND") and WIM_Data.showAFK) then
		local afkType;
		if( event == "CHAT_MSG_AFK" ) then
			afkType = "AFK";
		else
			afkType = "DND";
		end
		msg = "<"..afkType.."> |Hplayer:"..arg2.."|h"..arg2.."|h: "..arg1;
		WIM_PostMessage(arg2, msg, 3);
		ChatEdit_SetLastTellTarget(ChatFrameEditBox,arg2);
	elseif event == 'CHAT_MSG_WHISPER' then
		local content, sender = arg1, arg2
		
		-- 添加玩家屏蔽检查
		local blockedPlayers = {
			["Arc'tiras"] = true,
			-- 添加更多要屏蔽的玩家名
		}
		
		-- 如果玩家在屏蔽列表中，直接返回，不处理消息
		if blockedPlayers[sender] then
			return
		end
		
		playerCheck(sender, function()
			local fr = WIM_FilterResult(content) --只算一次（原逻辑同一条消息重复跑两遍全量过滤器）
			if fr ~= 1 and fr ~= 2 then
				msg = "[|Hplayer:"..sender.."|h"..WIM_GetAlias(sender, true).."|h]: "..content
				WIM_PostMessage(sender, msg, 1, sender, content)
			end
			ChatEdit_SetLastTellTarget(ChatFrameEditBox, sender)
			
			-- 新增：如果开启了战斗中禁用弹出窗口且玩家处于战斗中，允许消息显示在默认聊天框
			if WIM_Data.popCombat and UnitAffectingCombat("player") then
				return true -- 返回true让消息传递给默认聊天框
			end
		end)
	
	elseif event == 'CHAT_MSG_WHISPER_INFORM' then
		local content, receiver = arg1, arg2
		WIM_WhisperedTo[receiver] = true
		local fr = WIM_FilterResult(content) --只算一次
		if fr ~= 1 and fr ~= 2 then
			msg = "[|Hplayer:"..UnitName("player").."|h"..WIM_GetAlias(UnitName("player"), true).."|h]: "..content
			WIM_PostMessage(receiver, msg, 2, UnitName("player"), content)
			
			-- 新增：如果开启了战斗中禁用弹出窗口且玩家处于战斗中，允许消息显示在默认聊天框
			if WIM_Data.popCombat and UnitAffectingCombat("player") then
				return true -- 返回true让消息传递给默认聊天框
			end
		end
	elseif(event == "CHAT_MSG_SYSTEM") then
		local tstart,tfinish = string.find(arg1, "\'(%a+)\'");
		if(tstart ~= nil and tfinish ~= nil) then
			user = string.sub(arg1, tstart+1, tfinish-1);
			user = string.gsub(user, "^%l", string.upper)
			tstart, tfinish = string.find(arg1, "playing");
			if(tstart ~= nil and WIM_Windows[user] ~= nil) then
				-- player not playing, can't whisper
				msg = "|Hplayer:"..user.."|h"..user.."|h is not currently playing!";
				WIM_PostMessage(user, msg, 4);
			end
		end
	end
end

function WIM_ChatFrameSupressor_OnEvent(event)
	if(WIM_Data.enableWIM == false) then
		return true;
	end
	
	-- 新增：如果开启了战斗中禁用弹出窗口且玩家处于战斗中，允许私聊消息显示在默认聊天框
	if WIM_Data.popCombat and UnitAffectingCombat("player") then
		if event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM" then
			if WIM_FilterResult(arg1) == 2 then
				return false; -- 被阻止的消息仍然不显示
			else
				return true; -- 其他私聊消息显示在默认聊天框
			end
		end
	end
	
	local msg = "";
	if((event == "CHAT_MSG_AFK" or event == "CHAT_MSG_DND") and WIM_Data.showAFK) then
		if(WIM_Data.supressWisps) then
			return false; --[ false to supress from chatframe
		else
			return true;
		end	
	elseif(event == "CHAT_MSG_WHISPER") then
		if(WIM_Data.supressWisps) then
			if(WIM_FilterResult(arg1) == 1) then
				return true;
			else
				return false; --[ false to supress from chatframe
			end
		else
			if(WIM_FilterResult(arg1) == 2) then
				return false;
			else
				return true;
			end
		end
	elseif(event == "CHAT_MSG_WHISPER_INFORM") then
		if(WIM_Data.supressWisps) then
			if(WIM_FilterResult(arg1) == 1) then
				return true;
			else
				return false; --[ false to supress from chatframe
			end
		else
			if(WIM_FilterResult(arg1) == 2) then
				return false;
			else
				return true;
			end
		end
	elseif(event == "CHAT_MSG_SYSTEM") then
		local tstart,tfinish = string.find(arg1, "\'(%a+)\'");
		if(tstart ~= nil and tfinish ~= nil) then
			user = string.sub(arg1, tstart+1, tfinish-1);
			user = string.gsub(user, "^%l", string.upper)
			tstart, tfinish = string.find(arg1, "playing");
			if(tstart ~= nil and WIM_Windows[user] ~= nil) then
				-- player not playing, can't whisper
				if(WIM_Data.supressWisps) then
					return false; --[ false to supress from chatframe
				else
					return true;
				end
			end
		end
		return true;
	end
	return true;
end

function WIM_PostMessage(user, msg, ttype, from, raw_msg, hotkeyFix)
	--[[
		ttype:
			1 - Wisper from someone
			2 - Wisper sent
			3 - System Message
			4 - Error Message
			5 - Show window... Do nothing else...
	]]--
	if user == UnitName("player") and getglobal('WIM_msgFrame'..user) and getglobal('WIM_msgFrame'..user):IsShown() then
		return
	end
	local f,chatBox
	local isNew = false
	if not WIM_Windows[user] then
		if getglobal('WIM_msgFrame'..user) then
			f = getglobal('WIM_msgFrame'..user)
		else
			f = CreateFrame('Frame', 'WIM_msgFrame'..user,UIParent, 'WIM_msgFrameTemplate')
		end
		WIM_SetWindowProps(f)
		WIM_Windows[user] = {
			frame = 'WIM_msgFrame'..user,
			newMSG = true, 
			is_visible = false, 
			last_msg = time(),
		}
		f.theUser = user
		getglobal('WIM_msgFrame'..user..'From'):SetText(WIM_GetAlias(user))
		--建会话不再直接登记小地图菜单，改由下方真实会话活动（ttype 1~4）时补登记
		isNew = true
		WIM_SetWindowLocation(f,ttype) --25.10.22修改
		if WIM_Data.characterInfo.show then
			if table.getn(WIM_Split(user, '-')) == 2 then
				-- WIM_GetBattleWhoInfo(user)
			else
				WIM_WhoInfo(user, function()
					WIM_SetWhoInfo(user)
				end) 
			end
		end
		WIM_UpdateCascadeStep()
		WIM_DisplayHistory(user)
		--[[if(WIM_History[user]) then
			getglobal(f:GetName()..'HistoryButton'):Show()
		end]]
	end
	f = getglobal('WIM_msgFrame'..user)
	--WIM_SetWindowLocation(f,ttype) --25.10.22修改
	chatBox = getglobal('WIM_msgFrame'..user..'ScrollingMessageFrame')
	if msg then --25.11.2修改
		msg = WIM_ConvertURLtoLinks(msg)
	end
	--只有真实会话活动（收发密语/系统/错误消息）才标记活动、刷新排序时间并登记小地图菜单；
	--纯查看（ttype 为 nil 或 5：点击联系人、菜单/热键切换窗口）不登记、不打乱菜单排序
	if ttype and ttype ~= 5 then
		WIM_Windows[user].newMSG = true
		WIM_Windows[user].last_msg = time()
		if not WIM_IconItems[user] then
			WIM_Icon_AddUser(user) --先查看后有密语的场景，首次真实活动时补登记
		end
	end
	if ttype == 1 then
		--联系人列表
		--确保变量已初始化
		WIM_contact_Unread = WIM_contact_Unread or {}
		-- 更新未读计数
		if getglobal('WIM_msgFrame'..user) and getglobal('WIM_msgFrame'..user):IsShown() and (WIM_Data.multiWindow ~= false or WIM_NowShowWindow == user) then --窗口已打开才不累计（单窗口模式还须是当前窗口）
			WIM_contact_Unread[user] = 0 --未读计数为0
		else
       			WIM_contact_Unread[user] = (WIM_contact_Unread[user] or 0) + 1 --未读计数+1
		end
		WIM_PlaySoundWisp()
		WIM_AddToHistory(user, from, raw_msg, false, true)
        	UpdateUnreadBubble() --刷新联系人未读计数
		WIM_RecentListAdd(user)
		chatBox:AddMessage(WIM_getTimeStamp()..msg, WIM_Data.displayColors.wispIn.r, WIM_Data.displayColors.wispIn.g, WIM_Data.displayColors.wispIn.b)
	elseif ttype == 2 then
		WIM_AddToHistory(user, from, raw_msg, true)
		WIM_RecentListAdd(user)
		WIM_MarkContactListDirty() --主动发密语也刷新联系人盒子（标脏合并刷新，修复盒子不更新且避免每条全量重建）
		chatBox:AddMessage(WIM_getTimeStamp()..msg, WIM_Data.displayColors.wispOut.r, WIM_Data.displayColors.wispOut.g, WIM_Data.displayColors.wispOut.b)
	elseif ttype == 3 then
		chatBox:AddMessage(msg, WIM_Data.displayColors.sysMsg.r, WIM_Data.displayColors.sysMsg.g, WIM_Data.displayColors.sysMsg.b)
	elseif ttype == 4 then
		chatBox:AddMessage(msg, WIM_Data.displayColors.errorMsg.r, WIM_Data.displayColors.errorMsg.g, WIM_Data.displayColors.errorMsg.b)
	end
	if WIM_PopOrNot(isNew) or ttype == 2 or ttype == 5 or not ttype then
		WIM_Windows[user].newMSG = false
		if ttype == 2 and WIM_Data.popOnSend == false then
			--[ do nothing, user prefers not to pop on send
		else
			if WIM_Data.multiWindow == false and WIM_NowShowWindow ~= "" and WIM_NowShowWindow ~= user then
				--单窗口模式：先隐藏上一个联系人的窗口
				local prevWin = getglobal('WIM_msgFrame'..WIM_NowShowWindow)
				if prevWin then prevWin:Hide() end
			end
			WIM_NowShowWindow = user --记录当前显示窗口（单窗口互斥用，多窗口仅作参考）
			f:Show()
			--多窗口模式照搬 D:\WIM：只弹级联消息窗口，不自动弹出联系人盒子（盒子需手动点入口打开）；单窗口模式盒子为中心 UI，自动弹出
			if WIM_Data.multiWindow == false and boxFrame then boxFrame:Show() end
			RefreshUnread(user) --窗口已打开，清除该联系人未读计数
			if ttype ==5 then
				f:Raise()
				getglobal(f:GetName()..'MsgBox'):SetFocus()
			end
		end
	end

	WIM_UpdateScrollBars(chatBox)
	WIM_Icon_DropDown_Update()
	if WIM_HistoryFrame:IsVisible() then
		WIM_HistoryViewNameScrollBar_Update()
		WIM_HistoryViewFiltersScrollBar_Update()
	end

	if hotkeyFix then
		local orig = getglobal(f:GetName()..'MsgBox'):GetScript('OnChar')
		getglobal(f:GetName()..'MsgBox'):SetScript('OnChar', function()
			getglobal(f:GetName()..'MsgBox'):SetText('')
			getglobal(f:GetName()..'MsgBox'):SetScript('OnChar', orig)
		end)
	end
end

--[[function WIM_SetWindowLocation(theWin) --25.10.22移动到WIM_contact.lua
	local CascadeOffset_Left = 0;
	local CascadeOffset_Top = 0;

	if(WIM_Data.winCascade.enabled) then
		CascadeOffset_Left = WIM_CascadeDirection[WIM_Data.winCascade.direction].left;
		CascadeOffset_Top = WIM_CascadeDirection[WIM_Data.winCascade.direction].top;
	end
	
	theWin:SetPoint(
		"TOPLEFT",
		"UIParent",
		"BOTTOMLEFT",
		(WIM_Data.winLoc.left + WIM_CascadeStep*CascadeOffset_Left), 
		(WIM_Data.winLoc.top + WIM_CascadeStep*CascadeOffset_Top)
	);

end]]

function WIM_PopOrNot(isNew)
	if(isNew == true and WIM_Data.popNew == true) then
		if(WIM_Data.popCombat and UnitAffectingCombat("player")) then
			return false;
		else
			return true;
		end
	elseif(WIM_Data.popNew == true and WIM_Data.popUpdate == true) then
		if(WIM_Data.popCombat and UnitAffectingCombat("player")) then
			return false;
		else
			return true;
		end
	else
		return false;
	end
end


function WIM_UpdateScrollBars(smf)
	local parentName = smf:GetParent():GetName();
	if(smf:AtTop()) then
		getglobal(parentName.."ScrollUp"):Disable();
	else
		getglobal(parentName.."ScrollUp"):Enable();
	end
	if(smf:AtBottom()) then
		getglobal(parentName.."ScrollDown"):Disable();
	else
		getglobal(parentName.."ScrollDown"):Enable();
	end
end

function WIM_isLinkURL(link)
	if (strsub(link, 1, 3) == "url") then
		return true;
	else
		return false;
	end
end

function WIM_DisplayURL(link)
	local theLink = "";
	if (string.len(link) > 4) and (string.sub(link,1,4) == "url:") then
		theLink = string.sub(link,5, string.len(link));
	end
	--show UI to show url so it can be copied
	if(theLink) then
		WIM_urlCopyUrlBox:SetText(theLink);
		WIM_urlCopy:Show();
		WIM_urlCopyUrlBox:HighlightText(0);
	end
end

function WIM_ConvertURLtoLinks(text)
	local preLink, midLink, postLink;
	preLink = "|Hurl:";
	midLink = "|h|cff"..WIM_RGBtoHex(WIM_Data.displayColors.webAddress.r, WIM_Data.displayColors.webAddress.g, WIM_Data.displayColors.webAddress.b);
	postLink = "|h|r";
	text = string.gsub(text, "(%a+://[%w_/%.%?%%=~&-]+)", preLink.."%1"..midLink.."%1"..postLink);
	return text;
end

function WIM_SlashCommand(msg)
	if(msg == "" or msg == nil) then
		WIM_Options:Show();
	elseif(msg == "reset") then
		WIM_Data = WIM_Data_DEFAULTS;
	elseif(msg == "clear history") then
		WIM_History = {};
	elseif(msg == "reset filters") then
		WIM_LoadDefaultFilters();
	elseif(msg == "history") then
		WIM_HistoryFrame:Show();
	elseif(msg == "help") then
		WIM_Help:Show();
	end
end


function WIM_Icon_Move(toDegree)
	WIM_Data.iconPosition = toDegree;
	WIM_Icon_UpdatePosition();
end

function WIM_Icon_UpdatePosition()
	if(WIM_Data.showMiniMap == false) then
		WIM_IconFrame:Hide();
	else
		if(WIM_Data.miniFreeMoving.enabled == false) then
			WIM_IconFrame:SetPoint(
				"TOPLEFT",
				"Minimap",
				"TOPLEFT",
				54 - (78 * cos(WIM_Data.iconPosition)),
				(78 * sin(WIM_Data.iconPosition)) - 55
			);
		end
		WIM_IconFrame:Show();
	end
end


function WIM_SetWindowProps(theWin)
	if(WIM_Data.showShortcutBar) then
		getglobal(theWin:GetName().."ShortcutFrame"):Show();
		local tHeight = WIM_Data.winSize.height;
		if(tHeight < 240) then
			tHeight = 240;
		end
		theWin:SetHeight(tHeight);
	else
		getglobal(theWin:GetName().."ShortcutFrame"):Hide();
		theWin:SetHeight(WIM_Data.winSize.height);
	end
	theWin:SetWidth(WIM_Data.winSize.width);
	theWin:SetScale(WIM_Data.windowSize);
	theWin:SetAlpha(WIM_Data.windowAlpha);
	getglobal(theWin:GetName().."ScrollingMessageFrame"):SetFont("Fonts\\FZXHLJW.TTF",WIM_Data.fontSize);
	getglobal(theWin:GetName().."ScrollingMessageFrame"):SetAlpha(1);
	getglobal(theWin:GetName().."MsgBox"):SetAlpha(1);
	getglobal(theWin:GetName().."MsgBox"):SetAltArrowKeyMode(false);
	getglobal(theWin:GetName().."ShortcutFrame"):SetAlpha(1);
	if(WIM_Data.useEscape) then
		WIM_AddEscapeWindow(theWin);
	else
		WIM_RemoveEscapeWindow(theWin);
	end
	--WIM_SetTabFrameProps();
end


function WIM_AddEscapeWindow(theWin)
	for i=1, table.getn(UISpecialFrames) do 
		if(UISpecialFrames[i] == theWin:GetName()) then
			return;
		end
	end
	tinsert(UISpecialFrames,theWin:GetName());
	--查重后再加盒子，避免每个会话窗口都重复插入
	for i=1, table.getn(UISpecialFrames) do 
		if(UISpecialFrames[i] == "WIMBoxFrame") then
			return;
		end
	end
	tinsert(UISpecialFrames,"WIMBoxFrame");
end

function WIM_RemoveEscapeWindow(theWin)
	for i=1, table.getn(UISpecialFrames) do 
		if(UISpecialFrames[i] == theWin:GetName()) then
			table.remove(UISpecialFrames, i);
			--table.remove第二参数只能是数字索引，按值查找"WIMBoxFrame"再删
			for j=1, table.getn(UISpecialFrames) do 
				if(UISpecialFrames[j] == "WIMBoxFrame") then
					table.remove(UISpecialFrames, j);
					break
				end
			end
			return;
		end
	end
end

function WIM_SetAllWindowProps()
	for key in WIM_Windows do
		WIM_SetWindowProps(getglobal(WIM_Windows[key].frame));
	end
end


function WIM_Icon_ToggleDropDown()
    if(WIM_ConversationMenu:IsVisible()) then
        WIM_ConversationMenu:Hide();
    else
        WIM_ConversationMenu:ClearAllPoints();
        WIM_ConversationMenu:Show();
        
        -- 如果有保存的位置，使用保存的位置，否则使用默认位置
        if WIM_Data and WIM_Data.conversationMenuPosition and 
           WIM_Data.conversationMenuPosition.left and WIM_Data.conversationMenuPosition.top then
            -- 使用保存的位置
            WIM_ConversationMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 
                WIM_Data.conversationMenuPosition.left, 
                WIM_Data.conversationMenuPosition.top);
        else
            -- 使用默认位置（相对于图标）
            WIM_ConversationMenu:SetPoint("TOPRIGHT", WIM_IconFrame, "BOTTOMLEFT", 5, 5);
        end
    end
end

--多窗口模式下，聊天窗口"联系人按钮"点击：切换联系人列表盒子（boxFrame），定位在窗口右侧；单窗口模式该按钮隐藏
function WIM_ToggleContactMenuForWindow(frame)
    if(boxFrame:IsVisible() and WIM_ContactMenuAttachedTo == frame) then
        boxFrame:Hide();
        WIM_ContactMenuAttachedTo = nil;
        return;
    end
    --列表刷新由 boxFrame OnShow 兜底（打开时才重建，避免隐藏状态下白白全量重建）
    --用 UIParent 屏幕坐标定位，避免与"吸附在盒子上的窗口"形成锚定循环（frame 依赖 boxFrame 时 SetPoint 会报 dependent 错误）
    boxFrame:ClearAllPoints();
    local r = frame:GetRight();
    local t = frame:GetTop();
    if(r and t) then
        boxFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", r, t);
    else
        boxFrame:SetPoint("CENTER", UIParent, "CENTER");
    end
    boxFrame:Show();
    -- 已显示的列表切换到另一聊天窗口时不会触发 OnShow，也需要重新置前。
    boxFrame:Raise();
    WIM_ContactMenuAttachedTo = frame;
end

function WIM_Icon_DropDown_Update()
	
	local tList = {}
	local tListActivity = {}
	local tCount = 0
	for key in WIM_IconItems do
		table.insert(tListActivity, key)
		tCount = tCount + 1
	end
	
	--[first get a sorted list of users by most recent activity
	table.sort(tListActivity, WIM_Icon_SortByActivity)
	--[account for only the allowable amount of active users
	for i=1,table.getn(tListActivity) do
		if i <= WIM_MaxMenuCount then
			table.insert(tList, tListActivity[i])
		end
	end
	
	--Initialize Menu
	for i=1,20 do 
		getglobal("WIM_ConversationMenuTellButton"..i.."Close"):Show()
		getglobal("WIM_ConversationMenuTellButton"..i):Enable()
		getglobal("WIM_ConversationMenuTellButton"..i):Hide()
	end
	
	
	WIM_NewMessageCount = 0;
	
	if tCount == 0 then
		info = {}
		info.justifyH = "LEFT"
		info.text = "WIM_L_NONE"
		info.notClickable = 1
		info.notCheckable = 1
		getglobal("WIM_ConversationMenuTellButton1Close"):Hide()
		getglobal("WIM_ConversationMenuTellButton1"):Disable()
		getglobal("WIM_ConversationMenuTellButton1"):SetText(WIM_L_NONEC)
		getglobal("WIM_ConversationMenuTellButton1"):Show()
	else
		if WIM_Data.sortAlpha then
			table.sort(tList)
		end
		WIM_NewMessageFlag = false
		for i=1,table.getn(tList) do
			if WIM_Windows[tList[i]].newMSG and WIM_Windows[tList[i]].is_visible == false then
				WIM_IconItems[tList[i]].color = "|cff"..WIM_RGBtoHex(77/255, 135/233, 224/255)
				WIM_NewMessageFlag = true
				WIM_NewMessageCount = WIM_NewMessageCount + 1
			else
				WIM_IconItems[tList[i]].color = "|cffffffff"
			end
			getglobal("WIM_ConversationMenuTellButton"..i):SetText(WIM_IconItems[tList[i]].color..WIM_GetAlias(WIM_IconItems[tList[i]].text, true))
			getglobal("WIM_ConversationMenuTellButton"..i).theUser = WIM_IconItems[tList[i]].text
			getglobal("WIM_ConversationMenuTellButton"..i).value = WIM_IconItems[tList[i]].value
			getglobal("WIM_ConversationMenuTellButton"..i):Show()
		end
	end
	
	--Set Height of Conversation Menu depending on message count
	local ConvoMenuHeight = 60
	local CMH_Delta = 16 * (table.getn(tList)-1)
	if CMH_Delta < 0 then CMH_Delta = 0 end
	ConvoMenuHeight = ConvoMenuHeight + CMH_Delta
	WIM_ConversationMenu:SetHeight(ConvoMenuHeight)
	
	--Minimap icon
	if WIM_Data.enableWIM == true then
		if WIM_NewMessageFlag == true then
			WIM_IconFrameButton:SetNormalTexture("Interface\\AddOns\\WIM\\Images\\miniEnabled")
		else
			WIM_IconFrameButton:SetNormalTexture("Interface\\AddOns\\WIM\\Images\\miniDisabled")
		end
	else
		--show wim disabled icon
		WIM_IconFrameButton:SetNormalTexture("Interface\\AddOns\\WIM\\Images\\miniOff")
	end
end


function WIM_ConversationMenu_OnUpdate(elapsed)
	if this.isCounting then
		this.timeElapsed = this.timeElapsed + elapsed
		if this.timeElapsed > 1 then
			this:Hide()
			this.timeElapsed = 0
			this.isCounting = false
		end
	end
end

function WIM_Icon_AddUser(theUser)
	UIDROPDOWNMENU_INIT_MENU = "WIM_Options_DropDown"
	UIDROPDOWNMENU_OPEN_MENU = UIDROPDOWNMENU_INIT_MENU
	local info = {}
	info.text = theUser;
	info.justifyH = "LEFT"
	info.isTitle = nil
	info.notCheckable = 1
	info.value = WIM_Windows[theUser].frame
	info.func = WIM_Icon_PlayerClick
	WIM_IconItems[theUser] = info
	table.sort(WIM_IconItems)
	WIM_Icon_DropDown_Update()
end

function WIM_Icon_PlayerClick()
	if(this.value ~= nil) then
		--[local user = getglobal(this.value.."From"):GetText();
		local user = getglobal(this.value).theUser
		--改走主流程显示窗口：互斥隐藏上一个窗口、刷新未读计数和联系人盒子，修复多窗重叠与点击后不更新
		if(user and WIM_Windows[user]) then
			WIM_PostMessage(user, nil, 5)
		end
	end
end

function WIM_Icon_OnUpdate(elapsedTime)
	if WIM_NewMessageFlag == false then
		this.TimeSinceLastUpdate = 0
		if WIM_Icon_NewMessageFlash:IsVisible() then
			WIM_Icon_NewMessageFlash:Hide()
		end
		return
	end

	this.TimeSinceLastUpdate = this.TimeSinceLastUpdate + elapsedTime 	

	while this.TimeSinceLastUpdate > WIM_Icon_UpdateInterval do
		if WIM_Icon_NewMessageFlash:IsVisible() then
			WIM_Icon_NewMessageFlash:Hide()
		else
			WIM_Icon_NewMessageFlash:Show()
		end
		this.TimeSinceLastUpdate = this.TimeSinceLastUpdate - WIM_Icon_UpdateInterval
	end
end

function WIM_UpdateCascadeStep()
		WIM_CascadeStep = WIM_CascadeStep + 1
		if WIM_CascadeStep > 10 then
			WIM_CascadeStep = 0
		end
end

WIM_LastWispSoundTime = 0;
function WIM_PlaySoundWisp()
	--节流：多条密语短时间内同时到达只播一次，避免连发爆音与卡顿
	if WIM_Data.playSoundWisp == true and GetTime() - WIM_LastWispSoundTime > 0.3 then
		WIM_LastWispSoundTime = GetTime()
		PlaySoundFile("Interface\\AddOns\\WIM\\Sounds\\wisp.wav")
	end
end

function WIM_Icon_SortByActivity(user1, user2)
	return WIM_Windows[user1].last_msg > WIM_Windows[user2].last_msg
end

function WIM_RGBtoHex(r,g,b)
	return string.format ("%.2x%.2x%.2x",r*255,g*255,b*255)
end

function WIM_Icon_OnEnter()
	GameTooltip:SetOwner(this, "ANCHOR_LEFT");
	GameTooltip:SetText("WIM v"..WIM_VERSION.."              ");
	GameTooltip:AddDoubleLine("Conversation Menu", "Left-Click", 1,1,1,1,1,1);
	GameTooltip:AddDoubleLine("Show New Messages", "Right-Click", 1,1,1,1,1,1);
	GameTooltip:AddDoubleLine("WIM Options", "/wim", 1,1,1,1,1,1);
end

function WIM_ShowNewMessages()
	--多窗口模式：显示所有有新消息的会话窗口
	for key in WIM_Windows do
		if(WIM_Windows[key].newMSG == true) then
			getglobal(WIM_Windows[key].frame):Show();
			WIM_Windows[key].newMSG = false;
			RefreshUnread(key) --窗口已打开，清除该联系人未读计数
		end
	end
	WIM_Icon_DropDown_Update();
end

function WIM_ShowAll()
	--多窗口模式：显示全部会话窗口
	for key in WIM_Windows do
		getglobal(WIM_Windows[key].frame):Show();
	end
	WIM_Icon_DropDown_Update();
end

function WIM_HideAll()
	for key in WIM_Windows do
		getglobal(WIM_Windows[key].frame):Hide();
	end
end

function WIM_CloseAllConvos()
	for key in WIM_Windows do
		WIM_CloseConvo(key);
	end
end

function WIM_CloseConvo(theUser)
	if(WIM_Windows[theUser] == nil) then return; end; --[ fail silently
	
	getglobal(WIM_Windows[theUser].frame):Hide();
	getglobal(WIM_Windows[theUser].frame.."ScrollingMessageFrame"):Clear();
	getglobal(WIM_Windows[theUser].frame.."ClassIcon"):SetTexture("Interface\\AddOns\\WIM\\Images\\classBLANK");
	getglobal(WIM_Windows[theUser].frame.."CharacterDetails"):SetText("");
	WIM_Windows[theUser] = nil;
	WIM_IconItems[theUser] = nil;
	if(WIM_NowShowWindow == theUser) then
		WIM_NowShowWindow = ""; --关闭的是当前窗口时清掉标记
	end

	WIM_Icon_DropDown_Update();
end

function WIM_InitClassProps()
	WIM_ClassIcons[WIM_LOCALIZED_DRUID] 	= "Interface\\AddOns\\WIM\\Images\\classDRUID";
	WIM_ClassIcons[WIM_LOCALIZED_HUNTER] 	= "Interface\\AddOns\\WIM\\Images\\classHUNTER";
	WIM_ClassIcons[WIM_LOCALIZED_MAGE]	 	= "Interface\\AddOns\\WIM\\Images\\classMAGE";
	WIM_ClassIcons[WIM_LOCALIZED_PALADIN] 	= "Interface\\AddOns\\WIM\\Images\\classPALADIN";
	WIM_ClassIcons[WIM_LOCALIZED_PRIEST] 	= "Interface\\AddOns\\WIM\\Images\\classPRIEST";
	WIM_ClassIcons[WIM_LOCALIZED_ROGUE] 	= "Interface\\AddOns\\WIM\\Images\\classROGUE";
	WIM_ClassIcons[WIM_LOCALIZED_SHAMAN] 	= "Interface\\AddOns\\WIM\\Images\\classSHAMAN";
	WIM_ClassIcons[WIM_LOCALIZED_WARLOCK] 	= "Interface\\AddOns\\WIM\\Images\\classWARLOCK";
	WIM_ClassIcons[WIM_LOCALIZED_WARRIOR] 	= "Interface\\AddOns\\WIM\\Images\\classWARRIOR";
	
	WIM_ClassColors[WIM_LOCALIZED_DRUID]	= "ff7d0a";
	WIM_ClassColors[WIM_LOCALIZED_HUNTER]	= "abd473";
	WIM_ClassColors[WIM_LOCALIZED_MAGE]		= "69ccf0";
	WIM_ClassColors[WIM_LOCALIZED_PALADIN]	= "f58cba";
	WIM_ClassColors[WIM_LOCALIZED_PRIEST]	= "ffffff";
	WIM_ClassColors[WIM_LOCALIZED_ROGUE]	= "fff569";
	WIM_ClassColors[WIM_LOCALIZED_SHAMAN]	= "0070dd";
	WIM_ClassColors[WIM_LOCALIZED_WARLOCK]	= "9482ca";
	WIM_ClassColors[WIM_LOCALIZED_WARRIOR]	= "c79c6e";

    WIM_PfUIClassMap = {
        ["DRUID"] = WIM_LOCALIZED_DRUID,
        ["HUNTER"] = WIM_LOCALIZED_HUNTER,
        ["MAGE"] = WIM_LOCALIZED_MAGE,
        ["PALADIN"] = WIM_LOCALIZED_PALADIN,
        ["PRIEST"] = WIM_LOCALIZED_PRIEST,
        ["ROGUE"] = WIM_LOCALIZED_ROGUE,
        ["SHAMAN"] = WIM_LOCALIZED_SHAMAN,
        ["WARLOCK"] = WIM_LOCALIZED_WARLOCK,
        ["WARRIOR"] = WIM_LOCALIZED_WARRIOR
    }
end

function WIM_UserWithClassColor(theUser)
	if(WIM_PlayerCache[theUser].class == "") then
		return theUser;
	else
		if(WIM_ClassColors[WIM_PlayerCache[theUser].class]) then
			return "|cff"..WIM_ClassColors[WIM_PlayerCache[theUser].class]..WIM_GetAlias(theUser);
		else
			return WIM_GetAlias(theUser);
		end
	end
end

function WIM_SetWhoInfo(theUser)
	local classIcon = getglobal(WIM_Windows[theUser].frame.."ClassIcon");
	if(WIM_Data.characterInfo.classIcon and WIM_ClassIcons[WIM_PlayerCache[theUser].class]) then
		classIcon:SetTexture(WIM_ClassIcons[WIM_PlayerCache[theUser].class]);
	else
		classIcon:SetTexture("Interface\\AddOns\\WIM\\Images\\classBLANK");
	end
	if(WIM_Data.characterInfo.classColor) then	
		getglobal(WIM_Windows[theUser].frame.."From"):SetText(WIM_UserWithClassColor(theUser));
	end
	if(WIM_Data.characterInfo.details) then	
		local tGuild = "";
		if(WIM_PlayerCache[theUser].guild ~= "") then
			tGuild = "<"..WIM_PlayerCache[theUser].guild.."> ";
		end
		getglobal(WIM_Windows[theUser].frame.."CharacterDetails"):SetText("|cffffffff"..tGuild..WIM_PlayerCache[theUser].level.." "..WIM_PlayerCache[theUser].race.." "..WIM_PlayerCache[theUser].class.."|r");
	end
end

function WIM_getTimeStamp()
	if(WIM_Data.showTimeStamps) then
		return "|cff"..WIM_RGBtoHex(WIM_Data.displayColors.sysMsg.r, WIM_Data.displayColors.sysMsg.g, WIM_Data.displayColors.sysMsg.b)..date("%H:%M:%S").."|r ";
	else
		return "";
	end
end

function WIM_Bindings_EnableWIM()
	WIM_SetWIM_Enabled(not WIM_Data.enableWIM);
end

function WIM_SetWIM_Enabled(YesOrNo)
	WIM_Data.enableWIM = YesOrNo
	WIM_Icon_DropDown_Update();
end

function WIM_LoadShortcutFrame()
	local tButtons = {
		{
			icon = "Interface\\Icons\\Ability_Hunter_AimedShot",
			cmd		= "target",
			tooltip = WIM_L_TARGET
		},
		{
			icon = "Interface\\Icons\\Spell_Holy_BlessingOfStrength",
			cmd		= "invite",
			tooltip = WIM_L_INVITE
		},
		{
			icon = "Interface\\Icons\\INV_Misc_Bag_10_Blue",
			cmd		= "trade",
			tooltip = WIM_L_TRADE
		},
		{
			icon = "Interface\\Icons\\INV_Helmet_44",
			cmd		= "inspect",
			tooltip = WIM_L_INSPECT
		},
		{
			icon = "Interface\\Icons\\Ability_Physical_Taunt",
			cmd		= "ignore",
			tooltip = WIM_L_IGNORE
		},
	};
	for i=1,5 do
		getglobal(this:GetName().."ShortcutFrameButton"..i.."Icon"):SetTexture(tButtons[i].icon);
		getglobal(this:GetName().."ShortcutFrameButton"..i).cmd = tButtons[i].cmd;
		getglobal(this:GetName().."ShortcutFrameButton"..i).tooltip = tButtons[i].tooltip;
	end
	getglobal(this:GetName().."ShortcutFrame"):SetScale(.75);
end

function WIM_ShorcutButton_Clicked()
	local cmd = this.cmd;
	local theUser = this:GetParent():GetParent().theUser;
	if(cmd == "target") then
		TargetByName(theUser, true)
	elseif(cmd == "invite") then
		InviteByName(theUser)
	elseif(cmd == "trade") then
		TargetByName(theUser, true)
		InitiateTrade("target")
	elseif(cmd == "inspect") then
		TargetByName(theUser, true)
		InspectUnit("target")
	elseif(cmd == "ignore") then
		getglobal(this:GetParent():GetParent():GetName().."IgnoreConfirm"):Show();
	end
end

function WIM_GetAlias(theUser, nameOnly)
	if(WIM_Data.enableAlias and WIM_Alias[theUser] ~= nil) then
		if(WIM_Data.aliasAsComment) then
			if(nameOnly) then
				return theUser;
			else
				return theUser.." |cffffffff- "..WIM_Alias[theUser].."|r";
			end
		else
			return WIM_Alias[theUser];
		end
	else
		return theUser;
	end
end


function WIM_FilterResult(theMSG)
	if(WIM_Data.enableFilter) then
		local key, a, b;
		for key in WIM_Filters do
			if(strfind(strlower(theMSG), strlower(key)) ~= nil) then
				if(WIM_Filters[key] == "Ignore") then
					return 1;
				elseif(WIM_Filters[key] == "Block") then
					return 2;
				end
			end
		end
		return 0;
	else
		return 0;
	end
end

function WIM_CanRecordUser(theUser)
	if(WIM_Data.historySettings.recordEveryone) then
		return true;
	else
		if(WIM_Data.historySettings.recordFriends and WIM_FriendList[theUser]) then
			return true;
		elseif(WIM_Data.historySettings.recordGuild and WIM_GuildList[theUser]) then
			return true;
		end
	end
	return false;
end

function WIM_AddToHistory(theUser, userFrom, theMessage, isMsgIn, unread)
	local tmpEntry = {};
	local cacheEntry = {};
	if(WIM_Data.enableHistory) then --[if history is enabled
		if(WIM_CanRecordUser(theUser)) then --[if record user
			--getglobal(WIM_Windows[theUser].frame.."HistoryButton"):Show();
			tmpEntry["stamp"] = time();
			tmpEntry["date"] = date("%Y-%m-%d");
			tmpEntry["time"] = date("%H:%M:%S");
			tmpEntry["msg"] = WIM_ConvertURLtoLinks(theMessage);
			tmpEntry["from"] = userFrom;
			if(unread) then
				tmpEntry["unread"] = 1;
			end
			if(isMsgIn) then
				tmpEntry["type"] = 2;
			else
				tmpEntry["type"] = 1;
			end
			if(WIM_History[theUser] == nil) then
				WIM_History[theUser] = {};
			end
			if UnitName("player") ~= theUser then
				table.insert(WIM_History[theUser], tmpEntry);
			end
			
			if(WIM_Data.historySettings.maxMsg.enabled) then
				local tOver = table.getn(WIM_History[theUser]) - WIM_Data.historySettings.maxMsg.count;
				if(tOver > 0) then
					for i = 1, tOver do 
						table.remove(WIM_History[theUser], 1);
					end
				end
			end
			if(WIM_Options:IsVisible()) then
				WIM_HistoryScrollBar_Update();
			end
		end
	end
end

function WIM_SortHistory(a, b)
	if(a.stamp < b.stamp) then
		return true;
	else
		return false;
	end
end

function WIM_DisplayHistory(theUser)
	if(WIM_History[theUser] and WIM_Data.enableHistory and WIM_Data.historySettings.popWin.enabled) then
		table.sort(WIM_History[theUser], WIM_SortHistory);

		for i=table.getn(WIM_History[theUser])-WIM_Data.historySettings.popWin.count-1, table.getn(WIM_History[theUser]) do 
			if(WIM_History[theUser][i]) then
				--WIM_GetAlias
				msg = "|Hplayer:"..WIM_History[theUser][i].from.."|h["..WIM_GetAlias(WIM_History[theUser][i].from, true).."]|h: "..WIM_History[theUser][i].msg;
				if(WIM_Data.showTimeStamps) then
					msg = WIM_History[theUser][i].time.." "..msg;
				end
				local historycolor="" --窗口历史记录颜色
				local colororwisp = ""
				if WIM_History[theUser][i]["unread"] == 1 then
					historycolor = "displayColors"
					colororwisp = "wisp"
				else
					historycolor = "historySettings"
					colororwisp = "color"
				end
				if(WIM_History[theUser][i].type == 1) then
					getglobal("WIM_msgFrame"..theUser.."ScrollingMessageFrame"):AddMessage(msg, WIM_Data[historycolor][colororwisp.."In"].r, WIM_Data[historycolor][colororwisp.."In"].g, WIM_Data[historycolor][colororwisp.."In"].b);
				elseif(WIM_History[theUser][i].type == 2) then
					getglobal("WIM_msgFrame"..theUser.."ScrollingMessageFrame"):AddMessage(msg, WIM_Data[historycolor][colororwisp.."Out"].r, WIM_Data[historycolor][colororwisp.."Out"].g, WIM_Data[historycolor][colororwisp.."Out"].b);
				end
			end
		end
	end
end

function WIM_LoadDefaultFilters()
	WIM_Filters = {};
	WIM_Filters["^LVBM"] 					= "忽略";
	WIM_Filters["^YOU ARE BEING WATCHED!"] 	= "忽略";
	WIM_Filters["^YOU ARE MARKED!"] 		= "忽略";
	WIM_Filters["^YOU ARE CURSED!"] 		= "忽略";
	WIM_Filters["^YOU HAVE THE PLAGUE!"] 	= "忽略";
	WIM_Filters["^YOU ARE BURNING!"] 		= "忽略";
	WIM_Filters["^YOU ARE THE BOMB!"] 		= "忽略";
	WIM_Filters["VOLATILE INFECTION"] 		= "忽略";
	WIM_Filters["^<GA"]						= "阻止";
	WIM_Filters["USD"]						= "阻止";
	WIM_Filters["W@W"]						= "阻止";
	WIM_Filters["C@M"]						= "阻止";
	WIM_Filters["G4"]						= "阻止";
	WIM_Filters["G="]						= "阻止";
	WIM_Filters[">>"]						= "忽略";
	WIM_Filters[">>>"]						= "忽略";
	WIM_Filters["OKO"]						= "阻止";
	WIM_Filters["GAMES"]					= "阻止";
	WIM_Filters["NOST"]						= "忽略";
	WIM_Filters["DOLLARS"]					= "阻止";
	WIM_Filters["CQM"]						= "阻止";
	WIM_Filters["SERVICE"]					= "忽略";
	WIM_Filters["CHEAP"]					= "阻止";
	WIM_Filters["WWW"]						= "阻止";
	WIM_Filters["1-60"]						= "阻止";
--	WIM_Filters[""]						= "忽略";
	
	WIM_FilteringScrollBar_Update();
end

function WIM_LoadGuildList()
	WIM_GuildList = {};
	WIM_GuildOnline = {};
	if(IsInGuild()) then
		for i=1, GetNumGuildMembers(true) do
			local name, junk, junk2, junk3, junk4, junk5, junk6, junk7, online = GetGuildRosterInfo(i);
			if(name) then
				WIM_GuildList[name] = "1"; --[set place holder for quick lookup
				WIM_GuildOnline[name] = online and true or false; --同步记录在线状态（联系人列表查表用）
			end
		end
	end
end

function WIM_LoadFriendList()
	WIM_FriendList = {};
	WIM_FriendOnline = {};
	for i=1, GetNumFriends() do
		local name, junk, junk2, junk3, connected = GetFriendInfo(i);
		if(name) then
			WIM_FriendList[name] = "1"; --[set place holder for quick lookup
			WIM_FriendOnline[name] = connected and true or false; --同步记录在线状态（联系人列表查表用）
		end
	end
end

function WIM_HistoryPurge()
	if(WIM_Data.historySettings.autoDelete.enabled) then
		local delCount = 0;
		local eldestTime = time() - (60 * 60 * 24 * WIM_Data.historySettings.autoDelete.days);
		for key in WIM_History do
			if(WIM_History[key][1]) then
				while(WIM_History[key][1].stamp < eldestTime) do
					table.remove(WIM_History[key], 1);
					delCount = delCount + 1;
					if(table.getn(WIM_History[key]) == 0) then
						WIM_History[key] = nil;
						break
					end
				end
			end
		end
		if(delCount > 0) then
			DEFAULT_CHAT_FRAME:AddMessage("[WIM]: Purged "..delCount.." out-dated messages from history.");
		end
	end
end

function WIM_ToggleWindow_OnUpdate(elapsedTime)

	WIM_ToggleWindow_Timer = WIM_ToggleWindow_Timer + elapsedTime; 	

	while (WIM_ToggleWindow_Timer > 1) do
		WIM_ToggleWindow:Hide();
		WIM_ToggleWindow_Timer = 0;
	end
end

function WIM_RecentListAdd(theUser)
	for i=1, table.getn(WIM_RecentList) do 
		if(string.upper(WIM_RecentList[i]) == string.upper(theUser)) then
			table.remove(WIM_RecentList, i);
			break
		end
	end
	table.insert(WIM_RecentList, 1, theUser);
end

function WIM_ToggleWindow_Toggle()
	if(table.getn(WIM_RecentList) == 0) then
		return;
	end
	
	if(WIM_RecentList[WIM_ToggleWindow_Index] == nil) then
		WIM_ToggleWindow_Index = 1;
	end
	
	WIM_ToggleWindowUser:SetText(WIM_GetAlias(WIM_RecentList[WIM_ToggleWindow_Index], true));
	WIM_ToggleWindow.theUser = WIM_RecentList[WIM_ToggleWindow_Index];
	WIM_ToggleWindowCount:SetText("Recent Conversation "..WIM_ToggleWindow_Index.." of "..table.getn(WIM_RecentList));
	if(WIM_Windows[WIM_RecentList[WIM_ToggleWindow_Index]]) then
		if(WIM_Windows[WIM_RecentList[WIM_ToggleWindow_Index]].newMSG) then
			WIM_ToggleWindowStatus:SetText("New message!");
			WIM_ToggleWindowIconNew:Show();
			WIM_ToggleWindowIconRead:Hide();
		else
			WIM_ToggleWindowStatus:SetText("No new messages.");
			WIM_ToggleWindowIconRead:Show();
			WIM_ToggleWindowIconNew:Hide();
		end
	else
		WIM_ToggleWindowStatus:SetText("Conversation closed.");
		WIM_ToggleWindowIconRead:Show();
		WIM_ToggleWindowIconNew:Hide();
	end
	WIM_ToggleWindow_Timer = 0;
	WIM_ToggleWindow:Show();
	WIM_ToggleWindow_Index = WIM_ToggleWindow_Index + 1;
end

function WIM_Split(theString, thePattern)
	local t = {n = 0}
	local fpat = "(.-)"..thePattern
	local last_end = 1
	local s,e,cap = string.find(theString, fpat, 1)
	while s ~= nil do
		if s~=1 or cap~="" then
		table.insert(t,cap)
		end
		last_end = e+1
		s,e,cap = string.find(theString, fpat, last_end)
	end
	if last_end<=string.len(theString) then
		cap = string.sub(theString,last_end)
		table.insert(t,cap)
	end
	return t
end

function WIM_SetTabFrameProps()
	WIM_TabFrame:SetScale(WIM_Data.windowSize * 1);
	WIM_TabFrame:SetAlpha(WIM_Data.windowAlpha);
end

function WIM_UpdateTabs()
	local tabs = {};
	local offset = 0;
	
	for key in WIM_IconItems do
		table.insert(tabs, key);
	end
	
	for i=1,10 do 
		local tab = getglobal("WIM_TabFrameTab"..i);
		tab:Hide();
		if(tabs[i+offset]) then
			tab:SetText(WIM_GetAlias(tabs[i+offset], true));
			tab:Show();
			tab.theUser=tabs[i+offset];
		else
			tab:Hide();
			tab.theUser="";
		end
	end
	
end

--按窗口模式应用聊天窗口关闭按钮(ExitButton)显示/隐藏：多窗口显示、单窗口隐藏（单窗口下联系人列表本身有关闭按钮）；历史按钮统一放在忽略按钮下方（参考 D:\WIM）
function WIM_ApplyExitButtonPref(theWin)
	local exitBtn = getglobal(theWin:GetName().."ExitButton");
	local ignoreBtn = getglobal(theWin:GetName().."ShortcutFrameButton5"); --忽略按钮（快捷列最下方）
	if IsAddOnLoaded("pfUI") then --pfUI适配
		getglobal(theWin:GetName().."HistoryButton"):Hide()
		if not theWin.NewHistoryButton then
			theWin.NewHistoryButton = CreateFrame("Button", nil, theWin)
			theWin.NewHistoryButton:SetHeight(19)
			theWin.NewHistoryButton:SetWidth(19)
			theWin.NewHistoryButton:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
			theWin.NewHistoryButton:SetScript("OnClick", function()
				WIM_HistoryView_Name_Selected = this:GetParent().theUser;
				WIM_HistoryView_Filter_Selected = "";
				if(WIM_HistoryFrame:IsVisible()) then
					WIM_HistoryViewNameScrollBar_Update();
					WIM_HistoryViewFiltersScrollBar_Update();
				else
					WIM_HistoryFrame:Show();
				end
			end)
			theWin.NewHistoryButton:SetScript("OnEnter", function()
				if(WIM_Data.showToolTips == true) then
					GameTooltip:SetOwner(this, "ANCHOR_LEFT");
					GameTooltip:SetText(WIM_L_HISTORYTOOLTIP);
					GameTooltip:SetPoint("BOTTOMRIGHT", this, "TOPRIGHT", 0, 0);
				end
			end)
			theWin.NewHistoryButton:SetScript("OnLeave", function()
				if(WIM_Data.showToolTips == true) then
					GameTooltip:Hide();
				end
			end)
		end
		theWin.NewHistoryButton:ClearAllPoints()
		theWin.NewHistoryButton:SetPoint("TOP", ignoreBtn, "BOTTOM", 0, -2) --放在忽略按钮下方（D:\WIM）
	else
		local histBtn = getglobal(theWin:GetName().."HistoryButton");
		histBtn:Show()
		histBtn:ClearAllPoints()
		histBtn:SetPoint("TOP", ignoreBtn, "BOTTOM", 0, -2) --放在忽略按钮下方（D:\WIM）
	end
	--关闭按钮可见性：多窗口模式显示（每个窗口独立，需各自可关）；单窗口模式隐藏（联系人列表已有自己的关闭按钮）
	if(WIM_Data.multiWindow ~= false) then
		exitBtn:Show();
	else
		exitBtn:Hide();
	end
	--联系人按钮（关闭按钮左侧）：仅多窗口模式显示；单窗口模式隐藏（联系人列表即盒子本身）
	local contactBtn = getglobal(theWin:GetName().."ContactButton");
	if(contactBtn) then
		if(WIM_Data.multiWindow ~= false) then
			contactBtn:Show();
		else
			contactBtn:Hide();
		end
	end
end

function WIM_WindowOnShow()
	WIM_ApplyExitButtonPref(this);
end

function WIM_GetTabByUser(theUser)
	for i=1,10 do 
		local tab = getglobal("WIM_TabFrameTab"..i);
		if(string.upper(theUser) == string.upper(tab.theUser)) then
			return tab;
		end
	end
	return nil;
end

function WIM_TabSetSelected(theUser)
	for i=1,10 do 
		local tab = getglobal("WIM_TabFrameTab"..i);
		if(string.upper(theUser) == string.upper(tab.theUser)) then
			PanelTemplates_SelectTab(tab);
		else
			PanelTemplates_DeselectTab(tab);
		end
	end
end
