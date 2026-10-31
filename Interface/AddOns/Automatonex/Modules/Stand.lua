assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_Stand")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	["Stand"] = "自动站立",
	["Automatically stand when you receive the 'You must be standing' error"] = "当施法时，人物自动离开被系统判定为坐下的状态",
} end)



----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Stand = Automaton:NewModule("Stand")
Automaton_Stand.modulename = L["Stand"]
Automaton_Stand.moduledesc = L["Automatically stand when you receive the 'You must be standing' error"]
Automaton_Stand.options = {}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Stand:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("Stand")
	Automaton:RegisterDefaults("Stand", "profile", {
		disabled = false,
	})
	Automaton:SetDisabledAsDefault(self, "Stand")
	self:RegisterOptions(self.options)
end

-- Runtime ownership never changes the saved module preference.
function Automaton_Stand:UpdateMovementEvents()
    self:UnregisterAllEvents()
    if self.runtimeActive and not self.movementOwner then
        self:RegisterEvent("UI_ERROR_MESSAGE")
        self:RegisterEvent("UI_INFO_MESSAGE", "UI_ERROR_MESSAGE")
    end
end
function Automaton_Stand:SetMovementOwner(owner)
    if self.movementOwner == owner then return end
    self.movementOwner = owner
    self.lastMessage, self.lastStand = nil, nil
    self:UpdateMovementEvents()
end
function Automaton_Stand:OnEnable()
    self.runtimeActive = true
    if pfUI and pfUI.autoshift and pfUI.autoshift.SyncOwnership then pfUI.autoshift:SyncOwnership() end
    self:UpdateMovementEvents()
end
function Automaton_Stand:OnDisable()
    self.runtimeActive = nil
    self.lastMessage, self.lastStand = nil, nil
    self:UnregisterAllEvents()
    if pfUI and pfUI.autoshift and pfUI.autoshift.SyncOwnership then pfUI.autoshift:SyncOwnership() end
end
function Automaton_Stand:HandlesMessage(msg)
    return type(msg) == "string" and (msg == SPELL_FAILED_NOT_STANDING
        or msg == ERR_CANTATTACK_NOTSTANDING or msg == ERR_LOOT_NOTSTANDING or msg == ERR_TAXINOTSTANDING)
end
function Automaton_Stand:HandleError(msg)
    if not self.runtimeActive or not self:HandlesMessage(msg) then return false end
    local now = GetTime()
    if self.lastMessage == msg and self.lastStand and now - self.lastStand < .2 then return true end
    self.lastMessage, self.lastStand = msg, now
    UIErrorsFrame:Clear()
    -- Unlike SitOrStand, the explicit emote cannot toggle back to sitting.
    DoEmote("stand")
    return true
end
function Automaton_Stand:UI_ERROR_MESSAGE(msg)
    return self:HandleError(msg)
end
