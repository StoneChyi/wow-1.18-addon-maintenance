local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}

CleveRoids.Hooks = CleveRoids.Hooks or {}

local Extension = CleveRoids.RegisterExtension("ag_UnitFrames")
Extension.RegisterEvent("ADDON_LOADED", "OnLoad")

function Extension.OnEnter(unit)
    CleveRoids.SetMouseoverFrom("aguf", unit)
end

function Extension.OnLeave()
    CleveRoids.ClearMouseoverFrom("aguf")
    CleveRoids.ClearMouseoverFrom("native")
end

-- Because AddOns are loaded in alphabetical order, this callback will never see the aUF loaded message, had to do a workaround...
function Extension.OnLoad()
    -- 修复：OnLoad 原名大小写笔误（Onload≠OnLoad）导致 ADDON_LOADED 永不注销、每次事件
    -- 重跑并把 Hooks 覆盖成本插件的 wrapper（丢失原函数）；补幂等标志 by 武藤纯子酱 2026.9.11
    if Extension.__cr_hooked then return end
    -- 修复：仅判 aUF 不够——aUF.classes.aUFunit.prototype 链条任一环节缺失
    -- （版本差异/半初始化）都会报错导致扩展失效 by 武藤纯子酱 2026.9.9
    if not (aUF and aUF.classes and aUF.classes.aUFunit and aUF.classes.aUFunit.prototype) then
        return
    end
    Extension.__cr_hooked = true
    CleveRoids.Hooks.ag_UnitFrames = { OnEnter = aUF.classes.aUFunit.prototype.OnEnter, OnLeave = aUF.classes.aUFunit.prototype.OnLeave}
    aUF.classes.aUFunit.prototype.OnEnter = CleveRoids.aUFOnEnter
    aUF.classes.aUFunit.prototype.OnLeave = CleveRoids.aUFOnLeave
    Extension.UnregisterEvent("ADDON_LOADED", "OnLoad")
end

-- Taken from ag_UnitClass.lua
function CleveRoids:aUFOnEnter()
    Extension.OnEnter(self.unit)
    self.frame.unit = self.unit
    self:UpdateHighlight(true)
    UnitFrame_OnEnter()
end

function CleveRoids:aUFOnLeave()
    Extension.OnLeave()
    self:UpdateHighlight()
    UnitFrame_OnLeave()
end


_G["CleveRoids"] = CleveRoids
