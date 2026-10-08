
UnitXP_SP3_Addon = nil; -- It's a SavedVariable, not local
UnitXP_SP3_Icon = nil; -- It's a SavedVariable, not local

UnitXP_SP3_skipPermissionCheck = false;

-- 全局变量:本地标记列表(用于同步)
UnitXP_SP3_localMarks = {};

-- 全局变量:远程标记缓存(用于避免重复渲染)
UnitXP_SP3_remoteMarks = {};

UnitXP_SP3_groupState = {
    inRaid = false,
    inParty = false,
    isLeader = false,
    isRaidLeader = false,
    isRaidAssistant = false
};

UnitXP_SP3_syncTimer = nil;
UnitXP_SP3_syncInterval = 5;

function UnitXP_SP3_updateGroupState()
    local state = UnitXP_SP3_groupState;

    state.inRaid = (GetNumRaidMembers() > 0);
    state.inParty = (GetNumPartyMembers() > 0);

    -- 检查是否是队长
    state.isLeader = (IsPartyLeader("player") == 1);

    state.isRaidLeader = false;
    state.isRaidAssistant = false;

    if state.inRaid then
        local playerName = UnitName("player");
        for i = 1, 40 do
            local name, rank = GetRaidRosterInfo(i);
            if name == playerName then
                if rank == 2 then
                    state.isRaidLeader = true;
                elseif rank == 1 then
                    state.isRaidAssistant = true;
                end
                break;
            end
        end
    end
end

local L = UNITXPSP3_LOCALE;

local function UnitXP_SP3_Print(msg)
    if not DEFAULT_CHAT_FRAME then
        return;
    end
    DEFAULT_CHAT_FRAME:AddMessage(tostring(msg));
end

-- Bindings
BINDING_HEADER_UNITXPSP3TARGETING = L["BINDING_HEADER_UNITXPSP3TARGETING"];
BINDING_NAME_UNITXPSP3NEARESTENEMY = L["BINDING_NAME_UNITXPSP3NEARESTENEMY"];
BINDING_NAME_UNITXPSP3TARGETMOSTHP = L["BINDING_NAME_UNITXPSP3TARGETMOSTHP"];
BINDING_NAME_UNITXPSP3WORLDBOSS = L["BINDING_NAME_UNITXPSP3WORLDBOSS"];
BINDING_NAME_UNITXPSP3NEXTMARKER = L["BINDING_NAME_UNITXPSP3NEXTMARKER"];
BINDING_NAME_UNITXPSP3PREVIOUSMARKER = L["BINDING_NAME_UNITXPSP3PREVIOUSMARKER"];
BINDING_NAME_UNITXPSP3NEXTENEMY = L["BINDING_NAME_UNITXPSP3NEXTENEMY"];
BINDING_NAME_UNITXPSP3PREVIOUSENEMY = L["BINDING_NAME_UNITXPSP3PREVIOUSENEMY"];
BINDING_NAME_UNITXPSP3NEXTMELEE = L["BINDING_NAME_UNITXPSP3NEXTMELEE"];
BINDING_NAME_UNITXPSP3PREVIOUSMELEE = L["BINDING_NAME_UNITXPSP3PREVIOUSMELEE"];
BINDING_HEADER_UNITXPSP3UTILITIES = L["BINDING_HEADER_UNITXPSP3UTILITIES"];
BINDING_NAME_UNITXPSP3RAISECAMERA = L["BINDING_NAME_UNITXPSP3RAISECAMERA"];
BINDING_NAME_UNITXPSP3LOWERCAMERA = L["BINDING_NAME_UNITXPSP3LOWERCAMERA"];
BINDING_NAME_UNITXPSP3LEFTCAMERA = L["BINDING_NAME_UNITXPSP3LEFTCAMERA"];
BINDING_NAME_UNITXPSP3RIGHTCAMERA = L["BINDING_NAME_UNITXPSP3RIGHTCAMERA"];
BINDING_NAME_UNITXPSP3RESETCAMERA = L["BINDING_NAME_UNITXPSP3RESETCAMERA"];
BINDING_NAME_UNITXPSP3TOGGLEMODERNNAMEPLATEDISTANCE = L["BINDING_NAME_UNITXPSP3TOGGLEMODERNNAMEPLATEDISTANCE"];
BINDING_NAME_UNITXPSP3TOGGLEPRIORITIZETARGETNAMEPLATE = L["BINDING_NAME_UNITXPSP3TOGGLEPRIORITIZETARGETNAMEPLATE"];
BINDING_NAME_UNITXPSP3TOGGLEPRIORITIZEMARKEDNAMEPLATE = L["BINDING_NAME_UNITXPSP3TOGGLEPRIORITIZEMARKEDNAMEPLATE"];
BINDING_HEADER_UNITXPSP3MARKS = L["BINDING_HEADER_UNITXPSP3MARKS"];
BINDING_NAME_UNITXPSP3MARKRED = L["BINDING_NAME_UNITXPSP3MARKRED"];
BINDING_NAME_UNITXPSP3MARKYELLOW = L["BINDING_NAME_UNITXPSP3MARKYELLOW"];
BINDING_NAME_UNITXPSP3MARKGREEN = L["BINDING_NAME_UNITXPSP3MARKGREEN"];
BINDING_NAME_UNITXPSP3MARKBLUE = L["BINDING_NAME_UNITXPSP3MARKBLUE"];
BINDING_NAME_UNITXPSP3MARKPURPLE = L["BINDING_NAME_UNITXPSP3MARKPURPLE"];
BINDING_NAME_UNITXPSP3MARKORANGE = L["BINDING_NAME_UNITXPSP3MARKORANGE"];
BINDING_NAME_UNITXPSP3MARKWHITE = L["BINDING_NAME_UNITXPSP3MARKWHITE"];
BINDING_NAME_UNITXPSP3CLEARALLMARKS = L["BINDING_NAME_UNITXPSP3CLEARALLMARKS"];

local UNITXPSP3TOOLTIP = L["UnitXP SP3 is running"];

local libIcon = LibStub("LibDBIcon-1.0");
local libData = LibStub("LibDataBroker-1.1");
local skipUpdateMessage = false;

function UnitXP_SP3_OnLoad()
    xpsp3Frame:RegisterEvent("ADDON_LOADED");
end

local function UnitXP_SP3_flashTaskbarIcon()
    local test, result = pcall(UnitXP, "notify", "taskbarIcon");

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"notify taskbarIcon\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return nil;
    end

    return result;
end

function UnitXP_SP3_getAuraStack(unitID)
    local test, result = pcall(UnitXP, "getAuraStack", unitID or "player");

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"getAuraStack\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return nil;
    end

    if result then
        local count = getn(result);
        UnitXP_SP3_Print(L["Aura Count: "] .. count);
        for i = 1, count do
            local aura = result[i];
            UnitXP_SP3_Print(i .. L[". SpellID="] .. aura.spellId .. L[", Stack="] .. aura.stack);
        end
    else
        UnitXP_SP3_Print(L["No auras found or unit not found"]);
    end

    return result;
end

local function UnitXP_SP3_playSystemDefaultSound()
    local test, result = pcall(UnitXP, "notify", "systemSound", "SystemDefault");

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"notify systemSound\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return nil;
    end

    return result;
end

local function UnitXP_SP3_FPScap(cap)
    local test, result = pcall(UnitXP, "FPScap", cap);

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"FPScap\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return UnitXP_SP3_Addon["FPScap"];
    end

    UnitXP_SP3_Addon["FPScap"] = result;
    return UnitXP_SP3_Addon["FPScap"];
end

local function UnitXP_SP3_backgroundFPScap(cap)
    local test, result = pcall(UnitXP, "backgroundFPScap", cap);

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"backgroundFPScap\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return UnitXP_SP3_Addon["backgroundFPScap"];
    end

    UnitXP_SP3_Addon["backgroundFPScap"] = result;
    return UnitXP_SP3_Addon["backgroundFPScap"];
end

local function UnitXP_SP3_setTargetingRangeConeFactor(factor)
    local test, result = pcall(UnitXP, "target", "rangeCone", factor);

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"target rangeCone\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return UnitXP_SP3_Addon["targetingRangeConeFactor"];
    end

    UnitXP_SP3_Addon["targetingRangeConeFactor"] = result;
    return UnitXP_SP3_Addon["targetingRangeConeFactor"];
end

local function UnitXP_SP3_setModernNameplateDistance(enable)
    local test, result = pcall(UnitXP, "modernNameplateDistance", enable);

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"modernNameplateDistance\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return false;
    end
    return result;
end

local function UnitXP_SP3_setHideEXPtext(enable)
    local test, result = pcall(UnitXP, "hideEXPtext", enable);

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"hideEXPtext\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return false;
    end
    return result;
end

local function UnitXP_SP3_combatTextSP3_debugText()
    local test, result, scene_isEnabled = pcall(UnitXP, "combatTextSP3", "debugText");
    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"combatTextSP3 debugText\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return false;
    end

    UnitXP_SP3_Print(L["UnitXP_SP3 floating combat text debug"] .. ": " .. tostring(result));
end

local function UnitXP_SP3_combatTextSP3(enable)
    local test, result, scene_isEnabled = pcall(UnitXP, "combatTextSP3", enable);

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"combatTextSP3\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return false;
    end

    if type(result) ~= "boolean" then
        result = false;
        UnitXP_SP3_Print(
            L["UnitXP_SP3.dll failed to execute"] .. " \"combatTextSP3\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
    end

    if type(scene_isEnabled) == "boolean" and scene_isEnabled == false then
        UnitXP_SP3_combatTextSP3_debugText();
    end

    return result;
end

local function UnitXP_SP3_combatTextSP3_fontName(name)
    local test, result, scene_isEnabled = pcall(UnitXP, "combatTextSP3", "setFontName", name);

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"combatTextSP3 setFontName\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return UnitXP_SP3_Addon["combatTextSP3_fontName"];
    end

    if type(result) ~= "string" then
        result = "Cambria";
        UnitXP_SP3_Print(
            L["UnitXP_SP3.dll failed to execute"] .. " \"combatTextSP3 setFontName\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
    end

    if type(scene_isEnabled) == "boolean" and scene_isEnabled == false then
        UnitXP_SP3_combatTextSP3_debugText();
    end

    UnitXP_SP3_Addon["combatTextSP3_fontName"] = result;
    return UnitXP_SP3_Addon["combatTextSP3_fontName"];
end

local function UnitXP_SP3_setPrioritizeTargetNameplate(enable)
    local test, result = pcall(UnitXP, "prioritizeTargetNameplate", enable);

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"prioritizeTargetNameplate\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return false;
    end
    return result;
end

local function UnitXP_SP3_setPrioritizeMarkedNameplate(enable)
    local test, result = pcall(UnitXP, "prioritizeMarkedNameplate", enable);

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"prioritizeMarkedNameplate\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return false;
    end
    return result;
end

local function UnitXP_SP3_setNameplateCombatFilter(enable)
    local test, result = pcall(UnitXP, "nameplateCombatFilter", enable);

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"nameplateCombatFilter\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return false;
    end
    return result;
end

local function UnitXP_SP3_setHideCritterNameplate(enable)
    local test, result = pcall(UnitXP, "hideCritterNameplate", enable);

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"hideCritterNameplate\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return false;
    end
    return result;
end

local function UnitXP_SP3_setShowInCombatNameplatesNearPlayer(enable)
    local test, result = pcall(UnitXP, "showInCombatNameplatesNearPlayer", enable);

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"showInCombatNameplatesNearPlayer\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return false;
    end
    return result;
end

local function UnitXP_SP3_setWeatherAlwaysClear(enable)
    local test, result = pcall(UnitXP, "weatherAlwaysClear", enable);

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"weatherAlwaysClear\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return false;
    end
    return result;
end

local function UnitXP_SP3_screenshotQuality(perfect)
    local test, result = pcall(UnitXP, "screenshot", perfect);

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"screenshot\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return false;
    end
    return result;
end

local function UnitXP_SP3_setCameraPinHeight(enable)
    local test, result = pcall(UnitXP, "cameraPinHeight", enable);

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"cameraPinHeight\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return false;
    end
    return result;
end

local function UnitXP_SP3_setCameraHeight(value)
    local test, result = pcall(UnitXP, "cameraVerticalDisplacement", "set", value);

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"cameraVerticalDisplacement set\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return UnitXP_SP3_Addon["cameraHeight"];
    end

    UnitXP_SP3_Addon["cameraHeight"] = result;
    return UnitXP_SP3_Addon["cameraHeight"];
end

local function UnitXP_SP3_setCameraPitch(value)
    local test, result = pcall(UnitXP, "cameraPitch", "set", value);

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"cameraPitch set\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return UnitXP_SP3_Addon["cameraPitch"];
    end

    UnitXP_SP3_Addon["cameraPitch"] = result;
    return UnitXP_SP3_Addon["cameraPitch"];
end

local function UnitXP_SP3_setCameraHorizontalDisplacement(value)
    local test, result = pcall(UnitXP, "cameraHorizontalDisplacement", "set", value);

    if not test then
        if not skipUpdateMessage then
            skipUpdateMessage = true;
            UnitXP_SP3_Print(
                L["UnitXP_SP3.dll failed to execute"] .. " \"cameraHorizontalDisplacement set\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
        end
        return UnitXP_SP3_Addon["cameraHorizontalDisplacement"];
    end

    UnitXP_SP3_Addon["cameraHorizontalDisplacement"] = result;
    return UnitXP_SP3_Addon["cameraHorizontalDisplacement"];
end

function UnitXP_SP3_resetCamera()
    UnitXP_SP3_setCameraHorizontalDisplacement(0);
    UnitXP_SP3_setCameraHeight(0);
    UnitXP_SP3_setCameraPitch(0);
    return 0;
end

function UnitXP_SP3_leftPlayer()
    return UnitXP_SP3_setCameraHorizontalDisplacement(UnitXP_SP3_Addon["cameraHorizontalDisplacement"] + 0.11);
end

function UnitXP_SP3_rightPlayer()
    return UnitXP_SP3_setCameraHorizontalDisplacement(UnitXP_SP3_Addon["cameraHorizontalDisplacement"] - 0.11);
end

function UnitXP_SP3_raiseCameraHeight()
    return UnitXP_SP3_setCameraHeight(UnitXP_SP3_Addon["cameraHeight"] + 0.11);
end

function UnitXP_SP3_lowerCameraHeight()
    return UnitXP_SP3_setCameraHeight(UnitXP_SP3_Addon["cameraHeight"] - 0.11);
end

function UnitXP_SP3_cameraPitchUp()
    return UnitXP_SP3_setCameraPitch(UnitXP_SP3_Addon["cameraPitch"] + 0.011);
end

function UnitXP_SP3_cameraPitchDown()
    return UnitXP_SP3_setCameraPitch(UnitXP_SP3_Addon["cameraPitch"] - 0.011);
end

function UnitXP_SP3_hasRaidLeaderOrAssistant()
    local state = UnitXP_SP3_groupState;

    if not state.inRaid and not state.inParty then
        return true;
    end

    if state.inRaid then
        return state.isRaidLeader or state.isRaidAssistant;
    end

    if state.inParty then
        return (IsPartyLeader("player") == 1);
    end

    return false;
end

function UnitXP_SP3_shouldSyncMarks()
    local state = UnitXP_SP3_groupState;

    if not state.inRaid and not state.inParty then
        return false;
    end

    if state.inRaid then
        -- 只有团长可以同步(助理不能)
        local canSync = state.isRaidLeader;
        return canSync;
    end

    if state.inParty then
        local canSync = (IsPartyLeader("player") == 1);
        return canSync;
    end

    return false;
end

-- 同步所有标记给其他玩家
function UnitXP_SP3_syncAllMarks()
    if not UnitXP_SP3_shouldSyncMarks() then
        return;
    end

    -- 确定频道
    local channel = "PARTY";
    if GetNumRaidMembers() > 0 then
        channel = "RAID";
    end

    local markCount = 0;
    local skipCount = 0;
    for colorName, markData in pairs(UnitXP_SP3_localMarks) do
        local cachedMark = UnitXP_SP3_remoteMarks[colorName];
        local needSync = true;

        if cachedMark then
            local dx = math.abs(cachedMark.x - markData.x);
            local dy = math.abs(cachedMark.y - markData.y);
            local dz = math.abs(cachedMark.z - markData.z);

            if dx < 0.1 and dy < 0.1 and dz < 0.1 then
                needSync = false;
                skipCount = skipCount + 1;
            end
        end

        if needSync then
            local message = string.format("MARK %s %.2f %.2f %.2f", colorName, markData.x, markData.y, markData.z);
            SendAddonMessage("UnitXPSP3", message, channel);
            markCount = markCount + 1;
        end
    end

end

local UnitXP_SP3_SyncTimer = {
    frame = nil,
    nextSync = 0,
    lastDebugTime = 0
}

local function UnitXP_SP3_SyncTimer_OnUpdate(self, elapsed)
    local now = GetTime()
    local timer = UnitXP_SP3_SyncTimer
    local largeGap = false
    if timer._lastOntime then
        local dt = now - timer._lastOntime
        if dt > 2.5 then
            largeGap = true
        end
    end
    timer._lastOntime = now

    if not elapsed or type(elapsed) ~= "number" then
        elapsed = 0.016
    elseif elapsed < 0.001 then
        elapsed = 0.001
    elseif elapsed > 0.1 then
        elapsed = 0.1
    end

    if not timer.hpBar and UnitXP_SP3_Addon and UnitXP_SP3_Addon["selfHealthBar"] then
        UnitXP_SP3_InitSyncTimer()
    end

    if timer.hpBar and UnitXP_SP3_Addon and UnitXP_SP3_Addon["selfHealthBar"] then
        local success, errorMessage = pcall(function()
            -- 查询玩家数据
            local isValid, screenX, screenY, inRange, curHP, maxHP, curPower, maxPower, powerType, rawP1, rawMP1, rawP2, rawMP2, rawP3, rawMP3, rawP4, rawMP4, rawP5, rawMP5 = UnitXP("selfHealthBarQuery")

            local timer = UnitXP_SP3_SyncTimer

            local playerClass = timer.cachedPlayerClass
            local currentPowerType = timer.cachedPowerType
            local screenW = timer.cachedScreenW
            local screenH = timer.cachedScreenH
            if isValid and screenX and screenY and maxHP and maxHP > 0 and curHP then
                local inCombat = timer.cachedInCombat

                if timer.hpCurrentValue == nil or timer.hpTargetValue == nil then
                    timer.hpCurrentValue = 1
                    timer.hpTargetValue = 1
                    timer.manaCurrentValue = 0
                    timer.manaTargetValue = 0
                    timer.powerCurrentValue = 1
                    timer.powerTargetValue = 1
                end

                local alpha = 1.0
                if not inCombat then
                    alpha = 0.5
                end

                local bw = 160
                local hpH = 11
                local pwH = 7

                -- 使用C++侧返回的归一化坐标转换为屏幕坐标
                -- screenWidth/screenHeight 已在函数开头缓存为 screenW/screenH

                -- 计算血量百分比
                local hpPct = curHP / maxHP
                if hpPct > 1 then hpPct = 1 end

                if screenX >= 0 and screenX <= 1 and screenY >= 0 and screenY <= 1 then
                    local offsetX = 0
                    local offsetY = -40
                    local px = screenX * screenW + offsetX
                    local py = (1 - screenY) * screenH + offsetY

                    if px >= 0 and px <= screenW and py >= 0 and py <= screenH then
                        -- === 血量条 ===
                        timer.hpTargetValue = hpPct

                        local dt = elapsed * (timer.interpolationSpeed or 4)
                        timer.hpCurrentValue = timer.hpCurrentValue + (timer.hpTargetValue - timer.hpCurrentValue) * (1 - math.exp(-dt * 2))
                        timer.hpCurrentValue = math.min(math.max(timer.hpCurrentValue, 0), 1)

                        if math.abs(timer.hpCurrentValue - timer.hpTargetValue) < 0.02 then
                            timer.hpCurrentValue = timer.hpTargetValue
                        end

                        timer.hpBar:SetValue(timer.hpCurrentValue)

                        if timer.hpBar.spark then
                            local hpWidth = timer.hpBar:GetWidth()
                            local hpSparkPos = timer.hpTargetValue * hpWidth
                            timer.hpBar.spark:ClearAllPoints()
                            timer.hpBar.spark:SetPoint("CENTER", timer.hpBar, "LEFT", hpSparkPos, 0)
                        end

                        timer.container:SetPoint("CENTER", UIParent, "BOTTOMLEFT", px, py)
                        timer.container:Show()
                        timer.hpBar:Show()
                    else
                        local t = UnitXP_SP3_SyncTimer
                        if t.hpBar then t.hpBar:Hide() end
                        if t.powerBar then t.powerBar:Hide() end
                        if t.manaBar then t.manaBar:Hide() end
                        if t.cpContainer then t.cpContainer:Hide() end
                        if t.manaCursor then t.manaCursor:Hide() end
                        if t.container then t.container:Hide() end
                    end
                else
                    local t = UnitXP_SP3_SyncTimer
                    if t.hpBar then t.hpBar:Hide() end
                    if t.powerBar then t.powerBar:Hide() end
                    if t.manaBar then t.manaBar:Hide() end
                    if t.cpContainer then t.cpContainer:Hide() end
                    if t.manaCursor then t.manaCursor:Hide() end
                    if t.container then t.container:Hide() end
                end

                local r, g
                if hpPct and hpPct > 0.6 then
                    r = (1 - hpPct) / 0.4
                    g = 1
                elseif hpPct and hpPct > 0.3 then
                    r = 1
                    g = (hpPct - 0.3) / 0.3
                else
                    r = 1
                    g = 0
                end
                if r < 0 then r = 0 end
                if g < 0 then g = 0 end
                timer.hpBar:SetStatusBarColor(r, g, 0, alpha)

                -- playerClass 已在函数开头缓存

                local showPowerBar = false
                if playerClass == "ROGUE" or playerClass == "WARRIOR" or (playerClass == "DRUID" and (currentPowerType == 1 or currentPowerType == 2)) then
                    local powerToUse, maxPowerToUse
                    if playerClass == "ROGUE" or (playerClass == "DRUID" and currentPowerType == 2) then
                        powerToUse = rawP4
                        maxPowerToUse = rawMP4
                    elseif playerClass == "WARRIOR" then
                        powerToUse = rawP2
                        maxPowerToUse = rawMP2
                    end

                    local pwPct = 1
                    if maxPowerToUse and maxPowerToUse > 0 then
                        pwPct = powerToUse / maxPowerToUse
                        if pwPct > 1 then pwPct = 1 end
                        if pwPct < 0 then pwPct = 0 end
                    end



                    timer.powerTargetValue = pwPct

                    local dt = elapsed * (timer.interpolationSpeed or 4)
                    timer.powerCurrentValue = timer.powerCurrentValue + (timer.powerTargetValue - timer.powerCurrentValue) * (1 - math.exp(-dt * 2))
                    timer.powerCurrentValue = math.min(math.max(timer.powerCurrentValue, 0), 1)

                    if math.abs(timer.powerCurrentValue - timer.powerTargetValue) < 0.02 then
                        timer.powerCurrentValue = timer.powerTargetValue
                    end

                    timer.powerBar:SetValue(timer.powerCurrentValue)
                    timer.powerBar:Show()

                    if timer.powerBar.spark then
                        local pwWidth = timer.powerBar:GetWidth()
                        local pwSparkPos = timer.powerCurrentValue * pwWidth
                        timer.powerBar.spark:ClearAllPoints()
                        timer.powerBar.spark:SetPoint("CENTER", timer.powerBar, "LEFT", pwSparkPos, 0)
                    end

                    showPowerBar = true
                else
                    timer.powerBar:Hide()
                end

                -- 能量颜色
                local pwR, pwG, pwB
                if playerClass == "ROGUE" or (playerClass == "DRUID" and currentPowerType == 2) then
                    pwR, pwG, pwB = 1, 0.9, 0.1
                elseif playerClass == "WARRIOR" then
                    pwR, pwG, pwB = 1, 0.2, 0
                else
                    pwR, pwG, pwB = 0.2, 0.5, 1
                end
                timer.powerBar:SetStatusBarColor(pwR, pwG, pwB, alpha)

                local showManaBar = false
                if playerClass == "MAGE" or playerClass == "PRIEST" or playerClass == "WARLOCK" or
                   playerClass == "SHAMAN" or playerClass == "PALADIN" or playerClass == "HUNTER" or
                   playerClass == "DRUID" then
                    -- selfHealthBarQuery 已返回 curPower/maxPower，法力偏移独立于怒气/能量，所有姿态均正确
                    if maxPower and maxPower > 0 then
                        local manaPct = curPower / maxPower
                        if manaPct > 1 then manaPct = 1 end

                        timer.manaTargetValue = manaPct

                        local dt = elapsed * (timer.interpolationSpeed or 4)
                        timer.manaCurrentValue = timer.manaCurrentValue + (timer.manaTargetValue - timer.manaCurrentValue) * (1 - math.exp(-dt * 2))
                        timer.manaCurrentValue = math.min(math.max(timer.manaCurrentValue, 0), 1)

                        if math.abs(timer.manaCurrentValue - timer.manaTargetValue) < 0.02 then
                            timer.manaCurrentValue = timer.manaTargetValue
                        end

                        timer.manaBar:SetValue(timer.manaCurrentValue)

                        if timer.manaBar.spark then
                            local mnWidth = timer.manaBar:GetWidth()
                            local mnSparkPos = timer.manaCurrentValue * mnWidth
                            timer.manaBar.spark:ClearAllPoints()
                            timer.manaBar.spark:SetPoint("CENTER", timer.manaBar, "LEFT", mnSparkPos, 0)
                        end

                        timer.manaBar:SetStatusBarColor(0.2, 0.3, 1, alpha)
                        timer.manaBar:Show()
                        showManaBar = true
                    else
                        timer.manaBar:Hide()
                        showManaBar = false
                    end
                else
                    timer.manaBar:Hide()
                    showManaBar = false
                end

                local baseYOffset = 0

                local comboPointHeight = 0
                local comboPointOffset = 0
                if (playerClass == "ROGUE" or (playerClass == "DRUID" and currentPowerType == 2)) then
                    local cpCount = timer.lastCpCount or 0
                    if cpCount and cpCount > 0 then
                        comboPointHeight = 6
                        comboPointOffset = 6
                    end
                end


                timer.hpBar:ClearAllPoints()
                timer.hpBar:SetPoint("TOPLEFT", timer.container, "TOPLEFT", 0, -comboPointOffset)

                if comboPointOffset > 0 then
                    timer.cpContainer:ClearAllPoints()
                    timer.cpContainer:SetPoint("TOPLEFT", timer.container, "TOPLEFT", 0, 0)
                    timer.cpContainer:Show()
                    for i = 1, 5 do
                        if timer.cpTexs[i] then
                            if i <= timer.lastCpCount then
                                timer.cpTexs[i]:Show()
                            else
                                timer.cpTexs[i]:Hide()
                            end
                        end
                    end
                else
                    timer.cpContainer:Hide()
                end

                -- 锚定逻辑：德鲁伊布局为 hpBar → manaBar → powerBar；其他职业为 hpBar → powerBar → manaBar
                if playerClass == "DRUID" then
                    -- 德鲁伊：蓝条始终显示（在血条下方），能量/怒气条在蓝条下方
                    if showManaBar then
                        timer.manaBar:ClearAllPoints()
                        timer.manaBar:SetPoint("TOPLEFT", timer.hpBar, "BOTTOMLEFT", 0, 0)
                    end
                    if showPowerBar then
                        timer.powerBar:ClearAllPoints()
                        timer.powerBar:SetPoint("TOPLEFT", timer.manaBar, "BOTTOMLEFT", 0, 0)
                    end
                else
                    -- 其他职业：能量/怒气条在血条下方，蓝条在能量条下方
                    if showPowerBar then
                        timer.powerBar:ClearAllPoints()
                        timer.powerBar:SetPoint("TOPLEFT", timer.hpBar, "BOTTOMLEFT", 0, 0)
                    end
                    if showManaBar then
                        timer.manaBar:ClearAllPoints()
                        timer.manaBar:SetPoint("TOPLEFT", showPowerBar and timer.powerBar or timer.hpBar, "BOTTOMLEFT", 0, 0)
                    end
                end

                -- 设置容器总高度（含连击点条高度）
                local totalHeight = comboPointOffset + hpH
                if playerClass == "DRUID" then
                    if showManaBar then totalHeight = totalHeight + pwH end
                    if showPowerBar then totalHeight = totalHeight + pwH end
                else
                    if showPowerBar then totalHeight = totalHeight + pwH end
                    if showManaBar then totalHeight = totalHeight + pwH end
                end

                timer.container:SetHeight(totalHeight)


                local isManaUser = (playerClass == "MAGE" or playerClass == "PRIEST" or
                                   playerClass == "SHAMAN" or playerClass == "PALADIN" or
                                   playerClass == "HUNTER" or playerClass == "WARLOCK" or
                                   playerClass == "DRUID")
                local cursorPct = 0
                local bw = 160

                local currentMana = math.floor(curPower) or 0
                local lastMana = timer.lastManaValue or currentMana
                local manaDiff = currentMana - lastMana

                -- === 法力用户回蓝逻辑 ===
                if isManaUser then
                    local mana = curPower or 0
                    local maxMana = maxPower or 1
                    local now = GetTime()

                    if mana >= maxMana or UnitIsDeadOrGhost("player") then
                        timer.tickStart = nil
                    else
                        local spiritTick = 2

                        if not largeGap then
                        if manaDiff < 0 then
                            timer.tickStart = now
                            timer.tickMax = 5
                            timer.castNoRegenUntil = now + 5
                        elseif manaDiff > 0 and (not timer.castNoRegenUntil or now >= timer.castNoRegenUntil) then
                            timer.tickStart = now
                            timer.tickMax = spiritTick
                            timer.castNoRegenUntil = nil
                        end
                        end

                        -- 计算光标位置
                        if timer.tickStart and timer.tickMax then
                            local elapsed = now - timer.tickStart
                            -- 5秒规则光标：走完一个周期后停止，等回蓝事件重新启动
                            if timer.tickMax == 5 and elapsed >= 5 then
                                timer.tickStart = nil
                                timer.tickMax = nil
                                cursorPct = 0
                            else
                                local cycleTime = elapsed - math.floor(elapsed / timer.tickMax) * timer.tickMax
                                cursorPct = cycleTime / timer.tickMax
                            end
                        end
                    end

                    -- 光标渲染（蓝条用蓝色）
                    if timer.tickStart and timer.tickMax and timer.manaCursor then
                        local cursorX = cursorPct * bw
                        timer.manaCursor:ClearAllPoints()
                        if timer.manaBar then
                            timer.manaCursor:SetVertexColor(1, 1, 1, 1)
                            timer.manaCursor:SetPoint("CENTER", timer.manaBar, "LEFT", cursorX, 0)
                            timer.manaCursor:Show()
                        else
                            timer.manaCursor:Hide()
                        end
                    elseif timer.manaCursor then
                        timer.manaCursor:Hide()
                    end

                    timer.lastManaValue = currentMana

                -- === 能量用户(盗贼/猫德)回能逻辑 ===
                elseif playerClass == "ROGUE" or (playerClass == "DRUID" and currentPowerType == 2) then
                    local power = math.floor(rawP4) or 0
                    local maxPower = math.floor(rawMP4) or 1
                    local lastPower = timer.lastPowerValue or power
                    local powerDiff = power - lastPower

                    -- Energy cursor logic only (powerBar SetValue/Show already done above)
                                        if not UnitIsDeadOrGhost("player") then
                        if powerDiff > 0 then
                            timer.tickStart = now
                            timer.tickMax = 2
                        end
                        if timer.manaCursor and timer.tickStart then
                            if timer.manaCursor:GetParent() ~= timer.powerBar then
                                timer.manaCursor:SetParent(timer.powerBar)
                            end
                            local elapsed2 = now - timer.tickStart
                            cursorPct = elapsed2 - math.floor(elapsed2 / 2) * 2
                            cursorPct = cursorPct / 2
                            timer.manaCursor:ClearAllPoints()
                            timer.manaCursor:SetVertexColor(1, 1, 1, 1)
                            timer.manaCursor:SetPoint("CENTER", timer.powerBar, "LEFT", cursorPct * timer.powerBar:GetWidth(), 0)
                            timer.manaCursor:Show()
                        end
                    end
                    timer.lastPowerValue = power
                -- No cursor for other resource types (rage, focus)
                else
                    if timer.manaCursor then timer.manaCursor:Hide() end
                end
            else
                if timer.hpBar then timer.hpBar:Hide() end
                if timer.powerBar then timer.powerBar:Hide() end
                if timer.manaBar then timer.manaBar:Hide() end
                if timer.cpContainer then timer.cpContainer:Hide() end
                if timer.manaCursor then timer.manaCursor:Hide() end
                if timer.container then timer.container:Hide() end
            end
        end)
    else
        -- 未启用或StatusBar未初始化,确保所有条隐藏
        if UnitXP_SP3_SyncTimer.hpBar then
            UnitXP_SP3_SyncTimer.hpBar:Hide()
            UnitXP_SP3_SyncTimer.powerBar:Hide()
            UnitXP_SP3_SyncTimer.manaBar:Hide()
            UnitXP_SP3_SyncTimer.cpContainer:Hide()
            UnitXP_SP3_SyncTimer.manaCursor:Hide()
        end
    end

    if not UnitXP_SP3_SyncTimer.nextSync then
        return
    end

    if now < UnitXP_SP3_SyncTimer.nextSync then
        return
    end

    local hasLocalMarks = next(UnitXP_SP3_localMarks) ~= nil
    local hasRemoteMarks = next(UnitXP_SP3_remoteMarks) ~= nil
    local hasMarks = hasLocalMarks or hasRemoteMarks

    if not hasMarks then
        UnitXP_SP3_SyncTimer.nextSync = now + UnitXP_SP3_syncInterval;
        return;
    end

    local isLeader = (IsPartyLeader("player") == 1);

    if isLeader then
        UnitXP_SP3_syncAllMarks();
    end

    -- 计算下次同步时间
    UnitXP_SP3_SyncTimer.nextSync = now + UnitXP_SP3_syncInterval;
end

local function UnitXP_SP3_InitSyncTimer()
    if not UnitXP_SP3_SyncTimer.frame then
        UnitXP_SP3_SyncTimer.frame = CreateFrame("Frame", "UnitXP_SP3_SyncTimer", UIParent)
        UnitXP_SP3_SyncTimer.frame:SetScript("OnUpdate", UnitXP_SP3_SyncTimer_OnUpdate)
        UnitXP_SP3_SyncTimer.nextSync = GetTime() + UnitXP_SP3_syncInterval
        UnitXP_SP3_SyncTimer.lastDebugTime = 0
    end

    -- 初始化缓存变量（避免每帧调用API）
    local _, cachedPlayerClass = UnitClass("player")
    UnitXP_SP3_SyncTimer.cachedPlayerClass = cachedPlayerClass
    UnitXP_SP3_SyncTimer.cachedPowerType = UnitPowerType("player")
    UnitXP_SP3_SyncTimer.cachedScreenW = GetScreenWidth()
    UnitXP_SP3_SyncTimer.cachedScreenH = GetScreenHeight()
    UnitXP_SP3_SyncTimer.cachedInCombat = UnitAffectingCombat("player")

    if not UnitXP_SP3_Addon or not UnitXP_SP3_Addon["selfHealthBar"] then
        return
    end

    if UnitXP_SP3_SyncTimer.hpBar then
        return
    end

    -- 定义多种材质选项
    UnitXP_SP3_SyncTimer.barTextures = {
        "Interface\\TargetingFrame\\UI-StatusBar",
        "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
        "Interface\\Buttons\\WHITE8X8",
        "Interface\\AddOns\\UnitXP_SP3_Addon\\Pic\\bar_1",
        "Interface\\AddOns\\UnitXP_SP3_Addon\\Pic\\bar_2",
        "Interface\\AddOns\\UnitXP_SP3_Addon\\Pic\\bar_3"
    }
    if not UnitXP_SP3_SyncTimer.currentTextureIndex then
        if UnitXP_SP3_Addon and UnitXP_SP3_Addon["resourceBarTextureIndex"] then
            UnitXP_SP3_SyncTimer.currentTextureIndex = UnitXP_SP3_Addon["resourceBarTextureIndex"]
        else
            UnitXP_SP3_SyncTimer.currentTextureIndex = 1
        end
    end

    local barTex = UnitXP_SP3_SyncTimer.barTextures[UnitXP_SP3_SyncTimer.currentTextureIndex]
    local bw = 160
    local hpH = 11
    local pwH = 7

    if not UnitXP_SP3_SyncTimer.container then
        UnitXP_SP3_SyncTimer.container = CreateFrame("Frame", "UnitXP_SP3_Container", UIParent)
        UnitXP_SP3_SyncTimer.container:SetWidth(bw)
        UnitXP_SP3_SyncTimer.container:SetHeight(hpH + pwH * 2 + 10)
        UnitXP_SP3_SyncTimer.container:ClearAllPoints()
        UnitXP_SP3_SyncTimer.container:SetPoint("CENTER", UIParent, "TOPLEFT", 100, 100)
        UnitXP_SP3_SyncTimer.container:Show()
    end

    -- 血量条
    if not UnitXP_SP3_SyncTimer.hpBar then
        UnitXP_SP3_SyncTimer.hpBar = CreateFrame("StatusBar", "UnitXP_SP3_hpBar", UnitXP_SP3_SyncTimer.container)
        UnitXP_SP3_SyncTimer.hpBar:SetWidth(bw)
        UnitXP_SP3_SyncTimer.hpBar:SetHeight(hpH)
        UnitXP_SP3_SyncTimer.hpBar:SetFrameStrata("MEDIUM")
        UnitXP_SP3_SyncTimer.hpBar:SetMinMaxValues(0, 1)
        UnitXP_SP3_SyncTimer.hpBar:SetValue(1)
        UnitXP_SP3_SyncTimer.hpBar:SetStatusBarTexture(barTex)
        local hpBg = UnitXP_SP3_SyncTimer.hpBar:CreateTexture(nil, "BACKGROUND")
        hpBg:SetAllPoints()
        hpBg:SetTexture(barTex)
        hpBg:SetVertexColor(0.15, 0.15, 0.15, 0.5)
        UnitXP_SP3_SyncTimer.hpBar.background = hpBg
        UnitXP_SP3_SyncTimer.hpBar:SetPoint("TOPLEFT", UnitXP_SP3_SyncTimer.container, "TOPLEFT", 0, 0)

        -- 创建血量条光标
        local hpSpark = UnitXP_SP3_SyncTimer.hpBar:CreateTexture(nil, "OVERLAY")
        hpSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        hpSpark:SetWidth(16)
        hpSpark:SetHeight(hpH * 2)
        hpSpark:SetBlendMode("ADD")
        UnitXP_SP3_SyncTimer.hpBar.spark = hpSpark
    end

    if not UnitXP_SP3_SyncTimer.powerBar then
        UnitXP_SP3_SyncTimer.powerBar = CreateFrame("StatusBar", "UnitXP_SP3_powerBar", UnitXP_SP3_SyncTimer.container)
        UnitXP_SP3_SyncTimer.powerBar:SetWidth(bw)
        UnitXP_SP3_SyncTimer.powerBar:SetHeight(pwH)
        UnitXP_SP3_SyncTimer.powerBar:SetFrameStrata("MEDIUM")
        UnitXP_SP3_SyncTimer.powerBar:SetMinMaxValues(0, 1)
        UnitXP_SP3_SyncTimer.powerBar:SetValue(1)
        UnitXP_SP3_SyncTimer.powerBar:SetStatusBarTexture(barTex)
        local pwBg = UnitXP_SP3_SyncTimer.powerBar:CreateTexture(nil, "BACKGROUND")
        pwBg:SetAllPoints()
        pwBg:SetTexture(barTex)
        pwBg:SetVertexColor(0.15, 0.15, 0.15, 0.5)
        UnitXP_SP3_SyncTimer.powerBar.background = pwBg
        UnitXP_SP3_SyncTimer.powerBar:SetPoint("TOPLEFT", UnitXP_SP3_SyncTimer.hpBar, "BOTTOMLEFT", 0, 0)

        local pwSpark = UnitXP_SP3_SyncTimer.powerBar:CreateTexture(nil, "OVERLAY")
        pwSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        pwSpark:SetWidth(16)
        pwSpark:SetHeight(pwH * 2)
        pwSpark:SetBlendMode("ADD")
        UnitXP_SP3_SyncTimer.powerBar.spark = pwSpark
    end

    if not UnitXP_SP3_SyncTimer.manaBar then
        UnitXP_SP3_SyncTimer.manaBar = CreateFrame("StatusBar", "UnitXP_SP3_manaBar", UnitXP_SP3_SyncTimer.container)
        UnitXP_SP3_SyncTimer.manaBar:SetWidth(bw)
        UnitXP_SP3_SyncTimer.manaBar:SetHeight(pwH)
        UnitXP_SP3_SyncTimer.manaBar:SetFrameStrata("MEDIUM")
        UnitXP_SP3_SyncTimer.manaBar:SetMinMaxValues(0, 1)
        UnitXP_SP3_SyncTimer.manaBar:SetValue(1)
        UnitXP_SP3_SyncTimer.manaBar:SetStatusBarTexture(barTex)
        local mnBg = UnitXP_SP3_SyncTimer.manaBar:CreateTexture(nil, "BACKGROUND")
        mnBg:SetAllPoints()
        mnBg:SetTexture(barTex)
        mnBg:SetVertexColor(0.15, 0.15, 0.15, 0.5)
        UnitXP_SP3_SyncTimer.manaBar.background = mnBg
        UnitXP_SP3_SyncTimer.manaBar:SetPoint("TOPLEFT", UnitXP_SP3_SyncTimer.powerBar, "BOTTOMLEFT", 0, 0)

        local mnSpark = UnitXP_SP3_SyncTimer.manaBar:CreateTexture(nil, "OVERLAY")
        mnSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        mnSpark:SetWidth(16)
        mnSpark:SetHeight(pwH * 2)
        mnSpark:SetBlendMode("ADD")
        UnitXP_SP3_SyncTimer.manaBar.spark = mnSpark
    end


    -- 创建回蓝/回能光标(法力职业依附manaBar,能量职业依附powerBar)
    local _, unitClass = UnitClass("player")
    local playerClass = UnitXP_SP3_Addon.playerClass or unitClass
    local isManaUser = (playerClass == "MAGE" or playerClass == "PRIEST" or
        playerClass == "SHAMAN" or playerClass == "PALADIN" or
        playerClass == "HUNTER" or playerClass == "WARLOCK" or
        playerClass == "DRUID")

    if not UnitXP_SP3_SyncTimer.manaCursor then
        local cursorParent = isManaUser and UnitXP_SP3_SyncTimer.manaBar or UnitXP_SP3_SyncTimer.powerBar
        UnitXP_SP3_SyncTimer.manaCursor = cursorParent:CreateTexture(nil, "OVERLAY")
        UnitXP_SP3_SyncTimer.manaCursor:SetTexture("Interface\\Buttons\\WHITE8X8")
        UnitXP_SP3_SyncTimer.manaCursor:SetWidth(1)
        UnitXP_SP3_SyncTimer.manaCursor:SetHeight(7)
        UnitXP_SP3_SyncTimer.manaCursor:SetBlendMode("ADD")
        UnitXP_SP3_SyncTimer.manaCursor:SetAlpha(1.0)
        UnitXP_SP3_SyncTimer.manaCursor:SetVertexColor(0.8, 0.8, 1, 1)
        UnitXP_SP3_SyncTimer.manaCursor:SetDrawLayer("OVERLAY", 7)
        UnitXP_SP3_SyncTimer.manaCursor:Hide()
        UnitXP_SP3_SyncTimer.manaCursorParent = cursorParent
    end

    UnitXP_SP3_SyncTimer.hpCurrentValue = 1
    UnitXP_SP3_SyncTimer.hpTargetValue = 1
    UnitXP_SP3_SyncTimer.manaCurrentValue = 1
    UnitXP_SP3_SyncTimer.manaTargetValue = 1
    UnitXP_SP3_SyncTimer.powerCurrentValue = 1
    UnitXP_SP3_SyncTimer.powerTargetValue = 1

    -- 插值速度
    UnitXP_SP3_SyncTimer.interpolationSpeed = 4

    UnitXP_SP3_SyncTimer.tickStart = nil
    UnitXP_SP3_SyncTimer.tickMax = nil
    UnitXP_SP3_SyncTimer.lastManaValue = nil
    UnitXP_SP3_SyncTimer.lastPowerValue = nil

    if not UnitXP_SP3_SyncTimer.cpContainer then
        UnitXP_SP3_SyncTimer.cpContainer = CreateFrame("Frame", "UnitXP_SP3_cpContainer", UnitXP_SP3_SyncTimer.container)
        UnitXP_SP3_SyncTimer.cpContainer:SetWidth(bw)
        UnitXP_SP3_SyncTimer.cpContainer:SetHeight(6)
        UnitXP_SP3_SyncTimer.cpContainer:SetFrameStrata("MEDIUM")
        UnitXP_SP3_SyncTimer.cpContainer:Show()
    end

    -- 连击点默理扮?
    if not UnitXP_SP3_SyncTimer.cpTexs then
        UnitXP_SP3_SyncTimer.cpTexs = {}
        for i = 1, 5 do
            local cp = UnitXP_SP3_SyncTimer.cpContainer:CreateTexture(nil, "ARTWORK")
            cp:SetWidth(24)
            cp:SetHeight(6)
            cp:SetTexture(barTex)
            cp:SetVertexColor(1, 0, 0)
            local spacing = (bw - 24 * 5) / 4
            cp:SetPoint("LEFT", UnitXP_SP3_SyncTimer.cpContainer, "LEFT", (i - 1) * (spacing + 24), 0)
            cp:Hide()
            UnitXP_SP3_SyncTimer.cpTexs[i] = cp
        end
    end

end

function UnitXP_SP3_startSyncTimer()
    UnitXP_SP3_InitSyncTimer()
end

local function UnitXP_SP3_SetUITexts()
    if not xpsp3Frame then return end

    if xpsp3_fontStringFPSCap then
        xpsp3_fontStringFPSCap:SetText(L["FPS Cap:"]);
    end
    if xpsp3_fontStringBackgroundCap then
        xpsp3_fontStringBackgroundCap:SetText(L["Background:"]);
    end
    if xpsp3_fontStringTargetingInfo then
        xpsp3_fontStringTargetingInfo:SetText("");
    end
end

local function UnitXP_SP3_reloadConfig()
    UnitXP_SP3_FPScap(UnitXP_SP3_Addon["FPScap"]);
    xpsp3_editBox_FPScap:SetNumber(UnitXP_SP3_Addon["FPScap"]);

    UnitXP_SP3_backgroundFPScap(UnitXP_SP3_Addon["backgroundFPScap"]);
    xpsp3_editBox_backgroundFPScap:SetNumber(UnitXP_SP3_Addon["backgroundFPScap"]);

    UnitXP_SP3_setTargetingRangeConeFactor(UnitXP_SP3_Addon["targetingRangeConeFactor"]);

    UnitXP_SP3_setCameraHeight(UnitXP_SP3_Addon["cameraHeight"]);
    UnitXP_SP3_setCameraPitch(UnitXP_SP3_Addon["cameraPitch"]);
    UnitXP_SP3_setCameraHorizontalDisplacement(UnitXP_SP3_Addon["cameraHorizontalDisplacement"]);

    if UnitXP_SP3_Icon.hide then
        xpsp3_checkButton_minimapButton:SetChecked(false);
    else
        xpsp3_checkButton_minimapButton:SetChecked(true);
    end

    if UnitXP_SP3_Addon["modernNameplateDistance"] then
        UnitXP_SP3_setModernNameplateDistance("enable");
        xpsp3_checkButton_modernNameplate:SetChecked(true);
    else
        UnitXP_SP3_setModernNameplateDistance("disable");
        xpsp3_checkButton_modernNameplate:SetChecked(false);
    end

    if UnitXP_SP3_Addon["combatTextSP3"] then
        UnitXP_SP3_combatTextSP3("enable");
        xpsp3_checkButton_combatTextSP3:SetChecked(true);
        xpsp3_editBox_combatTextSP3_fontName:Show();
        xpsp3_fontString_combatTextSP3_fontName:Show();

        UnitXP_SP3_combatTextSP3_fontName(UnitXP_SP3_Addon["combatTextSP3_fontName"]);
        xpsp3_editBox_combatTextSP3_fontName:SetText(UnitXP_SP3_Addon["combatTextSP3_fontName"]);
    else
        UnitXP_SP3_combatTextSP3("disable");
        xpsp3_checkButton_combatTextSP3:SetChecked(false);
        xpsp3_editBox_combatTextSP3_fontName:Hide();
        xpsp3_fontString_combatTextSP3_fontName:Hide();
    end

    if UnitXP_SP3_Addon["hideEXPtext"] then
        UnitXP_SP3_setHideEXPtext("enable");
        xpsp3_checkButton_hideEXPtext:SetChecked(true);
    else
        UnitXP_SP3_setHideEXPtext("disable");
        xpsp3_checkButton_hideEXPtext:SetChecked(false);
    end

    if UnitXP_SP3_Addon["cameraPinHeight"] then
        UnitXP_SP3_setCameraPinHeight("enable");
        xpsp3_checkButton_cameraPinHeight:SetChecked(true);
    else
        UnitXP_SP3_setCameraPinHeight("disable");
        xpsp3_checkButton_cameraPinHeight:SetChecked(false);
    end

    if UnitXP_SP3_Addon["prioritizeTargetNameplate"] then
        UnitXP_SP3_setPrioritizeTargetNameplate("enable");
        xpsp3_checkButton_prioritizeTargetNameplate:SetChecked(true);
    else
        UnitXP_SP3_setPrioritizeTargetNameplate("disable");
        xpsp3_checkButton_prioritizeTargetNameplate:SetChecked(false);
    end

    if UnitXP_SP3_Addon["prioritizeMarkedNameplate"] then
        UnitXP_SP3_setPrioritizeMarkedNameplate("enable");
        xpsp3_checkButton_prioritizeMarkedNameplate:SetChecked(true);
    else
        UnitXP_SP3_setPrioritizeMarkedNameplate("disable");
        xpsp3_checkButton_prioritizeMarkedNameplate:SetChecked(false);
    end

    if UnitXP_SP3_Addon["nameplateCombatFilter"] then
        UnitXP_SP3_setNameplateCombatFilter("enable");
        xpsp3_checkButton_nameplateCombatFilter:SetChecked(true);
    else
        UnitXP_SP3_setNameplateCombatFilter("disable");
        xpsp3_checkButton_nameplateCombatFilter:SetChecked(false);
    end

    if UnitXP_SP3_Addon["hideCritterNameplate"] then
        UnitXP_SP3_setHideCritterNameplate("enable");
        xpsp3_checkButton_hideCritterNameplate:SetChecked(true);
    else
        UnitXP_SP3_setHideCritterNameplate("disable");
        xpsp3_checkButton_hideCritterNameplate:SetChecked(false);
    end

    if UnitXP_SP3_Addon["showInCombatNameplatesNearPlayer"] then
        UnitXP_SP3_setShowInCombatNameplatesNearPlayer("enable");
        xpsp3_checkButton_showInCombatNameplatesNearPlayer:SetChecked(true);
    else
        UnitXP_SP3_setShowInCombatNameplatesNearPlayer("disable");
        xpsp3_checkButton_showInCombatNameplatesNearPlayer:SetChecked(false);
    end

    if UnitXP_SP3_Addon["weatherAlwaysClear"] then
        UnitXP_SP3_setWeatherAlwaysClear("enable");
        xpsp3_checkButton_weatherAlwaysClear:SetChecked(true);
    else
        UnitXP_SP3_setWeatherAlwaysClear("disable");
        xpsp3_checkButton_weatherAlwaysClear:SetChecked(false);
    end

    if UnitXP_SP3_Addon["perfectScreenshot"] then
        UnitXP_SP3_screenshotQuality("perfect");
        xpsp3_checkButton_perfectScreenshot:SetChecked(true);
    else
        UnitXP_SP3_screenshotQuality("good");
        xpsp3_checkButton_perfectScreenshot:SetChecked(false);
    end

    if UnitXP_SP3_Addon["selfHealthBar"] then
        xpsp3_checkButton_selfHealthBar:SetChecked(true);
    else
        xpsp3_checkButton_selfHealthBar:SetChecked(false);
    end

    for ev, v in pairs(UnitXP_SP3_Addon["notify_flashTaskbarIcon"]) do
        xpsp3Frame:UnregisterEvent(ev);
    end
    for ev, v in pairs(UnitXP_SP3_Addon["notify_playSystemDefaultSound"]) do
        xpsp3Frame:UnregisterEvent(ev);
    end

    for ev, v in pairs(UnitXP_SP3_Addon["notify_flashTaskbarIcon"]) do
        if v == true then
            xpsp3Frame:RegisterEvent(ev);
            xpsp3_checkButton_notify_flashTaskbarIcon:SetChecked(true);
        else
            xpsp3_checkButton_notify_flashTaskbarIcon:SetChecked(false);
        end
    end
    for ev, v in pairs(UnitXP_SP3_Addon["notify_playSystemDefaultSound"]) do
        if v == true then
            xpsp3Frame:RegisterEvent(ev);
            xpsp3_checkButton_notify_playSystemDefaultSound:SetChecked(true);
        else
            xpsp3_checkButton_notify_playSystemDefaultSound:SetChecked(false);
        end
    end

end

function UnitXP_SP3_UI_OnClick(widget)
    if widget == nil or string.find(widget:GetName(), "xpsp3") == nil then
        return
    end

    xpsp3_editBox_FPScap:ClearFocus();
    xpsp3_editBox_backgroundFPScap:ClearFocus();
    xpsp3_editBox_combatTextSP3_fontName:ClearFocus();

    skipUpdateMessage = false;

    if string.find(widget:GetName(), "_editBox_") then
        PlaySound("igMainMenuContinue");
        if string.find(widget:GetName(), "_FPScap") then
            UnitXP_SP3_FPScap(widget:GetNumber());
        end
        if string.find(widget:GetName(), "_backgroundFPScap") then
            UnitXP_SP3_backgroundFPScap(widget:GetNumber());
        end
        if string.find(widget:GetName(), "_combatTextSP3_fontName") then
            UnitXP_SP3_combatTextSP3_fontName(widget:GetText());
        end
    end

    if string.find(widget:GetName(), "_button_") then
            PlaySound("igMainMenuContinue");
            if string.find(widget:GetName(), "_cameraHeight_raise") then
                UnitXP_SP3_raiseCameraHeight();
            end
            if string.find(widget:GetName(), "_cameraHeight_lower") then
                UnitXP_SP3_lowerCameraHeight();
            end
            if string.find(widget:GetName(), "_cameraPitch_up") then
                UnitXP_SP3_cameraPitchUp();
            end
            if string.find(widget:GetName(), "_cameraPitch_down") then
                UnitXP_SP3_cameraPitchDown();
            end
            if string.find(widget:GetName(), "_cameraHorizontalDisplacement_leftPlayer") then
                UnitXP_SP3_leftPlayer();
            end
            if string.find(widget:GetName(), "_cameraHorizontalDisplacement_rightPlayer") then
                UnitXP_SP3_rightPlayer();
            end
            if string.find(widget:GetName(), "_resourceBar_Texture") then
                UnitXP_SP3_SwitchResourceBarTexture();
            end
        end

    if string.find(widget:GetName(), "_buttonCancel_") then
        PlaySound("gsTitleOptionExit");
        if string.find(widget:GetName(), "_close") then
            xpsp3Frame:Hide();
        end
        if string.find(widget:GetName(), "_resetCamera") then
            UnitXP_SP3_resetCamera();
        end
    end

    if string.find(widget:GetName(), "_checkButton_") then
        if widget:GetChecked() then
            PlaySound("igMainMenuOptionCheckBoxOn");
        else
            PlaySound("igMainMenuOptionCheckBoxOff");
        end

        if string.find(widget:GetName(), "_minimapButton") then
            UnitXP_SP3_Icon.hide = not widget:GetChecked();
            libIcon:Refresh("UnitXP SP3 icon", UnitXP_SP3_Icon);
        end

        if string.find(widget:GetName(), "_modernNameplate") then
            if widget:GetChecked() then
                UnitXP_SP3_Addon["modernNameplateDistance"] = true;
            else
                UnitXP_SP3_Addon["modernNameplateDistance"] = false;
            end
        end

        if string.find(widget:GetName(), "_combatTextSP3") then
            if widget:GetChecked() then
                UnitXP_SP3_Addon["combatTextSP3"] = true;
            else
                UnitXP_SP3_Addon["combatTextSP3"] = false;
            end
        end

        if string.find(widget:GetName(), "_hideEXPtext") then
            if widget:GetChecked() then
                UnitXP_SP3_Addon["hideEXPtext"] = true;
            else
                UnitXP_SP3_Addon["hideEXPtext"] = false;
            end
        end

        if string.find(widget:GetName(), "_cameraPinHeight") then
            if widget:GetChecked() then
                UnitXP_SP3_Addon["cameraPinHeight"] = true;
            else
                UnitXP_SP3_Addon["cameraPinHeight"] = false;
            end
        end

        if string.find(widget:GetName(), "_prioritizeTargetNameplate") then
            if widget:GetChecked() then
                UnitXP_SP3_Addon["prioritizeTargetNameplate"] = true;
            else
                UnitXP_SP3_Addon["prioritizeTargetNameplate"] = false;
            end
        end

        if string.find(widget:GetName(), "_prioritizeMarkedNameplate") then
            if widget:GetChecked() then
                UnitXP_SP3_Addon["prioritizeMarkedNameplate"] = true;
            else
                UnitXP_SP3_Addon["prioritizeMarkedNameplate"] = false;
            end
        end

        if string.find(widget:GetName(), "_nameplateCombatFilter") then
            if widget:GetChecked() then
                UnitXP_SP3_Addon["nameplateCombatFilter"] = true;
            else
                UnitXP_SP3_Addon["nameplateCombatFilter"] = false;
            end
        end

        if string.find(widget:GetName(), "_weatherAlwaysClear") then
            if widget:GetChecked() then
                UnitXP_SP3_Addon["weatherAlwaysClear"] = true;
            else
                UnitXP_SP3_Addon["weatherAlwaysClear"] = false;
            end
        end

        if string.find(widget:GetName(), "_perfectScreenshot") then
            if widget:GetChecked() then
                UnitXP_SP3_Addon["perfectScreenshot"] = true;
            else
                UnitXP_SP3_Addon["perfectScreenshot"] = false;
            end
        end

        if string.find(widget:GetName(), "_selfHealthBar") then
            if widget:GetChecked() then
                UnitXP_SP3_Addon["selfHealthBar"] = true;
                if not UnitXP_SP3_SyncTimer.hpBar then
                    UnitXP_SP3_InitSyncTimer()
                end
            else
                UnitXP_SP3_Addon["selfHealthBar"] = false;
                if UnitXP_SP3_SyncTimer.hpBar then
                    UnitXP_SP3_SyncTimer.hpBar:Hide()
                end
                if UnitXP_SP3_SyncTimer.powerBar then
                    UnitXP_SP3_SyncTimer.powerBar:Hide()
                end
                if UnitXP_SP3_SyncTimer.manaBar then
                    UnitXP_SP3_SyncTimer.manaBar:Hide()
                end
                if UnitXP_SP3_SyncTimer.cpContainer then
                    UnitXP_SP3_SyncTimer.cpContainer:Hide()
                end
                if UnitXP_SP3_SyncTimer.container then
                    UnitXP_SP3_SyncTimer.container:Hide()
                end
            end
        end

        if string.find(widget:GetName(), "_showInCombatNameplatesNearPlayer") then
            if widget:GetChecked() then
                UnitXP_SP3_Addon["showInCombatNameplatesNearPlayer"] = true;
            else
                UnitXP_SP3_Addon["showInCombatNameplatesNearPlayer"] = false;
            end
        end

        if string.find(widget:GetName(), "_hideCritterNameplate") then
            if widget:GetChecked() then
                UnitXP_SP3_Addon["hideCritterNameplate"] = true;
            else
                UnitXP_SP3_Addon["hideCritterNameplate"] = false;
            end
        end

        if string.find(widget:GetName(), "_notify_flashTaskbarIcon") then
            for ev, v in pairs(UnitXP_SP3_Addon["notify_flashTaskbarIcon"]) do
                if widget:GetChecked() then
                    UnitXP_SP3_Addon["notify_flashTaskbarIcon"][ev] = true;
                else
                    UnitXP_SP3_Addon["notify_flashTaskbarIcon"][ev] = false;
                end
            end
        end

        if string.find(widget:GetName(), "_notify_playSystemDefaultSound") then
            for ev, v in pairs(UnitXP_SP3_Addon["notify_playSystemDefaultSound"]) do
                if widget:GetChecked() then
                    UnitXP_SP3_Addon["notify_playSystemDefaultSound"][ev] = true;
                else
                    UnitXP_SP3_Addon["notify_playSystemDefaultSound"][ev] = false;
                end
            end
        end
    end

    UnitXP_SP3_reloadConfig();
end

function UnitXP_SP3_toggleModernNameplateDistance()
    UnitXP_SP3_Addon["modernNameplateDistance"] = not UnitXP_SP3_Addon["modernNameplateDistance"];
    UnitXP_SP3_reloadConfig();
end

function UnitXP_SP3_togglePrioritizeTargetNameplate()
    UnitXP_SP3_Addon["prioritizeTargetNameplate"] = not UnitXP_SP3_Addon["prioritizeTargetNameplate"];
    UnitXP_SP3_reloadConfig();
end

function UnitXP_SP3_togglePrioritizeMarkedNameplate()
    UnitXP_SP3_Addon["prioritizeMarkedNameplate"] = not UnitXP_SP3_Addon["prioritizeMarkedNameplate"];
    UnitXP_SP3_reloadConfig();
end

-- Recording party members from previous PARTY_MEMBERS_CHANGED events so that we can verify if the party just became full
local lastRecordedPartyMembers = 0

local function checkEvent(listenedEvents, actionFunction)
    if listenedEvents[event] then
        if event == "PARTY_MEMBERS_CHANGED" then
            -- Party full
            if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 4 and lastRecordedPartyMembers ~= 4 then
                actionFunction();
            end
        elseif event == "UPDATE_BATTLEFIELD_STATUS" then
            for i = 1, MAX_BATTLEFIELD_QUEUES do
                local s = GetBattlefieldStatus(i);
                -- Battlefield is ready
                if s == "confirm" then
                    actionFunction();
                    break
                end
            end
        elseif event == "UNIT_MANA" or event == "UNIT_RAGE" or event == "UNIT_ENERGY" or event == "UNIT_FOCUS" then
            if arg1 ~= "player" then return end
            local _, fallbackPlayerClass = UnitClass("player")
            local playerClass = UnitXP_SP3_SyncTimer and UnitXP_SP3_SyncTimer.cachedPlayerClass or fallbackPlayerClass
            local powerType = UnitXP_SP3_SyncTimer and UnitXP_SP3_SyncTimer.cachedPowerType or UnitPowerType("player")
            local isEnergyUser = (playerClass == "ROGUE" or (playerClass == "DRUID" and powerType == 2))
            if event == "UNIT_ENERGY" and isEnergyUser then
                local now = GetTime()
                if UnitXP_SP3_SyncTimer then
                    UnitXP_SP3_SyncTimer.tickStart = now
                    UnitXP_SP3_SyncTimer.tickMax = 2
                end
            end
            return;
    elseif event == "PLAYER_COMBO_POINTS" then
        -- 连击点事件驱动更新，取消 OnUpdate 轮询
        if UnitXP_SP3_SyncTimer then
            UnitXP_SP3_SyncTimer.lastCpCount = GetComboPoints()
        end
        return;
    elseif event == "CHAT_MSG_ADDON" then
            if arg1 == (LFT_ADDON_PREFIX or "TW_LFG") then
                if string.find(arg2, "S2C_OFFER_NEW") or string.find(arg2, "S2C_ROLECHECK_START") or
                    string.find(arg2, "S2C_QUEUE_LEFT") then
                    -- LFT found group or role check start or somehow player left queue
                    actionFunction();
                end
            end
        else
            actionFunction();
        end
    end
end

function UnitXP_SP3_OnEvent(event)
    -- 调试：打印所有事件
    if event == "ADDON_LOADED" and arg1 == "UnitXP_SP3_Addon" then
        local dataVersion = 34;
        if UnitXP_SP3_Addon == nil or UnitXP_SP3_Addon["dataVersion"] ~= dataVersion then
            UnitXP_SP3_Addon = {};
            UnitXP_SP3_Addon["dataVersion"] = dataVersion;
            UnitXP_SP3_Addon["targetRangeConeFactor"] = 2.2;
            UnitXP_SP3_Addon["cameraHeight"] = 0.0;
            UnitXP_SP3_Addon["cameraPitch"] = 0.0;
            UnitXP_SP3_Addon["cameraHorizontalDisplacement"] = 0.0;
            UnitXP_SP3_Addon["cameraPinHeight"] = false;
            UnitXP_SP3_Addon["modernNameplateDistance"] = true;
            UnitXP_SP3_Addon["prioritizeTargetNameplate"] = false;
            UnitXP_SP3_Addon["prioritizeMarkedNameplate"] = false;
            UnitXP_SP3_Addon["nameplateCombatFilter"] = false;
            UnitXP_SP3_Addon["showInCombatNameplatesNearPlayer"] = false;
            UnitXP_SP3_Addon["FPScap"] = 0;
            UnitXP_SP3_Addon["backgroundFPScap"] = 60;
            UnitXP_SP3_Addon["weatherAlwaysClear"] = false;
            UnitXP_SP3_Addon["hideCritterNameplate"] = true;
            UnitXP_SP3_Addon["combatTextSP3"] = false;
            UnitXP_SP3_Addon["combatTextSP3_fontName"] = "Cambria";
            UnitXP_SP3_Addon["hideEXPtext"] = false;
            UnitXP_SP3_Addon["perfectScreenshot"] = false;
            UnitXP_SP3_Addon["selfHealthBar"] = false;

            UnitXP_SP3_Addon["notify_flashTaskbarIcon"] = {};
            UnitXP_SP3_Addon["notify_flashTaskbarIcon"]["PLAYER_REGEN_DISABLED"] = true;
            UnitXP_SP3_Addon["notify_flashTaskbarIcon"]["CHAT_MSG_WHISPER"] = true;
            UnitXP_SP3_Addon["notify_flashTaskbarIcon"]["CHAT_MSG_RAID_WARNING"] = true;
            UnitXP_SP3_Addon["notify_flashTaskbarIcon"]["TRADE_SHOW"] = true;
            UnitXP_SP3_Addon["notify_flashTaskbarIcon"]["PARTY_INVITE_REQUEST"] = true;
            UnitXP_SP3_Addon["notify_flashTaskbarIcon"]["READY_CHECK"] = true;
            UnitXP_SP3_Addon["notify_flashTaskbarIcon"]["GUILD_INVITE_REQUEST"] = true;
            UnitXP_SP3_Addon["notify_flashTaskbarIcon"]["UPDATE_BATTLEFIELD_STATUS"] = true;
            UnitXP_SP3_Addon["notify_flashTaskbarIcon"]["PARTY_MEMBERS_CHANGED"] = true;
            UnitXP_SP3_Addon["notify_flashTaskbarIcon"]["CHAT_MSG_ADDON"] = true; -- For LFT

            UnitXP_SP3_Addon["notify_playSystemDefaultSound"] = {};
            UnitXP_SP3_Addon["notify_playSystemDefaultSound"]["PLAYER_REGEN_DISABLED"] = false;
            UnitXP_SP3_Addon["notify_playSystemDefaultSound"]["CHAT_MSG_WHISPER"] = false;
            UnitXP_SP3_Addon["notify_playSystemDefaultSound"]["CHAT_MSG_RAID_WARNING"] = false;
            UnitXP_SP3_Addon["notify_playSystemDefaultSound"]["TRADE_SHOW"] = false;
            UnitXP_SP3_Addon["notify_playSystemDefaultSound"]["PARTY_INVITE_REQUEST"] = false;
            UnitXP_SP3_Addon["notify_playSystemDefaultSound"]["READY_CHECK"] = false;
            UnitXP_SP3_Addon["notify_playSystemDefaultSound"]["GUILD_INVITE_REQUEST"] = false;
            UnitXP_SP3_Addon["notify_playSystemDefaultSound"]["UPDATE_BATTLEFIELD_STATUS"] = false;
            UnitXP_SP3_Addon["notify_playSystemDefaultSound"]["PARTY_MEMBERS_CHANGED"] = false;
            UnitXP_SP3_Addon["notify_playSystemDefaultSound"]["CHAT_MSG_ADDON"] = false; -- For LFT
        end
        if UnitXP_SP3_Icon == nil then
            UnitXP_SP3_Icon = {
                hide = false
            };
        end
        xpsp3Frame:UnregisterEvent("ADDON_LOADED");
        xpsp3Frame:RegisterEvent("PLAYER_LOGIN");
        return;
    elseif event == "PLAYER_LOGIN" then
        if pcall(UnitXP, "nop", "nop") == true then
            UnitXP_SP3_SetUITexts();
            UnitXP_SP3_reloadConfig();
            xpsp3Frame:RegisterEvent("PLAYER_ENTERING_WORLD");
            xpsp3Frame:RegisterEvent("PLAYER_LEAVING_WORLD");
            xpsp3Frame:RegisterEvent("CHAT_MSG_ADDON");  -- 注册接收 addon 消息
            xpsp3Frame:RegisterEvent("RAID_ROSTER_UPDATE");  -- 团队成员变化
            xpsp3Frame:RegisterEvent("PARTY_MEMBERS_CHANGED");  -- 小队成员变化
            xpsp3Frame:RegisterEvent("PARTY_LEADER_CHANGED");  -- 队长变更
            xpsp3Frame:RegisterEvent("PLAYER_COMBO_POINTS");  -- 连击点变化，pUI 方式事件驱动
            xpsp3Frame:RegisterEvent("PLAYER_TARGET_CHANGED");  -- 切换目标，查新目标连击点数，调试用
            xpsp3Frame:RegisterEvent("UNIT_MANA");  -- pUI 方式事件驱动
            xpsp3Frame:RegisterEvent("UNIT_RAGE");  -- pUI 方式事件驱动
            xpsp3Frame:RegisterEvent("UNIT_ENERGY");  -- pUI 方式事件驱动
            xpsp3Frame:RegisterEvent("UNIT_FOCUS");  -- pUI 方式事件驱动
            xpsp3Frame:RegisterEvent("UNIT_DISPLAYPOWER");
            xpsp3Frame:RegisterEvent("PLAYER_REGEN_ENABLED");
            xpsp3Frame:RegisterEvent("PLAYER_REGEN_DISABLED");
            UnitXP_SP3_startSyncTimer();

            local message = L["UnitXP Service Pack 3 is loaded"] .. ".";
            local hasCOFFtimestamp, coffTimestamp = pcall(UnitXP, "version", "coffTimeDateStamp");
            if hasCOFFtimestamp then
                message = message .. " " .. L["It was built on"] .. " " .. date("%d %b %Y", coffTimestamp) .. ".";
            end
            UnitXP_SP3_Print(message);
        else
            UnitXP_SP3_Print(L["UnitXP Service Pack 3 didn't load properly"] .. ".");
            return;
        end

        -- Chat Command
        SLASH_UNITXP1 = "/unitxp";
        SlashCmdList["UNITXP"] = function()
            if pcall(UnitXP, "nop", "nop") == true then
                if xpsp3Frame:IsShown() then
                    PlaySound("igMainMenuContinue");
                    xpsp3Frame:Hide();
                else
                    PlaySound("igMainMenuOpen");
                    xpsp3Frame:Show();
                end
            else
                UnitXP_SP3_Print(L["UnitXP Service Pack 3 didn't load properly"] .. ".");
            end
        end

        if UnitXP_SP3_Addon["notify_flashTaskbarIcon"] ~= nil and
            UnitXP_SP3_Addon["notify_flashTaskbarIcon"]["PLAYER_REGEN_DISABLED"] == true and
            UnitXP_SP3_SyncTimer and UnitXP_SP3_SyncTimer.cachedInCombat then
            UnitXP_SP3_flashTaskbarIcon();
        end

        if UnitXP_SP3_Addon["notify_playSystemDefaultSound"] ~= nil and
            UnitXP_SP3_Addon["notify_playSystemDefaultSound"]["PLAYER_REGEN_DISABLED"] == true and
            UnitXP_SP3_SyncTimer and UnitXP_SP3_SyncTimer.cachedInCombat then
            UnitXP_SP3_playSystemDefaultSound();
        end

        local iconData = libData:NewDataObject("UnitXP SP3 icon data", {
            OnClick = function()
                if pcall(UnitXP, "nop", "nop") == true then
                    if xpsp3Frame:IsShown() then
                        PlaySound("igMainMenuContinue");
                        xpsp3Frame:Hide();
                    else
                        PlaySound("igMainMenuOpen");
                        xpsp3Frame:Show();
                    end
                else
                    UnitXP_SP3_Print(L["UnitXP Service Pack 3 didn't load properly"] .. ".");
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:SetText(UNITXPSP3TOOLTIP);
            end,
            icon = "Interface\\Icons\\INV_Misc_Gem_Pearl_05"
        });

        libIcon:Register("UnitXP SP3 icon", iconData, UnitXP_SP3_Icon);

        local original_UnitXP = UnitXP;

        UnitXP = function(cmd, arg1, arg2, arg3, arg4, arg5)
            if UnitXP_SP3_skipPermissionCheck then
                return original_UnitXP(cmd, arg1, arg2, arg3, arg4, arg5);
            end

            if cmd == "2DMark" then
                if not UnitXP_SP3_hasRaidLeaderOrAssistant() then
                    UnitXP_SP3_Print(L["No raid permission, cannot set mark"]);
                    return;
                end

                -- 调用原始函数创建标记
                local x, y, z, colorName = original_UnitXP(cmd, arg1, arg2, arg3, arg4, arg5);

                if x and y and z then
                    UnitXP_SP3_localMarks[colorName or arg1] = {x = x, y = y, z = z};

                    local cleanColor = "white";
                    if colorName and type(colorName) == "string" then
                        cleanColor = colorName;
                    elseif arg1 and type(arg1) == "string" then
                        cleanColor = arg1;
                    end

                    local cleanX = tonumber(x);
                    local cleanY = tonumber(y);
                    local cleanZ = tonumber(z);

                    if cleanX and cleanY and cleanZ then
                        local message = string.format("MARK %s %.2f %.2f %.2f", cleanColor, cleanX, cleanY, cleanZ);
                        local channel = "PARTY";
                        if GetNumRaidMembers() > 0 then
                            channel = "RAID";
                        end
                        SendAddonMessage("UnitXPSP3", message, channel);
                    end
                end

                return x, y, z, colorName;
            elseif cmd == "ClearAllMarks" then
                if not UnitXP_SP3_hasRaidLeaderOrAssistant() then
                    UnitXP_SP3_Print(L["No raid permission, cannot clear marks"]);
                    return;
                end

                -- 调用原始函数清除标记
                local result = original_UnitXP(cmd, arg1, arg2, arg3, arg4, arg5);

                -- 清空本地标记列表
                UnitXP_SP3_localMarks = {};

                local channel = "PARTY";
                if GetNumRaidMembers() > 0 then
                    channel = "RAID";
                end
                SendAddonMessage("UnitXPSP3", "CLEAR", channel);

                return result;
            else
                -- 其他命令直接转发
                return original_UnitXP(cmd, arg1, arg2, arg3, arg4, arg5);
            end
        end;

        return;
    elseif event == "PLAYER_ENTERING_WORLD" then
        pcall(UnitXP, "onEvent", event);

        local success, markCount, marks = pcall(UnitXP, "QueryMarks");
        if not success then
            if not skipUpdateMessage then
                skipUpdateMessage = true;
                UnitXP_SP3_Print(
                    L["UnitXP_SP3.dll failed to execute"] .. " \"QueryMarks\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
            end
        elseif markCount and marks then
            for _, mark in ipairs(marks) do
                UnitXP_SP3_localMarks[mark.color] = {x = mark.x, y = mark.y, z = mark.z};
            end
        end

        UnitXP_SP3_updateGroupState();

        UnitXP_SP3_startSyncTimer();

        return;
    elseif event == "PLAYER_LEAVING_WORLD" then
        pcall(UnitXP, "onEvent", event);
        return;
    elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" or event == "PARTY_LEADER_CHANGED" then
        local oldState = {
            inRaid = UnitXP_SP3_groupState.inRaid,
            inParty = UnitXP_SP3_groupState.inParty,
            raidCount = GetNumRaidMembers(),
            partyCount = GetNumPartyMembers()
        };

        UnitXP_SP3_updateGroupState();

        -- 获取新的人数
        local newRaidCount = GetNumRaidMembers();
        local newPartyCount = GetNumPartyMembers();

        -- 检查是否退出了团队/小队
        local leftGroup = (oldState.inRaid and not UnitXP_SP3_groupState.inRaid) or
                          (oldState.inParty and not UnitXP_SP3_groupState.inParty);

        local countChanged = (oldState.raidCount ~= newRaidCount) or
                             (oldState.partyCount ~= newPartyCount);

        if leftGroup then
            local success, result = pcall(UnitXP, "ClearAllMarks");
            if not success then
                if not skipUpdateMessage then
                    skipUpdateMessage = true;
                    UnitXP_SP3_Print(
                        L["UnitXP_SP3.dll failed to execute"] .. " \"ClearAllMarks\". " .. L["You might need to update UnitXP_SP3.dll to support this method"] .. ".");
                end
            end
            UnitXP_SP3_localMarks = {};
            UnitXP_SP3_remoteMarks = {};
        elseif countChanged then
            if next(UnitXP_SP3_localMarks) and UnitXP_SP3_shouldSyncMarks() then
                UnitXP_SP3_syncAllMarks();
                UnitXP_SP3_Print(string.format("团队变动（%d=>%d），正在同步标记",
                    oldState.inRaid and oldState.raidCount or oldState.partyCount,
                    UnitXP_SP3_groupState.inRaid and newRaidCount or newPartyCount));
            end
        end

        return;
    elseif event == "UNIT_MANA" or event == "UNIT_RAGE" or event == "UNIT_ENERGY" or event == "UNIT_FOCUS" then
        -- 能量/法力事件驱动，相对轻量，只标记更新需要，实际值从C++ hook获取
        if arg1 ~= "player" then return end
        return;
    elseif event == "PLAYER_COMBO_POINTS" then
        -- 连击点事件驱动更新，取消 OnUpdate 轮询
        if UnitXP_SP3_SyncTimer then
            UnitXP_SP3_SyncTimer.lastCpCount = GetComboPoints()
        end
        return;
    elseif event == "PLAYER_TARGET_CHANGED" then
        -- 切换目标，主动查询连击点数并更新渲染
        if UnitXP_SP3_SyncTimer then
            UnitXP_SP3_SyncTimer.lastCpCount = GetComboPoints()
        end
        return;
    elseif event == "UNIT_DISPLAYPOWER" then
        -- 更新缓存的powerType（德鲁伊切形态时触发）
        if UnitXP_SP3_SyncTimer then
            UnitXP_SP3_SyncTimer.cachedPowerType = UnitPowerType("player")
        end
        return;
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- 更新缓存的战斗状态
        if UnitXP_SP3_SyncTimer then
            UnitXP_SP3_SyncTimer.cachedInCombat = false
        end
        return;
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- 更新缓存的战斗状态
        if UnitXP_SP3_SyncTimer then
            UnitXP_SP3_SyncTimer.cachedInCombat = true
        end
        return;
    elseif event == "CHAT_MSG_ADDON" then
        if arg1 == "UnitXPSP3" then
            local message = arg2;
            local sender = arg4;

            -- 忽略自己发送的消息
            local playerName = UnitName("player");
            if sender == playerName then
                return;
            end

            -- 使用空格分割
            local parts = {};
            local partCount = 0;
            for part in string.gmatch(message, "[^ ]+") do
                table.insert(parts, part);
                partCount = partCount + 1;
            end

            if partCount >= 1 then
                if parts[1] == "MARK" and partCount == 5 then
                    -- 创建标记
                    local colorName = parts[2];
                    local x = tonumber(parts[3]);
                    local y = tonumber(parts[4]);
                    local z = tonumber(parts[5]);

                    if colorName and x and y and z then
                        local cachedMark = UnitXP_SP3_remoteMarks[colorName];
                        local needUpdate = true;

                        if cachedMark then
                            local dx = math.abs(cachedMark.x - x);
                            local dy = math.abs(cachedMark.y - y);
                            local dz = math.abs(cachedMark.z - z);

                            if dx < 0.1 and dy < 0.1 and dz < 0.1 then
                                needUpdate = false;
                            end
                        end

                        if needUpdate then
                            UnitXP_SP3_skipPermissionCheck = true;
                            local success = pcall(UnitXP, "RemoteMark", colorName, x, y, z, sender);
                            -- 重置标志
                            UnitXP_SP3_skipPermissionCheck = false;

                            if success then
                                -- 更新缓存
                                UnitXP_SP3_remoteMarks[colorName] = {x = x, y = y, z = z};
                            end
                        end
                    end
                elseif parts[1] == "CLEAR" then
                    UnitXP_SP3_skipPermissionCheck = true;
                    local success = pcall(UnitXP, "ClearAllMarks");
                    -- 重置标志
                    UnitXP_SP3_skipPermissionCheck = false;

                    if success then
                        -- 清空远程标记缓存
                        UnitXP_SP3_remoteMarks = {};
                    end
                end
            end
        end
        return;
    end

    if UnitXP_SP3_Addon then
        if UnitXP_SP3_Addon["notify_flashTaskbarIcon"] then
            checkEvent(UnitXP_SP3_Addon["notify_flashTaskbarIcon"], UnitXP_SP3_flashTaskbarIcon)
        end

        if UnitXP_SP3_Addon["notify_playSystemDefaultSound"] then
            checkEvent(UnitXP_SP3_Addon["notify_playSystemDefaultSound"], UnitXP_SP3_playSystemDefaultSound)
        end

        if event == "PARTY_MEMBERS_CHANGED" then
            lastRecordedPartyMembers = GetNumPartyMembers()
        end
    end
end

function UnitXP_SP3_SwitchResourceBarTexture()
    if UnitXP_SP3_SyncTimer and UnitXP_SP3_SyncTimer.barTextures then
        UnitXP_SP3_SyncTimer.currentTextureIndex = UnitXP_SP3_SyncTimer.currentTextureIndex + 1

        local maxIndex = table.getn(UnitXP_SP3_SyncTimer.barTextures)
        if not maxIndex then
            maxIndex = getn(UnitXP_SP3_SyncTimer.barTextures)
        end
        if not maxIndex then
            maxIndex = 0
            for i, v in pairs(UnitXP_SP3_SyncTimer.barTextures) do
                maxIndex = maxIndex + 1
            end
        end

        if UnitXP_SP3_SyncTimer.currentTextureIndex > maxIndex then
            UnitXP_SP3_SyncTimer.currentTextureIndex = 1
        end

        -- 保存材质索引到配置中
        if UnitXP_SP3_Addon then
            UnitXP_SP3_Addon["resourceBarTextureIndex"] = UnitXP_SP3_SyncTimer.currentTextureIndex
        end

        -- 获取新的材质路径
        local newTexture = UnitXP_SP3_SyncTimer.barTextures[UnitXP_SP3_SyncTimer.currentTextureIndex]

        -- 更新按钮文本
        local button = _G["xpsp3_button_resourceBar_Texture"]
        if button then
            UnitXP_SP3_SetResourceBarTextureButtonText(button)
        end

        if UnitXP_SP3_SyncTimer.hpBar then
            UnitXP_SP3_SyncTimer.hpBar:SetStatusBarTexture(newTexture)
            if UnitXP_SP3_SyncTimer.hpBar.background then
                UnitXP_SP3_SyncTimer.hpBar.background:SetTexture(newTexture)
            end
        end

        if UnitXP_SP3_SyncTimer.powerBar then
            UnitXP_SP3_SyncTimer.powerBar:SetStatusBarTexture(newTexture)
            if UnitXP_SP3_SyncTimer.powerBar.background then
                UnitXP_SP3_SyncTimer.powerBar.background:SetTexture(newTexture)
            end
        end

        if UnitXP_SP3_SyncTimer.manaBar then
            UnitXP_SP3_SyncTimer.manaBar:SetStatusBarTexture(newTexture)
            if UnitXP_SP3_SyncTimer.manaBar.background then
                UnitXP_SP3_SyncTimer.manaBar.background:SetTexture(newTexture)
            end
        end

        if UnitXP_SP3_SyncTimer.cpTexs then
            for i = 1, 5 do
                if UnitXP_SP3_SyncTimer.cpTexs[i] then
                    UnitXP_SP3_SyncTimer.cpTexs[i]:SetTexture(newTexture)
                end
            end
        end

        -- 显示当前材质名称
        local textureNames = {
            "默认条纹",
            "技能栏材质",
            "纯色",
            "自定义1",
            "自定义2",
            "自定义3"
        }

        local nameCount = getn(textureNames)
        if UnitXP_SP3_SyncTimer.currentTextureIndex <= nameCount then
            DEFAULT_CHAT_FRAME:AddMessage("资源条材质已切换" .. textureNames[UnitXP_SP3_SyncTimer.currentTextureIndex])
        else
            DEFAULT_CHAT_FRAME:AddMessage("资源条材质已切换")
        end
    end
end

function UnitXP_SP3_SetResourceBarTextureButtonText(button)
    -- 定义材质名称列表
    local textureNames = {
        "材质: 默认条纹",
        "材质: 技能栏",
        "材质: 纯色",
        "材质: 自定义1",
        "材质: 自定义2",
        "材质: 自定义3"
    }

    -- 获取当前材质索引
    local currentIndex = 1
    if UnitXP_SP3_SyncTimer and UnitXP_SP3_SyncTimer.currentTextureIndex then
        currentIndex = UnitXP_SP3_SyncTimer.currentTextureIndex
    elseif UnitXP_SP3_Addon and UnitXP_SP3_Addon["resourceBarTextureIndex"] then
        currentIndex = UnitXP_SP3_Addon["resourceBarTextureIndex"]
    end

    -- 获取材质名称
    local nameCount = getn(textureNames)
    local textureName = "材质: 默认"
    if currentIndex <= nameCount then
        textureName = textureNames[currentIndex]
    end

    -- 设置按钮文本
    button:SetText(textureName)
end
