assert(Automaton, "Automaton not found!")



----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_invall = Automaton:NewModule("invall")
Automaton_invall.modulename = "自动邀请周围玩家"
Automaton_invall.moduledesc = "按说话、大喊或密语关键字邀请玩家，可限制区域并单独控制自动升助理"
Automaton_invall.options = {}
local function Toggle(key, name, desc, order)
    return { type = "toggle", name = name, desc = desc, order = order,
        get = function() return Automaton_invall.db.profile[key] end,
        set = function(value) Automaton_invall.db.profile[key] = value end }
end
Automaton_invall.options.say = Toggle("say", "响应说话", "说话中包含 inv、invite 或组时邀请。", 1)
Automaton_invall.options.yell = Toggle("yell", "响应大喊", "大喊中包含 inv、invite 或组时邀请。", 2)
Automaton_invall.options.whisper = Toggle("whisper", "响应密语", "密语中包含 inv、invite 或组时邀请；组队密语邀请同时启用时，共用其邀请名单。", 3)
Automaton_invall.options.onlyWinterVeil = Toggle("onlyWinterVeil", "仅在冬幕谷邀请", "关闭时各区域均可邀请，与旧版实际行为一致。", 4)
Automaton_invall.options.promoteAssistant = Toggle("promoteAssistant", "自动提升新团员为助理", "仅自己为团长时生效；默认保留本模块原有升助理行为，可单独关闭。", 5)

------------------------------
--      Initialization      --
------------------------------

function Automaton_invall:OnInitialize()
    self.db = Automaton:AcquireDBNamespace("invall")
    Automaton:RegisterDefaults("invall", "profile", {
        disabled = true,
        say = true,
        yell = true,
        whisper = true,
        onlyWinterVeil = false,
        -- The old enabled module promoted every new raid member. Do not change
        -- existing module activation; make that behavior independently visible.
        promoteAssistant = true,
    })
    Automaton:SetDisabledAsDefault(self, "invall")

    self:RegisterOptions(self.options)
end

function Automaton_invall:OnEnable()
    self:ZONE_CHANGED_NEW_AREA()
    self:RegisterEvent("CHAT_MSG_WHISPER")
    self:RegisterEvent("CHAT_MSG_SAY")
    self:RegisterEvent("CHAT_MSG_YELL")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("CHAT_MSG_SYSTEM")
end

function Automaton_invall:OnDisable()
    self:UnregisterAllEvents()
end

function Automaton_invall:ZONE_CHANGED_NEW_AREA()
    self.zone = GetZoneText()
end
function Automaton_invall:CHAT_MSG_SYSTEM(text)
    if not self.db.profile.promoteAssistant or GetNumRaidMembers() == 0 then return end
    local leader
    for i = 1, GetNumRaidMembers() do
        local name, rank = GetRaidRosterInfo(i)
        if name == UnitName("player") and rank == 2 then leader = true; break end
    end
    if not leader then return end
    text = text or arg1
    if type(text) ~= "string" then return end
    local _, _, playername = string.find(text, "^(.+)加入了团队$")
    if playername and playername ~= UnitName("player") then PromoteToAssistant(playername) end
end
function Automaton_invall:InvUnit(text, player, channel)
    if not self.db.profile[channel] then return end
    if self.db.profile.onlyWinterVeil and self.zone ~= "冬幕谷" then return end
    if type(text) ~= "string" or type(player) ~= "string" then return end
    local invite = Automaton.modules and Automaton.modules.Invite
    if channel == "whisper" and invite and invite.outgoingEnabled and not invite:IsSenderAllowed(player) then return end
    local msg = string.lower(text)
    if not (string.find(msg, "组", 1, true) or string.find(msg, "inv", 1, true)) then return end
    local sender = Automaton.outgoingInvites
    if sender then sender:Send(player, false) end
end
function Automaton_invall:CHAT_MSG_WHISPER(text, player) self:InvUnit(text, player, "whisper") end
function Automaton_invall:CHAT_MSG_SAY(text, player) self:InvUnit(text, player, "say") end
function Automaton_invall:CHAT_MSG_YELL(text, player) self:InvUnit(text, player, "yell") end
