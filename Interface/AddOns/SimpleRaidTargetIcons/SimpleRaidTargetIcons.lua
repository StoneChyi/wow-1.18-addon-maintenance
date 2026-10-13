-- Simple Raid Target Icons
--
--------------------------------
--                            --
-- Concept originally by Qzot --
--                            --
--------------------------------

local menu, doubleClick, doubleClickX, doubleClickY;

-- SuperWoW 才有的 API，用来判断能不能走"仅自己可见"的本地标记
local SUPERWOW = SetAutoloot and true or false;

local function inGroup()
	return ( GetNumPartyMembers() + GetNumRaidMembers() ) > 0;
end

-- 1.12 原生 SetRaidTarget 只在队伍/团队里有权限时才落地标记；不在队伍时靠 SuperWoW 的第三参数做本地标记
local function setRaidTarget(unit, index)
	local localOnly = SRTI_UseLocalRaidTarget(unit);
	if ( not SRTI_ValidateRaidTarget(unit, localOnly) ) then return false; end
	if ( index > 0 ) then SRTI_CancelPendingClear(); end
	if ( localOnly ) then
		SetRaidTarget(unit, index, 1);
	else
		SetRaidTarget(unit, index);
	end
	return true;
end


-- 环外辉光强度（0~1）：SRTIGlow.tga 是素材包 glow 的窄收贴版（白图，靠 SetVertexColor 染翠绿）
local GLOW_ALPHA = 0.55;


local function buildMenu()
	if ( menu ) then return; end
	
	local menu = CreateFrame("button", "SRTIRadialMenu", UIParent);
	-- 提到最高层级：pfUI 单元框 strata/level 很高，不提菜单会被头像框挡在后面
	pcall(function() menu:SetFrameStrata("TOOLTIP"); end);
	menu:SetFrameLevel(100);
	menu:SetWidth(94);
	menu:SetHeight(94);
	menu:SetPoint( "CENTER", UIParent, "BOTTOMLEFT", 0, 0 );
	menu:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	menu:RegisterEvent("PLAYER_TARGET_CHANGED");
	menu.p = menu:CreateTexture("SRTIRadialMenuPortrait","BORDER");
	menu.p:SetWidth(40);
	menu.p:SetHeight(40);
	menu.p:SetPoint("CENTER", menu, "CENTER", 0, 0 );
	menu.b = menu:CreateTexture("SRTIRadialMenuBorder", "BACKGROUND");
	menu.b:SetTexture("Interface\\AddOns\\SimpleRaidTargetIcons\\img\\SRTIRing");
	menu.b:SetWidth(48);
	menu.b:SetHeight(48);
	menu.b:SetTexCoord(0,1,0,1);
	menu.b:SetPoint("CENTER", menu, "CENTER", 0, 0 );
	-- 环外辉光：96 是算出来的 —— 贴图的上升沿（纹素 44→56）显示时落在 16.5~21.0，整段藏在环带（19.5~23.25）里，
	-- 所以环外缘一出来就是满亮，环与光之间不留暗环；外光到 33 归零（宽约 10px，< menu 半宽 47，不裁）。
	-- 尺寸再放大上升沿就会露到环外、空挡重现 —— 要改大必须同步把贴图的 R_UP0/R_UP1 往内移。
	menu.g = menu:CreateTexture("SRTIRadialMenuGlow", "BACKGROUND");
	menu.g:SetTexture("Interface\\AddOns\\SimpleRaidTargetIcons\\img\\SRTIGlow");
	menu.g:SetWidth(96);
	menu.g:SetHeight(96);
	menu.g:SetTexCoord(0,1,0,1);
	menu.g:SetPoint("CENTER", menu, "CENTER", 0, 0 );
	menu.g:SetVertexColor(0.29, 0.87, 0.50);
	menu.g:SetAlpha(0);
	menu.g:SetDrawLayer("BACKGROUND", -2);
	for i=1, 8 do
		menu[i] = menu:CreateTexture("SRTIRadialMenu"..i,"OVERLAY");
	end
		
	menu:SetScript("OnUpdate", function()
			local unit = this.unit or "target";
			local saved, index = this.i, GetRaidTargetIndex(unit);
			local curtime = GetTime();
			if ( not this.h ) then
				-- target 走"存在且(在团队或没死)"判定；框架单位（party/raid/player）只要求存在，
				-- 否则点击团队框弹菜单时 mouseover/死亡判定会误杀
				local valid;
				if ( unit == "target" ) then
					valid = UnitExists("target") and ( UnitPlayerOrPetInRaid("target") or not UnitIsDeadOrGhost("target") );
				else
					valid = UnitExists(unit);
				end
				if ( not valid ) then
					if ( menu.portrait ) then
						this:Hide();
						return;
					else
						this.h = curtime;
					end
				elseif ( menu.portrait ) then
					menu.portrait = nil;
					if ( unit == "target" and not UnitIsUnit("target","mouseover") ) then
						this:Hide();
						return;
					end
					PlaySound("igMainMenuOptionCheckBoxOn");
					SetPortraitTexture( menu.p, unit );
				end

			local cx, cy = GetCursorPosition();
			local s = menu:GetEffectiveScale();
			local mx, my = menu:GetCenter();
			cx = cx / s;
			cy = cy / s;

			local a, b = cy - my, cx - mx;
				
				local dist = floor(math.sqrt( a*a + b*b ));
				
				this.i = nil;
				
				if ( dist > 56 ) then
					if ( dist > 200 ) then
						this.l = nil;
						this.h = curtime;
						this.s = nil;
						PlaySound("igMainMenuOptionCheckBoxOff");
					elseif ( not this.l ) then
						this.l = curtime;
					end
				else
					this.l = nil;
					
					if ( dist > 26 and dist < 50 ) then
						local pos = math.deg(math.atan2( a, b )) + 27.5;
						this.i = mod(11-ceil(pos/45),8)+1;
					end
				end
				
				for i=1, 8 do
					local t = this[i];
					if ( index == i ) then
						t:SetTexCoord(0,1,0,1);
						t:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up");
					else
						SRTI_SetIconTexture(t, i);
					end
				end
				
				if ( not IsControlKeyDown() and not this.c ) then
					if ( this.i ) then
						this:Click();
					else
						this.c = 1;
					end
				else
					this.c = nil;
				end
			end
			
			if ( this.s ) then
				local status = curtime - this.s;
				if ( status > 0.1 ) then
					menu.p:SetAlpha(1);
					menu.b:SetAlpha(1);
					menu.g:SetAlpha(GLOW_ALPHA);
					for i=1, 8 do
						local t, radians = this[i], (0.375 - i/8) * 360;
						t:SetPoint("CENTER", this, "CENTER", 38*cos(radians), 38*sin(radians) );
						t:SetAlpha(0.5);
						t:SetWidth(18);
						t:SetHeight(18);
					end
					this.s = nil;
				else
					status = status / 0.1;
					menu.p:SetAlpha(status);
					menu.b:SetAlpha(status);
					menu.g:SetAlpha(GLOW_ALPHA*status);
					for i=1, 8 do
						local t, radians = this[i], (0.375 - i/8) * 360;
						t:SetPoint("CENTER", this, "CENTER", (22*status + 16)*cos(radians), (22*status + 16)*sin(radians) );
						if ( i == index ) then
							t:SetAlpha(status);
						else
							t:SetAlpha(0.5*status);
						end
						t:SetWidth(9*status + 9);
						t:SetHeight(9*status + 9);
					end
				end
			elseif ( this.h ) then
				local status = curtime - this.h;
				if ( status > 0.1 ) then
					this.h = nil;
					this.c = nil;
					this:Hide();
				else
					status = 1 - status / 0.1;
					menu.p:SetAlpha(status);
					menu.b:SetAlpha(status);
					menu.g:SetAlpha(GLOW_ALPHA*status);
					for i=1, 8 do
						local t, radians = this[i], (0.375 - i/8) * 360;
						if ( this.i == i ) then
							t:SetWidth(36-18*status);
							t:SetHeight(36-18*status);
							t:SetAlpha(min(4*status,1));
						else
							t:SetPoint("CENTER", this, "CENTER", (22*status + 16)*cos(radians), (22*status + 16)*sin(radians) );
							t:SetAlpha(0.75*status);
							t:SetWidth(18*status);
							t:SetHeight(18*status);
						end
					end
				end
			else
				for i=1, 8 do
					local t = this[i];
					if ( i == index ) then
						t:SetAlpha(1);
					else
						t:SetAlpha(0.75);
					end
					t:SetWidth(18);
					t:SetHeight(18);
				end
			end
			
			if ( this.i ) then
				local t = this[this.i];
				local a, w = t:GetAlpha(), t:GetWidth();

				if ( not this.t or saved ~= this.i ) then
					this.t = curtime;
				end
				local s = 1 + min( (curtime - this.t)/0.05, 1 );

				t:SetAlpha(min(a+0.125*s,1));
				t:SetWidth(w*s);
				t:SetHeight(w*s);
			end
			
			if ( this.l ) then
				local status = curtime - this.l;
				if ( status > 0.75 ) then
					this.h = curtime;
					this.l = nil
					this.s = nil
					this.i = nil;
					PlaySound("igMainMenuOptionCheckBoxOff");
				end
			end	
		end
		);
		
	menu:SetScript("OnClick", function()
			-- 右键 = 取消当前标记，鼠标落在圆环内也走这条。特意放在 this.h 门禁之外：
			-- 悬停自动选中会立刻设上 this.h，旧写法此时会把圆环内的右键整个吞掉。
			-- 右键永不设置标记，无标记时只当"关掉菜单"。
			if ( arg1 == "RightButton" or not this.h ) then
				local unit = this.unit or "target";
				local index = GetRaidTargetIndex(unit);
				if ( arg1 == "RightButton" ) then
					if ( index and index > 0 ) then
						this.i = index;
						if ( setRaidTarget(unit, 0) ) then PlaySound("igMiniMapZoomOut"); end
					else
						PlaySound("igMainMenuOptionCheckBoxOff");
					end
				elseif ( this.i and this.i == index ) then
					this.i = index;
					if ( setRaidTarget(unit, 0) ) then PlaySound("igMiniMapZoomOut"); end
				elseif ( this.i ) then
					if ( setRaidTarget(unit, this.i) ) then PlaySound("igMiniMapZoomIn"); end
				else
					PlaySound("igMainMenuOptionCheckBoxOff");
				end
				this.s = nil;
				this.h = GetTime();
			end
		end
		);
		
	menu:SetScript("OnEvent", function()
			if ( this:IsVisible() and not this.e and not this.h ) then
				this.i = nil;
				this.s = nil;
				this.h = GetTime();
				PlaySound("igMainMenuOptionCheckBoxOff");
			end
			this.e = nil;
		end
		);
	
	return menu;
end

-- 从鼠标焦点帧向上回溯找带 unit 字段的 UnitFrame（头像/队伍/团队框），一路到顶都没有就降级 target。
-- 子控件（血条/名字）大多不带 unit，必须回溯到父帧；_pfUI 这类第三方框架不设 unit 字段也靠这里兜底。
local function resolveUnit()
	local f = GetMouseFocus and GetMouseFocus() or nil;
	while ( f and f ~= WorldFrame and f ~= UIParent ) do
		-- 暴雪帧带 .unit；pfUI 帧带 label/id（如 label="raid" id="14" → "raid14"），label 为空串的是按名字寻target的帧，跳过
		if ( f.unit and UnitExists(f.unit) ) then return f.unit; end
		if ( f.label and f.id and f.label ~= "" and UnitExists(f.label .. f.id) ) then return f.label .. f.id; end
		f = f.GetParent and f:GetParent() or nil;
	end
	return "target";
end

-- resolveUnit 真机报错时打一次聊天提示（静默回退 target，菜单照常弹）
local SRTI_radialWarned;
function SRTI_RadialWarn(msg)
	if ( SRTI_radialWarned ) then return; end
	SRTI_radialWarned = 1;
	if ( DEFAULT_CHAT_FRAME ) then
		DEFAULT_CHAT_FRAME:AddMessage("|cffabd473SRTI|r：框架标记取单位失败，已回退普通模式（" .. msg .. "）", 1, 0.6, 0.2);
	end
end

function SRTIRadialMenu_Show()
	
			
	if ( not menu ) then
		menu = buildMenu();
	end
	-- 框架标记：resolveUnit 在真机一旦有引擎差异就静默回退 target，绝不阻塞菜单弹出
	menu.unit = "target";
	if ( resolveUnit ) then
		local ok, u = pcall(resolveUnit);
		if ( ok and u ) then
			menu.unit = u;
		else
			SRTI_RadialWarn(ok and ("unit 无效：" .. tostring(u)) or tostring(u));
		end
	end
	if ( inGroup() and not SRTI_UseLocalRaidTarget(menu.unit) and not IsPartyLeader() and not IsRaidLeader() and not IsRaidOfficer() ) then menu:Hide(); return; end
	menu.s = GetTime();
	menu.h = nil;
	menu.i = nil;
	menu.c = nil;
	menu.l = nil;
	menu.e = 1;
	menu.portrait = 1;

	-- 距离自适应：0.85 + 3/d，20 码≈1.0，区间收到 0.85~1.15（只做轻微呼吸，避免近处糊脸/远处太小）
	if ( SUPERWOW and UnitXP ) then
		local _, guid = UnitExists("target");
		local d = guid and UnitXP("distanceBetween", "player", guid) or nil;
		if ( d and d > 0 ) then
			local sc = 0.85 + 3 / d;
			if ( sc > 1.15 ) then sc = 1.15; end
			if ( sc < 0.85 ) then sc = 0.85; end
			menu:SetScale(sc);
		else
			menu:SetScale(1);
		end
	else
		menu:SetScale(1);
	end

	local x,y = GetCursorPosition();
	local s = menu:GetEffectiveScale();
	menu:SetPoint( "CENTER", UIParent, "BOTTOMLEFT", x/s, y/s );
	menu:Show();
end

local OnMouseUp = WorldFrame:GetScript("OnMouseUp");
local SRTI_lastHandled;

-- 双击/Ctrl+左键的判定逻辑抽成公共函数：WorldFrame 只能收到"世界区域"的鼠标事件，
-- 点击落在 TargetFrame/PartyMemberFrame/RaidGroupButton 等自带鼠标处理的框架上时，
-- 事件被该框架吞掉不会到 WorldFrame——所以这些框架也要各自挂钩子才能在头像框上弹菜单。
local function SRTI_HandleMouseUp()
		-- 同帧去重：单元框同时钩了 OnMouseUp 与 OnClick，一次点击两路都会进（GetTime 同值），只处理第一路
		local now = GetTime();
		if ( SRTI_lastHandled == now ) then return; end
		SRTI_lastHandled = now;
		-- 菜单打开时，右键在屏幕任意位置都直接取消当前标记（不必把鼠标挪到禁止图标上）——
		-- 这是 menu 自身 OnClick 之外的第二套取消路径，两套并存：鼠标在圆环上时走 OnClick，
		-- 在圆环外时走这里。仅当目标确实有标记才吞掉这次右键；无标记只关菜单，右键继续往下传。
		if ( arg1 == "RightButton" and menu and menu:IsVisible() ) then
			local index = GetRaidTargetIndex("target");
			menu.s = nil;
			menu.l = nil;
			menu.h = GetTime();
			if ( index and index > 0 ) then
				menu.i = index;
				if ( setRaidTarget("target", 0) ) then PlaySound("igMiniMapZoomOut"); end
				return;
			end
		end
		if ( arg1 == "LeftButton" ) then
			local curtime = GetTime();
			local x, y = GetCursorPosition();
			if ( doubleClick and curtime - doubleClick < 0.25 and abs(x-doubleClickX) < 20 and abs(y-doubleClickY) < 20 ) then
				SRTIRadialMenu_Show();
				doubleClick = nil;
			elseif ( IsControlKeyDown() ) then
				SRTIRadialMenu_Show();
				doubleClick = nil;
			else
				doubleClick = curtime;
			end
			doubleClickX, doubleClickY = x, y;
		end
end

WorldFrame:SetScript("OnMouseUp", function()
		SRTI_HandleMouseUp();
	if ( OnMouseUp ) then
		OnMouseUp();
	end
	end
);

-- 头像/宠物/队伍/团队框架钩子：包裹各框架原始 OnMouseUp/OnClick（先跑 SRTI 判定再放行原生行为）。
-- 实证（SuperCleveRoidMacros Mouseover/Blizzard.lua 同款手法）：点击经常落在 HealthBar/ManaBar
-- 等子控件上，父框钩子收不到——所以每个单元框的血条/蓝条/小队宠物框/目标的目标框都要单独钩。
local SRTI_HOOK_NAMES = { "RaidGroupButton1", "RaidGroupButton2", "RaidGroupButton3", "RaidGroupButton4", "RaidGroupButton5",
	"RaidGroupButton6", "RaidGroupButton7", "RaidGroupButton8", "RaidGroupButton9", "RaidGroupButton10",
	"RaidGroupButton11", "RaidGroupButton12", "RaidGroupButton13", "RaidGroupButton14", "RaidGroupButton15",
	"RaidGroupButton16", "RaidGroupButton17", "RaidGroupButton18", "RaidGroupButton19", "RaidGroupButton20",
	"RaidGroupButton21", "RaidGroupButton22", "RaidGroupButton23", "RaidGroupButton24", "RaidGroupButton25",
	"RaidGroupButton26", "RaidGroupButton27", "RaidGroupButton28", "RaidGroupButton29", "RaidGroupButton30",
	"RaidGroupButton31", "RaidGroupButton32", "RaidGroupButton33", "RaidGroupButton34", "RaidGroupButton35",
	"RaidGroupButton36", "RaidGroupButton37", "RaidGroupButton38", "RaidGroupButton39", "RaidGroupButton40" };
local SRTI_UNIT_FRAMES = { "PlayerFrame", "PetFrame", "TargetFrame", "TargetofTargetFrame",
	"PartyMemberFrame1", "PartyMemberFrame2", "PartyMemberFrame3", "PartyMemberFrame4",
	"PartyMemberFrame1PetFrame", "PartyMemberFrame2PetFrame", "PartyMemberFrame3PetFrame", "PartyMemberFrame4PetFrame" };
for _, u in ipairs(SRTI_UNIT_FRAMES) do
	table.insert(SRTI_HOOK_NAMES, u);
	table.insert(SRTI_HOOK_NAMES, u .. "HealthBar");
	table.insert(SRTI_HOOK_NAMES, u .. "ManaBar");
end
-- pfUI 自建头像/团队框架（pfUI 加载后才存在）：点击走 OnClick，unit=label..id。PEW 时补装（见下）
local SRTI_PF_NAMES = { "pfPlayer", "pfTarget", "pfTargetTarget", "pfPet",
	"pfGroup1", "pfGroup2", "pfGroup3", "pfGroup4",
	"pfPartyPet1", "pfPartyPet2", "pfPartyPet3", "pfPartyPet4" };
for i = 1, 40 do
	table.insert(SRTI_PF_NAMES, "pfRaid" .. i);
	table.insert(SRTI_PF_NAMES, "pfRaidPet" .. i);
end
for _, n in ipairs(SRTI_PF_NAMES) do
	table.insert(SRTI_HOOK_NAMES, n);
end
-- 1.12 对控件类型不支持的脚本类型，连 GetScript 查询都会抛错（StatusBar 查 OnClick 即报错）——一律 pcall 包裹
local function SRTI_GetScript(f, s)
	local ok, r = pcall(f.GetScript, f, s);
	if ( ok ) then return r; end
	return nil;
end
local function SRTI_SetScript(f, s, fn)
	pcall(f.SetScript, f, s, fn);
end
local function SRTI_HookFrame(name)
	local f = getglobal(name);
	if ( f and not f.SRTI_hooked ) then
		f.SRTI_hooked = 1;
		local orig = SRTI_GetScript(f, "OnMouseUp");
		SRTI_SetScript(f, "OnMouseUp", function()
			SRTI_HandleMouseUp();
			if ( orig ) then orig(); end
		end);
		-- OnClick 是 Button 专属脚本，StatusBar（血条/蓝条）不支持——只对已带 OnClick 的框补第二路
		local oc = SRTI_GetScript(f, "OnClick");
		if ( oc ) then
			SRTI_SetScript(f, "OnClick", function()
				SRTI_HandleMouseUp();
				if ( oc ) then oc(); end
			end);
		end
	end
end
local function SRTI_InstallFrameHooks()
	for _, name in ipairs(SRTI_HOOK_NAMES) do
		SRTI_HookFrame(name);
	end
end
SRTI_InstallFrameHooks();

-- 单人模式提醒：未装 SuperWoW 时脱队无法本地标记（仅队伍/团队有权限时才能标记）；一次性，避免读条/进本重复刷
local SRTI_warnDone;
local function SRTI_SuperWoW_Warn()
	if ( not SRTI_warnDone and not SUPERWOW and not inGroup() ) then
		SRTI_warnDone = 1;
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cffabd473SimpleRaidTargetIcons|r：未检测到 SuperWoW，单人模式下无法使用本地标记（仅队伍/团队有权限时才能标记）。如需单人标记功能请安装 SuperWoW模组。",
			1, 0.6, 0.2
		);
	end
end
local SRTI_warnFrame = CreateFrame("Frame");
SRTI_warnFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
SRTI_warnFrame:SetScript("OnEvent", function()
	-- pfUI 等框架的帧可能在本插件加载之后才创建——进世界时按 SRTI_hooked 标记补装一遍
	SRTI_InstallFrameHooks();
	SRTI_SuperWoW_Warn();
end);
	
