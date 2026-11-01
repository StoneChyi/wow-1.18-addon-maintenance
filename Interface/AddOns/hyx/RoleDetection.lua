-- PureDispel adapter for the shared role service. Maintained by StoneChyi & Codex.
-- No private roster, talent request, health scan, override storage or timer.
local D = XinDispel
local R = { enabled = false, visible = true }
D.Roles = R
local function Service() return SC_TeamRolesService end
local function Legacy(role, style)
    if role == "DAMAGER" then return style end
    return role
end
function R.Get(name)
    local s = Service()
    return s and s:GetInfo(name) or nil
end
function R.Peek(name, key, class)
    local s = Service()
    if s and s.Peek then
        local rec, usable = s:Peek(name, key, class)
        if usable then return rec end
        return nil
    end
    local rec = R.Get(name)
    if rec and rec.key == key and rec.class == class then return rec end
end
function R.SetEnabled(value)
    value = value and true or false
    if R.enabled == value then return end
    R.enabled = value
    local s = Service()
    if s then
        if R.enabled then s:Acquire("PureDispel") else s:Release("PureDispel") end
    end
end
function R.SetVisible(value) R.visible = value and true or false end
function R.UpdateRoster() end -- The shared service owns team identity/lifecycle.
function R.Tick() end -- Compatibility only; no private driver remains.
function R.ResetTeam() end -- Hiding/resetting one consumer cannot erase shared data.
local function SetManual(name, role)
    local s = Service()
    if not s then return false, "统一职责服务尚未加载" end
    local rec = s:GetInfo(name)
    local old = rec and Legacy(rec.overrideRole, rec.overrideStyle)
    local canonical, style = role, nil
    if role == "MELEE" or role == "RANGED" then canonical, style = "DAMAGER", role end
    if role == "UNKNOWN" then canonical = nil end
    local ok, reason = s:SetOverride(name, canonical, style)
    return ok, reason, old
end
R.SetManual = SetManual
R.RestoreManual = SetManual
function R.Refresh()
    local s = Service()
    if not s then return false, "统一职责服务尚未加载" end
    return s:Refresh()
end
function R.StartValidation() return false, "请在pfUI团队职责页查看统一识别结果" end
function R.GetDiagnostics()
    local s = Service()
    if s then
        local result = s:GetDiagnostics()
        result.enabled = s:IsReady()
        return result
    end
    return {enabled=false,total=0,completed=0,unknown=0,state="paused",message="统一职责服务未加载"}
end
local s = Service()
if s then s:Subscribe("PureDispel", function() D.dirty = true end) end
