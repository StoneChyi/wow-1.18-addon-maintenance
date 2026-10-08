local module, L = BigWigs:ModuleDeclaration("Kruul", "Karazhan")

-- module variables
module.revision = 30001
module.enabletrigger = { module.translatedName, "库鲁尔", "Kruul" }
module.toggleoptions = { "markofthelord", "markofthelordmark", "remorsestrikes", "proximity", "bosskill" }
module.zonename = {
 AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
 AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
  "The Rock of Desolation",
  "外域",
  "荒芜王座",
}

local BC = AceLibrary("Babble-Class-2.2")
local _, playerClass = UnitClass("player")

-- module defaults
module.defaultDB = {
 markofthelord = true,
 markofthelordmark = true,
 remorsestrikes = playerClass ~= BC["MAGE"] and playerClass ~= BC["WARLOCK"] and playerClass ~= BC["HUNTER"],
 proximity = playerClass ~= BC["WARRIOR"] and playerClass ~= BC["ROGUE"],
}

local syncName = {
 markofthelord = "KruulMarkOfTheLord" .. module.revision,
 markofthelordFade = "KruulMarkOfTheLordFade" .. module.revision,
 remorselessStrikes = "KruulRemorselessStrikes" .. module.revision,
}

-- localization
L:RegisterTranslations("enUS", function()
 return {
  cmd = "Kruul",

  markofthelord_cmd = "markofthelord",
  markofthelord_name = "Mark of the Highlord Alert",
  markofthelord_desc = "Warns when players get afflicted by Mark of the Highlord",

  markofthelordmark_cmd = "markofthelordmark",
  markofthelordmark_name = "Mark of the Highlord Raid Mark",
  markofthelordmark_desc = "Marks players with Mark of the Highlord and restores previous mark when it fades",

  remorsestrikes_cmd = "remorsestrikes",
  remorsestrikes_name = "Next Remorseless Strikes Alert",
  remorsestrikes_desc = "Shows a timer for Kruul's next Remorseless Strikes",

  proximity_cmd = "proximity",
  proximity_name = "Proximity Warning",
  proximity_desc = "Show Proximity Warning Frame",

  trigger_markofthelordYou = "You are afflicted by Mark of the Highlord",
  trigger_markofthelordOther = "(.+) is afflicted by Mark of the Highlord",
  trigger_markofthelordFade = "Mark of the Highlord fades from you",
  trigger_markofthelordFadeOther = "Mark of the Highlord fades from (.+)",
  trigger_wrathOfTheHighlord = "Kruul gains Wrath of the Highlord",
  trigger_markofthelordFaderemove = "(.+) Highlord is removed",

  msg_markofthelordYou = "Mark of the Highlord on YOU - GET OUT!",
  msg_markofthelordOther = "Mark of the Highlord on %s!",
  msg_wrathOfTheHighlord = "Kruul is ENRAGED - Good luck!",

  bar_markofthelordExpires = "Mark on YOU! GET OUT!",
  bar_nextCurses = "Next Curses",

  sync_markofthelord = syncName.markofthelord .. "(.*)", -- pattern to isolate player name
  sync_markofthelordfade = syncName.markofthelordFade .. "(.*)", -- pattern to isolate player name

  bar_nextRemorselessStrikes = "Next Remorseless Strikes",
  trigger_remorselessStrikes = "Kruul's Remorseless Strikes",

  trigger_engage = "Stepping before the High Lord of the Burning Legion",
 }
end)

L:RegisterTranslations("zhCN", function()
 return {
   cmd = "Kruul",

   markofthelord_cmd = "markofthelord",
   markofthelord_name = "大领主印记警报",
   markofthelord_desc = "当玩家受到大领主印记效果影响时发出警告",

   markofthelordmark_cmd = "markofthelordmark",
   markofthelordmark_name = "大领主印记团队标记",
   markofthelordmark_desc = "为受到大领主印记影响的玩家添加团队标记，并在效果消失时恢复之前的标记",

   remorsestrikes_cmd = "remorsestrikes",
   remorsestrikes_name = "下一次冷漠打击警报",
   remorsestrikes_desc = "显示库鲁尔下一次冷漠打击的计时器",

   proximity_cmd = "proximity",
   proximity_name = "距离警告",
   proximity_desc = "显示距离警告框体",

   trigger_markofthelordYou = "^你受到了大领主印记效果的影响",
   trigger_markofthelordOther = "(.+)受到了大领主印记效果的影响",
   trigger_markofthelordFade = "大领主印记效果从你身上消失了",
   trigger_markofthelordFadeOther = "大领主印记效果从(.+)身上消失",
   trigger_wrathOfTheHighlord = "库鲁尔获得了大领主之怒",

   msg_markofthelordYou = "你身上有大领主印记 - 快躲开！",
   msg_markofthelordOther = "%s身上有大领主印记！",
   msg_wrathOfTheHighlord = "库鲁尔激怒了-祝好运！",

   bar_markofthelordExpires = "你身上有印记！躲开！",
   bar_nextCurses = "下一次诅咒",

   sync_markofthelord = syncName.markofthelord .. "(.*)", 
   sync_markofthelordfade = syncName.markofthelordFade .. "(.*)", 

   bar_nextRemorselessStrikes = "下一次冷漠打击",
   trigger_remorselessStrikes = "库鲁尔的冷漠打击",

   trigger_engage = "军团将会像它毁灭了无数其他世界一样焚烧这个世界！",
 }
end)

module.proximityCheck = function(unit)
 return CheckInteractDistance(unit, 2)
end
module.proximitySilent = true

module:RegisterYellEngage(L.trigger_engage)

-- timer and icon variables
local timer = {
 markofthelordDuration = 20,
 nextCurses = 30,
 nextCursesEnraged = 15,
 firstRemorselessStrikes = 2,
 remorselessStrikes = 4,
}

local icon = {
 markofthelord = "Spell_Shadow_AntiShadow",
 nextCurses = "Spell_Shadow_AntiShadow",
 remorselessStrikes = "Spell_Shadow_RaiseDead",
}

local color = {
 red = "Red",
}

function module:OnEnable()
 -- only use self + party to avoid rate limiting
 self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "AfflictionEvent")
 self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "AfflictionEvent")

 self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")
 self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER")
 self:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLY_DEATH", "OnFriendlyDeath")

 self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "DamageEvent") --trigger_ww
 self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE", "DamageEvent") --trigger_ww

 -- Add detection for Wrath of the Highlord
 self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS")

 -- other syncs will default to 1 second throttle
 self:ThrottleSync(1, syncName.remorselessStrikes)
 self:Message("友情提示：佩戴勇士印记/恶魔套装", "Important", false, nil, false)
end

function module:OnSetup()
 self.started = nil
 self.enragePhase = false
 

 -- Enable proximity warning
 if self.db.profile.proximity then
  self:Proximity()
 end
end

function module:OnEngage()
 self.enragePhase = false

 -- Start Next Curses timer when fight starts
 if self.db.profile.markofthelord then
  self:Bar(L["bar_nextCurses"], timer.nextCurses, icon.nextCurses)
 end

 -- Start first Remorseless Strikes timer
 if self.db.profile.remorsestrikes then
  self:Bar(L["bar_nextRemorselessStrikes"], timer.firstRemorselessStrikes, icon.remorselessStrikes)
 end

 -- Enable proximity warning
 if self.db.profile.proximity then
  self:Proximity()
 end
end

function module:OnDisengage()
 self:RemoveProximity()
end

function module:DamageEvent(msg)
 if string.find(msg, L["trigger_remorselessStrikes"]) then
  self:Sync(syncName.remorselessStrikes)
 end
end

function module:RemorselessStrikes()
 if self.db.profile.remorsestrikes then
  self:Bar(L["bar_nextRemorselessStrikes"], timer.remorselessStrikes, icon.remorselessStrikes)
 end
end

function module:CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS(msg)
 if string.find(msg, L["trigger_wrathOfTheHighlord"]) then
  self.enragePhase = true
  if self.db.profile.markofthelord then
   self:Message(L["msg_wrathOfTheHighlord"], "Important", true, "Alarm")
  end
 end
end

function module:AfflictionEvent(msg)
 -- Mark of the Highlord
 if string.find(msg, L["trigger_markofthelordYou"]) then
  self:Sync(syncName.markofthelord .. UnitName("player")) -- include player name in sync to throttle for each player
 else
  local _, _, player = string.find(msg, L["trigger_markofthelordOther"])
  if player then
   self:Sync(syncName.markofthelord .. player) -- include player name in sync to throttle for each player
  end
 end
end

function module:CHAT_MSG_SPELL_AURA_GONE_SELF(msg)
 if string.find(msg, L["trigger_markofthelordFade"]) then
  self:Sync(syncName.markofthelordFade .. UnitName("player"))
  self:RemoveBar(L["bar_markofthelordExpires"])
 end
end

function module:CHAT_MSG_SPELL_AURA_GONE_OTHER(msg)
 local _, _, player = string.find(msg, L["trigger_markofthelordFadeOther"])
 if player then
  self:Sync(syncName.markofthelordFade .. player)
 end
end

function module:OnFriendlyDeath(msg)
 local _, _, player = string.find(msg, "(.+)死亡了")
 if player then
  self:Sync(syncName.markofthelordFade .. player)
 end
end

function module:BigWigs_RecvSync(sync, rest, nick)
 if sync == syncName.remorselessStrikes then
  self:RemorselessStrikes()
  return
 end

 local _, _, markedPlayer = string.find(sync, L["sync_markofthelord"])

 if markedPlayer then
  self:MarkOfTheLord(markedPlayer)
  return
 end

 local _, _, unmarkedPlayer = string.find(sync, L["sync_markofthelordfade"])
 if unmarkedPlayer then
  self:MarkOfTheLordFade(unmarkedPlayer)
  return
 end
end

function module:MarkOfTheLord(player)
 if self.db.profile.markofthelord then
  if player == UnitName("player") then
   self:Sound("Beware")
   self:Message(L["msg_markofthelordYou"], "Important", true, "Alarm")
   self:WarningSign(icon.markofthelord, 5, true, "离开！")
   self:Bar(L["bar_markofthelordExpires"], timer.markofthelordDuration, icon.markofthelord, true, color.red)
  else
   self:Message(string.format(L["msg_markofthelordOther"], player), "Important", nil, "Alert")
  end

  -- Reset the next curses timer
  self:RemoveBar(L["bar_nextCurses"])
  if self.enragePhase then
   self:Bar(L["bar_nextCurses"], timer.nextCursesEnraged, icon.nextCurses)
  else
   self:Bar(L["bar_nextCurses"], timer.nextCurses, icon.nextCurses)
  end
 end

 -- Set raid mark if enabled
 if self.db.profile.markofthelordmark then
  self:SetCurseMark(player)
 end
end

function module:MarkOfTheLordFade(player)
 -- Restore previous raid mark if enabled
 if self.db.profile.markofthelordmark then
  self:RestoreMark(player)
 end
end

function module:SetCurseMark(player)
 local markToUse = self:GetAvailableRaidMark()
 if markToUse then
  self:SetRaidTargetForPlayer(player, markToUse)
 end
end

function module:RestoreMark(player)
 self:RestorePreviousRaidTargetForPlayer(player)
end