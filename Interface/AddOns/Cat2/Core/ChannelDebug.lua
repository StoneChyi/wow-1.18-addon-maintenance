-- 临时引导诊断：默认关闭，只观察事件与状态，不清理计时、不停止施法。
local frame = CreateFrame("Frame")
local enabled = false
local pending = {}
local watchedName = nil
local watchedGUID = nil
local deathSeen = false
local zeroSeen = false
local elapsed = 0

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff[Cat2引导监测]|r " .. message)
end

local function TargetText()
    if not UnitExists("target") then return "目标=无" end
    return "目标=" .. tostring(UnitName("target")) .. " 血量=" .. tostring(UnitHealth("target"))
        .. " 死亡=" .. tostring(UnitIsDeadOrGhost("target") and true or false)
end

local function StateText()
    local text = string.format("保护剩余=%.3f秒", Cat2.GetChanneled())
    if Cat2.Nampower and type(GetCastInfo) == "function" then
        local ok, info = pcall(GetCastInfo)
        if ok and type(info) == "table" then
            text = text .. " NP类型=" .. tostring(info.castType) .. " NP剩余毫秒=" .. tostring(info.castRemainingMs)
        else
            text = text .. " NP=" .. (ok and "无施法数据" or "读取失败")
        end
    else
        text = text .. "（事件计时，无NP实时检测）"
    end
    return text
end

local function Queue(message)
    table.insert(pending, string.format("t=%.3f ", GetTime()) .. message .. " | " .. TargetText())
end

local function WatchTarget()
    local exists, guid = UnitExists("target")
    watchedGUID = guid
    watchedName = exists and UnitName("target") or nil
    deathSeen = false
    zeroSeen = false
end

frame:SetScript("OnEvent", function()
    if not enabled then return end
    if event == "UNIT_CASTEVENT" then
        local guid = Cat2.PlayerInformation.basic.guid
        if not guid or arg1 ~= guid then return end
        Queue(event .. " 类型=" .. tostring(arg3) .. " 技能ID=" .. tostring(arg4)
            .. " 施法目标=" .. tostring(arg2))
    elseif event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
        if watchedName and type(arg1) == "string" and string.find(arg1, watchedName, 1, true) then
            Queue("死亡日志（按名称匹配） " .. arg1)
        end
    else
        if event == "SPELLCAST_CHANNEL_START" then WatchTarget() end
        Queue(event .. " arg1=" .. tostring(arg1) .. " arg2=" .. tostring(arg2))
    end
end)

frame:SetScript("OnUpdate", function()
    if not enabled then return end
    -- 下一帧输出公共引导状态，避开各个 OnEvent 处理器执行顺序的影响。
    local index = 1
    while index <= table.getn(pending) do
        Print(pending[index] .. " | 帧后 " .. StateText())
        index = index + 1
    end
    pending = {}
    elapsed = elapsed + (tonumber(arg1) or 0)
    if elapsed < 0.1 then return end
    elapsed = 0
    if not watchedName then return end

    local unit = nil
    local exists, guid = UnitExists("target")
    if exists and ((watchedGUID and guid == watchedGUID)
        or (not watchedGUID and UnitName("target") == watchedName)) then
        unit = "target"
    elseif Cat2.SuperWoW and watchedGUID and UnitExists(watchedGUID) then
        unit = watchedGUID
    end
    if unit and not deathSeen and (UnitIsDeadOrGhost(unit) or UnitHealth(unit) <= 0) then
        deathSeen = true
        Print(string.format("t=%.3f 引导目标确认死亡：", GetTime()) .. watchedName .. " | " .. StateText())
    end
    if deathSeen and not zeroSeen and Cat2.GetChanneled() <= 0 then
        zeroSeen = true
        Print("死亡后保护剩余归零（不等同于收到停止事件） | " .. StateText())
    end
end)

SLASH_CAT2CHANNELDEBUG1 = "/cat2channel"
SlashCmdList["CAT2CHANNELDEBUG"] = function(message)
    local command = string.lower(string.gsub(message or "", "^%s*(.-)%s*$", "%1"))
    if command ~= "" and command ~= "on" and command ~= "off" then
        Print("用法：/cat2channel on 开启；/cat2channel off 关闭")
        return
    end
    enabled = command == "on" or (command == "" and not enabled)
    frame:UnregisterAllEvents()
    pending = {}
    watchedName = nil
    watchedGUID = nil
    elapsed = 0
    if enabled then
        frame:RegisterEvent("SPELLCAST_CHANNEL_START")
        frame:RegisterEvent("SPELLCAST_CHANNEL_UPDATE")
        frame:RegisterEvent("SPELLCAST_CHANNEL_STOP")
        frame:RegisterEvent("SPELLCAST_INTERRUPTED")
        frame:RegisterEvent("SPELLCAST_FAILED")
        frame:RegisterEvent("SPELLCAST_STOP")
        frame:RegisterEvent("PLAYER_TARGET_CHANGED")
        frame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
        Cat2.RegisterOptionalEvent(frame, "UNIT_CASTEVENT")
        Print("已开启；请用奥术飞弹击杀怪物，保留死亡前后 CHANNEL_STOP / UPDATE / INTERRUPTED 等记录。")
    else
        Print("已关闭")
    end
end
