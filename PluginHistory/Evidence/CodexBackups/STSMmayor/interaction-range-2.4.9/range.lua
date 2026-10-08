-- Verified against the installed wsloot.dll: its object scan rejects center
-- distances above 5 yards, before the NPC branch's separate 6-yard check.
-- Match that effective 5-yard limit using 3D positions, including height.
local REPAIR_BOT_RANGE = 5

local function STSMmayor_ValidNumber(value)
    return type(value) == "number" and value - value == 0
end

local function STSMmayor_BotRange(unit)
    if type(UnitPosition) == "function" then
        local okPlayer, px, py, pz = pcall(UnitPosition, "player")
        local okUnit, x, y, z = pcall(UnitPosition, unit)
        if okPlayer and okUnit and STSMmayor_ValidNumber(px) and STSMmayor_ValidNumber(py)
            and STSMmayor_ValidNumber(pz) and STSMmayor_ValidNumber(x)
            and STSMmayor_ValidNumber(y) and STSMmayor_ValidNumber(z) then
            local dx, dy, dz = x - px, y - py, z - pz
            return dx * dx + dy * dy + dz * dz <= REPAIR_BOT_RANGE * REPAIR_BOT_RANGE, true
        end
    end
    if type(UnitXP) == "function" then
        local ok, distance = pcall(UnitXP, "distanceBetween", "player", unit)
        if ok and STSMmayor_ValidNumber(distance) and distance >= 0 then
            return distance <= REPAIR_BOT_RANGE, true
        end
    end
    -- Visible plates/targets alone cannot prove that a unit is within 5 yards.
    return nil, true
end

local function STSMmayor_RememberRepairBot(unit)
    if not STSMmayor_UnitIsRepairBot(unit) or STSMmayor_BotRange(unit) ~= true then return false end
    local guid = STSMmayor_GetBotGUID(unit)
    if guid then repairBotUnits[guid] = true; repairBotGUID = guid end
    return true
end

