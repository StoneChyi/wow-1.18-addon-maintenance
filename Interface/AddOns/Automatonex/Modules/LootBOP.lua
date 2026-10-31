assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_LootBOP")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	["LootBOP"] = "拾取绑定确认",
	["Ignore BOP confirm message"] = "自动确认拾取后绑定物品；保留独立的队伍/团队开关",
	["Confirm in party/raid"] = "队伍/团队中也自动确认",
	["Also auto-confirm BOP loot when in a party or raid"] = "在小队或团队中也确认拾取后绑定物品；不会自动选择需求、贪婪或分配给玩家",
} end)



----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_LootBOP = Automaton:NewModule("LootBOP")
Automaton_LootBOP.modulename = L["LootBOP"]
Automaton_LootBOP.moduledesc = L["Ignore BOP confirm message"]
Automaton_LootBOP.options = {
	confirmInGroup = {
		type = "toggle",
		name = L["Confirm in party/raid"],
		desc = L["Also auto-confirm BOP loot when in a party or raid"],
		order = 1,
		get = function() return Automaton_LootBOP.db.profile.confirmInGroup end,
		set = function(v)
            Automaton_LootBOP.db.profile.confirmInGroup = v
            Automaton_LootBOP:CancelBindConfirmations()
            if Automaton_LootBOP.bindOwner then Automaton_LootBOP.bindOwner:CancelBindConfirmations() end
        end,
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_LootBOP:OnInitialize()
    self.db = Automaton:AcquireDBNamespace("LootBOP")
	Automaton:RegisterDefaults("LootBOP", "profile", {
		disabled = true,
		confirmInGroup = false,
	})
	Automaton:SetDisabledAsDefault(self, "LootBOP")

	self:RegisterOptions(self.options)
end

-- The native pfUI owner and the independent module share the saved policy.
-- Runtime flags do not depend on Core writing disabledModules after callbacks.
function Automaton_LootBOP:CancelBindConfirmations()
    self.bindGeneration = (self.bindGeneration or 0) + 1
    for slot in pairs(self.bindPending or {}) do
        self:CancelScheduledEvent("Automaton_LootBind" .. slot)
    end
    self.bindPending = {}
end

function Automaton_LootBOP:SetPfUILootOwner(owner)
    if self.bindOwner == owner then return end
    self:CancelBindConfirmations()
    self.bindOwner = owner
    self:UpdateBindEvents()
end

function Automaton_LootBOP:UpdateBindEvents()
    self:UnregisterAllEvents()
    if self.bindActive and not self.bindOwner then
        self:RegisterEvent("LOOT_BIND_CONFIRM")
        self:RegisterEvent("LOOT_OPENED", "CancelBindConfirmations")
        self:RegisterEvent("LOOT_CLOSED", "CancelBindConfirmations")
        self:RegisterEvent("PLAYER_LEAVING_WORLD", "CancelBindConfirmations")
        self:RegisterEvent("LOOT_SLOT_CLEARED")
    end
end

function Automaton_LootBOP:OnEnable()
    self.bindActive = true
    self:CancelBindConfirmations()
    local owner = pfUI and pfUI.loot
    if owner and owner.SyncBindOwnership then owner:SyncBindOwnership() end
    self:UpdateBindEvents()
end

function Automaton_LootBOP:OnDisable()
    self.bindActive = nil
    self:CancelBindConfirmations()
    self:UnregisterAllEvents()
    if self.bindOwner then self.bindOwner:CancelBindConfirmations() end
end

function Automaton_LootBOP:LOOT_SLOT_CLEARED(slot)
    if self.bindPending then self.bindPending[slot] = nil end
    self:CancelScheduledEvent("Automaton_LootBind" .. tostring(slot))
end

function Automaton_LootBOP:CanConfirmBind()
    return self.bindActive and not self.bindOwner and
        (self.db.profile.confirmInGroup or (GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0))
end

function Automaton_LootBOP:LOOT_BIND_CONFIRM(slot)
    if not self:CanConfirmBind() or type(slot) ~= "number" or slot < 1 or slot ~= math.floor(slot) then return end
    local link = GetLootSlotLink(slot)
    if not link then return end
    self.bindPending = self.bindPending or {}
    if self.bindPending[slot] then
      if self.bindPending[slot].executing then self.bindPending[slot].reentered = true end
      return
    end
    local receiver = self
    for i = 1, (STATICPOPUP_NUMDIALOGS or 4) do
      local dialog = _G["StaticPopup" .. i]
      if dialog and not dialog.automatonBindWatch then
        dialog.automatonBindWatch = true
        local onHide = dialog:GetScript("OnHide")
        dialog:SetScript("OnHide", function(...)
          if dialog.which == "LOOT_BIND" and receiver.bindPending then
            local task = receiver.bindPending[dialog.data]
            if task and not task.executing then receiver.bindPending[dialog.data] = nil end
          end
          if onHide then return onHide(unpack(arg)) end
        end)
      end
    end
    local pending = { link = link, generation = self.bindGeneration }
    self.bindPending[slot] = pending
    self:ScheduleEvent("Automaton_LootBind" .. slot, function()
        if self.bindPending[slot] ~= pending then return end
        if pending.generation ~= self.bindGeneration or not self:CanConfirmBind()
            or GetLootSlotLink(slot) ~= pending.link then self.bindPending[slot] = nil; return end
        -- UIParent sets LOOT_BIND.data to the native slot (WoW 1.12.1).
        -- Never create an approval popup or click an unrelated first popup.
        for i = 1, (STATICPOPUP_NUMDIALOGS or 4) do
            local dialog = _G["StaticPopup" .. i]
            if dialog and dialog:IsShown() and dialog.which == "LOOT_BIND" and dialog.data == slot then
                pending.executing = true
                local ok, err = pcall(LootSlot, slot)
                if ok and pending.generation == self.bindGeneration and not pending.reentered and (not self.bindPending[slot] or self.bindPending[slot] == pending)
                  and dialog:IsShown() and dialog.which == "LOOT_BIND" and dialog.data == slot then dialog:Hide() end
                if self.bindPending[slot] == pending then self.bindPending[slot] = nil end
                if not ok then geterrorhandler()(err) end
                return
            end
        end
        self.bindPending[slot] = nil
    end, 0.05)
end
