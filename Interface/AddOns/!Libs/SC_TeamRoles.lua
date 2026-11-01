-- Unified team-role consumer bridge; maintained by StoneChyi & Codex.
-- Optional SC_TeamRolesProvider API v1 supplies current-team facts only.
-- No editor, saved roster, network traffic, frame, or polling is installed here.
if type(SC_TeamRoles) == "table" and SC_TeamRoles.apiVersion == 1 then return end
SC_TeamRoles = { apiVersion = 1 }
local A = SC_TeamRoles
local warned = {}
local function Truth(v) return v ~= nil and v ~= false and v ~= 0 end

function A:IsReady()
    local p = SC_TeamRolesProvider
    if type(p) ~= "table" or p.apiVersion ~= 1 or type(p.GetRole) ~= "function" then return false end
    if p.IsReady ~= nil then
        if type(p.IsReady) ~= "function" then return false end
        local ok, ready = pcall(p.IsReady, p)
        return ok and (ready == true or ready == 1)
    end
    return true
end

function A:GetRole(unit)
    if type(unit) ~= "string" or unit == "" or not self:IsReady() then return nil end
    if type(UnitExists) ~= "function" or not Truth(UnitExists(unit)) then return nil end
    local p = SC_TeamRolesProvider
    local ok, role, order, source = pcall(p.GetRole, p, unit)
    if not ok or (role ~= "TANK" and role ~= "HEALER" and role ~= "DAMAGER") then return nil end
    if role == "TANK" then
        order = tonumber(order)
        if not order or order < 1 or order > 40 or order ~= math.floor(order) then order = nil end
    else order = nil end
    if type(source) ~= "string" then source = nil end
    return role, order, source
end

function A:IsTank(unit)
    local role = self:GetRole(unit)
    if role == nil then return nil end
    return role == "TANK"
end

function A:GetTankOrder(unit)
    local role, order = self:GetRole(unit)
    return role == "TANK" and order or nil
end

function A:WarnUnavailable(addon)
    addon = type(addon) == "string" and addon or "团队职责"
    if warned[addon] then return end
    warned[addon] = true
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(addon .. "：统一职责数据或指定目标未就绪，本次职责限定操作未执行。")
    end
end
