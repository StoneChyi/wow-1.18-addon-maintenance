-- One player-link action dispatcher shared by pfUI chat and PlayerLinkEnhance.
-- It is an internal helper, not another independently enabled component.
do
  local links = { title = "聊天角色链接" }
  pfUI.chatPlayerLinks = links
  pfUI.automationIntegrations = pfUI.automationIntegrations or {}
  pfUI.automationIntegrations.InterPlayerLink = links

  function links:GetEnabled()
    return pfUI_config.chat and pfUI_config.chat.text and pfUI_config.chat.text.playerlinks == "1"
  end
  function links:SetEnabled(value)
    pfUI_config.chat.text.playerlinks = value and "1" or "0"
  end
  function links:Handle(link, text, button)
    if not self.ready or type(link) ~= "string" then return false end
    local _, _, name = string.find(link, "^player:([^:]+)")
    if not name or name == "" then return false end
    name = string.gsub(name, "([^%s]*)%s+([^%s]*)%s+([^%s]*)", "%3")
    name = string.gsub(name, "([^%s]*)%s+([^%s]*)", "%2")
    local enhanced = type(ple_SetItemRef) == "function"
    if IsShiftKeyDown() then
      -- An invitation/friend popup has priority even while chat is open.
      if enhanced then
        for _, which in ipairs({ "ADD_IGNORE", "ADD_FRIEND", "ADD_GUILDMEMBER", "ADD_RAIDMEMBER" }) do
          local popup = StaticPopup_Visible(which)
          local edit = popup and getglobal(popup .. "EditBox")
          if edit then edit:SetText(name); return true end
        end
      end
      if ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
        if self:GetEnabled() then
          ChatFrameEditBox:Insert("|cffffffff|Hplayer:" .. name .. "|h[" .. name .. "]|h|r")
        elseif enhanced then
          ChatFrameEditBox:Insert(name)
        else
          return false
        end
      elseif enhanced then
        SendWho("n-" .. name)
      else
        return false
      end
    elseif enhanced then
      if IsControlKeyDown() then TargetByName(name)
      elseif IsAltKeyDown() then ple_GetName(name)
      elseif button == "RightButton" then FriendsFrame_ShowDropdown(name, 1)
      else ChatFrame_SendTell(name) end
    else
      return false
    end
    return true
  end
  function links:Sync(enabled)
    local module = Automaton and Automaton.modules and Automaton.modules.InterPlayerLink
    if not enabled or not self.ready then
      if self.managed then
        self.managed = nil
        local bridge = AutomatonPfUIBridge
        if module and bridge and bridge:SavedActive("InterPlayerLink") then module:OnEnable() end
      end
      return true
    end
    if not module then return true end
    if not module.db or not module._options then return false end
    local db = pfUI_config.automation
    if not db then db = {}; pfUI_config.automation = db end
    if not db.playerlinksMigrated then
      local bridge = AutomatonPfUIBridge
      local active = bridge and bridge:SavedActive("InterPlayerLink") or Automaton:IsModuleActive("InterPlayerLink")
      if active then self:SetEnabled(true) end
      db.playerlinksMigrated = "1"
    end
    if not self.managed then
      self.managed = true
      module:OnDisable()
    end
    return true
  end
  function links:OpenSettings()
    if not pfUI.ShowGUI or not pfUI:ShowGUI() then return end
    local title = pfUI.env and pfUI.env.T and pfUI.env.T["Chat"] or "Chat"
    local entry = pfUI.gui and pfUI.gui.frames[title]
    if entry then entry:Click() end
  end
end
