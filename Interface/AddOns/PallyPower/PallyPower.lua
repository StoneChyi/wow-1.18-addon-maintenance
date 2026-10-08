local initalized = false
local clearTime = 0
TenMinuteBlessingOn = false;
ppRefreshAfterClear = false

BINDING_HEADER_PALLYPOWER_HEADER = "Pally Power";
BINDING_NAME_TOGGLE = "Toggle Buff Bar";
BINDING_NAME_REPORT = "Report Assignments";

AllPallys = { };

PallyPower_Assignments = { };

PallyPower = {};

BlessingIcon = {};
BuffIcon = {};
PP_PerUser = {
    scalemain = 1, -- corner of main window docked to
    scalebar = 1, -- corner menu window is docked from
    scalesolo = 1, -- 单人祝福条缩放
    scanfreq = 3,
    scanperframe = 1,
    smartbuffs = 1,
    solomode = 1, -- 单人模式：无队伍时显示单人祝福条（参考 HolyHope）
    soloGreater = 0, -- 单人祝福组：0=小祝福(10分钟) 1=大祝福(30分钟)，点宝珠切换
    soloForce = 0, -- 强制单人祝福：1=组队/进团也显示单人宝珠（默认关）
}
PP_NextScan = PP_PerUser.scanfreq

function PallyPower_TenMinuteBlessings()
    isChecked = TenMinBlessingChk:GetChecked()

    if (isChecked == 1) then
      PP_Symbols = 0
      TenMinuteBlessingOn = true;
      ReloadUI()
    else
      PP_Symbols = 0
      TenMinuteBlessingOn = false;
      ReloadUI()
    end
end

-- 主界面（祝福助手）左下角勾选框：实时切换 强效祝福/小祝福 模式（免重载）
-- 勾选后重扫技能书，AllPallys 0..5 改指向小祝福，左键点格子即施放 10 分钟小祝福（低等级小号组队练级用）
function PallyPower_ToggleTenMinBlessing()
    if TenMinuteBlessingOn then
        TenMinuteBlessingOn = false;
        TenMinBlessing = false;
        PallyPower_SwapIconsForThirtyMin();
        PallyPower_ShowFeedback("祝福模式：强效祝福（30分钟）", 0.5, 1.0, 0.5);
    else
        TenMinuteBlessingOn = true;
        TenMinBlessing = true;
        PallyPower_SwapIconsForTenMin();
        PallyPower_ShowFeedback("祝福模式：小祝福（10分钟），左键点格子施放", 0.5, 1.0, 0.5);
    end
    -- 两个勾选框（选项面板 + 主界面）状态保持同步
    if TenMinBlessingChk then
        TenMinBlessingChk:SetChecked(TenMinuteBlessingOn);
    end
    local mainChk = getglobal("TenMinBlessingMainChk");
    if mainChk then
        mainChk:SetChecked(TenMinuteBlessingOn);
    end
    -- 重扫技能书 + 符印数，刷新格子图标与分配
    PallyPower_ScanSpells();
    PallyPower_UpdateUI();
end

LastCast = { };
LastCastOn = { };
PP_Symbols = 0
IsPally = 0;

-- 复用表：清空而非新建，减少每次 UI 更新产生的垃圾
-- 注意：Lua 5.0 下直接把键置 nil 不会重置表的内部长度（table.getn/table.concat 用的
-- 是 setn 维护的存储值），残留幻影长度会让 table.concat 扫到 nil 空洞报
-- "table contains non-strings"，所以清空后必须 table.setn(t, 0) 显式归零。
local function PP_WipeTable(t)
    if t then
        for k in pairs(t) do
            t[k] = nil
        end
        if table.setn then
            table.setn(t, 0)
        end
        return t
    end
    return {}
end

-- 安全拼接：过滤非字符串/数字元素（表内有 nil 空洞或异常值时降级为空串，不报错）
local function PP_SafeConcat(tbl, sep)
    if type(tbl) ~= "table" then
        return ""
    end
    local parts = {}
    for i = 1, table.getn(tbl) do
        local v = tbl[i]
        if type(v) == "string" or type(v) == "number" then
            tinsert(parts, v)
        end
    end
    return table.concat(parts, sep)
end

-- getglobal 结果缓存：XML 元素加载后固定不变，热路径免去反复字符串拼接查找
local PP_FrameCache = {}
local function pp_getglobal(name)
    local f = PP_FrameCache[name]
    if f == nil then
        f = getglobal(name)
        PP_FrameCache[name] = f or false
    end
    return f or nil
end

-- 职业图标：与 ShaguDPS 同款 classicons 图集（512x512，8x8 网格，每格 64px）
-- 坐标取自 ShaguDPS window.lua 的 classIcons 表，保证两插件图标外观一致
PallyPower_ClassTexture = { };
PallyPower_ClassTexCoord = { };
local PP_CLASSICON_ATLAS = "Interface\\AddOns\\PallyPower\\Icons\\classicons";
for id = 0, 9 do
    PallyPower_ClassTexture[id] = PP_CLASSICON_ATLAS;
end

-- PallyPower 职业顺序: 0战士 1盗贼 2牧师 3德鲁伊 4骑士 5猎人 6法师 7术士 8萨满 9宠物
-- 各职业在图集中的纹理坐标 {left, right, top, bottom}（与 ShaguDPS 完全一致）
PallyPower_ClassTexCoord[0] = { 0.000, 0.122, 0.000, 0.123 }; -- Warrior
PallyPower_ClassTexCoord[1] = { 0.250, 0.372, 0.000, 0.123 }; -- Rogue
PallyPower_ClassTexCoord[2] = { 0.250, 0.372, 0.125, 0.248 }; -- Priest
PallyPower_ClassTexCoord[3] = { 0.375, 0.497, 0.000, 0.123 }; -- Druid
PallyPower_ClassTexCoord[4] = { 0.000, 0.122, 0.250, 0.373 }; -- Paladin
PallyPower_ClassTexCoord[5] = { 0.000, 0.122, 0.125, 0.248 }; -- Hunter
PallyPower_ClassTexCoord[6] = { 0.125, 0.247, 0.000, 0.123 }; -- Mage
PallyPower_ClassTexCoord[7] = { 0.373, 0.504, 0.121, 0.238 }; -- Warlock
PallyPower_ClassTexCoord[8] = { 0.125, 0.247, 0.125, 0.248 }; -- Shaman
-- 宠物（绿色爪印）：解码图集定位，位于第 4 行第 2 列（r3c1，64px 格）
PallyPower_ClassTexCoord[9] = { 0.125, 0.247, 0.375, 0.498 }; -- Pet

-- 设置职业图标贴图：同时设置图集纹理与该职业的裁剪坐标
function PallyPower_SetClassIcon(tex, class)
    if not tex then return end
    tex:SetTexture(PallyPower_ClassTexture[class]);
    local tc = PallyPower_ClassTexCoord[class];
    if tc then
        tex:SetTexCoord(tc[1], tc[2], tc[3], tc[4]);
    else
        tex:SetTexCoord(0, 1, 0, 1);
    end
end

Assignment = { };

CurrentBuffs = { };

PP_PREFIX = "PLPWR";

local RestorSelfAutoCastTimeOut = 1;
local RestorSelfAutoCast = false;

-- 小祝福到大祝福的映射表 (大祝福ID -> 小祝福ID)
PallyPower_LesserBlessingMap = {};
PallyPower_LesserBlessingMap[0] = 6;  -- 智慧祝福 -> 小智慧祝福
PallyPower_LesserBlessingMap[1] = 7;  -- 力量祝福 -> 小力量祝福
PallyPower_LesserBlessingMap[2] = 8;  -- 拯救祝福 -> 小拯救祝福
PallyPower_LesserBlessingMap[3] = 9;  -- 光明祝福 -> 小光明祝福  
PallyPower_LesserBlessingMap[4] = 10; -- 王者祝福 -> 小王者祝福
PallyPower_LesserBlessingMap[5] = 11; -- 庇护祝福 -> 小庇护祝福

local function PP_Debug(string)
    if not string then
        string = "(nil)"
    end
    if (PP_DebugEnabled) then
        -- 聊天通知已关闭；操作结果由界面状态显示。
    end
end

function PallyPower_OnLoad()
    this:RegisterEvent("SPELLS_CHANGED");
    this:RegisterEvent("PLAYER_ENTERING_WORLD");
    this:RegisterEvent("CHAT_MSG_ADDON");
    this:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLY_DEATH");
    this:RegisterEvent("PLAYER_LOGIN");
    this:RegisterEvent("PARTY_MEMBERS_CHANGED");
    -- 单人宝珠：进出战斗换红色贴图（照抄 HolyHope）
    this:RegisterEvent("PLAYER_REGEN_DISABLED");
    this:RegisterEvent("PLAYER_REGEN_ENABLED");
    this:SetBackdropColor(0.0, 0.0, 0.0, 0.5);
    this:SetScale(1);

    -- 主面板职业表头行（PallyPowerFrameClass0..9）：套用 ShaguDPS 同款图集与裁剪坐标
    for id = 0, 9 do
        PallyPower_SetClassIcon(getglobal("PallyPowerFrameClass" .. id), id);
    end

	SlashCmdList["PALLYPOWER"] = function(msg)
        PallyPower_SlashCommandHandler(msg)
    end
	
	--DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080Relar|r 祝福助手 - TurtleWoW version "..PallyPower_Version.." |cff00FF00加载成功!|r")
end

function PallyPower_OnUpdate(tdiff)
    if (RestorSelfAutoCast) then
		RestorSelfAutoCastTimeOut = RestorSelfAutoCastTimeOut - tdiff;
		if (RestorSelfAutoCastTimeOut < 0) then
			RestorSelfAutoCast = false;
			SetCVar("autoSelfCast", "1");
		end
	end
    
    --  PP_Debug("OnUpdate "..tdiff);
    if (not PP_PerUser.scanfreq) then
        PP_PerUser.scanfreq = 10;
        PP_PerUser.scanperframe = 1;
    end
    PP_NextScan = PP_NextScan - tdiff
    if PP_NextScan < 0 and PP_IsPally then
        PP_Debug("Scanning");
        PallyPower_ScanRaid()
        PallyPower_UpdateUI()
    end
    -- 节流期间被合并的 UI 更新，到时间后在这里补刷
    if PP_UIDirty and (GetTime() - (PP_UILastUpdate or 0)) >= 0.25 then
        PallyPower_UpdateUI()
    end
end

function PallyPower_OnEvent(event)
    local type, id;
    if (event == "SPELLS_CHANGED" or event == "PLAYER_ENTERING_WORLD") then
		if (TenMinuteBlessingOn == true) then
			TenMinBlessing = true
			PallyPower_SwapIconsForTenMin()
			
		else
			TenMinBlessing = false
			PallyPower_SwapIconsForThirtyMin()
		end
        PallyPower_UpdateUI()
        PallyPower_ScanSpells()
    end

    if (event == "PLAYER_ENTERING_WORLD" and (not PallyPower_Assignments[UnitName("player")])) then
        PallyPower_Assignments[UnitName("player")] = {};
        if UnitName("player") == "Aznamir" then
            PP_DebugEnabled = true
        end
    end

    if event == "CHAT_MSG_ADDON" and arg1 == PP_PREFIX and (arg3 == "PARTY" or arg3 == "RAID") then
        PallyPower_ParseMessage(arg4, arg2)
    end

    if event == "CHAT_MSG_COMBAT_FRIENDLY_DEATH" and PP_NextScan > 1 then
        PP_NextScan = 1
    end

    -- 单人宝珠战斗变色（照抄 HolyHope：战斗中红色 HolyHopeC，脱战恢复符印环）
    if event == "PLAYER_REGEN_DISABLED" then
        PP_SoloInCombat = true
        PallyPower_Solo_UpdateOrbTexture()
    end
    if event == "PLAYER_REGEN_ENABLED" then
        PP_SoloInCombat = false
        PallyPower_Solo_UpdateOrbTexture()
    end

    if event == "PLAYER_LOGIN" then
        -- 老角色存档缺新键时补默认值（solomode/scalesolo 为 1.075 新增）
        if PP_PerUser.solomode == nil then
            PP_PerUser.solomode = 1
        end
        if PP_PerUser.scalesolo == nil then
            PP_PerUser.scalesolo = 1
        end
        if PP_PerUser.soloGreater == nil then
            PP_PerUser.soloGreater = 0
        end
        if PP_PerUser.soloForce == nil then
            PP_PerUser.soloForce = 0
        end
        PallyPower_UpdateUI()
    end

    if event == "PARTY_MEMBERS_CHANGED" then
        PallyPower_ScanRaid()
        PallyPower_UpdateUI()
    end
end

function PallyPower_SwapIconsForTenMin()
	BlessingIcon[0] = "Interface\\Icons\\Spell_Holy_SealOfWisdom";
    BlessingIcon[1] = "Interface\\Icons\\Spell_Holy_FistOfJustice";
    BlessingIcon[2] = "Interface\\Icons\\Spell_Holy_SealOfSalvation";
    BlessingIcon[3] = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02";
    BlessingIcon[4] = "Interface\\Icons\\Spell_Magic_MageArmor";
    BlessingIcon[5] = "Interface\\Icons\\Spell_Nature_LightningShield";
    BuffIcon[0] = "Interface\\Icons\\Spell_Holy_SealOfWisdom";
    BuffIcon[1] = "Interface\\Icons\\Spell_Holy_FistOfJustice";
    BuffIcon[2] = "Interface\\Icons\\Spell_Holy_SealOfSalvation";
    BuffIcon[3] = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02";
    BuffIcon[4] = "Interface\\Icons\\Spell_Magic_MageArmor";
    BuffIcon[5] = "Interface\\Icons\\Spell_Nature_LightningShield";
    -- 小祝福图标
    BuffIcon[6] = "Interface\\Icons\\Spell_Holy_SealOfWisdom";
    BuffIcon[7] = "Interface\\Icons\\Spell_Holy_FistOfJustice";
    BuffIcon[8] = "Interface\\Icons\\Spell_Holy_SealOfSalvation";
    BuffIcon[9] = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02";
    BuffIcon[10] = "Interface\\Icons\\Spell_Magic_MageArmor";
    BuffIcon[11] = "Interface\\Icons\\Spell_Nature_LightningShield";
end

function PallyPower_SwapIconsForThirtyMin()
	BlessingIcon[0] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom";
	BlessingIcon[1] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings";
	BlessingIcon[2] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSalvation";
	BlessingIcon[3] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofLight";
	BlessingIcon[4] = "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings";
	BlessingIcon[5] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSanctuary";
	BuffIcon[0] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom"
	BuffIcon[1] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings"
	BuffIcon[2] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSalvation"
	BuffIcon[3] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofLight"
	BuffIcon[4] = "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings"
	BuffIcon[5] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSanctuary"
    -- 小祝福图标
    BuffIcon[6] = "Interface\\Icons\\Spell_Holy_SealOfWisdom";
    BuffIcon[7] = "Interface\\Icons\\Spell_Holy_FistOfJustice";
    BuffIcon[8] = "Interface\\Icons\\Spell_Holy_SealOfSalvation";
    BuffIcon[9] = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02";
    BuffIcon[10] = "Interface\\Icons\\Spell_Magic_MageArmor";
    BuffIcon[11] = "Interface\\Icons\\Spell_Nature_LightningShield";
end

function PallyPower_SlashCommandHandler(msg)
    if (msg == "debug") then
        if PP_DebugEnabled then
            PP_DebugEnabled = nil
        else
            PP_DebugEnabled = true
        end
    end
    if (msg == "solo") then
        if PP_PerUser.solomode == 1 then
            PP_PerUser.solomode = 0
            PallyPower_ShowFeedback("单人模式已关闭", 1.0, 0.5, 0.5)
        else
            PP_PerUser.solomode = 1
            PallyPower_ShowFeedback("单人模式已开启：无队伍时显示单人祝福条", 0.5, 1.0, 0.5)
        end
        PallyPower_UpdateUI()
        return true
    end
    if (msg == "report") then
        PallyPower_Report()
        return true
    end
    if PallyPowerFrame:IsVisible() then
        PallyPowerFrame:Hide()
    else
        PallyPowerFrame:Show()
    end
    PallyPower_UpdateUI()
end

function PallyPower_Report()
    if PallyPower_CanControl(UnitName("player")) then
        local type
        if GetNumRaidMembers() > 0 then
            type = "RAID"
        else
            type = "PARTY"
        end
        PP_Debug(type);
        SendChatMessage(PallyPower_Assignments1, type)
        for name in AllPallys do
            local blessings
            local list = { }
            list[0] = 0;
            list[1] = 0;
            list[2] = 0;
            list[3] = 0;
            list[4] = 0;
            list[5] = 0;
            PP_Debug(list[0]);
            for id = 0, 9 do
                local bid = PallyPower_Assignments[name][id]
                if bid >= 0 then
                    list[bid] = list[bid] + 1
                end
            end
            for id = 0, 5 do
                if (list[id] > 0) then
                    if (blessings) then
                        blessings = blessings .. ", "
                    else
                        blessings = ""
                    end
                    blessings = blessings .. PallyPower_BlessingID[id]
                end
            end
            if not (blessings) then
                blessings = "Nothing"
            end
            SendChatMessage(name .. ": " .. blessings, type)
            PP_Debug(name .. ": " .. blessings)
        end
        SendChatMessage(PallyPower_Assignments2, type)
    end
end

function PallyPower_FormatTime(time)
    if not time or time < 0 then
        return "";
    end
    mins = floor(time / 60)
    secs = time - (mins * 60)
    return string.format("%d:%02d", mins, secs);
end

-- LastCast 改存「到期时间戳」（GetTime()+时长），读取时惰性计算剩余秒数，
-- 取代原来 OnUpdate 每帧遍历递减；无记录返回 -1（旧代码 nil 时同样视为无效）
function PallyPower_LastCastRemaining(key)
    local t = LastCast[key]
    if not t then
        return -1
    end
    return t - GetTime()
end

function PallyPowerGrid_Update()
    if not initalized then
        -- 聊天通知已关闭；操作结果由界面状态显示。
        PallyPower_ScanSpells()
    end
    -- Pally 1 is always myself
    local i = 1;
    local numPallys = 0
    local name, skills
    if PallyPowerFrame:IsVisible() then
        PallyPowerFrame:SetScale(PP_PerUser.scalemain);
        for name, skills in AllPallys do
            if i > 12 then break end
            local base = "PallyPowerFramePlayer" .. i
            pp_getglobal(base .. "Name"):SetText(name)
            pp_getglobal(base .. "Symbols"):SetText(skills["symbols"])
            pp_getglobal(base .. "Symbols"):SetTextColor(1, 1, 0.5)
            if (PallyPower_CanControl(name)) then
                pp_getglobal(base .. "Name"):SetTextColor(1, 1, 1)
            else
                if (PallyPower_CheckRaidLeader(name)) then
                    pp_getglobal(base .. "Name"):SetTextColor(0, 1, 0)
                else
                    pp_getglobal(base .. "Name"):SetTextColor(1, 0, 0)
                end
            end
            for id = 0, 5 do
                if (skills[id]) then
                    pp_getglobal(base .. "Icon" .. id):Show()
                    pp_getglobal(base .. "Skill" .. id):Show()
                    local txt = skills[id]["rank"];
                    if (skills[id]["talent"] + 0 > 0) then
                        txt = txt .. "+" .. skills[id]["talent"]
                    end
                    pp_getglobal(base .. "Skill" .. id):SetText(txt)
                else
                    pp_getglobal(base .. "Icon" .. id):Hide()
                    pp_getglobal(base .. "Skill" .. id):Hide()
                end
            end
            for id = 0, 9 do
                if (PallyPower_Assignments[name]) then
                  pp_getglobal(base .. "Class" .. id .. "Icon"):SetTexture(BlessingIcon[PallyPower_Assignments[name][id]])
                else
                    pp_getglobal(base .. "Class" .. id .. "Icon"):SetTexture(nil)
                end
            end
            i = i + 1
            numPallys = numPallys + 1
        end
        PallyPowerFrame:SetHeight(14 + 24 + 56 + (numPallys * 56) + 22) -- 14 from border, 24 from Title, 56 from space for class icons, 56 per paladin, 22 for Buttons at bottom
        for i = 1, 12 do
            if i <= numPallys then
                pp_getglobal("PallyPowerFramePlayer" .. i):Show()
            else
                pp_getglobal("PallyPowerFramePlayer" .. i):Hide()
            end
        end
    end
end

function PallyPower_UpdateUI()
    -- 节流：0.25s 内的重复调用合并为一次（多个骑手同时刷新发消息时避免连击重绘）
    local now = GetTime()
    if (now - (PP_UILastUpdate or 0)) < 0.25 then
        PP_UIDirty = true
        return
    end
    PP_UILastUpdate = now
    PP_UIDirty = false
    if not initalized then
        PallyPower_ScanSpells()
    end
    -- Buff Bar
    PallyPowerBuffBar:SetScale(PP_PerUser.scalebar);
    local pclass, eclass = UnitClass("player")

    if eclass == "PALADIN" then
		IsPally = 1
	else
		PallyPowerBuffBar:Hide()
    end

    -- 单人模式：无队伍/团队且是圣骑士时，BuffBar 让位给单人祝福条（强制模式下组队时 BuffBar 照常显示，仅宝珠额外出现）
    local soloActive = PP_Solo_IsActive(false)

    --if ((GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0) or (IsPally == 0)) then
    --    PallyPowerBuffBar:Hide()
    --else
    if soloActive and PP_PerUser.alwaysBuffBar ~= 1 then
        PallyPowerBuffBar:Hide()
    elseif ((IsPally == 1) or (GetNumRaidMembers() > 0 and GetNumPartyMembers() > 0)) then
        PallyPowerBuffBar:Show()
        PallyPowerBuffBarTitleText:SetText(format(PallyPower_BuffBarTitle, PP_Symbols));
        BuffNum = 1
        if PallyPower_Assignments[UnitName("player")] then
            local assign = PallyPower_Assignments[UnitName("player")]
            for class = 0, 9 do
                if (assign[class] and assign[class] ~= -1) then
                    PallyPower_SetClassIcon(pp_getglobal("PallyPowerBuffBarBuff" .. BuffNum .. "ClassIcon"), class);
                    pp_getglobal("PallyPowerBuffBarBuff" .. BuffNum .. "BuffIcon"):SetTexture(BlessingIcon[assign[class]]);

                    local btn = pp_getglobal("PallyPowerBuffBarBuff" .. BuffNum);
                    btn.classID = class;
                    btn.buffID = assign[class];
                    -- 复用已有表并清空，避免每次更新都新建表产生垃圾
                    btn.need = PP_WipeTable(btn.need);
                    btn.have = PP_WipeTable(btn.have);
                    btn.range = PP_WipeTable(btn.range);
                    btn.dead = PP_WipeTable(btn.dead);
                    -- Calculate number of people who need buff.
                    local nneed = 0;
                    local nhave = 0;
                    local ndead = 0;
                    if CurrentBuffs[class] then
                        for member, stats in CurrentBuffs[class] do
                            if stats["visible"] then
                                -- stats["name"] 对未取到名字的单位（如宠物）可能为 nil，
                                -- tinsert(t, nil) 会在表里造出空洞让 concat 报错，回退用 unit token
                                local uname = stats["name"] or member;
                                local desiredBuff = assign[class]
                                if PallyPower_PersonalBlessing then
                                    local personal = PallyPower_PersonalBlessing(class,uname)
                                    if personal ~= nil then desiredBuff = personal end
                                end
                                if not stats[desiredBuff] then
                                    if UnitIsDeadOrGhost(member) then
                                        ndead = ndead + 1;
                                        tinsert(btn.dead, uname);
                                    else
                                        nneed = nneed + 1
                                        tinsert(btn.need, uname);
                                    end
                                else
                                    tinsert(btn.have, uname);
                                    nhave = nhave + 1
                                end
                            else
                                tinsert(btn.range, stats["name"] or member);
                                nhave = nhave + 1
                            end
                        end
                    end
                    if ndead > 0 then
                        pp_getglobal("PallyPowerBuffBarBuff" .. BuffNum .. "Text"):SetText(nneed .. " (" .. ndead .. ")");
                    else
                        pp_getglobal("PallyPowerBuffBarBuff" .. BuffNum .. "Text"):SetText(nneed);
                    end
                    pp_getglobal("PallyPowerBuffBarBuff" .. BuffNum .. "Time"):SetText(PallyPower_FormatTime(PallyPower_LastCastRemaining(assign[class] .. class)));
                    if not (nneed > 0 or nhave > 0) then
                    else
                        BuffNum = BuffNum + 1
                        if (nhave == 0) then
                            PallyPower_SetBuffBarColor(btn,1,0,0);
                        elseif (nneed > 0) then
                            PallyPower_SetBuffBarColor(btn,1,1,0.5);
                        else
                            PallyPower_SetBuffBarColor(btn,0,0,0);
                        end
                        btn:Show();
                    end
                end
            end
        end
        for rest = BuffNum, 10 do
            local btn = pp_getglobal("PallyPowerBuffBarBuff" .. rest);
            btn:Hide();
        end
        PallyPowerBuffBar:SetHeight(30 + (34 * (BuffNum - 1)));
    end

    -- 主窗口网格随事件刷新（内部有 IsVisible 守卫，主窗口关闭时几乎零开销）
    PallyPowerGrid_Update()

    -- 单人祝福条刷新（ HolyHope 模式：点击直接施放，不依赖分配）
    PallyPower_SoloBar_Update()
end

function PallyPower_ScanSpells()
    local RankInfo = {}
    local i = 1
    
    while true do
        local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL)
        local spellTexture = GetSpellTexture(i, BOOKTYPE_SPELL)
        if not spellName then do break end end
        if not spellRank or spellRank == "" then
			spellRank = PallyPower_Rank1
        end
        
    if TenMinBlessing == true then
        local _, _, bless = string.find(spellName, PallyPower_BlessingSpellSearch)
		if bless then
            local tmp_str, _ = string.find(spellName, PPGreater)
            for id, name in PallyPower_BlessingID do
				if ((name == bless) and (tmp_str == nil)) then
					local _, _, rank = string.find(spellRank, PallyPower_RankSearch);
					if not (RankInfo[id] and spellRank < RankInfo[id]["rank"]) then
						RankInfo[id] = {};
						RankInfo[id]["rank"] = rank;
						RankInfo[id]["id"] = i;
						RankInfo[id]["name"] = name;
						RankInfo[id]["talent"] = 0;
					end
				end
			end
		end
    else
        local _, _, bless = string.find(spellName, PallyPower_BlessingSpellSearch)
        if bless then
            local tmp_str, _ = string.find(spellName, PPGreater)
            for id, name in PallyPower_BlessingID do
				if ((PPGreater..name == bless) and (tmp_str == 1)) then
					local _, _, rank = string.find(spellRank, PallyPower_RankSearch);
					if not (RankInfo[id] and spellRank < RankInfo[id]["rank"]) then
						RankInfo[id] = {};
						RankInfo[id]["rank"] = rank;
						RankInfo[id]["id"] = i;
						RankInfo[id]["name"] = name;
						RankInfo[id]["talent"] = 0;
					end
				end
			end
        end
    end
    
    -- 扫描小祝福技能
    for id, name in PallyPower_BlessingID do
        if spellName == name then
            local _, _, rank = string.find(spellRank, PallyPower_RankSearch);
            local lesserId = PallyPower_LesserBlessingMap[id]
            if lesserId then
                if not (RankInfo[lesserId] and spellRank < RankInfo[lesserId]["rank"]) then
                    RankInfo[lesserId] = {};
                    RankInfo[lesserId]["rank"] = rank;
                    RankInfo[lesserId]["id"] = i;
                    RankInfo[lesserId]["name"] = name;
                    RankInfo[lesserId]["talent"] = 0;
                end
            end
        end
    end
    
    i = i + 1
    end
    local numTabs = GetNumTalentTabs();
    for t = 1, numTabs do
        local numTalents = GetNumTalents(t);
        for i = 1, numTalents do
            nameTalent, icon, iconx, icony, currRank, maxRank = GetTalentInfo(t, i);
            local _, _, bless = string.find(nameTalent, PallyPower_BlessingTalentSearch)
            if bless then
                initalized = true;
                for id, name in PallyPower_BlessingID do
                    if name == bless then
                        if (RankInfo[id]) then
                            RankInfo[id]["talent"] = currRank;
                        end
                    end
                end
            end
        end
    end
    _, class = UnitClass("player");
    if class == "PALADIN" then
        AllPallys[UnitName("player")] = RankInfo;
        if initalized then
            PallyPower_SendSelf();
        end
        PP_IsPally = true
    else
        PP_Debug("我不是圣骑士？ " .. class);
        PP_IsPally = nil
        initalized = true;
    end
    PallyPower_ScanInventory()
end

function PallyPower_Refresh()
	if ppRefreshAfterClear ~= true then
		-- 聊天通知已关闭；操作结果由界面状态显示。
	end

	--ADDED THESE TO FIX THE REFRESH NOT WORKING
	PP_Symbols = 0
	AllPallys = { };
	PP_IsPally = nil
	PallyPower_ScanSpells()
	PallyPowerGrid_Update()
	
	--This was present before
    PallyPower_SendSelf()
    PallyPower_RequestSend()
	PallyPower_ScanSpells()
    PallyPower_UpdateUI()
	
	if ppRefreshAfterClear ~= true then
		-- 聊天通知已关闭；操作结果由界面状态显示。
	elseif ppRefreshAfterClear == true then
		-- 聊天通知已关闭；操作结果由界面状态显示。
		ppRefreshAfterClear = false
	end
end

function PallyPower_Clear(fromupdate, who)
	--ButtonClick = PallyPower_Clear() -> then there is no "fromupdate" and no "who"
		--then sends the message at the end to everyone else
	
	if not who then
        who = UnitName("player")
    end
	
    for name, skills in PallyPower_Assignments do
        if (PallyPower_CheckRaidLeader(who) or name == who) then
            if name == who then
				-- 聊天通知已关闭；操作结果由界面状态显示。
			else
				if (clearTime + 5) < GetTime() then
					clearTime = GetTime()
					-- 聊天通知已关闭；操作结果由界面状态显示。
				end
			end
			for class, id in PallyPower_Assignments[name] do
                PallyPower_Assignments[name][class] = -1
            end
			ppRefreshAfterClear = true
		end
    end
	
    --PallyPower_UpdateUI()
	PallyPower_Refresh()
	
    if not fromupdate then
        PallyPower_SendMessage("CLEAR")
    end
end

function PallyPower_RequestSend()
    PallyPower_SendMessage("REQ")
end

function PallyPower_SendSelf()
    if not initalized then
        PallyPower_ScanSpells()
    end
    if not AllPallys[UnitName("player")] then
        return
    end
    msg = "SELF "
    local RankInfo = AllPallys[UnitName("player")]
    local i
    for id = 0, 5 do
        if (not RankInfo[id]) then
            msg = msg .. "nn";
        else
            msg = msg .. RankInfo[id]["rank"]
            msg = msg .. RankInfo[id]["talent"]
        end
    end
    msg = msg .. "@"
    for id = 0, 9 do
        if (not PallyPower_Assignments[UnitName("player")]) or (not PallyPower_Assignments[UnitName("player")][id]) or PallyPower_Assignments[UnitName("player")][id] == -1 then
            msg = msg .. "n"
        else
            msg = msg .. PallyPower_Assignments[UnitName("player")][id]
        end
    end
    PallyPower_SendMessage(msg)
    PallyPower_SendMessage("SYMCOUNT " .. PP_Symbols);
end

function PallyPower_SendMessage(msg)
    if GetNumRaidMembers() == 0 then
        SendAddonMessage(PP_PREFIX, msg, "PARTY", UnitName("player"));
    else
        SendAddonMessage(PP_PREFIX, msg, "RAID", UnitName("player"));
    end
end

function PallyPower_ParseMessage(sender, msg)
    if not (sender == UnitName("player")) then
        if msg == "REQ" then
            PallyPower_SendSelf()
        end
        if string.find(msg, "^SELF") then
            PallyPower_Assignments[sender] = {}
            AllPallys[sender] = {}
            _, _, numbers, assign = string.find(msg, "SELF ([0-9n]*)@?([0-9n]*)")
            for id = 0, 5 do
                rank = string.sub(numbers, id * 2 + 1, id * 2 + 1)
                talent = string.sub(numbers, id * 2 + 2, id * 2 + 2)
                if not (rank == "n") then
                    AllPallys[sender][id] = { }
                    AllPallys[sender][id]["rank"] = rank
                    AllPallys[sender][id]["talent"] = talent
                end
            end
            if assign then
                for id = 0, 9 do
                    tmp = string.sub(assign, id + 1, id + 1)
                    if (tmp == "n" or tmp == "") then
                        tmp = -1
                    end
                    PallyPower_Assignments[sender][id] = tmp + 0
                end
            end
            PallyPower_UpdateUI()
        end
        if string.find(msg, "^ASSIGN") then
            _, _, name, class, skill = string.find(msg, "^ASSIGN (.*) (.*) (.*)")
            if (not (name == sender)) and (not PallyPower_CheckRaidLeader(sender)) then
                return false
            end
            if (not PallyPower_Assignments[name]) then
                PallyPower_Assignments[name] = {}
            end
            class = class + 0
            skill = skill + 0
            PallyPower_Assignments[name][class] = skill;
            PallyPower_UpdateUI()
        end
        if string.find(msg, "^MASSIGN") then
            _, _, name, skill = string.find(msg, "^MASSIGN (.*) (.*)")
            if (not (name == sender)) and (not PallyPower_CheckRaidLeader(sender)) then
                return false
            end
            if (not PallyPower_Assignments[name]) then
                PallyPower_Assignments[name] = {}
            end
            skill = skill + 0
            for class = 0, 9 do
                PallyPower_Assignments[name][class] = skill;
            end
            PallyPower_UpdateUI()
        end
        if string.find(msg, "^SYMCOUNT ([0-9]*)") then
            _, _, count = string.find(msg, "^SYMCOUNT ([0-9]*)")
            if AllPallys[sender] then
                AllPallys[sender]["symbols"] = count;
            else
                PallyPower_SendMessage("REQ");
            end
        end
        if string.find(msg, "^CLEAR") then
            PallyPower_Clear(true, sender)
        end
    end
end

function PallyPower_ShowCredits()
    GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
    GameTooltip:SetText(PallyPower_Credits1, 1, 1, 1)
    GameTooltip:AddLine(PallyPower_Credits2, 1, 1, 1);
    GameTooltip:AddLine(PallyPower_Credits3);
    GameTooltip:AddLine(PallyPower_Credits4, 0, 1, 0);
    GameTooltip:AddLine(PallyPower_Credits5);
    GameTooltip:Show()
end

function PallyPowerFrame_MouseDown(arg1)
    if (((not PallyPowerFrame.isLocked) or (PallyPowerFrame.isLocked == 0)) and (arg1 == "LeftButton")) then
        PallyPowerFrame:StartMoving();
        PallyPowerFrame.isMoving = true;
    end
end

function PallyPowerFrame_MouseUp()
    if (PallyPowerFrame.isMoving) then
        PallyPowerFrame:StopMovingOrSizing();
        PallyPowerFrame.isMoving = false;
    end
end

function PallyPowerBuffBar_MouseDown(arg1)
    if (((not PallyPowerBuffBar.isLocked) or (PallyPowerBuffBar.isLocked == 0)) and (arg1 == "LeftButton")) then
        PallyPowerBuffBar:StartMoving();
        PallyPowerBuffBar.isMoving = true;
        PallyPowerBuffBar.startPosX = PallyPowerBuffBar:GetLeft();
        PallyPowerBuffBar.startPosY = PallyPowerBuffBar:GetTop();
    end
end

function PallyPowerBuffBar_MouseUp()
    if not PallyPowerBuffBar.startPosX or not PallyPowerBuffBar.startPosY then return end
    if (PallyPowerBuffBar.isMoving) then
        PallyPowerBuffBar:StopMovingOrSizing();
        PallyPowerBuffBar.isMoving = false;
    end
    if abs(PallyPowerBuffBar.startPosX - PallyPowerBuffBar:GetLeft()) < 2 and abs(PallyPowerBuffBar.startPosY - PallyPowerBuffBar:GetTop()) < 2 then
        PallyPowerFrame:Show();
        PallyPower_UpdateUI()
    end
end

function PallyPowerGridButton_OnLoad(btn)
end

function PallyPowerGridButton_OnClick(btn, mouseBtn)
    _, _, pnum, class = string.find(btn:GetName(), "PallyPowerFramePlayer(.+)Class(.+)");
    pnum = pnum + 0;
    class = class + 0;
    pname = getglobal("PallyPowerFramePlayer" .. pnum .. "Name"):GetText()
    if not PallyPower_CanControl(pname) then
        return false
    end

    if (mouseBtn == "RightButton") then
        PallyPower_Assignments[pname][class] = -1
        PallyPower_UpdateUI()
        PallyPower_SendMessage("ASSIGN " .. pname .. " " .. class .. " -1")
    else
        PallyPower_PerformCycle(pname, class)
    end
end

function PallyPowerGridButton_OnLeave(btn)
end

function PallyPowerGridButton_OnEnter(btn)
end

function PallyPower_PerformCycleBackwards(name, class)

    shift = IsShiftKeyDown()

    --force pala (all buff possible) when shift wheeling
    if shift then
        class = 4
    end

    if not PallyPower_Assignments[name][class] then
        cur = 6
    else
        cur = PallyPower_Assignments[name][class]
        if cur == -1 then
            cur = 6
        end
    end

    PallyPower_Assignments[name][class] = -1

    for test = cur - 1, -1, -1 do
        cur = test
        if PallyPower_CanBuff(name, test) and (PallyPower_NeedsBuff(class, test) or shift) then
            do
                break
            end
        end
    end

    if shift then
        for test = 0, 9 do
            PallyPower_Assignments[name][test] = cur
        end
        PallyPower_SendMessage("MASSIGN " .. name .. " " .. cur)
    else
        PallyPower_Assignments[name][class] = cur
        PallyPower_SendMessage("ASSIGN " .. name .. " " .. class .. " " .. cur)
    end

    PallyPower_UpdateUI()

end

function PallyPower_PerformCycle(name, class)

    shift = IsShiftKeyDown()

    --force pala (all buff possible) when shift wheeling
    if shift then
        class = 4
    end

    if not PallyPower_Assignments[name][class] then
        cur = -1
    else
        cur = PallyPower_Assignments[name][class]
    end
    PallyPower_Assignments[name][class] = -1
    for test = cur + 1, 6 do
        if PallyPower_CanBuff(name, test) and (PallyPower_NeedsBuff(class, test) or shift) then
            cur = test
            do
                break
            end
        end
    end

    if (cur == 6) then
        cur = -1
    end

    if shift then
        for test = 0, 9 do
            PallyPower_Assignments[name][test] = cur
        end
        PallyPower_SendMessage("MASSIGN " .. name .. " " .. cur)
    else
        PallyPower_Assignments[name][class] = cur
        PallyPower_SendMessage("ASSIGN " .. name .. " " .. class .. " " .. cur)
    end

    PallyPower_UpdateUI()

end

function PallyPower_CanBuff(name, test)
    if test == 6 then
        return true
    end
    if (not AllPallys[name][test]) or (AllPallys[name][test]["rank"] == 0) then
        return false
    end
    return true
end

function PallyPower_NeedsBuff(class, test)
    if test == 6 then
        return true
    end
    if test == -1 then
        return true
    end
    if PP_PerUser.smartbuffs then
        -- no wisdom for warriors and rogues
        if (class == 0 or class == 1) and test == 0 then
            return false
        end
        -- no salv for warriors
        --if class == 0 and test == 2 then
        --    return false
        --end
        -- no might for casters
        if (class == 2 or class == 5 or class == 6 or class == 7) and test == 1 then
            return false
        end
    end

    for name, skills in PallyPower_Assignments do
        if (AllPallys[name]) and ((skills[class]) and (skills[class] == test)) then
            return false
        end
    end
    return true
end

function PallyPower_CheckRaidLeader(nick)
    if GetNumRaidMembers() == 0 then
        for i = 1, GetNumPartyMembers(), 1 do
            if nick == UnitName("party" .. i) and UnitIsPartyLeader("party" .. i) then
                return true
            end
        end
        return false
    end
    for i = 1, GetNumRaidMembers(), 1 do
        local name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(i)
        if (rank >= 1 and name == nick) then
            return true
        end
    end
    return false
end

function PallyPower_CanControl(name)
    return (IsPartyLeader() or IsRaidLeader() or IsRaidOfficer() or (name == UnitName("player")))
end

function PallyPower_ScanInventory()
    if not PP_IsPally then
        return
    end
    PP_Debug("Scanning for symbols");
    oldcount = PP_Symbols
    PP_Symbols = 0
    for bag = 0, 4 do
        local bagslots = GetContainerNumSlots(bag);
        if (bagslots) then
            for slot = 1, bagslots do
                local link = GetContainerItemLink(bag, slot)
                if (link and string.find(link, PallyPower_Symbol)) then
                    local _, count, locked = GetContainerItemInfo(bag, slot);
                    PP_Symbols = PP_Symbols + count
                end
            end
        end
    end
    if PP_Symbols ~= oldcount then
        PallyPower_SendMessage("SYMCOUNT " .. PP_Symbols);
    end
    --DEFAULT_CHAT_FRAME:AddMessage("[PallyPower old count] " .. oldcount, r, g, b, a)
    --DEFAULT_CHAT_FRAME:AddMessage("[PallyPower] " .. PP_Symbols, r, g, b, a)
--    if (AllPallys[UnitName("player")] ~= nil) then
--	  DEFAULT_CHAT_FRAME:AddMessage(AllPallys[UnitName("player")], r, g, b, a)
      AllPallys[UnitName("player")]["symbols"] = PP_Symbols;
--	end;
end

PP_ScanInfo = nil

function PallyPower_ScanRaid()
    if not PP_IsPally then
        return
    end
    if not (PP_ScanInfo) then
        PP_Scanners = {}
        PP_ScanInfo = {}
        PP_ScanCursor = 1
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                tinsert(PP_Scanners, "raid" .. i)
            end
            INRAID = 1
        else
            tinsert(PP_Scanners, "player");
            for i = 1, GetNumPartyMembers() do
                tinsert(PP_Scanners, "party" .. i)
            end
            INRAID = 0
        end
    end
    local tests = PP_PerUser.scanperframe
    if (not tests) then
        tests = 1
    end

    while PP_Scanners[PP_ScanCursor] do
        local unit = PP_Scanners[PP_ScanCursor]
        local name = UnitName(unit)
        local class = UnitClass(unit)
        if (name and class) then
            local cid = PallyPower_GetClassID(class)
            PP_Debug("unit " .. unit .. " cid " .. cid .. " class " .. class);

            if cid == 5 then -- hunters
                local petId = "raidpet" .. string.sub(unit, 5);
                PP_Debug(petId);

                local pet_name = UnitName(petId)
                PP_Debug(petId);

                if pet_name then
                    local classID = 9
                    if not PP_ScanInfo[classID] then
                        PP_ScanInfo[classID] = {}
                    end

                    PP_ScanInfo[classID][petId] = {};
                    PP_ScanInfo[classID][petId]["name"] = pet_name;
                    PP_ScanInfo[classID][petId]["visible"] = UnitIsVisible(petId);

                    local j = 1
                    while true do
                        local buffIcon = UnitBuff(petId, j, true)
                        if not buffIcon then break end
                        local txtID = PallyPower_GetBuffTextureID(buffIcon)
                        if txtID > 5 then
                            txtID = txtID - 6
                        end
                        PP_ScanInfo[classID][petId][txtID] = true
                        j = j + 1
                    end
                end
            end

            if not PP_ScanInfo[cid] then
                PP_ScanInfo[cid] = {}
            end
            PP_ScanInfo[cid][unit] = {};
            PP_ScanInfo[cid][unit]["name"] = name;
            PP_ScanInfo[cid][unit]["visible"] = UnitIsVisible(unit);

            local j = 1
            while true do
                local buffIcon = UnitBuff(unit, j, true)
                if not buffIcon then break end
                local txtID = PallyPower_GetBuffTextureID(buffIcon)
                if txtID > 5 then
                    txtID = txtID - 6
                end
                PP_ScanInfo[cid][unit][txtID] = true
                j = j + 1
            end
        end
        PP_ScanCursor = PP_ScanCursor + 1
        tests = tests - 1
        PP_Debug("Scanning " .. unit .. " and " .. tests .. " remain");
        if (tests <= 0) then
            return
        end
    end
    CurrentBuffs = PP_ScanInfo
    PP_ScanInfo = nil
    PP_NextScan = PP_PerUser.scanfreq
    PallyPower_ScanInventory()
end

function PallyPower_GetClassID(class)
    for id, name in PallyPower_ClassID do
        if (name == class) then
            return id
        end
    end
    return -1
end

function PallyPower_GetBuffTextureID(text)
    for id, name in BuffIcon do
        if (name == text) then
            return id
        end
    end
    return -2
end

-- 点击时读取当前队伍名单，不能把周期扫描缓存当作可施法名单。
-- 新入团、换组或 raid 编号重排后，CurrentBuffs 可能仍是上一次扫描结果。
local function PP_CurrentClassUnits(classID)
    local units = {}
    local function AddMember(unit, pet)
        if not UnitName(unit) then return end
        local cid = PallyPower_GetClassID(UnitClass(unit))
        if cid == classID and not UnitIsDeadOrGhost(unit) then
            tinsert(units, unit)
        end
        if classID == 9 and cid == 5 and UnitName(pet) and not UnitIsDeadOrGhost(pet) then
            tinsert(units, pet)
        end
    end
    local raidCount = GetNumRaidMembers()
    if raidCount > 0 then
        for i = 1, raidCount do AddMember("raid"..i, "raidpet"..i) end
    else
        AddMember("player", "pet")
        for i = 1, GetNumPartyMembers() do AddMember("party"..i, "partypet"..i) end
    end
    return units
end

local function PP_RecentlyCastOn(classID, unit)
    -- 精确比较 unit token；raid10 不能误匹配 raid1，缺失记录也不能报错。
    for _, previous in ipairs(LastCastOn[classID] or {}) do
        if previous == unit then return true end
    end
    return false
end

-- 背景透明度独立于文字、图标；保存状态色供设置滑条即时刷新。
function PallyPower_SetBuffBarColor(button,r,g,b)
    button.ppStatusR,button.ppStatusG,button.ppStatusB=r,g,b
    local alpha=PP_PerUser.barBackgroundAlpha
    if type(alpha) ~= "number" then alpha=0.5 end
    button:SetBackdropColor(r,g,b,alpha)
end

function PallyPowerBuffButton_OnLoad(btn)
    this:SetBackdropColor(0.0, 0.0, 0.0, 0.5);
end

-- 修改后的点击函数，支持左键大祝福、右键小祝福
function PallyPowerBuffButton_OnClick(btn, mousebtn)
	local _,class = UnitClass("player")
	if class ~= "PALADIN" then return end
	if not btn.classID or not btn.buffID then return end

    RestorSelfAutoCastTimeOut = 1;
    if (GetCVar("autoSelfCast") == "1") then
	    RestorSelfAutoCast = true;
	    SetCVar("autoSelfCast", "0");
    end
    
    ClearTarget()
    
    -- 右键点击施放小祝福
    if (mousebtn == "RightButton") then
        PP_Debug("Casting lesser blessing "..btn.buffID.." on "..btn.classID)
        PallyPower_CastLesserBlessing(btn.buffID, btn.classID)
        return
    else
        -- 左键点击施放大祝福
        PP_Debug("Casting "..btn.buffID.." on "..btn.classID)
        -- 防呆：该祝福尚未学会时直接提示，避免对 nil 取值报错（如40级前点了强效祝福按钮）
        if not AllPallys[UnitName("player")] or not AllPallys[UnitName("player")][btn.buffID] then
            PallyPower_ShowFeedback("尚未学会该祝福，无法施放！低等级请勾选主界面左下角“10分钟祝福”，左键即施放小祝福", 1.0, 0.0, 0.0)
            TargetLastTarget()
            return
        end
        CastSpell(AllPallys[UnitName("player")][btn.buffID]["id"], BOOKTYPE_SPELL);
    end
    
    local RecentCast = false
    if (TenMinBlessing == true) then
        if PallyPower_LastCastRemaining(btn.buffID .. btn.classID) > (10 * 60) - 30 then
            RecentCast = true
        end
    else
        if PallyPower_LastCastRemaining(btn.buffID .. btn.classID) > (30 * 60) - 30 then
            RecentCast = true
        end
    end
    
    -- 强效祝福按职业施放，点击时允许重新选择可施法成员。
    -- 30 秒逐人跳过仅适用于 10 分钟小祝福，不能把强效祝福目标锁死。
    for _, unit in ipairs(PP_CurrentClassUnits(btn.classID)) do
        if SpellCanTargetUnit(unit) and not (TenMinBlessing == true and RecentCast and PP_RecentlyCastOn(btn.classID, unit)) then
            PP_Debug("Trying to cast on " .. unit);
            SpellTargetUnit(unit)
            PP_NextScan = 1
            if (TenMinBlessing == true) then
                LastCast[btn.buffID .. btn.classID] = GetTime() + 10 * 60;
            else
                LastCast[btn.buffID .. btn.classID] = GetTime() + 30 * 60;
            end
            LastCastOn[btn.classID] = {}
            tinsert(LastCastOn[btn.classID], unit)
            PallyPower_ShowFeedback(format(PallyPower_Casting, PallyPower_BlessingID[btn.buffID], PallyPower_ClassID[btn.classID], UnitName(unit)), 0.0, 1.0, 0.0);
            TargetLastTarget()
            return
        end
    end
    SpellStopTargeting()
    TargetLastTarget()
    PallyPower_ShowFeedback(format(PallyPower_CouldntFind, PallyPower_BlessingID[btn.buffID], PallyPower_ClassID[btn.classID]), 1.0, 0.0, 0.0);
end

-- 添加小祝福施放函数
function PallyPower_CastLesserBlessing(buffID, classID)
    local lesserId = PallyPower_LesserBlessingMap[buffID]
    if not lesserId then
        PallyPower_ShowFeedback("没有找到对应的小祝福！", 1.0, 0.0, 0.0)
        return
    end
    
    local playerName = UnitName("player")
    if not AllPallys[playerName] or not AllPallys[playerName][lesserId] then
        PallyPower_ShowFeedback("你没有学会对应的小祝福技能！", 1.0, 0.0, 0.0)
        return
    end
    
    PP_Debug("Casting lesser blessing "..lesserId.." on "..classID)
    CastSpell(AllPallys[playerName][lesserId]["id"], BOOKTYPE_SPELL);
    
    local RecentCast = false
    if (TenMinBlessing == true) then
        if PallyPower_LastCastRemaining(lesserId .. classID) > (10 * 60) - 30 then
            RecentCast = true
        end
    else
        if PallyPower_LastCastRemaining(lesserId .. classID) > (30 * 60) - 30 then
            RecentCast = true
        end
    end
    
    for unit, stats in (CurrentBuffs[classID] or {}) do
        -- 检查是否已经有对应的大祝福buff，如果有则跳过
        local hasGreaterBlessing = false
        if stats[buffID] then
            hasGreaterBlessing = true
            PP_Debug("Unit "..unit.." already has greater blessing "..buffID..", skipping")
        end
        
        if not hasGreaterBlessing and SpellCanTargetUnit(unit) and not (RecentCast and PP_RecentlyCastOn(classID, unit)) then
            PP_Debug("Trying to cast lesser blessing on "..unit);
            SpellTargetUnit(unit)
            PP_NextScan = 1
            if (TenMinBlessing == true) then
                LastCast[lesserId .. classID] = GetTime() + 10 * 60;
            else
                LastCast[lesserId .. classID] = GetTime() + 30 * 60;
            end
            if not RecentCast then 
                LastCastOn[classID] = {} 
            end
            tinsert(LastCastOn[classID], unit)
            PallyPower_ShowFeedback(format("施放%s到%s (%s)", PallyPower_BlessingID[buffID], PallyPower_ClassID[classID], UnitName(unit)), 0.0, 1.0, 0.0);
            TargetLastTarget()
            return
        end
    end
    SpellStopTargeting()
    TargetLastTarget()
    PallyPower_ShowFeedback(format("无法找到%s的目标来施放%s！", PallyPower_ClassID[classID], PallyPower_BlessingID[buffID]), 1.0, 0.0, 0.0);
end

-- 修改后的悬停提示函数
function PallyPowerBuffButton_OnEnter(btn)
    local _,class = UnitClass("player")
    if class ~= "PALADIN" then return end
    if not btn.classID or not btn.buffID then return end
    if not PallyPower_ClassID[btn.classID] or not PallyPower_BlessingID[btn.buffID] then return end

    GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
    GameTooltip:SetText(PallyPower_ClassID[btn.classID] .. PallyPower_BuffFrameText .. PallyPower_BlessingID[btn.buffID], 1, 1, 1)
    GameTooltip:AddLine(PallyPower_Have .. PP_SafeConcat(btn.have, ", "), 0.5, 1, 0.5);
    GameTooltip:AddLine(PallyPower_Need .. PP_SafeConcat(btn.need, ", "), 1, 0.5, 0.5);
    GameTooltip:AddLine(PallyPower_NotHere .. PP_SafeConcat(btn.range, ", "), 0.5, 0.5, 1);
    GameTooltip:AddLine(PallyPower_Dead .. PP_SafeConcat(btn.dead, ", "), 1, 0, 0);
    GameTooltip:AddLine(" ");
    if TenMinBlessing == true then
        GameTooltip:AddLine("左键: 施放"..PallyPower_BlessingID[btn.buffID].."（10分钟）", 1, 1, 0);
        GameTooltip:AddLine("右键: 施放强效"..PallyPower_BlessingID[btn.buffID].."（30分钟）", 0, 1, 1);
    else
        GameTooltip:AddLine("左键: 施放强效"..PallyPower_BlessingID[btn.buffID], 1, 1, 0);
        GameTooltip:AddLine("右键: 施放"..PallyPower_BlessingID[btn.buffID], 0, 1, 1);
    end
    GameTooltip:Show()
end

function PallyPowerBuffButton_OnLeave(btn)
    GameTooltip:Hide()
end

------------------------------------------------------------------------------------------------------
-- 单人祝福（完全照抄 D:\HolyHope 模式）
-- 中央宝珠 + 6 个祝福按钮环形围绕（布局偏移与贴图照抄 HolyHope）；
-- 点宝珠切换 小祝福/大祝福 组（按钮贴图同步切换，未学的组不显示按钮）；
-- 点按钮直接施放最高等级已学技能；拖动宝珠移动，右键宝珠打开主窗口。
PP_SOLO_SLOTS = {
    { id = 1, dx = 17,  dy = 42,  tex = "Might" },     -- 力量
    { id = 0, dx = -17, dy = 42,  tex = "Wisdom" },    -- 智慧
    { id = 2, dx = -42, dy = 17,  tex = "Salvation" }, -- 拯救
    { id = 3, dx = 42,  dy = 17,  tex = "Light" },     -- 光明
    { id = 4, dx = 42,  dy = -17, tex = "Kings" },     -- 王者
    { id = 5, dx = -42, dy = -17, tex = "Sanctuary" }, -- 庇护
}
PP_SOLO_UI = "Interface\\AddOns\\PallyPower\\UI\\"

-- 单人模式激活判定：圣骑士 + solomode 开启。
-- force=false：严格判定（无队伍才激活）——用于 BuffBar 让位；force=true：soloForce（强制单人祝福）开启时组队/进团也显示宝珠
function PP_Solo_IsActive(force)
    if PP_PerUser.solomode ~= 1 or not PP_IsPally then
        return false
    end
    if force and PP_PerUser.soloForce == 1 then
        return true
    end
    return GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0
end

PP_SoloInCombat = false

-- 宝珠底图（照抄 HolyHope 两层效果）：
-- 1) 脱战：符印余量环——扫背包统计「王者符印」总数，每 10 个亮一段、共 32 段（320 满环 Symbol32、0 空环 Symbol0）；
-- 2) 战斗中：整珠换红色贴图 HolyHopeC，脱战恢复符印环。
function PallyPower_Solo_UpdateOrbTexture()
    if not PallyPowerSoloBar then
        return
    end
    if PP_SoloInCombat then
        PallyPowerSoloBar:SetNormalTexture(PP_SOLO_UI .. "HolyHopeC")
        return
    end
    local skills = AllPallys[UnitName("player")]
    local kings = 0
    if skills and skills["symbols"] then
        kings = skills["symbols"]
    end
    if kings > 320 then
        kings = 320
    end
    -- 换算照抄 HolyHope（number=320 起、每轮 -10 计一段）
    local number = 320
    local count = -1
    while kings <= number and count < 40 do
        number = number - 10
        count = count + 1
    end
    count = 32 - count
    if count < 0 then count = 0 end
    if count > 32 then count = 32 end
    PallyPowerSoloBar:SetNormalTexture(PP_SOLO_UI .. "Symbol" .. count)
end

local function PP_Solo_SetButtonTexture(btn, texName, greater)
    local suffix = ""
    if greater then suffix = "Up" end
    btn:SetNormalTexture(PP_SOLO_UI .. texName .. suffix)
    btn:SetHighlightTexture(PP_SOLO_UI .. texName .. suffix .. "2")
end

-- 扫描自己身上祝福的真实剩余时间（1.12 GetPlayerBuff 系列 API，与施放来源无关——
-- 手动从法术书/动作条加的 buff 也能读到；小/大祝福纹理折叠到同一槽位 id 0..5）
function PP_Solo_ScanPlayerBuffTimeLeft()
    local timeLefts = {}
    for i = 0, 31 do
        local buffId = GetPlayerBuff(i, "HELPFUL")
        if buffId and buffId > 0 then
            local tex = GetPlayerBuffTexture(buffId)
            if tex then
                local id = PallyPower_GetBuffTextureID(tex)
                if id and id >= 0 then
                    if id > 5 then
                        id = id - 6
                    end
                    local tl = GetPlayerBuffTimeLeft(buffId)
                    if tl and tl > 0 then
                        if timeLefts[id] == nil or tl < timeLefts[id] then
                            timeLefts[id] = tl
                        end
                    end
                end
            end
        end
    end
    return timeLefts
end

function PallyPower_SoloBar_Update()
    if not PallyPowerSoloBar then
        return
    end
    PallyPowerSoloBar:SetScale(PP_PerUser.scalesolo or 1)
    local soloActive = PP_Solo_IsActive(true)
    if not soloActive then
        if PallyPowerSoloBar:IsVisible() then
            PallyPowerSoloBar:Hide()
        end
        return
    end
    if not PallyPowerSoloBar:IsVisible() then
        PallyPowerSoloBar:Show()
    end
    -- 宝珠底图：战斗红珠 / 符印余量环
    PallyPower_Solo_UpdateOrbTexture()
    local skills = AllPallys[UnitName("player")]
    local greater = PP_PerUser.soloGreater == 1
    local buffTimeLefts = PP_Solo_ScanPlayerBuffTimeLeft()
    for i = 1, 6 do
        local btn = pp_getglobal("PallyPowerSoloBarButton" .. i)
        if btn then
            local slot = PP_SOLO_SLOTS[i]
            -- 按钮环绕宝珠（HolyHope 布局偏移）
            btn:ClearAllPoints()
            btn:SetPoint("CENTER", PallyPowerSoloBar, "CENTER", slot.dx, slot.dy)
            -- 当前组对应的技能：小祝福组用 LesserBlessingMap 映射 id，大祝福组用基础 id
            local trackId = slot.id
            if not greater then
                trackId = PallyPower_LesserBlessingMap[slot.id] or slot.id
            end
            local learned = skills and skills[trackId]
            if learned then
                btn.spellToCast = skills[trackId]["id"]
                btn.trackId = trackId
                btn.buffID = slot.id
                btn.duration = 10 * 60
                if greater then
                    btn.duration = 30 * 60
                end
                PP_Solo_SetButtonTexture(btn, slot.tex, greater)
                -- 剩余时间倒计时：以扫描到的实际 buff 在身为前提（小/大祝福折叠到同一 id）。
                -- 优先客户端读到的真实剩余时间（手动加的 buff 也能显示）；无则回退 LastCast 施放记录；都没有显示「已加」
                local timeText = ""
                local myBuffs = CurrentBuffs[4] and CurrentBuffs[4]["player"]
                if myBuffs and myBuffs[slot.id] then
                    local remain = buffTimeLefts[slot.id]
                    if not remain then
                        remain = PallyPower_LastCastRemaining(trackId .. 4)
                    end
                    if remain and remain > 0 then
                        timeText = PallyPower_FormatTime(remain)
                    else
                        timeText = "已加"
                    end
                end
                pp_getglobal("PallyPowerSoloBarButton" .. i .. "Time"):SetText(timeText)
                btn:Show()
            else
                btn:Hide()
            end
        end
    end
end

function PallyPowerSoloBar_MouseDown(arg1)
    PallyPowerSoloBar.startPosX = PallyPowerSoloBar:GetLeft();
    PallyPowerSoloBar.startPosY = PallyPowerSoloBar:GetTop();
    if (((not PallyPowerSoloBar.isLocked) or (PallyPowerSoloBar.isLocked == 0)) and (arg1 == "LeftButton")) then
        PallyPowerSoloBar:StartMoving();
        PallyPowerSoloBar.isMoving = true;
    end
end

function PallyPowerSoloBar_MouseUp(arg1)
    if not PallyPowerSoloBar.startPosX or not PallyPowerSoloBar.startPosY then return end
    if (PallyPowerSoloBar.isMoving) then
        PallyPowerSoloBar:StopMovingOrSizing();
        PallyPowerSoloBar.isMoving = false;
    end
    -- 原地单击宝珠（HolyHope 交互）：左键切换 小祝福/大祝福 组，右键打开主窗口
    if abs(PallyPowerSoloBar.startPosX - PallyPowerSoloBar:GetLeft()) < 2 and abs(PallyPowerSoloBar.startPosY - PallyPowerSoloBar:GetTop()) < 2 then
        if arg1 == "RightButton" then
            PallyPowerFrame:Show();
            PallyPower_UpdateUI()
        else
            if PP_PerUser.soloGreater == 1 then
                PP_PerUser.soloGreater = 0
                PallyPower_ShowFeedback("单人祝福：小祝福（10分钟）", 0.5, 1.0, 0.5)
            else
                PP_PerUser.soloGreater = 1
                PallyPower_ShowFeedback("单人祝福：大祝福（30分钟）", 0.5, 1.0, 0.5)
            end
            PallyPower_SoloBar_Update()
        end
    end
end

function PallyPowerSoloButton_OnClick(btn, mousebtn)
    if not btn.spellToCast then return end

    -- 防止自我施放设置抢目标（同 BuffBar 逻辑，1 秒后自动恢复）
    RestorSelfAutoCastTimeOut = 1;
    if (GetCVar("autoSelfCast") == "1") then
        RestorSelfAutoCast = true;
        SetCVar("autoSelfCast", "0");
    end

    -- 目标选择：有友方目标则给目标施放，否则给自己
    local friendly = UnitExists("target") and UnitIsFriend("player", "target")
    if not friendly then
        ClearTarget()
    end
    CastSpell(btn.spellToCast, BOOKTYPE_SPELL);
    if friendly and SpellCanTargetUnit("target") then
        SpellTargetUnit("target")
        PallyPower_ShowFeedback(format("正在给 %s 施放%s", UnitName("target"), PallyPower_BlessingID[btn.buffID]), 0.0, 1.0, 0.0);
    else
        SpellTargetUnit("player")
        PallyPower_ShowFeedback(format("正在给自己施放%s", PallyPower_BlessingID[btn.buffID]), 0.0, 1.0, 0.0);
    end

    -- 记录到期时间：小祝福组 10 分钟，大祝福组 30 分钟
    LastCast[btn.trackId .. 4] = GetTime() + (btn.duration or 600);
    PP_NextScan = 1
    -- 若原本目标是敌对单位，施放后恢复目标
    if not friendly then
        TargetLastTarget()
    end
end

function PallyPowerSoloButton_OnEnter(btn)
    if not btn.spellToCast then return end
    GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
    -- 照抄 HolyHope tooltip2：显示真实法术提示（含耗魔/等级）
    GameTooltip:SetSpell(btn.spellToCast, BOOKTYPE_SPELL)
    -- 附加剩余时间（仅身上确实有该祝福时；优先真实 buff 剩余时间，手动加的也能显示）
    if btn.buffID and btn.trackId then
        local myBuffs = CurrentBuffs[4] and CurrentBuffs[4]["player"]
        if myBuffs and myBuffs[btn.buffID] then
            local remain
            local realTl = PP_Solo_ScanPlayerBuffTimeLeft()
            if realTl then
                remain = realTl[btn.buffID]
            end
            if not remain then
                remain = PallyPower_LastCastRemaining(btn.trackId .. 4)
            end
            if remain and remain > 0 then
                GameTooltip:AddLine("剩余时间：" .. PallyPower_FormatTime(remain), 0.7, 1, 0.7)
            end
        end
    end
    GameTooltip:Show()
end

function PallyPowerSoloButton_OnLeave(btn)
    GameTooltip:Hide()
end

-- 鼠标滚轮缩放宝珠（悬停宝珠或环形按钮上滚动；每格 0.1，范围 0.5~2.0，
-- 复用 PallyPower_ScaleFrame：保持左上角屏幕位置不变并把 PP_PerUser.scalesolo 存档）
function PallyPowerSoloBar_OnMouseWheel(delta)
    local scale = PP_PerUser.scalesolo or 1
    if delta and delta > 0 then
        scale = scale + 0.1
    else
        scale = scale - 0.1
    end
    if scale < 0.5 then
        scale = 0.5
    end
    if scale > 2.0 then
        scale = 2.0
    end
    PallyPower.FrameToScale = PallyPowerSoloBar
    PallyPower_ScaleFrame(scale)
    PallyPower.FrameToScale = nil
end

function PallyPowerSoloOrb_OnEnter()
    GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
    GameTooltip:SetText("单人祝福", 1, 1, 1)
    if PP_PerUser.soloGreater == 1 then
        GameTooltip:AddLine("当前：大祝福（30分钟）", 1, 0.7, 0)
    else
        GameTooltip:AddLine("当前：小祝福（10分钟）", 0.7, 1, 0.7)
    end
    GameTooltip:AddLine("左键：切换 小祝福/大祝福", 1, 1, 0)
    GameTooltip:AddLine("右键：打开主窗口", 0, 1, 1)
    GameTooltip:AddLine("滚轮：缩放", 1, 1, 0)
    GameTooltip:AddLine("拖动移动位置", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

--[[ MainFrame and MenuFrame Scaling ]]--

function PallyPower_StartScaling(arg1)
    if arg1 == "LeftButton" then
        this:LockHighlight()
        PallyPower.FrameToScale = this:GetParent()
        PallyPower.ScalingWidth = this:GetParent():GetWidth() * PallyPower.FrameToScale:GetParent():GetEffectiveScale()
        PallyPower.ScalingHeight = this:GetParent():GetHeight() * PallyPower.FrameToScale:GetParent():GetEffectiveScale()
        PallyPower_ScalingFrame:Show()
    end
end

function PallyPower_StopScaling(arg1)
    if arg1 == "LeftButton" then
        PallyPower_ScalingFrame:Hide()
        PallyPower.FrameToScale = nil
        this:UnlockHighlight()
    end
end

local function really_setpoint(frame, point, relativeTo, relativePoint, xoff, yoff)
    frame:SetPoint(point, relativeTo, relativePoint, xoff, yoff)
end

function PallyPower_ScaleFrame(scale)
    local frame = PallyPower.FrameToScale
    local oldscale = frame:GetScale() or 1
    local framex = (frame:GetLeft() or PallyPowerPerOptions.XPos) * oldscale
    local framey = (frame:GetTop() or PallyPowerPerOptions.YPos) * oldscale

    frame:SetScale(scale)
    if frame:GetName() == "PallyPowerFrame" then
        really_setpoint(PallyPowerFrame, "TOPLEFT", "UIParent", "BOTTOMLEFT", framex / scale, framey / scale)
        PP_PerUser.scalemain = scale
    end
    if frame:GetName() == "PallyPowerBuffBar" then
        really_setpoint(PallyPowerBuffBar, "TOPLEFT", "UIParent", "BOTTOMLEFT", framex / scale, framey / scale)
        PP_PerUser.scalebar = scale
    end
    if frame:GetName() == "PallyPowerSoloBar" then
        really_setpoint(PallyPowerSoloBar, "TOPLEFT", "UIParent", "BOTTOMLEFT", framex / scale, framey / scale)
        PP_PerUser.scalesolo = scale
    end
end

function PallyPower_ScalingFrame_OnUpdate(arg1)
    if not PallyPower.ScalingTime then
        PallyPower.ScalingTime = 0
    end
    PallyPower.ScalingTime = PallyPower.ScalingTime + arg1
    if PallyPower.ScalingTime > 0.25 then
        PallyPower.ScalingTime = 0
        local frame = PallyPower.FrameToScale
        local oldscale = frame:GetEffectiveScale()
        local framex, framey, cursorx, cursory = frame:GetLeft() * oldscale, frame:GetTop() * oldscale, GetCursorPosition()
        if PallyPower.ScalingWidth > PallyPower.ScalingHeight then
            if (cursorx - framex) > 32 then
                local newscale = (cursorx - framex) / PallyPower.ScalingWidth
                PallyPower_ScaleFrame(newscale)
            end
        else
            if (framey - cursory) > 32 then
                local newscale = (framey - cursory) / PallyPower.ScalingHeight
                PallyPower_ScaleFrame(newscale)
            end
        end
    end
end

function PallyPower_SetOption(opt, value)
    PP_PerUser[opt] = value
end

function PallyPower_Options()
    PallyPowerFrame:Hide()
    PallyPower_OptionsFrame:Show()
end

local ppLastFeedback, ppLastFeedbackAt
function PallyPower_ShowFeedback(msg, r, g, b, a)
    if PP_PerUser.screenfeedback == 0 then return end
    local now = GetTime()
    if msg == ppLastFeedback and now - (ppLastFeedbackAt or 0) < 1 then return end
    ppLastFeedback, ppLastFeedbackAt = msg, now
    UIErrorsFrame:AddMessage(msg, r, g, b, a)
end

function PallyPowerGridButton_OnMouseWheel(btn, arg1)
    _, _, pnum, class = string.find(btn:GetName(), "PallyPowerFramePlayer(.+)Class(.+)");
    pnum = pnum + 0;
    class = class + 0;
    pname = getglobal("PallyPowerFramePlayer" .. pnum .. "Name"):GetText()
    if not PallyPower_CanControl(pname) then
        return false
    end

    if (arg1 == -1) then
        --mouse wheel down
        PallyPower_PerformCycle(pname, class)
    else
        PallyPower_PerformCycleBackwards(pname, class)
    end
end

function PallyPower_BarToggle()
    if ((GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0) or (PP_IsPally == false)) then
        PallyPower_ShowFeedback(" Not in raid or not a paladin", 0.5, 1, 1, 1)
    else
        if PallyPowerBuffBar:IsVisible() then
            PallyPowerBuffBar:Hide()
            PallyPower_ShowFeedback(" Bar hidden", 0.5, 1, 1, 1)
        else
            PallyPowerBuffBar:Show()
            PallyPower_ShowFeedback(" Bar visible", 0.5, 1, 1, 1)
        end
    end
end