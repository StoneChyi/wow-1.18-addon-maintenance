-- 创建一个 Frame 并监听事件
local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UNIT_ENERGY")
frame:RegisterEvent("PLAYER_DEAD")

frame:RegisterEvent("SPELLCAST_START")
frame:RegisterEvent("SPELLCAST_STOP")
frame:RegisterEvent("SPELLCAST_FAILED")
frame:RegisterEvent("SPELLCAST_INTERRUPTED")

frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_ENTER_COMBAT")
frame:RegisterEvent("PLAYER_LEAVE_COMBAT")

frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
frame:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
frame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
frame:RegisterEvent("CHAT_MSG_ADDON")

frame:RegisterEvent("UI_ERROR_MESSAGE")

-- SuperWow专有事件
frame:RegisterEvent("UNIT_CASTEVENT")
frame:RegisterEvent("RAW_COMBATLOG")

-- Nampower专有事件
--frame:RegisterEvent("SPELL_FAILED_SELF")
--frame:RegisterEvent("BUFF_ADDED_SELF")
--frame:RegisterEvent("BUFF_REMOVED_SELF")
--frame:RegisterEvent("DEBUFF_ADDED_SELF")
--frame:RegisterEvent("DEBUFF_REMOVED_SELF")
--frame:RegisterEvent("AURA_CAST_ON_SELF")

--frame:RegisterEvent("BUFF_UPDATE_DURATION_SELF")
--frame:RegisterEvent("DEBUFF_UPDATE_DURATION_SELF")
frame:RegisterEvent("AUTO_ATTACK_SELF")


MP_UnitXP = pcall(UnitXP, "nop", "nop");
MP_SuperWoW = false
MP_SuperWoWVersion = 0
MP_Nampower = false
MP_Nampower3 = false
MP_Nampower4 = false
MP_Nampower5 = false
MP_Interact = false

CatMod = false
CatModVersion = 0
CatModVersionStr = ""
MPClientLanguage = GetLocale()  --"zhCN"
MPtextSystemInfo = ""

-- 是否能打背标记变量
local ErrorBehind = true
local ErrorBehindTimer = 0

-- 是否正在施法计时器
local castStartTime = {}
local castName = {}
local castDuration = {}

-- 普攻计时器(主手)
local MainHandBeginTime = 0
local MainHandDuration = 0

-- Buff & Debuff
MPPlayerAurasSpellID = {}
MPPlayerAurasSpellSlot = {}
MPPlayerAurasSpellName = {}
MPPlayerAurasSpellStacks = {}
MPPlayerAurasSpellDuration = {}

-- GCD计时器
local gcdtimer = 0
local isCast = false
local gcdmax = 1.5

-- 回能监测
local OldEnergy = 0
local RestoredEnergyTime=0

-- 自己的GUID
MP_PLAYER_GUID = 0

-- 周围的guid
local ObjectArray = {}

-- 团队的guid
local PlayerArray = {}
local PlayerArrayOrigin = {}

local function ResetData()
    MPInCombat = false
    isCast = false
    castStartTime = {}
    castName = {}
    castDuration = {}
    MPAutoAttack = false
    MPAutoAttackLock = false
end

local function BeginHit()

    -- 记录挥击开始时间
    MainHandBeginTime = GetTime()
    -- 记录挥击时的普攻总时长
    MainHandDuration = UnitAttackSpeed("player")

end

function MPPushObject(inGUID)

    if inGUID and not ObjectArray[inGUID] then
        if UnitCanAttack("player", inGUID) and not UnitIsDead(inGUID) then
            ObjectArray[inGUID] = GetTime()
        end
    end

end

local function CheckSpellLog(str)

    if not str then
        return
    end

    -- 通过日志收集周围目标
    local objectGUID = MPMatchGUID(str) 
    --MPPushObject(objectGUID)

    if objectGUID and UnitCanAttack("player", objectGUID) then
        -- 打断部分收集信息
        local spellName = MPMatch(str, MPLanguage.CL_BeginsCasting)
        if spellName then
            castStartTime[objectGUID] = GetTime()
            castName[objectGUID] = spellName
            castDuration[objectGUID] = 20000        -- 用20秒作为长度
            --MPMsg("敌方 ["..objectGUID.."] 开始施放 ["..spellName.."]")
            return
        end
    end

end

local function CheckCombatLog(str)

    -- 通过日志收集周围目标
    local objectGUID = MPMatchGUID(str) 
    MPPushObject(objectGUID)

end



local function OnEvent()

    -- 初始化
    if event == "PLAYER_LOGIN" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF9264cd"..string.format(MPLanguage.UI_AddonLoaded, MPCatAddonVer).."|r")

        if SUPERWOW_STRING then
            MP_SuperWoW = true
        end

        if type(GetNampowerVersion) == "function" then
            MP_Nampower = true
        end

        -- 检测Interact
        local secc = false
        if type(InteractNearest) == "function" then
            secc = true
        end
        if not secc then
            secc = pcall(function()
                UnitXP("interact", 1)
            end)
        end
        MP_Interact = secc

        
        if type(GetCatVersion) == "function" then
            local modString = GetCatVersion()
            local vPos = string.find(modString, "v")
            if vPos then
                CatModVersionStr = string.sub(modString, vPos + 1)
                CatModVersion = MPToNumber(CatModVersionStr)
            else
                CatModVersion = 10
            end
            CatMod = true
        end


        -- 检测模组相关，优化性能，预制
        MPtextSystemInfo = MPLanguage.UI_SystemInfo

        if string.find(TURTLE_WOW_VERSION,"1.18.1") then
            if MPClientLanguage == "zhCN" then
                MPtextSystemInfo = MPtextSystemInfo .. MPLanguage.UI_ClientLanguage..MPClientLanguage
            else
                MPtextSystemInfo = MPtextSystemInfo .. MPLanguage.UI_ClientLanguage..MPClientLanguage..MPLanguage.UI_ClientNotSupported
            end
        else
            MPtextSystemInfo = MPtextSystemInfo .. MPLanguage.UI_GameVersionNotSupported
        end

        if SUPERWOW_STRING then
            MP_SuperWoWVersion = MPToNumber(SUPERWOW_VERSION)
            if MP_SuperWoWVersion>=15  then
                MPtextSystemInfo = MPtextSystemInfo .. MPLanguage.UI_FoundSuperWoW..SUPERWOW_VERSION.."|r"
            else
                MPtextSystemInfo = MPtextSystemInfo .. MPLanguage.UI_FoundSuperWoW..SUPERWOW_VERSION..MPLanguage.UI_SuperWoWAbnormalSuffix
                DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_SuperWoWVersionWarn)
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_NoSuperWoW)
        end

        if MP_UnitXP then
            local compileTime = UnitXP("version", "coffTimeDateStamp");
            MPtextSystemInfo = MPtextSystemInfo .. MPLanguage.UI_FoundUnitXP..date("%Y-%m-%d", compileTime).."|r"
        else
            DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_NoUnitXP)
        end

        if MP_Nampower then
            local major, minor, patch=GetNampowerVersion()
            if major>=4 then
                MPtextSystemInfo = MPtextSystemInfo .. MPLanguage.UI_FoundNampower..major.."."..minor.."."..patch.."|r"
                MP_Nampower4 = true
		        SetCVar("NP_EnableAutoAttackEvents", "1") 
		        SetCVar("NP_EnableAuraCastEvents", "1") 
		        SetCVar("NP_EnableSpellHealEvents", "1") 
		        SetCVar("NP_EnableSpellGoEvents", "1")
		        SetCVar("NP_EnableSpellStartEvents", "1")
            else
                MPtextSystemInfo = MPtextSystemInfo .. "\n发现 |cFFFF0000nampower模组 "..major.."."..minor.."."..patch.." (过期)|r"
            end

        end

        if MP_Interact then
            MPtextSystemInfo = MPtextSystemInfo .. MPLanguage.UI_FoundInteract
        end

        if CatMod then
            MPtextSystemInfo = MPtextSystemInfo .. MPLanguage.UI_FoundCatMod..CatModVersionStr.."|r"
        end

	    if MPIsAddOnLoaded("MacroPlus") then
		    DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ConflictMacroPlus)
            MPtextSystemInfo = MPtextSystemInfo .. MPLanguage.UI_ConflictMacroPlusInfo
	    end

	    if MPIsAddOnLoaded("CatPaw-Turtle") then
		    DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ConflictCatPaw)
            MPtextSystemInfo = MPtextSystemInfo .. MPLanguage.UI_ConflictCatPawInfo
	    end

        MPtextSystemInfo = MPtextSystemInfo .. "\n"

        MPCatSettingsCloseAll()

    elseif event == "ADDON_LOADED" then

        if arg1 == "Cat" then

            -- 获取并保存自己的GUID
            local a,guid = UnitExists("player")
            MP_PLAYER_GUID = guid

            _, MPPlayerClass = UnitClass("player")

            -- 初始化全局存储（如果不存在）
            if MPPublicSaved and MPPublicSaved.DebugWindowDisplay then
                if MPPublicSaved.DebugWindowDisplay==0 then
                    CatDebugWindow:Hide()
                else
                    CatDebugWindow:Show()
                end
            else
                CatDebugWindow:Show()
            end

            -- 初始化界面相关参数
            MPInitMiniButton()

        end

    -- 进入游戏世界刷新常量值
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- 刷新角色属性状态值
        MPRefreshInfo()
        ResetData()

        --[[
        if MP_Nampower4 then
            local data = GetUnitData("player")
            if data and data.aura then
                local slot = 0
                for i=1,48 do
                    --MPMsg(data.aura[i])
                    if data.aura[i]>0 then
                        local spellname = GetSpellRecField(data.aura[i], "name")
                        MPPlayerAurasSpellID[data.aura[i] = true
                        MPPlayerAurasSpellSlot[spellname] = slot
                        MPPlayerAurasSpellName[spellname] = true
                        MPPlayerAurasSpellStacks[spellname] = 1
                        MPPlayerAurasSpellDuration[spellname] = 0
                        slot = slot + 1
                    end
                end
            end
        end
        ]]

        frame:UnregisterEvent("PLAYER_ENTERING_WORLD")

    -- 装备变化刷新常量值
    elseif event == "UNIT_INVENTORY_CHANGED" then
        -- 刷新角色属性状态值
        if arg1=="player" then
            MPRefreshInfo()
        end

    -- 目标变化事件
    elseif event == "PLAYER_TARGET_CHANGED" then
        -- 检测目标是否可以流血
        MPTargetBleed = MPCanBleed()

        -- 重置当前目标的战斗事件
        if MPInCombat then
            MPInCombatTime = GetTime()
        end

    -- 背面判断
    elseif event == "UI_ERROR_MESSAGE" then
        --if not MP_Nampower4 then
            if arg1=="你必须位于目标背后" then
                ErrorBehindTimer = GetTime()
                ErrorBehind = false
            end
        --end

    -- 进入战斗事件
    elseif event == "PLAYER_REGEN_DISABLED" then

        -- 刷新角色属性状态值
        MPRefreshInfo()

        -- 战斗标记
        MPInCombat = true
        MPInCombatTime = GetTime()

        MPMsg(MPLanguage.UI_EnterCombat)

    -- 离开战斗事件
    elseif event == "PLAYER_REGEN_ENABLED" then
        ResetData()

        MPMsg(MPLanguage.UI_LeaveCombat)

    -- 玩家死亡，重置一些参数
    elseif event == "PLAYER_DEAD" then
        ResetData()

    -- 施法事件处理，读条类，读条也要处理GCD
    elseif event == "SPELLCAST_START" then
        -- GCD时间处理
        isCast = true
        gcdtimer = GetTime()
        gcdmax = 1.5

        if MPPlayerClass=="DRUID" then
            if MPGetShape(MPDruidCatShapeshiftID) then
                gcdmax = 1.0
            end
        elseif MPPlayerClass=="ROGUE" then
            gcdmax = 1.0
        end

    elseif event == "SPELLCAST_STOP" then
        -- GCD时间处理
        if isCast then
            isCast = false
        else

            -- 未读条，应该是瞬发，GCD时间启动
            gcdtimer = GetTime()
            gcdmax = 1.5

            if MPPlayerClass=="DRUID" then
                if MPGetShape(MPDruidCatShapeshiftID) then
                    gcdmax = 1.0
                end
            elseif MPPlayerClass=="ROGUE" then
                gcdmax = 1.0
            end

        end

    elseif event == "SPELLCAST_FAILED" then
        -- GCD时间处理
        if isCast then
            isCast = false
        end

    elseif event == "SPELLCAST_INTERRUPTED" then
        -- GCD时间处理
        if isCast then
            isCast = false
        end

    -- 回能量事件处理
    elseif event == "UNIT_ENERGY" and arg1 == "player" then
        local eMax = UnitManaMax("player")

        -- 防止非能量
        if eMax<150 then

            -- 计算差值
            local eNow = UnitMana("player")
            if eNow-OldEnergy==20 then

                -- 重置回能时钟
                RestoredEnergyTime = GetTime()
                --message(OldEnergy.." -> "..eNow)
            end

        end


    -- 技能伤害
    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then

        if string.find( arg1, "你的英勇打击.*" ) then
            BeginHit()
        elseif string.find( arg1, "你的顺劈斩.*" ) then
            BeginHit()
        end

    -- 躲避miss等
    elseif event == "CHAT_MSG_COMBAT_SELF_MISSES" then

        if not MP_SuperWoW then
            if string.find( arg1, "你发起了攻击.*" ) then
                BeginHit()
            elseif string.find( arg1, "你没有击中.*" ) then
                BeginHit()
            end
        end

    elseif event == "CHAT_MSG_COMBAT_SELF_HITS" then

        if not MP_SuperWoW then
            if string.find( arg1, "你对.*" ) then
                BeginHit()
            elseif string.find( arg1, "你击中.*" ) then
                BeginHit()
            end
        end

    -- 开启自动攻击的状态处理，未必进入战斗
    elseif event == "PLAYER_ENTER_COMBAT" then
        MPAutoAttack = true

    elseif event == "PLAYER_LEAVE_COMBAT" then
        MPAutoAttack = false

    elseif event == "CHAT_MSG_ADDON" then

        --MPMsg("addon: "..arg1.." character: "..arg4)
        if arg1=="Cat" then
            MPPushPlayer(arg2, arg3)
        end


    ---------------------------
    -- SuperWoW事件 -----------
    ---------------------------

    -- 施法、攻击事件处理
    elseif event == "UNIT_CASTEVENT" then

        MPPushObject(arg1)
        MPPushObject(arg2)
        
        -- 施法事件监测
        if arg3 == "START" then

            if arg1 == MP_PLAYER_GUID then
                isCast = true
            end

        elseif arg3 == "CAST" then

            -- 监控所有人

            -- 用于打断，清空该读条
            if castStartTime[arg1] then 
                castStartTime[arg1] = nil
                castName[arg1] = nil
                castDuration[arg1] = nil
            end

            -- 仅监控自己放出的技能
            if arg1 == MP_PLAYER_GUID then
                isCast = false

                -- 献祭之油
                if arg4 == 11350 then
                    MPSacrificialTimer = GetTime()+15
                end

            end


        elseif arg3 == "FAIL"  then
            if arg1 == MP_PLAYER_GUID then
                isCast = false
            end

            -- 用于打断，清空该读条
            if castStartTime[arg1] then
                castStartTime[arg1] = nil
                castName[arg1] = nil
                castDuration[arg1] = nil
            end

        elseif arg3 == "MAINHAND" then

            if not MP_Nampower4 then

                if arg1==MP_PLAYER_GUID then
                    MPMsg("普攻")
                    BeginHit()
                end

            end

        end


    -- 战斗日志事件处理
    elseif event == "RAW_COMBATLOG" then

        -- 用于收集读条的技能名字，而不是ID
        CheckSpellLog(arg2)



    -- Nampower专有事件

    elseif event == "AUTO_ATTACK_SELF" then
        MPMsg("普攻")
        BeginHit()

    elseif event == "SPELL_FAILED_SELF" then

        -- 背面错误信息
        if arg2==51 then
            ErrorBehindTimer = GetTime()
            ErrorBehind = false
        end

    elseif event == "BUFF_ADDED_SELF" then

        local spellname = GetSpellRecField(arg3, "name")
        if arg2<=0 then arg2=99 end

        MPPlayerAurasSpellID[arg3] = true
        MPPlayerAurasSpellSlot[spellname] = arg6
        MPPlayerAurasSpellName[spellname] = true
        MPPlayerAurasSpellStacks[spellname] = arg4
        MPPlayerAurasSpellDuration[spellname] = -1

    elseif event == "BUFF_REMOVED_SELF" then

        local spellname = GetSpellRecField(arg3, "name")

        if MPPlayerAurasSpellID[arg3] then MPPlayerAurasSpellID[arg3]=nil end
        if MPPlayerAurasSpellSlot[spellname] then MPPlayerAurasSpellSlot[spellname]=nil end
        if MPPlayerAurasSpellName[spellname] then MPPlayerAurasSpellName[spellname]=nil end
        if MPPlayerAurasSpellStacks[spellname] then MPPlayerAurasSpellStacks[spellname]=nil end
        if MPPlayerAurasSpellDuration[spellname] then MPPlayerAurasSpellDuration[spellname]=nil end

    elseif event == "DEBUFF_ADDED_SELF" then

        local spellname = GetSpellRecField(arg3, "name")
        if arg2<=0 then arg2=99 end

        MPPlayerAurasSpellID[arg3] = true
        MPPlayerAurasSpellSlot[spellname] = arg6
        MPPlayerAurasSpellName[spellname] = true
        MPPlayerAurasSpellStacks[spellname] = arg4
        MPPlayerAurasSpellDuration[spellname] = -1

    elseif event == "DEBUFF_REMOVED_SELF" then

        local spellname = GetSpellRecField(arg3, "name")

        if MPPlayerAurasSpellID[arg3] then MPPlayerAurasSpellID[arg3]=nil end
        if MPPlayerAurasSpellSlot[spellname] then MPPlayerAurasSpellSlot[spellname]=nil end
        if MPPlayerAurasSpellName[spellname] then MPPlayerAurasSpellName[spellname]=nil end
        if MPPlayerAurasSpellStacks[spellname] then MPPlayerAurasSpellStacks[spellname]=nil end
        if MPPlayerAurasSpellDuration[spellname] then MPPlayerAurasSpellDuration[spellname]=nil end

    elseif event == "AURA_CAST_ON_SELF" then

        if arg9>0 then

            local spellname = GetSpellRecField(arg1, "name")

            if spellname and not MPPlayerAurasSpellID[arg1] then
                MPPlayerAurasSpellID[arg1] = true
                MPPlayerAurasSpellSlot[spellname] = 0
                MPPlayerAurasSpellName[spellname] = true
                MPPlayerAurasSpellStacks[spellname] = 1
                MPPlayerAurasSpellDuration[spellname] = arg8
                --print(spellname)
                --print(arg8)
            end

        end
    --[[
    elseif event == "BUFF_UPDATE_DURATION_SELF" or event == "DEBUFF_UPDATE_DURATION_SELF" then

        MPMsg(arg1.." - "..arg2)
        for key, value in pairs(MPPlayerAurasSpellSlot) do
            MPMsg( key .. " - ".. value)
            if value == arg1 then
                MPPlayerAurasSpellDuration[key] = arg2
            end
        end
    ]]

    end


end

-- 测试，要删除
function MPPrintAuras()
    local count = 1
    MPMsg("=== Auras ===")
    for key, value in pairs(MPPlayerAurasSpellName) do
        if value then
            MPMsg(count.." Auras:"..key.." Layer:"..MPPlayerAurasSpellStacks[key].." Slot:"..MPPlayerAurasSpellSlot[key].." Dru:"..MPPlayerAurasSpellDuration[key])
            count = count + 1
        else
            MPMsg("空 Auras")
        end
    end
end

local interval = 0.05  -- 轮询间隔（秒）
local elapsed = 0
local catmsg_interval = 30  -- 轮询间隔（秒）
local catmsg_elapsed = 0
local nameframe_interval = 0.2  -- 轮询间隔（秒）
local nameframe_elapsed = 0
local UIinterval = 0.1  -- 轮询间隔（秒）
local UIelapsed = 0

local RefreshInfo_elapsed = 3
local RefreshInfo_count = 0

local prevX, prevY = 0, 0
-- 地图坐标轮询得到的移动状态，作为扩展接口均未确认移动时的最终兜底。
MPPlayerIsMoving = false
local MP_MOVEMENT_SPEED_THRESHOLD = 0.01

local function EventPollingFunction()

    if RefreshInfo_count<3 then
        RefreshInfo_elapsed = RefreshInfo_elapsed + 0.05
        if RefreshInfo_elapsed >= 5 then
            RefreshInfo_elapsed = 0
            RefreshInfo_count = RefreshInfo_count + 1
            -- 刷新角色属性状态值
            MPRefreshInfo()
        end
    end


    -- 处理自动攻击
    if MPAutoAttackLock then
        if GetTime()-MPAutoAttackLockTimer > 0.2 then
            MPAutoAttackLock = false
        end
    end

    -- 始终保留地图坐标轮询作为最终兜底。狭窄区域可能无法正确更新坐标，
    -- 因此 MPIsMoving() 还会优先合并 UnitXP、SuperWoW 与 Nampower 的结果。
    local x, y = GetPlayerMapPosition("player")
    if x ~= prevX or y ~= prevY then
        if not MPPlayerIsMoving then
            MPPlayerIsMoving = true
        end
    else
        if MPPlayerIsMoving then
            MPPlayerIsMoving = false
        end
    end
    prevX, prevY = x, y


    OldEnergy = UnitMana("player")
end

local function NameFramePollingFunction()

    if not MP_SuperWoW then
        return
    end

    -- 收集NamePlate

    --[[
    if _G["pfNamePlate1"] then
        for i=1,30 do
            local frameName = "pfNamePlate"..i
            local frame = _G[frameName]
            if frame then
                if frame:IsVisible() and frame.lastGuid then
                    MPPushObject(frame.lastGuid)
                end
            else
                break
            end
        end
    end
    ]]
    local parentcount = WorldFrame:GetNumChildren()
    local childs = { WorldFrame:GetChildren() }
	for i=1, parentcount do
		plate = childs[i]
		if plate:GetObjectType() ~= NAMEPLATE_FRAMETYPE then 
            if plate:GetName(1) then
                MPPushObject(plate:GetName(1))
			end
		end
	end

end


local function OnUpdate()

    elapsed = elapsed + arg1
    if elapsed >= interval then
        elapsed = 0  -- 重置计时器
        EventPollingFunction()  -- 调用轮询函数
    end



    nameframe_elapsed = nameframe_elapsed + arg1
    if nameframe_elapsed >= nameframe_interval then
        nameframe_elapsed = 0  -- 重置计时器
        NameFramePollingFunction()
    end

    catmsg_elapsed = catmsg_elapsed + arg1
    if catmsg_elapsed >= catmsg_interval then
        catmsg_elapsed = 0  -- 重置计时器
        MPSendCatMsg()
    end

    UIelapsed = UIelapsed + arg1
    if UIelapsed >= UIinterval then
        UIelapsed = 0  -- 重置计时器

        if type(MPRefreshInfoUI) == "function" then
            MPRefreshInfoUI()
        end
    end

end


-- 设置事件处理函数
frame:SetScript("OnEvent", OnEvent)
frame:SetScript("OnUpdate", OnUpdate)


-- 获取当前回能时间（盗贼、猫德使用）
-- 注：双流血猫德不建议使用
-- return 返回值在0.0-2.0 为有效范围，超过2.0则无效
function MPGetRestoredEnergy()
    local timer = GetTime()-RestoredEnergyTime
    local fullCycles = math.floor(timer / 2)  -- 完整的2秒周期数
    local cyclePos = timer - (fullCycles * 2)  -- 当前周期中的位置
    return cyclePos
end

-- 获取当前技能GCD
-- 适用于瞬发技能，读条技能不适用
-- return 0-1.5 有效范围，超出则GCD已经完成
function MPGetGCD()
    return GetTime()-gcdtimer
end

-- 获取当前技能GCD的剩余时间
function MPGetLeftGCD()
    if MPGetGCD() < MPGCDMax() then
        return MPGCDMax()-MPGetGCD()
    end

    return 0
end

-- 获取当前技能GCD的时长，如：1.5秒 1.0秒
function MPGCDMax()
    return gcdmax
end

-- 获取当前是否在读条
function MPGetCast()
    return isCast
end

-- 获取玩家的移动状态
function MPIsMoving()
    -- UnitXP 的第一个返回值是当前移动速度；大于阈值即可确认正在移动。
    if MP_UnitXP and type(UnitXP) == "function" then
        local succeeded, currentSpeed = pcall(UnitXP, "speed", "player")
        currentSpeed = tonumber(currentSpeed) or 0
        if succeeded and currentSpeed > MP_MOVEMENT_SPEED_THRESHOLD then
            return true
        end
    end

    -- Nampower 直接提供移动状态；使用函数存在性判断兼容不同大版本。
    if MP_Nampower and type(PlayerIsMoving) == "function" then
        local succeeded, moving = pcall(PlayerIsMoving)
        if succeeded and moving == 1 then
            return true
        end
    end

    return MPPlayerIsMoving
end



-- 获取目标的朝向
-- return 获取成立返回真
function MPCheckBehind(value)

    -- 任意参数，则不进行UnitXP调用，用于特殊情况下，UnitXP无法正常使用下的临时处理
    --[[
    if not value then
        value=0
    end

    -- 如果UnityXP模组存在，通过模组返回
    if MP_UnitXP and value==1 then
        return UnitXP("behind", "player", "target")
    else
        -- 检测异常捕获的方向错误
        if ErrorBehind == false then
            if GetTime() - ErrorBehindTimer > 0.5 then
                ErrorBehind = true
            else
                return false
            end
        end
    end

    ]]

    -- 检测异常捕获的方向错误
    if ErrorBehind == false then
        if GetTime() - ErrorBehindTimer > 0.3 then
            ErrorBehind = true
        else
            return false
        end
    end

    --[[ 不使用UnitXP
    if MP_UnitXP then
        return UnitXP("behind", "player", "target")
    end
    ]]

    return true
end


-- 获取目标是否正在施法
-- 注：需要SuperWow支持
-- return 成立返回真,返回法术ID
function MPTargetCast()

    -- 检测是否有SuperWow模组
    if not MP_SuperWoW then
        --DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."未加载SuperWow，MPTargetCast()无效。|r")
        return false, 0
    end

    -- 获取目标GUID，并确保其存在
    local _,guid=UnitExists("target")
    if not guid then
        return false, 0
    end

    if castStartTime[guid] ~= nil then
        if castName[guid] then
            --local spellName, _, _, _, _, _, _, _ = GetSpellInfo(castName[guid],"spell")
            local timer = GetTime()-castStartTime[guid]
            if timer < castDuration[guid] then
                return true, castName[guid]
            else
                return false, 0
            end
        end
        
        return true, 0
    end

    return false, 0
end

-- 获取普攻剩余时间（主手）
-- return 返回下一次攻击的剩余时间
function MPGetMainHandLeft()
    local t = GetTime() - MainHandBeginTime
    local left = MainHandDuration - t;

    if left < 0 then
        return 0
    end

    return left
end

-- 获取普攻消耗掉的时间（主手）
function MPGetMainHandTime()
    return GetTime() - MainHandBeginTime
end


-- 搜索身边的敌人数量
-- return 敌人数量
local MPNearEmeny = 0
local MPNearEmenyTimer = 0
local MPMaxCount = 0
local MPNearEmenyList = {}
local MPEmenyExecuteList = {}
local MPEmenyList = {}


function MPScanEnemy()

    -- 未安装SuperWoW
    if not MP_SuperWoW then
        return
    end

    local a,targetGUID = UnitExists("target")  -- 保存当前目标GUID

    for i = 1, 8 do
        TargetNearestEnemy(i)
        has,objectGUID = UnitExists("target")
        MPPushObject(objectGUID)
    end

    -- 恢复原始目标
    if targetGUID then
        TargetUnit(targetGUID)
    else
        ClearTarget()
    end

end

function MPScanNearbyEnemiesCount(range)

    range = range or MPMeleeRange;

    -- 未安装SuperWoW
    if not MP_SuperWoW then
        return 0,0
    end

    --[[ 缓存
    if GetTime()-MPNearEmenyTimer<0.6 then
        return MPNearEmeny,MPMaxCount,MPNearEmenyList,MPEmenyExecuteList,MPEmenyList
    end
    ]]

    local count = 0
    local inMeleeRange
    local a,targetGUID = UnitExists("target")  -- 保存当前目标GUID
    local toRemove = {}  -- 存储待删除的键

    MPMaxCount = 0
    MPNearEmenyList = {}
    MPEmenyExecuteList = {}
    MPEmenyList = {}

    -- 检查自己的目标
    if a then
        MPPushObject(targetGUID)
    end

    --MPScanEnemy()

    --[[ 优化部分A
    local i,has,objectGUID
    for i = 1, 8 do
        TargetNearestEnemy(i)
        local has,objectGUID = UnitExists("target")
        if has and objectGUID and not ObjectArray[objectGUID] then
            MPPushObject(objectGUID)
        end

        TargetNearestEnemy(i)
        local has,objectGUID = UnitExists("target")
        if has and objectGUID and not ObjectArray[objectGUID] then
            MPPushObject(objectGUID)
        end

        TargetNearestEnemy(i)
        local has,objectGUID = UnitExists("target")
        if has and objectGUID and not ObjectArray[objectGUID] then
            MPPushObject(objectGUID)
        end
    end

    -- 优化部分A+
    for i = 1, 18 do
        TargetNearestEnemy()
        has,objectGUID = UnitExists("target")
        --message( i.."="..objectGUID)
        if has then
            MPPushObject(objectGUID)
        end
    end
    ]]
    


    -- 优化部分B

    if not MPInCombat then
        -- 检查团队成员（1-40），仅在团队中时生效
        if GetNumRaidMembers() > 0 then  -- 替代 IsInRaid()
            for i = 1, 40 do
                local unit = "raid" .. i
                if UnitExists(unit) then
                    local targetUnit = unit .. "target"
                    local r, raidtargetGUID = UnitExists(targetUnit)
                    if r then
                        MPPushObject(raidtargetGUID)
                    end
                end
            end
        elseif GetNumPartyMembers() > 0 then
            -- 检查小队成员（1-4）
            for i = 1, 4 do
                local unit = "party" .. i
                if UnitExists(unit) then
                    local targetUnit = unit .. "target"
                    local p, partytargetGUID = UnitExists(targetUnit)
                    if p then
                        MPPushObject(partytargetGUID)
                    end
                end
            end
        end
    end



    -- 基础部分

    for key, value in pairs(ObjectArray) do
        if GetTime()-value < 120 then
            local t = UnitExists(key)
            if t then
                if UnitCanAttack("player", key) and not UnitIsDead(key) then        -- 这里不能去掉，目标状态可能会变化 
                    MPEmenyList[key] = true
                    -- 是否在近战距离
                    if MP_UnitXP then
                        --inMeleeRange = UnitXP("distanceBetween", "player", key, "meleeAutoAttack")
                        --if inMeleeRange and inMeleeRange==true then
                        inMeleeRange = UnitXP("distanceBetween", "player", key)
                        if inMeleeRange and inMeleeRange<range then
                            count = count + 1
                            MPNearEmenyList[key] = true

                            -- 收集斩杀线近战敌人，仅对战士有效
                            if playerClass == "WARRIOR" then
                                local percent = UnitHealth(key) / UnitHealthMax(key)
                                if percent < 0.2 then
                                    MPEmenyExecuteList[key] = true
                                end
                            end

                        end
                    else
                        inMeleeRange = CheckInteractDistance(key, 3)
                        if inMeleeRange then
                            count = count + 1
                            MPNearEmenyList[key] = true

                            -- 收集斩杀线近战敌人
                            local percent = UnitHealth(key) / UnitHealthMax(key)
                            if percent < 0.2 then
                                MPEmenyExecuteList[key] = true
                            end
                        end
                    end
                else
                    table.insert(toRemove, key)
                end
            else
                table.insert(toRemove, key)
            end

        else
            table.insert(toRemove, key)
        end

        MPMaxCount = MPMaxCount + 1
    end

    -- 循环结束后统一删除
    for _, k in ipairs(toRemove) do
        ObjectArray[k] = nil
    end

    --[[
    -- 恢复原始目标
    if targetGUID then
        TargetUnit(targetGUID)
    else
        ClearTarget()
    end
    ]]

    -- 存储计时，用于缓存，优化性能
    MPNearEmenyTimer = GetTime()
    MPNearEmeny = count

    return MPNearEmeny,MPMaxCount,MPNearEmenyList,MPEmenyExecuteList,MPEmenyList  -- 返回近战数量和整体数量，近战列表，斩杀线列表,敌人全列表
end



-- 获取目标与自己是否在近战距离
-- return 真/否
function MPGetTargetDistance(unit,range)

    unit = unit or "target";
    range = range or MPMeleeRange
    local inMeleeRange = 0

    -- 对象检测
    if not UnitExists(unit) then
        return false
    end

    -- 是否在近战距离
    if MP_UnitXP then
        if range>MPMeleeRange then
            inMeleeRange = UnitXP("distanceBetween", "player", unit)
            if not inMeleeRange then
                return false
            end
        else
            inMeleeRange = UnitXP("distanceBetween", "player", unit, "meleeAutoAttack")
            if not inMeleeRange then
                return false
            end
        end
        --print(inMeleeRange)
        --print(range)
        if inMeleeRange>range then
            return false
        end
    else

        -- 判断近战距离
        if range < 3.0 then
            inMeleeRange = CheckInteractDistance(unit, 3)
            if inMeleeRange then
                return true
            else
                return false
            end
        end
    end

    return true
end




function MPIsAutoAttack()
    return MPAutoAttack
end


function MPSendCatMsg()

    if GetTime()-MPSendCatMsgTimer>60 then

        -- reset time
        MPSendCatMsgTimer = GetTime()

        -- send message
        local name = UnitName("player")

        local inRaid = GetNumRaidMembers() > 0
        local inParty = GetNumPartyMembers() > 0

        SendAddonMessage("Cat", name.." ["..MPCatAddonVer.."]", "GUILD")
        if inRaid then
            -- 当前在团队中（可能是团队或者团队中的小队）
            SendAddonMessage("Cat", name.." ["..MPCatAddonVer.."]", "RAID")
        elseif inParty then
            -- 当前在小队中（但不是团队）
            SendAddonMessage("Cat", name.." ["..MPCatAddonVer.."]", "PARTY")
        else
            -- 单独一人
        end
        --print("cat msg")

    end

end

function MPPushPlayer(inGUID, Origin)

    PlayerArray[inGUID] = GetTime()
    PlayerArrayOrigin[inGUID] = Origin

    local toRemove = {}  -- 存储待删除的键

    for key, value in pairs(PlayerArray) do
        if GetTime()-value > 601 then
            table.insert(toRemove, key)
        end
    end

    for _, k in ipairs(toRemove) do
        PlayerArray[k] = nil
        PlayerArrayOrigin[k] = nil
    end

end

function MPPlayerList()
    local Count = 0
    local PartyCount = 0
    local RaidCount = 0
    local GuildCount = 0
    DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."Users installed CAT:")
    for key, value in pairs(PlayerArray) do
        if GetTime()-value <= 600 then
            Count = Count + 1
            if PlayerArrayOrigin[key]=="RAID" then
                DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."|cffFF7D0A"..key.." - "..PlayerArrayOrigin[key])
                RaidCount = RaidCount + 1
            elseif PlayerArrayOrigin[key]=="PARTY" then
                DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."|cffAAAFFF"..key.." - "..PlayerArrayOrigin[key])
                PartyCount = PartyCount + 1
            elseif PlayerArrayOrigin[key]=="GUILD" then
                DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."|cff00FF00"..key.." - "..PlayerArrayOrigin[key])
                GuildCount = GuildCount + 1
            else
                DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..""..key.." - "..PlayerArrayOrigin[key])
            end
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."Total: "..Count.."  |cffFF7D0ARaid: "..RaidCount.."|r  |cffAAAFFFParty: "..PartyCount.."|r  |cff00FF00Guild: "..GuildCount)
end




MPTimerID = nil

function MyCallbackFunction()
	ActionButtonDown(5)
    ActionButtonUp(5)
	print("test")
	--MPCat(4)
end

function MPAutoBegin()

	MPTimerID = UnitXP("timer", "arm", 100, 1000, "MyCallbackFunction")
	if MPTimerID then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."启动 ID="..MPTimerID)
	end

end

function MPAutoStop()
	if MPTimerID then
		UnitXP("timer", "disarm", MPTimerID)
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."关闭 ID="..MPTimerID)
	end
	MPTimerID = nil
end





