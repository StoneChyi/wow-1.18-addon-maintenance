assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_Group")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
    ["Group"] = "组队自动进组",
	["Who"] = "自动查询陌生人",
    ["Perform a /who on incoming party invites from unknown sources."] = "来自陌生人的消息，自动/Who查询",
	["Delay"] = "延迟设置",
	["With this option enabled, automatic joining or declining is delayed for 55 seconds."] = "启用此选项后，自动加入/拒绝将延迟55秒。",
    ["Declining party invitation..."] = "拒绝邀请。。。",
	["Accepting invite in 55..."] = "55秒后自动接受邀请。。。",
	["Declining invite in 55..."] = "55秒后自动拒绝邀请。。。",
	
	["Options for accepting or declining group invites."] = "自动接受/拒绝组队邀请（好友及工会）",
    ["Decline"] = "总是拒绝（好友及工会以外的）",
    ["Decline party invites from unknown sources."] = "自动拒绝组队邀请",
} end)



----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Group = Automaton:NewModule("Group")
Automaton_Group.modulename = L["Group"]
Automaton_Group.moduledesc = L["Options for accepting or declining group invites."]
Automaton_Group.options = {
	who = {
		type = 'toggle', name = L["Who"], desc = L["Perform a /who on incoming party invites from unknown sources."],
		order = 2,
		get = function() return Automaton_Group.db.profile.who end,
		set = function(v) Automaton_Group.db.profile.who = v end,
	},
	decline = {
		type = 'toggle', name = L["Decline"], desc = L["Decline party invites from unknown sources."],
		order = 3,
		get = function() return Automaton_Group.db.profile.decline end,
		set = function(v) Automaton_Group.db.profile.decline = v end,
	},
	delay = {
		type = 'toggle', name = L["Delay"], desc = L["With this option enabled, automatic joining or declining is delayed for 55 seconds."],
		order = 4,
		get = function() return Automaton_Group.db.profile.delay end,
		set = function(v) Automaton_Group.db.profile.delay = v end,
	}
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Group:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("Group")
	Automaton:RegisterDefaults("Group", "profile", {
		who = true,
		decline = false,
		delay = false,
		disabled = true,
	})
	Automaton:SetDisabledAsDefault(self, "Group")

	self:RegisterOptions(self.options)
end

-- One receiver owns party invitations. Module lifecycle flags are explicit:
-- Core persists its role/account disabled table after OnEnable/OnDisable.
local incoming = { active = {}, generation = 0 }
Automaton.incomingInvites = incoming
incoming.frame = CreateFrame("Frame")

function incoming:Cancel()
    self.generation = self.generation + 1
    self.pending = nil
    for _, name in ipairs({ "Group", "StrangerDecline" }) do
        local module = Automaton.modules[name]
        if module then
            for _, id in ipairs({ "Automaton_GroupPending", "Automaton_GroupBind",
                "Automaton_GroupAccept", "Automaton_GroupDecline" }) do
                module:CancelScheduledEvent(id)
            end
        end
    end
end

function incoming:Enable(name, enabled)
    self:Cancel()
    self.active[name] = enabled and true or nil
    self.frame:UnregisterAllEvents()
    if self.active.Group or self.active.StrangerDecline then
        for _, ev in ipairs({ "PARTY_INVITE_REQUEST", "PARTY_INVITE_CANCEL",
            "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD",
            "PLAYER_LEAVING_WORLD" }) do self.frame:RegisterEvent(ev) end
    end
end

function incoming:IsTrusted(from)
    GuildRoster()
    local lower = string.lower(from)
    for i=1,GetNumFriends() do
        local name = GetFriendInfo(i)
        if name and string.lower(name) == lower then return true end
    end
    for i=1,GetNumGuildMembers() do
        local name = GetGuildRosterInfo(i)
        if name and string.lower(name) == lower then return true end
    end
    return false
end

function incoming:Evaluate(from)
    if type(from) ~= "string" or from == "" then return "manual" end
    local guard = self.active.StrangerDecline and Automaton.modules.StrangerDecline
    if guard and guard:IsInBlackList(from) then return "decline", "blacklist" end
    local trusted = self:IsTrusted(from)
    if self.active.Group and trusted then return "accept", "trusted" end
    if guard and guard:IsInWhiteList(from) then return "manual", "whitelist" end
    if guard and not guard.isDisabled and guard.db.profile.partyEnabled and not trusted then
        return "decline", "stranger"
    end
    if self.active.Group and not trusted then
        if Automaton_Group.db.profile.decline then return "decline", "group" end
        if Automaton_Group.db.profile.who then return "manual", "who" end
    end
    return "manual"
end

function incoming:MatchesPopup(frame, from)
    if not frame or frame.which ~= "PARTY_INVITE" or not frame:IsShown() then return false end
    local dialog = StaticPopupDialogs and StaticPopupDialogs.PARTY_INVITE
    local template = dialog and dialog.text
    local label = frame:GetName() and _G[frame:GetName() .. "Text"]
    if type(template) ~= "string" or not label then return false end
    -- Do not guess a .data field. Use the native localized invitation template.
    -- A third-party rewrite that cannot be identified stays a manual decision.
    local ok, expected = pcall(string.format, template, from)
    return ok and label:GetText() == expected
end

function incoming:Apply(pending)
    if self.pending ~= pending or pending.generation ~= self.generation then return end
    if not self:MatchesPopup(pending.popup, pending.from) then self:Cancel();return end
    local decision, reason = self:Evaluate(pending.from)
    if decision ~= pending.decision then self:Cancel();return end
    local guard = Automaton.modules.StrangerDecline
    self:Cancel()
    if decision == "accept" then
        AcceptGroup()
    else
        DeclineGroup()
        if guard and (reason == "blacklist" or reason == "stranger") then
            guard:PrintPartyDecline(pending.from, reason)
        else Automaton_Group:print(L["Declining party invitation..."]) end
    end
    StaticPopup_Hide("PARTY_INVITE")
end

function incoming:Bind(pending)
    if self.pending ~= pending or pending.generation ~= self.generation then return end
    for i=1,(STATICPOPUP_NUMDIALOGS or 4) do
        local frame = _G["StaticPopup" .. i]
        if self:MatchesPopup(frame, pending.from) then
            pending.popup = frame
            if not frame.automatonInviteWatcher then
                frame.automatonInviteWatcher = true
                local onHide = frame:GetScript("OnHide")
                frame:SetScript("OnHide", function(...)
                    if incoming.pending and incoming.pending.popup == frame then incoming:Cancel() end
                    if onHide then return onHide(unpack(arg)) end
                end)
            end
            if pending.delayed then
                pending.owner:ScheduleEvent("Automaton_GroupPending", function()
                    incoming:Apply(pending)
                end, math.max(0, pending.deadline - GetTime()))
            else self:Apply(pending) end
            return
        end
    end
    self:Cancel()
end

function incoming:Request(from)
    self:Cancel()
    if not self.active.Group and not self.active.StrangerDecline then return end
    local decision, reason = self:Evaluate(from)
    if decision == "manual" then
        if reason == "who" then SendWho('n-"' .. from .. '"') end
        return
    end
    local delayed = self.active.Group and Automaton_Group.db.profile.delay
        and (reason == "trusted" or reason == "group")
    local owner = self.active.Group and Automaton_Group or Automaton.modules.StrangerDecline
    local pending = { generation = self.generation, from = from, decision = decision,
        owner = owner, delayed = delayed, deadline = GetTime() + 55 }
    self.pending = pending
    if delayed then
        Automaton_Group:print(decision == "accept" and L["Accepting invite in 55..."] or L["Declining invite in 55..."])
    end
    -- Wait one scheduler turn for the native UI event handler to show its popup.
    owner:ScheduleEvent("Automaton_GroupBind", function() incoming:Bind(pending) end, .05)
end

incoming.frame:SetScript("OnEvent", function()
    if event == "PARTY_INVITE_REQUEST" then incoming:Request(arg1)
    else incoming:Cancel() end
end)

-- Manual responses (including other addons) invalidate the delayed response.
-- Wrapping exactly once in this loaded chunk preserves native return values.
local acceptGroup, declineGroup = AcceptGroup, DeclineGroup
function AcceptGroup(...)
    incoming:Cancel()
    return acceptGroup(unpack(arg))
end
function DeclineGroup(...)
    incoming:Cancel()
    return declineGroup(unpack(arg))
end

function Automaton_Group:OnEnable() incoming:Enable("Group", true) end
function Automaton_Group:OnDisable()
    incoming:Enable("Group", false)
    self:UnregisterAllEvents()
end
function Automaton_Group:PARTY_INVITE_REQUEST(from) incoming:Request(from or arg1) end
function Automaton_Group:ProcessInvite(accept)
    local pending = incoming.pending
    if pending and (pending.decision == "accept") == accept then incoming:Apply(pending) end
end
