-- A loaded/visible GUID is not proof that a robot is nearby. Prefer a current
-- distance query. Without range APIs, only recent visible unit/plate evidence
-- may establish presence; cached GUID checks alone never renew that evidence.
local REPAIR_BOT_RANGE = 40
local REPAIR_BOT_EVIDENCE_TTL = 3

local function STSMmayor_ValidNumber(value)
    return type(value) == "number" and value - value == 0
end

local function STSMmayor_BotRange(unit)
    local queried = false
    if type(UnitXP) == "function" then
        queried = true
        local ok, distance = pcall(UnitXP, "distanceBetween", "player", unit)
        if ok and STSMmayor_ValidNumber(distance) and distance >= 0 then
            return distance <= REPAIR_BOT_RANGE, true
        end
    end
    if type(UnitPosition) == "function" then
        queried = true
        local okPlayer, px, py, pz = pcall(UnitPosition, "player")
        local okUnit, x, y, z = pcall(UnitPosition, unit)
        if okPlayer and okUnit and STSMmayor_ValidNumber(px) and STSMmayor_ValidNumber(py)
            and STSMmayor_ValidNumber(pz) and STSMmayor_ValidNumber(x)
            and STSMmayor_ValidNumber(y) and STSMmayor_ValidNumber(z) then
            local dx, dy, dz = x - px, y - py, z - pz
            return dx * dx + dy * dy + dz * dz <= REPAIR_BOT_RANGE * REPAIR_BOT_RANGE, true
        end
    end
    return nil, queried
end

local function STSMmayor_RememberRepairBot(unit, visiblePlate)
    if not STSMmayor_UnitIsRepairBot(unit) then return false end
    local nearby, queried = STSMmayor_BotRange(unit)
    if nearby == false or (queried and nearby == nil) then return false end
    if nearby == nil and not visiblePlate and unit ~= "target" and unit ~= "mouseover" then return false end
    local guid = STSMmayor_GetBotGUID(unit)
    if guid then
        repairBotUnits[guid] = { lastObserved = GetTime(), plate = visiblePlate }
        repairBotGUID = guid
    end
    return true
end

local function STSMmayor_CurrentBotPlate(guid, frame)
    if not frame or not frame.IsShown or not frame:IsShown() or not frame.GetName then return false end
    local ok, currentGUID = pcall(frame.GetName, frame, 1)
    return ok and currentGUID == guid
end
