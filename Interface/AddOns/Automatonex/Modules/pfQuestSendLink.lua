
local Automaton_pfQuestSendLink = Automaton:NewModule("pfQuestSendLink")
Automaton_pfQuestSendLink.modulename = "任务英文链接"
Automaton_pfQuestSendLink.moduledesc = "按住Ctrl点击任务标题发送英文名字的任务Link到聊天框"
Automaton_pfQuestSendLink.options = {}

------------------------------
--      Initialization      --
------------------------------

function Automaton_pfQuestSendLink:OnInitialize()
  
	self.db = Automaton:AcquireDBNamespace("pfQuestSendLink")
	Automaton:RegisterDefaults("pfQuestSendLink", "profile", {
		disabled = true,
	})
	Automaton:SetDisabledAsDefault(self, "pfQuestSendLink")
	self:RegisterOptions(self.options)
end

function Automaton_pfQuestSendLink:InstallHook()
    if self.runtimeActive and pfQuestCompat and type(pfQuestCompat.GetQuestLogTitle) == "function"
        and pfDatabase and type(pfDatabase.GetQuestIDs) == "function"
        and type(QuestLogTitleButton_OnClick) == "function"
        and not self:IsHooked("QuestLogTitleButton_OnClick") then self:Hook("QuestLogTitleButton_OnClick") end
end
function Automaton_pfQuestSendLink:OnEnable()
    if self.runtimeActive then self:InstallHook(); return end
    self.runtimeActive = true
    self:InstallHook()
    self:RegisterEvent("ADDON_LOADED", "InstallHook")
    if not pfQuestCompat or not pfDatabase then self:Print("pfQuest尚未就绪，英文任务链接暂用原点击处理。") end
end
function Automaton_pfQuestSendLink:OnDisable()
    self.runtimeActive = nil
    self:UnregisterAllEvents()
    self:UnhookAll()
end
function Automaton_pfQuestSendLink:TryQuestLink(button)
    if not self.runtimeActive or button ~= "LeftButton" or not IsControlKeyDown()
        or IsShiftKeyDown() or IsAltKeyDown() or not this or this.isHeader or not this.GetID
        or not ChatFrameEditBox or not ChatFrameEditBox:IsVisible() then return false end
    if not pfQuestCompat or type(pfQuestCompat.GetQuestLogTitle) ~= "function"
        or not pfDatabase or type(pfDatabase.GetQuestIDs) ~= "function" then return false end
    local scroll = EQL3_QuestLogListScrollFrame or ShaguQuest_QuestLogListScrollFrame or QuestLogListScrollFrame
    if not scroll or type(FauxScrollFrame_GetOffset) ~= "function" then return false end
    local index = this:GetID() + FauxScrollFrame_GetOffset(scroll)
    local title, level, tag, header = pfQuestCompat.GetQuestLogTitle(index)
    if type(title) ~= "string" or header then return false end
    local ids = pfDatabase:GetQuestIDs(index)
    local id = type(ids) == "table" and tonumber(ids[1])
    if not self:InsertQuestLink_enUS(id, title) then return false end
    if type(QuestLog_SetSelection) == "function" then QuestLog_SetSelection(index) end
    return true
end
function Automaton_pfQuestSendLink:QuestLogTitleButton_OnClick(button)
    if self:TryQuestLink(button) then return end
    return self.hooks.QuestLogTitleButton_OnClick(button)
end
function Automaton_pfQuestSendLink:InsertQuestLink_enUS(id, fallback)
    if not ChatFrameEditBox or type(fallback) ~= "string" then return false end
    local quests = pfDB and pfDB.quests
    local data = quests and quests.data and quests.data[id]
    local translation = quests and quests.enUS and quests.enUS[id]
    local title = translation and translation.T or fallback
    if type(title) ~= "string" or title == "" then return false end
    local level = data and tonumber(data.lvl) or 0
    local text = "[" .. title .. "]"
    if id and id > 0 and pfQuest_config and pfQuest_config.questlinks == "1" then
        local color = type(GetDifficultyColor) == "function" and GetDifficultyColor(level)
        local r, g, b = 1, 1, 1
        if type(color) == "table" then r, g, b = color.r or 1, color.g or 1, color.b or 1 end
        local function Byte(v) return math.floor(math.max(0, math.min(1, v)) * 255) end
        local hex = string.format("|cff%02x%02x%02x", Byte(r), Byte(g), Byte(b))
        text = hex .. "|Hquest:" .. id .. ":" .. level .. "|h[" .. title .. "]|h|r"
    end
    ChatFrameEditBox:Insert(text)
    return true
end
