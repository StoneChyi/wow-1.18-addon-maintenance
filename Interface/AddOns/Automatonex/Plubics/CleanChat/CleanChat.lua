local Automaton_CleanChat

local PURGE_INTERVAL             = 60 * 5; -- every 5 minutes remove names which are timed out.
local nextPurgeCheck             = GetTime() + PURGE_INTERVAL;
--local Gratuity = AceLibrary("Gratuity-2.0")
local loc                        = GetLocale()
local HC_LEVEL_RANGE             = 5
local strsub                     = string.sub
local RANDOM_ROLL_RESULT = "(.+)掷出(%d+)（(%d+)%-(%d+)）"
local EVENTS_EMOTES              = {
  ["CHAT_MSG_BG_SYSTEM_ALLIANCE"] = true,
  ["CHAT_MSG_BG_SYSTEM_HORDE"] = true,
  ["CHAT_MSG_BG_SYSTEM_NEUTRAL"] = true,
  ["CHAT_MSG_EMOTE"] = true,
  ["CHAT_MSG_TEXT_EMOTE"] = true,
  ["CHAT_MSG_MONSTER_EMOTE"] = true,
  ["CHAT_MSG_MONSTER_SAY"] = true,
  ["CHAT_MSG_MONSTER_WHISPER"] = true,
  ["CHAT_MSG_MONSTER_YELL"] = true,
  ["CHAT_MSG_RAID_BOSS_EMOTE"] = true
};
local CHANNELE_MSG_EVENT         = {
  CHAT_MSG_CHANNEL = true,
  CHAT_MSG_YELL = true,
  CHAT_MSG_SAY = true,
  CHAT_MSG_GUILD = true,
  --CHAT_MSG_HARDCORE = true,
  CHAT_MSG_WHISPER = true,
  CHAT_MSG_HARDCORE = true,
  CHAT_MSG_LOOT = true,  -- 添加战利品消息
  CHAT_MSG_PARTY = true,        -- 队伍频道（供频道选择使用）
  CHAT_MSG_PARTY_LEADER = true, -- 队长说话（并入队伍频道）
}
-- local FACTION_COLOR = {
--   ["BL"] = fontRed,
--   ["LM"] = fontBlue,
-- }

-- ========== 修正1：变量名拼写错误 fiter → filter ==========
local filter = {
  "Delete your WDB",
  "If you want to",
  "Discord server",
  "All gold transactions are heavily",
  'Tune in to Everlook',
  'We encourage everyone to change',
  'Welcome to Turtle WoW! ',
  '/join world to connect with the community around you!',
}

-- 默认颜色定义
local DEFAULT_COLORS = {
    highlight = {0.2, 1.0, 0.8},    -- 对应33ffcc
    hardcore = {0.9, 0.8, 0.5},      -- 对应e6cd80
    roll = {0.0, 1.0, 1.0},          -- 对应00FFFF
}

-----------------------------------------------------------------------
---                   公调函数
-----------------------------------------------------------------------
local function firstToUpper(str)
  return (gsub(str, "^%l", string.upper))
end

-- 辅助函数：将RGB值转换为十六进制颜色字符串
local function RGBToHex(rgb)
    local r = math.floor(rgb[1] * 255 + 0.5)
    local g = math.floor(rgb[2] * 255 + 0.5)
    local b = math.floor(rgb[3] * 255 + 0.5)
    return string.format("%02x%02x%02x", r, g, b)
end

-- 防重复弹窗机制
local lastPopupTime = 0
local lastPopupMessage = ""
local POPUP_COOLDOWN = 0.5 -- 0.5秒的冷却时间，防止重复弹窗
local SERVER_RESTART_COOLDOWN = 30 -- 服务器重启弹窗冷却（秒），避免倒计时刷屏；分钟级广播下约每分钟提示一次
local lastServerRestartPopup = 0

local function ShouldShowPopup(message)
    if Automaton_CleanChat and Automaton_CleanChat.renderPass then return false end
    local currentTime = GetTime()
    if message == lastPopupMessage and (currentTime - lastPopupTime) < POPUP_COOLDOWN then
        return false
    end
    lastPopupTime = currentTime
    lastPopupMessage = message
    return true
end

-- 频道识别：把聊天事件映射为与"自动喊话"一致的频道 key（服务器基本就这几个频道）
-- channelName 取全局 arg9（1.12 里 CHAT_MSG_CHANNEL 的 arg9 是不带编号的频道名，如 "世界"/"World"）
local function CleanChat_GetChannelKey(event, channelName)
    if event == "CHAT_MSG_YELL" then return "yell" end
    if event == "CHAT_MSG_SAY" then return "say" end
    if event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER" then return "party" end
    if event == "CHAT_MSG_GUILD" then return "guild" end
    if event == "CHAT_MSG_HARDCORE" then return "Hardcore" end
    if event == "CHAT_MSG_CHANNEL" then
        local name = channelName or ""
        local nameLower = string.lower(name)
        -- 世界频道：精确匹配或前缀匹配（排除防务频道）
        if nameLower == "世界" or nameLower == "world" or nameLower == "世界频道" then
            return "world"
        end
        if string.find(nameLower, "^世界") or string.find(nameLower, "^world") then
            if not (string.find(nameLower, "防务") or string.find(nameLower, "defense")) then
                return "world"
            end
        end
        return "channel"  -- 其它自定义频道（交易/综合/组队频道等）
    end
    return nil
end


Automaton_CleanChat = Automaton:NewModule("CleanChat")
Automaton_CleanChat.modulename = "聊天增强"
Automaton_CleanChat.moduledesc = "聊天增强，包含很多实用的功能，可以单独开启关闭。"
Automaton_CleanChat.options = {
  -- ===== 硬核频道 =====
  header_hc = {
    type = "header",
    name = "硬核频道",
    order = 10,
  },
  HCFFrame = {
    type = "text",
    name = "设置HC显示窗口",
    desc = "指定HC频道消息显示在第一个聊天窗口1-9",
    order = 11,
    get = function() return Automaton_CleanChat.db.profile.HCFFrame end,
    set = function(v) Automaton_CleanChat.db.profile.HCFFrame = tonumber(v) end,
  },
  onoff = {
    type = "toggle",
    name = "关闭HC频道消息",
    desc = "关闭HC频道消息，不再显示",
    order = 12,
    get = function() return Automaton_CleanChat.db.profile.onoff end,
    set = function(v) Automaton_CleanChat.db.profile.onoff = v end,
  },
  hcDeathPopup = {
    type = 'toggle',
    name = "硬核死亡弹窗",
    desc = "当有硬核玩家死亡时在屏幕中央弹窗显示",
    order = 13,
    get = function() return Automaton_CleanChat.db.profile.hcDeathPopup end,
    set = function(v) Automaton_CleanChat.db.profile.hcDeathPopup = v end,
  },
  hcColour = {
    type = "color",
    name = "硬核频道颜色",
    desc = "设置硬核频道消息的颜色",
    order = 14,
    hasAlpha = false,
    get = function()
        return unpack(Automaton_CleanChat.db.profile.hcColour)
    end,
    set = function(r, g, b, a)
        Automaton_CleanChat.db.profile.hcColour = {r, g, b}
        Automaton_CleanChat:Print("硬核频道颜色已更新")
    end,
  },

  -- ===== 弹窗提醒 =====
  header_popup = {
    type = "header",
    name = "弹窗提醒",
    order = 20,
  },
  tradePopup = {
    type = 'toggle',
    name = "交易消息弹窗提醒",
    desc = "当有玩家交易物品时，在屏幕中央弹窗高亮显示",
    order = 21,
    get = function() return Automaton_CleanChat.db.profile.tradePopup end,
    set = function(v) Automaton_CleanChat.db.profile.tradePopup = v end,
  },
  CleanChat_Popup = {
    type = 'toggle',
    name = "弹窗显示有自己名字的聊天",
    desc = "当聊天中包含自己的名字时屏幕中间弹窗显示",
    order = 22,
    get = function() return Automaton_CleanChat.db.profile.CleanChat_Popup end,
    set = function(v) Automaton_CleanChat.db.profile.CleanChat_Popup = v end,
  },
  showpopup = {
    type = 'toggle',
    name = "关键字屏幕中央提醒",
    desc = "当出现关键字时在屏幕中央显示整句聊天内容",
    order = 23,
    get = function() return Automaton_CleanChat.db.profile.showpopup end,
    set = function(v) Automaton_CleanChat.db.profile.showpopup = v end,
  },
  keywordChannel = {
    type = 'text',
    name = "关键字监听频道",
    desc = "选择关键字高亮和弹窗提醒监听的频道，选\"全部频道\"则监听所有频道",
    order = 24,
    get = function() return Automaton_CleanChat.db.profile.keywordChannel end,
    set = function(v) Automaton_CleanChat.db.profile.keywordChannel = v end,
    validate = {
      ["all"] = "全部频道",
      ["yell"] = "喊话频道",
      ["say"] = "说",
      ["party"] = "队伍",
      ["guild"] = "公会",
      ["world"] = "世界频道",
      ["Hardcore"] = "硬核",
    },
  },

  -- ===== 关键字管理 =====
  header_keyword = {
    type = "header",
    name = "关键字管理",
    order = 30,
  },
  highlightColour = {
    type = "color",
    name = "高亮关键字颜色",
    desc = "设置高亮关键字的颜色",
    order = 31,
    hasAlpha = false,
    get = function()
        return unpack(Automaton_CleanChat.db.profile.highlightColour)
    end,
    set = function(r, g, b, a)
        Automaton_CleanChat.db.profile.highlightColour = {r, g, b}
        Automaton_CleanChat:Print("高亮颜色已更新")
    end,
  },
  HighlightText = {
    type = "group",
    name = "高亮关键字",
    desc = "聊天内容会高亮显示的关键字",
    order = 32,
    args = {
      list = {
        type = "execute",
        name = "打印关键字列表",
        desc = "打印输出所有已经保持的关键字列表",
        order = 1,
        func = function() Automaton_CleanChat:ListKeyworld(Automaton_CleanChat.db.profile.THighlightText) end
      },
      add = {
        type = "text",
        name = "添加关键字（按回车确认）",
        desc = "添加指定关键字，一次添加一个关键字，可以说是一个字也可以是词语，按回车确认输入",
        order = 2,
        usage = "<一次一个关键字>",
        get = false,
        set = function(v) Automaton_CleanChat:AddKeyword(Automaton_CleanChat.db.profile.THighlightText, v) end,
      },
      remove = {
       type = "text",
       name = "删除关键字（按回车确认）",
       desc = "删除指定关键字...",
       order = 3,
       usage = "<一次一个关键字>",
       get = false,
       set = function(v) Automaton_CleanChat:RemoveKeyword(Automaton_CleanChat.db.profile.THighlightText, v) end,
     },
      purge = {
        type = "execute",
        name = "清除全部关键字",
        desc = "清除全部关键字，清空关键字列表（会先弹窗二次确认）。",
        order = 4,
        func = function()
          -- 先弹确认框，防止误点一下就把全部高亮关键字清空
          local count = table.getn(Automaton_CleanChat.db.profile.THighlightText)
          Automaton_CleanChat:ShowPurgePopup("CLEANCHAT_PURGE_HIGHLIGHT", count)
        end
      }
    },
  },
  FilterKeyworld = {
    type = "group",
    name = "屏蔽关键字",
    desc = "屏蔽聊天内容的关键字",
    order = 33,
    args = {
      hasunitname = {
        type = 'toggle',
        name = "关键字对角色名有效",
        desc = "屏蔽聊天内容的关键字是对包含关键字的角色名生效",
        order = 1,
        get = function() return Automaton_CleanChat.db.profile.hasunitname end,
        set = function(v) Automaton_CleanChat.db.profile.hasunitname = v end,
      },
      list = {
        type = "execute",
        name = "打印关键字列表",
        desc = "打印输出所有已经保持的关键字列表",
        order = 2,
        func = function() Automaton_CleanChat:ListKeyworld(Automaton_CleanChat.db.profile.TFilterKeyworld) end
      },
      add = {
        type = "text",
        name = "添加关键字（按回车确认）",
        desc = "添加指定关键字，一次添加一个关键字，可以说是一个字也可以是词语，按回车确认输入",
        order = 3,
        usage = "<一次一个关键字>",
        get = false,
        set = function(v) Automaton_CleanChat:AddKeyword(Automaton_CleanChat.db.profile.TFilterKeyworld, v) end,
      },
      remove = {
        type = "text",
        name = "删除关键字（按回车确认）",
        desc = "删除指定关键字，一次添加一个关键字，按回车确认输入（必须于输入时相同）",
        order = 4,
        usage = "<一次一个关键字>",
        get = false,
        set = function(v) Automaton_CleanChat:RemoveKeyword(Automaton_CleanChat.db.profile.TFilterKeyworld, v) end,
      },
      purge = {
        type = "execute",
        name = "清除全部关键字",
        desc = "清除全部关键字，清空关键字列表（会先弹窗二次确认）。",
        order = 5,
        func = function()
          -- 先弹确认框，防止误点一下就把全部屏蔽关键字清空
          local count = table.getn(Automaton_CleanChat.db.profile.TFilterKeyworld)
          Automaton_CleanChat:ShowPurgePopup("CLEANCHAT_PURGE_FILTER", count)
        end
      }
    },
  },

  -- ===== ROLL点与组队 =====
  header_roll = {
    type = "header",
    name = "ROLL点与组队",
    order = 40,
  },
  highlightroll = {
    type = 'toggle',
    name = "高亮自己的ROLL点信息",
    desc = "高亮显示自己的roll点信息，装绑自动ROLL点和自己手动ROLL点信息",
    order = 41,
    get = function() return Automaton_CleanChat.db.profile.highlightroll end,
    set = function(v) Automaton_CleanChat.db.profile.highlightroll = v end,
  },
  rollColour = {
    type = "color",
    name = "ROLL点高亮颜色",
    desc = "设置自己ROLL点信息的高亮颜色",
    order = 42,
    hasAlpha = false,
    get = function()
        return unpack(Automaton_CleanChat.db.profile.rollColour)
    end,
    set = function(r, g, b, a)
        Automaton_CleanChat.db.profile.rollColour = {r, g, b}
        Automaton_CleanChat:Print("ROLL点颜色已更新")
    end,
  },
  clickinvite = {
    type = 'toggle',
    name = "关键字组队链接",
    desc = "聊天中包含INV,组我等关键字时生成组队链接",
    order = 43,
    get = function() return Automaton_CleanChat.db.profile.clickinvite end,
    set = function(v) Automaton_CleanChat.db.profile.clickinvite = v end,
  },

  -- ===== 战利品庆祝 =====
  header_loot = {
    type = "header",
    name = "战利品庆祝",
    order = 50,
  },
  lootCelebration = {
    type = "toggle",
    name = "战利品庆祝",
    desc = "获得特定物品时自动庆祝",
    order = 51,
    get = function() return Automaton_CleanChat.db.profile.lootCelebration end,
    set = function(v) Automaton_CleanChat.db.profile.lootCelebration = v end,
  },
  lootCelebrationItems = {
    type = "group",
    name = "庆祝物品列表",
    desc = "设置获得哪些物品时庆祝",
    order = 52,
    args = {
      addItem = {
        type = "text",
        name = "添加庆祝物品",
        desc = "输入物品名称（按回车确认）",
        order = 1,
        usage = "<物品名称>",
        get = false,
        set = function(v)
          Automaton_CleanChat:AddLootCelebrationItem(v)
        end,
      },
      removeItem = {
        type = "text",
        name = "删除庆祝物品",
        desc = "删除物品名称（按回车确认）",
        order = 2,
        usage = "<物品名称>",
        get = false,
        set = function(v)
          Automaton_CleanChat:RemoveLootCelebrationItem(v)
        end,
      },
      listItems = {
        type = "execute",
        name = "列出所有庆祝物品",
        desc = "显示当前设置的庆祝物品列表",
        order = 3,
        func = function()
          Automaton_CleanChat:ListLootCelebrationItems()
        end
      },
      resetItems = {
        type = "execute",
        name = "重置为默认列表",
        desc = "重置庆祝物品列表为默认值",
        order = 4,
        func = function()
          Automaton_CleanChat.db.profile.lootCelebrationItems = {
            "正义宝珠",
            "骨火",
            "黑莲花",
            "奥术水晶",
            "恶魔布",
            "提布的炽炎长剑",
            "克罗之刃",
            "失落遗骸",
          }
          Automaton_CleanChat:Print("庆祝物品列表已重置为默认值")
        end
      },
    }
  },

  -- ===== 外观设置 =====
  header_appearance = {
    type = "header",
    name = "外观设置",
    order = 60,
  },
  chatFontHeights = {
    type = "text",
    name = "聊天字号范围",
    desc = "设置可用字号列表，用英文逗号分隔，例如：10,12,14,16,18,20,22,24",
    order = 61,
    get = function()
        return Automaton_CleanChat.db.profile.chatFontHeightsString
    end,
    set = function(v)
        Automaton_CleanChat.db.profile.chatFontHeightsString = v
        Automaton_CleanChat:ApplyChatFontHeights(v)
        Automaton_CleanChat:Print("聊天字号范围已更新: " .. v)
    end,
  },
  resetColors = {
    type = "execute",
    name = "重置颜色",
    desc = "将所有颜色重置为默认值",
    order = 62,
    func = function()
        Automaton_CleanChat.db.profile.highlightColour = {unpack(DEFAULT_COLORS.highlight)}
        Automaton_CleanChat.db.profile.hcColour = {unpack(DEFAULT_COLORS.hardcore)}
        Automaton_CleanChat.db.profile.rollColour = {unpack(DEFAULT_COLORS.roll)}
        Automaton_CleanChat:Print("所有颜色已重置为默认值")
    end,
  },
}

------------------------------
--      Initialization      --
------------------------------

local playerName = UnitName('player')
function Automaton_CleanChat:OnInitialize()
  --AceLibrary("AceHook-2.1"):embed(Automaton_CleanChat)
  self.db = Automaton:AcquireDBNamespace("CleanChat")
  Automaton:RegisterDefaults("CleanChat", "profile", {
    disabled = false,
    CleanChat_Popup = true,
    ShowChatTime = false,
    
    clickinvite = true,
    hasunitname = false,
    CopyChatTime = true,
    whispersound = false,
    HighlightText = true,
    FilterKeyworld = true,
    
    highlightroll = true,
    showpopup = true,
    hcDeathPopup = true, -- 添加硬核死亡弹窗开关，默认开启
    tradePopup = true,   -- 交易消息弹窗开关，默认开启
    keywordChannel = "all", -- 关键字高亮/弹窗监听的频道，默认全部
    THighlightText = {},
    TFilterKeyworld = {},

    onoff = false,
    HCFFrame = 1,
    --HCFLevelFilter = true,
    
    -- 战利品庆祝功能
    lootCelebration = true,
    lootCelebrationItems = {
      "正义宝珠",
      "骨火",
      "黑莲花",
      "奥术水晶",
      "恶魔布",
      "提布的炽炎长剑",
      "瑞文戴尔之剑",
      "克罗之刃",
    },
    
    -- 添加颜色配置
    highlightColour = {unpack(DEFAULT_COLORS.highlight)},
    hcColour = {unpack(DEFAULT_COLORS.hardcore)},
    rollColour = {unpack(DEFAULT_COLORS.roll)},
    -- 新增：聊天字号范围默认值
    chatFontHeightsString = "10,12,14,16,18,20,22,24",
  })
  Automaton:SetDisabledAsDefault(self, "CleanChat")
  self:RegisterOptions(self.options)
  self:RegisterStaticPopups()  -- 注册「清除全部关键字」的二次确认弹窗
end

-- Event notices run once per native event, independently of the number of chat windows.
local noticeEvents = { "CHAT_MSG_SYSTEM", "CHAT_MSG_LOOT", "CHAT_MSG_HARDCORE", "CHAT_MSG_CHANNEL",
  "CHAT_MSG_YELL", "CHAT_MSG_SAY", "CHAT_MSG_GUILD", "CHAT_MSG_WHISPER", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER" }
function Automaton_CleanChat:SetChatOwner(owner)
  if self.chatOwner == owner then return end
  self:RestoreVisuals()
  self.chatOwner = owner
  if self.runtimeActive and not owner then self:ApplyVisuals() end
end
function Automaton_CleanChat:OnEnable()
  if self.runtimeActive then return end
  self.runtimeActive = true
  self:Hook("ChatFrame_OnEvent")
  self:Hook("SetItemRef")
  for i = 1, NUM_CHAT_WINDOWS do
    local frame = getglobal("ChatFrame" .. i)
    if frame then self:Hook(frame, "AddMessage") end
  end
  if not self.noticeFrame then
    self.noticeFrame = CreateFrame("Frame")
    self.noticeFrame:SetScript("OnEvent", function()
      if self.runtimeActive then self:NotifyEvent(event, arg1, arg2, arg9) end
    end)
  end
  for _, kind in ipairs(noticeEvents) do
    local known = kind == "CHAT_MSG_CHANNEL"
    for _, events in pairs(ChatTypeGroup or {}) do
      for _, registered in pairs(events) do if registered == kind then known = true; break end end
      if known then break end
    end
    if known then self.noticeFrame:RegisterEvent(kind) end
  end
  if pfUI and pfUI.chat and pfUI.chat.SyncAutomation then pfUI.chat:SyncAutomation() end
  if not self.chatOwner then self:ApplyVisuals() end
  self:RegisterEvent("VARIABLES_LOADED", "OnEvent")
end
function Automaton_CleanChat:OnDisable()
  self.runtimeActive = nil
  self:UnhookAll()
  self:UnregisterAllEvents()
  if self.noticeFrame then self.noticeFrame:UnregisterAllEvents() end
  self:RestoreVisuals()
end

-- ===== 「清除全部关键字」二次确认弹窗 =====
-- 高亮 / 屏蔽两组各注册一个，避免误点一下就把整份关键字列表清空。
-- 弹窗文案里的 %s 由 StaticPopup_Show(dialog, arg1) 的 arg1 填充（这里传当前关键字数量）。
function Automaton_CleanChat:RegisterStaticPopups()
  StaticPopupDialogs["CLEANCHAT_PURGE_HIGHLIGHT"] = {
    text = "确定要清除全部高亮关键字吗？\n当前共 %s 个关键字，清除后将无法恢复。",
    button1 = "确定",
    button2 = "取消",
    OnAccept = function()
      Automaton_CleanChat:PurgeTHighlightText()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
  }

  StaticPopupDialogs["CLEANCHAT_PURGE_FILTER"] = {
    text = "确定要清除全部屏蔽关键字吗？\n当前共 %s 个关键字，清除后将无法恢复。",
    button1 = "确定",
    button2 = "取消",
    OnAccept = function()
      Automaton_CleanChat:PurgeTFilterKeyworld()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
  }
end

-- 弹出确认框，并把弹窗抬到 TOOLTIP 层。
-- 原因：Automaton 主窗口本身是 DIALOG 层、且比 FrameXML 的 StaticPopup1~4 后创建，
-- 同层同级别时新窗口在上，会把弹窗的「确定/取消」压住点不到。
function Automaton_CleanChat:ShowPurgePopup(which, count)
  count = count or 0
  if count <= 0 then
    self:Print("关键字列表为空，无需清除")
    return
  end

  local dialog = StaticPopup_Show(which, tostring(count))
  if not dialog then
    -- 老版本 StaticPopup_Show 不返回 frame，按 which 回查一次
    for i = 1, 10 do
      local f = getglobal("StaticPopup" .. i)
      if not f then break end
      if f:IsShown() and f.which == which then
        dialog = f
        break
      end
    end
  end
  if dialog and dialog.SetFrameStrata then
    dialog:SetFrameStrata("TOOLTIP")
  end
end

-- 新增：事件处理
function Automaton_CleanChat:OnEvent(event, ...)
  if self.runtimeActive and not self.chatOwner and event == "VARIABLES_LOADED" then
    self:ApplyChatFontHeights()
  end
end

function Automaton_CleanChat:ListKeyworld(t)
  if table.getn(t) == 0 then
    self:Print("关键字列表为空")
  else
    self:Print("关键字为:")
    for k, v in pairs(t) do
      self:Print(v)
    end
  end
end

-- ========== 修改1：AddKeyword 过滤空字符串 ==========
function Automaton_CleanChat:AddKeyword(t, v)
  if not v then return end
  v = gsub(v, "^%s*(.-)%s*$", "%1")  -- 去除首尾空格
  if v ~= "" then
    tinsert(t, v)
  end
end

-- ========== 修改2：RemoveKeyword 使用 table.remove 保持紧凑 ==========
function Automaton_CleanChat:RemoveKeyword(t, item)
  if not item or item == "" then return end
  for i = table.getn(t), 1, -1 do
    if t[i] == item then
      table.remove(t, i)
    end
  end
end

function Automaton_CleanChat:PurgeTFilterKeyworld()
  self:Print("共清理关键字：" .. table.getn(Automaton_CleanChat.db.profile.TFilterKeyworld) .. " 个")
  Automaton_CleanChat.db.profile.TFilterKeyworld = {}
end

function Automaton_CleanChat:PurgeTHighlightText(t)
  self:Print("共清理关键字：" .. table.getn(Automaton_CleanChat.db.profile.THighlightText) .. " 个")
  Automaton_CleanChat.db.profile.THighlightText = {}
end

-- ===== 新增：应用聊天字号范围 =====
function Automaton_CleanChat:ApplyChatFontHeights(str)
    if not self.runtimeActive or self.chatOwner then return end
    if not str then str = self.db.profile.chatFontHeightsString end
    local nums = {}
    for num in string.gfind(str, "[^,]+") do
        local n = tonumber(num)
        if n then table.insert(nums, n) end
    end
    -- 使用 table.getn 替代 # 避免解析错误
    if table.getn(nums) > 0 then
        self.visuals = self.visuals or {}
        if not self.visuals.fontCaptured then self.visuals.fontBefore, self.visuals.fontCaptured = CHAT_FONT_HEIGHTS, true end
        CHAT_FONT_HEIGHTS = nums
        self.visuals.fontApplied = nums
    else
        self:Print("无效的字号列表，请用英文逗号分隔数字")
    end
end

-- works only for numbers between 0-255;
local CLEANCHAT_HEX = { [0] = "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f" };

function Automaton_CleanChat:HideButtons()
  for i = 1, NUM_CHAT_WINDOWS do
    getglobal("ChatFrame" .. i .. "DownButton"):Hide();
    getglobal("ChatFrame" .. i .. "UpButton"):Hide();
    --getglobal("ChatFrame" .. i .. "BottomButton"):Show();
  end
end


local function CleanChat_UnlinkMessage(linkmessage)
  local message = linkmessage;
  local links = { "quest:", "item:", "spell:" }
  for _, v in pairs(links) do
    if (strfind(message, "|H" .. v) ~= nil) then
      for pat1, pat2, pat3 in string.gfind(message, "(.+)|H.+|h(.+)|h(.+)") do
        if pat1 and pat2 and pat3 then
          message = pat1 .. pat2 .. pat3;
        end
      end
    end
  end
  return gsub(gsub(message, "/", "/1"), "|", "/2");
end

-- generate color string from current Blizzard raid colors
local function CleanChat_HashString(name)
  local hash = 17;
  for i = 1, string.len(name) do
    hash = hash * 37 * string.byte(name, i);
  end
  return hash;
end

--添加函数，来自cleachat,随机颜色用的
local function CleanChat_ToHex(number)
  if number <= 0 then
    return "00";
  end
  if number >= 255 then
    return "ff";
  end
  if math.fmod then
    return CLEANCHAT_HEX[math.floor(number / 16)] .. CLEANCHAT_HEX[math.fmod(number, 16)];
  end
  return CLEANCHAT_HEX[math.floor(number / 16)] .. CLEANCHAT_HEX[math.mod(number, 16)];
end

function CleanChat_ChatAddTime(t, msg)
  if Automaton_CleanChat.db.profile.ShowChatTime then
    local time = date("%H:%M");
    local timestamp = time
    if Automaton_CleanChat.db.profile.CopyChatTime then
      timestamp = "|Hezc:" .. (CleanChat_UnlinkMessage(t)) .. "|h[" .. time .. "]|h";
      t = "|cffffc800" .. timestamp .. "|r " .. t;
    else
      t = "|cffffc800[" .. timestamp .. "]|r " .. t;
    end
  end
  return t
end

-----------------------------------------------------------------------
--                 HOOK FUNC
-----------------------------------------------------------------------

-- local HookChatFrame_OnHyperlinkShow = ChatFrame_OnHyperlinkShow
-- function ChatFrame_OnHyperlinkShow(link, text, button)
-- return HookChatFrame_OnHyperlinkShow(link, text, button);
-- end
function Automaton_CleanChat:HandleLink(link, text, button)
  if not self.runtimeActive or type(link) ~= "string" then return false end
  if string.sub(link, 1, 4) == "inv:" then
    local name = string.sub(link, 5)
    if name ~= "" then InviteByName(name) end
    return true
  elseif string.sub(link, 1, 4) == "ezc:" then
    local txt = gsub(gsub(string.sub(link, 5), "/2", "|"), "/1", "/")
    local copy = self.chatOwner and self.chatOwner.urlcopy
    if copy and type(copy.CopyText) == "function" then
      copy.CopyText(txt)
      return true
    end
    if EasyCopyText and EasyCopy then
      EasyCopyText:SetFontObject(ChatFontNormal)
      EasyCopyText:SetText(txt)
      EasyCopy:Show()
      return true
    end
  end
  return false
end
function Automaton_CleanChat:SetItemRef(link, text, button)
  if not self.chatOwner and self:HandleLink(link, text, button) then return end
  return self.hooks.SetItemRef(link, text, button)
end
local function Pack(...) return arg end
local function ReturnResult(result)
  if not result[1] then error(result[2]) end
  local function ReturnFrom(index)
    if index > result.n then return end
    return result[index], ReturnFrom(index + 1)
  end
  return ReturnFrom(2)
end
function Automaton_CleanChat:WithContext(frame, kind, message, speaker, channel, render, callback)
  local oldThis, oldArg1, oldArg2, oldArg9 = this, arg1, arg2, arg9
  local oldRender, oldEvent = self.renderPass, frame.event
  local oldName, oldChannel, oldShort = frame.CleanChat_UnitName, frame.CleanChat_Channelname, frame.CleanChatShort_Channelname
  this, arg1, arg2, arg9 = frame, message, speaker, channel
  self.renderPass, frame.event = render, kind
  frame.CleanChat_UnitName = speaker ~= "" and speaker
  frame.CleanChat_Channelname, frame.CleanChatShort_Channelname = nil, nil
  local result = Pack(pcall(callback))
  this, arg1, arg2, arg9 = oldThis, oldArg1, oldArg2, oldArg9
  self.renderPass, frame.event = oldRender, oldEvent
  frame.CleanChat_UnitName, frame.CleanChat_Channelname, frame.CleanChatShort_Channelname = oldName, oldChannel, oldShort
  return ReturnResult(result)
end
function Automaton_CleanChat:TransformEvent(kind, message, speaker, channel)
  if type(message) ~= "string" then return message end
  if CHANNELE_MSG_EVENT[kind] and speaker and not (channel and string.lower(channel) == "lft") then
    if self:FilterKeyworld(message, speaker) then return nil end
    local selected = self.db.profile.keywordChannel or "all"
    if selected == "all" or CleanChat_GetChannelKey(kind, channel) == selected then message = self:HighlightText(message) end
    message = self:SpellLink(message)
    if not self.renderPass then self:HighlightSelfText(message, speaker) end
  end
  if kind == "CHAT_MSG_SYSTEM" then
    message = self:LFT(message)
    message = self:AuxFilter(message)
    message = self:ChatMsgSystemHCMsg(message)
    message = self:ChatMsgSystemRoll(message)
    message = self:CharacterDisplaying(message)
    if not self.renderPass then self:PopupTradeMessage(message) end
  elseif kind == "CHAT_MSG_LOOT" then message = self:ChatMsgLootRoll(message) end
  return message
end
function Automaton_CleanChat:NotifyEvent(kind, message, speaker, channel)
  if not self.runtimeActive or type(message) ~= "string" then return end
  local subscribed
  for i = 1, NUM_CHAT_WINDOWS do
    local frame = getglobal("ChatFrame" .. i)
    if frame then
      if kind == "CHAT_MSG_CHANNEL" then
        for index, name in pairs(frame.channelList or {}) do
          if (type(name) == "string" and type(channel) == "string" and string.upper(name) == string.upper(channel))
            or (type(arg7) == "number" and arg7 > 0 and frame.zoneChannelList and frame.zoneChannelList[index] == arg7) then subscribed = true; break end
        end
      else
        -- 1.12 has no Frame:IsEventRegistered. Native message groups are public.
        -- Turtle's HARDCORE group is registered in this same messageTypeList.
        for _, group in pairs(frame.messageTypeList or {}) do
          for _, registered in pairs(ChatTypeGroup and ChatTypeGroup[group] or {}) do
            if registered == kind then subscribed = true; break end
          end
          if subscribed then break end
        end
      end
      if subscribed then break end
    end
  end
  if not subscribed then return end
  local repeatFilter = pfUI and pfUI.chatRepeatFilter
  if repeatFilter and repeatFilter.ShouldNotify and not repeatFilter:ShouldNotify(kind, message, speaker, channel) then return end
  self.noticeContext = self.noticeContext or {}
  return self:WithContext(self.noticeContext, kind, message, speaker, channel, false, function()
    if kind == "CHAT_MSG_SYSTEM" then
      local now = GetTime()
      if string.find(message, "重启", 1, true) and now - lastServerRestartPopup >= SERVER_RESTART_COOLDOWN then
        lastServerRestartPopup = now
        UIErrorsFrame:AddMessage(message, 1, .2, .2, 1, 5)
        PlaySound("FriendJoinGame")
      end
      if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
        if string.find(message, "已被重置", 1, true) then SendChatMessage('副本可以进了！', 'PARTY') end
        if string.find(message, "该副本中仍有玩家", 1, true) then SendChatMessage('正在重置副本，请尽快出本！', 'PARTY') end
      end
    elseif kind == "CHAT_MSG_LOOT" then self:ProcessLootMessage(message) end
    local transformed = self:TransformEvent(kind, message, speaker, channel)
    if not transformed then return end
    if kind == "CHAT_MSG_WHISPER" and self.db.profile.whispersound then
      PlaySoundFile([[interface\Addons\Automatonex\Sound\3.mp3]])
    elseif kind == "CHAT_MSG_HARDCORE" and not self.db.profile.onoff then
      local target = getglobal("ChatFrame" .. tostring(self.db.profile.HCFFrame))
      if target then
        local hex = RGBToHex(self.db.profile.hcColour)
        local body = string.gsub(transformed, "|r", "|r|cff" .. hex)
        target:AddMessage("|cff" .. hex .. "[核] |Hplayer:" .. (speaker or "") .. "|h[" .. (speaker or "") .. "]|h |cff" .. hex .. body .. "|r")
      end
    end
  end)
end
function Automaton_CleanChat:ChatFrame_OnEvent(kind)
  local repeatFilter = pfUI and pfUI.chatRepeatFilter
  if repeatFilter and repeatFilter.Run then
    return repeatFilter:Run(this, kind, function(ev) return self:ProcessChatFrameEvent(ev) end)
  end
  return self:ProcessChatFrameEvent(kind)
end
function Automaton_CleanChat:ProcessChatFrameEvent(kind)
  if not self.runtimeActive or type(kind) ~= "string" or string.sub(kind, 1, 9) ~= "CHAT_MSG_" then return self.hooks.ChatFrame_OnEvent(kind) end
  local frame, message, speaker, channel = this, arg1, arg2, arg9
  return self:WithContext(frame, kind, message, speaker, channel, true, function()
    arg1 = self:TransformEvent(kind, message, speaker, channel)
    if arg1 == nil or kind == "CHAT_MSG_HARDCORE" then return end
    if channel and channel ~= "" then
      local _, _, stripped = string.find(channel, "([%aé]*)")
      if stripped and CLEANCHAT_CHANNELS[stripped] then
        frame.CleanChat_Channelname = firstToUpper(stripped)
        frame.CleanChatShort_Channelname = CLEANCHAT_CHANNELS[stripped]
      else frame.CleanChat_Channelname = channel end
    end
    return self.hooks.ChatFrame_OnEvent(kind)
  end)
end

function Automaton_CleanChat:CharacterDisplaying(t)
  for k, j in pairs(CLEANCAHT_CHAT_MSG_SYSTEM) do
    if string.find(t, k) then
      t = gsub(t, k, j)
      return t
    end
  end
  return t
end

function Automaton_CleanChat:SpellLink(t, num)
  if not num then num = 1 end
  local _, last, spellstr, spellname = strfind(t or "", "|Hspell:([%d:]+)|h%[([%a%p%d]+)%]|hr", num)
  if spellstr and spellname and not IsCn(spellname) then
    local cnspellname = Localization_SpellNametocn(spellname)
    if cnspellname then
      t = gsub(t, spellname, cnspellname)
    end
    t = self:SpellLink(t, last)
  end
  return t
end

--- 高亮自己信息--20240623 end
function Automaton_CleanChat:HighlightSelfText(msg, unit)
  if Automaton_CleanChat.db.profile.CleanChat_Popup
      and unit and unit ~= ""
      and unit ~= playerName
      and not EVENTS_EMOTES[this.event]
      and type(msg) == "string" and type(playerName) == "string" and (string.find(msg, playerName, 1, true)) --not perfect atm
  then
    -- 使用UIErrorsFrame显示弹窗，与关键字弹窗保持一致
    -- 高亮消息中的玩家名字
    local hexColor = RGBToHex(self.db.profile.highlightColour)
    local pattern = string.gsub(playerName, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    local highlightedMsg = string.gsub(msg, pattern, function() return "|cff" .. hexColor .. playerName .. "|r" end)
    local displayMsg = "|cffff8800[提到我]|r |cffffdd00" .. unit .. "|r: " .. highlightedMsg
    
    -- 检查是否应该显示弹窗
    if ShouldShowPopup(displayMsg) then
        UIErrorsFrame:AddMessage(displayMsg, 1.0, 0.8, 0.0, 1.0, 5.0) -- 橙色，持续5秒
        PlaySound("FriendJoinGame");
    end
  end
end

function Automaton_CleanChat:LFT(t)
    -- 暂时不处理，直接返回原字符串
    return t
end

-- ========== 修改3：HighlightText 增加 nil 检查，跳过空关键字 ==========
function Automaton_CleanChat:HighlightText(msg)
  if type(msg) ~= "string" or not self.db.profile.HighlightText then return msg end
  local keywords = self.db.profile.THighlightText or {}
  local color = "|cff" .. RGBToHex(self.db.profile.highlightColour)
  local found
  local function HighlightPlain(text)
    local lower, position, parts = string.lower(text), 1, {}
    while position <= string.len(text) do
      local first, last
      for _, keyword in ipairs(keywords) do
        if type(keyword) == "string" and keyword ~= "" then
          local ok, begin, finish = pcall(string.find, lower, string.lower(keyword), position)
          -- Preserve valid historical Lua patterns; malformed/empty matches cannot hang chat.
          if ok and begin and finish >= begin and (not first or begin < first or (begin == first and finish > last)) then
            first, last = begin, finish
          end
        end
      end
      if not first then table.insert(parts, string.sub(text, position)); break end
      found = true
      table.insert(parts, string.sub(text, position, first - 1))
      table.insert(parts, color .. string.sub(text, first, last) .. "|r")
      position = last + 1
    end
    return table.concat(parts)
  end
  local parts, position = {}, 1
  while position <= string.len(msg) do
    local pipe = string.find(msg, "|", position, true)
    if not pipe then table.insert(parts, HighlightPlain(string.sub(msg, position))); break end
    table.insert(parts, HighlightPlain(string.sub(msg, position, pipe - 1)))
    local token, finish = string.sub(msg, pipe, pipe + 1), nil
    if token == "|H" then
      local close = string.find(msg, "|h", pipe + 2, true)
      finish = close and close + 1 or string.len(msg)
    elseif token == "|c" or token == "|C" then
      local hex = string.sub(msg, pipe + 2, pipe + 9)
      if string.len(hex) == 8 and not string.find(hex, "[^%x]") then finish = pipe + 9 end
    elseif token == "||" or token == "|r" or token == "|R" or token == "|h" then finish = pipe + 1 end
    finish = finish or pipe
    table.insert(parts, string.sub(msg, pipe, finish))
    position = finish + 1
  end
  msg = table.concat(parts)
  if found and self.db.profile.showpopup and not self.renderPass then
    local fullMessage = "|cffff8800[关键字提醒]|r |cffffdd00" .. (arg2 or "未知") .. "|r: " .. msg
    if ShouldShowPopup(fullMessage) then
      UIErrorsFrame:AddMessage(fullMessage, 1, .8, 0, 1, 5)
      PlaySound("FriendJoinGame")
    end
  end
  return msg
end

-- ========== 修改4：FilterKeyworld 增加 nil 检查 ==========
function Automaton_CleanChat:FilterKeyworld(msg, unit)
  if type(msg) ~= "string" then return false end
  unit = unit or ""
  -- 修改：自身发出的信息不受屏蔽关键字影响
  if unit == playerName then
    return false
  end
  
  if Automaton_CleanChat.db.profile.FilterKeyworld then
    local texts = msg
    if Automaton_CleanChat.db.profile.hasunitname then
      texts = unit .. msg
    end
    for _, text in pairs(Automaton_CleanChat.db.profile.TFilterKeyworld) do
      if type(text) == "string" and text ~= "" then
        local ok, first = pcall(string.find, texts, text)
        if ok and first then return true end
      end
    end
  end
  return false
end


function Automaton_CleanChat:ChatMsgSystemRoll(t)
  -- 检查是否开启高亮ROLL点功能
  if not self.db.profile.highlightroll then
    return t
  end
  
  local _, _, who, roll, from, to = string.find(t, RANDOM_ROLL_RESULT)
  if who == playerName then
    -- 使用配置的ROLL点颜色
    local rollHex = RGBToHex(self.db.profile.rollColour)
    t = format("|CFF%s%s|r掷出|CFF%s%d|r（%d-%d）", rollHex, who, rollHex, roll, from, to)
  end
  return t
end

function Automaton_CleanChat:ChatMsgLootRoll(msg)
  local _, _, typ, roll, item, name = strfind(msg, "（(.+)）(%d+)点：(.+)（(.+)）")
  if name == playerName then
    -- 使用配置的ROLL点颜色
    local rollHex = RGBToHex(self.db.profile.rollColour)
    msg = format("（%s）|CFF%s%d|r点： %s （|CFF%s%s|r）", typ, rollHex, roll, item, rollHex, name)
  end
  return msg
end

-- 处理战利品消息
function Automaton_CleanChat:ProcessLootMessage(msg)
  -- 如果未开启战利品庆祝，直接返回
  if not self.db.profile.lootCelebration then
    return
  end
  
  -- 检查用户配置的物品列表
  if self.db.profile.lootCelebrationItems and table.getn(self.db.profile.lootCelebrationItems) > 0 then
    -- 从消息中提取实际拾取的物品名（物品链接 [名字] 中的完整名字）
    local _, _, lootedName = string.find(msg, "%[(.-)%]")

    -- 检查是否是自己拾取
    if string.find(msg, "你获得了物品：", 1, true) or string.find(msg, "你得到了物品：", 1, true) then
      if lootedName then
        for _, itemName in ipairs(self.db.profile.lootCelebrationItems) do
          -- 精确匹配：物品名完全相等才庆祝（避免"恶魔布"误命中"恶魔布披风"）
          if lootedName == itemName then
            DoEmote("CHEER")
            PlaySoundFile("Interface\\AddOns\\Automatonex\\Sound\\ding.ogg")
            break
          end
        end
      end
    end

    -- 处理队友拾取（可选）
    local _, _, playerNameFound, itemLink = string.find(msg, "(.+)拾取了物品：(.+)")
    if playerNameFound and itemLink and playerNameFound ~= UnitName("player") then
      local _, _, mateLootedName = string.find(itemLink, "%[(.-)%]")
      mateLootedName = mateLootedName or itemLink
      for _, item in ipairs(self.db.profile.lootCelebrationItems) do
        if mateLootedName == item then
          DEFAULT_CHAT_FRAME:AddMessage(format("|cffffcc00[恭喜]|r |cff00ffff%s|r 获得了稀有物品: |cff00ff00%s|r！",
            playerNameFound, item))
          break
        end
      end
    end
  end
end

-- 添加庆祝物品管理函数
function Automaton_CleanChat:AddLootCelebrationItem(itemName)
  if not self.db.profile.lootCelebrationItems then
    self.db.profile.lootCelebrationItems = {}
  end
  
  -- 检查是否已存在
  for _, item in ipairs(self.db.profile.lootCelebrationItems) do
    if item == itemName then
      self:Print("物品已存在: " .. itemName)
      return
    end
  end
  
  table.insert(self.db.profile.lootCelebrationItems, itemName)
  self:Print("已添加庆祝物品: " .. itemName)
end

function Automaton_CleanChat:RemoveLootCelebrationItem(itemName)
  if not self.db.profile.lootCelebrationItems then return end
  
  for i, item in ipairs(self.db.profile.lootCelebrationItems) do
    if item == itemName then
      table.remove(self.db.profile.lootCelebrationItems, i)
      self:Print("已删除庆祝物品: " .. itemName)
      return
    end
  end
  
  self:Print("未找到物品: " .. itemName)
end

function Automaton_CleanChat:ListLootCelebrationItems()
  if not self.db.profile.lootCelebrationItems or table.getn(self.db.profile.lootCelebrationItems) == 0 then
    self:Print("庆祝物品列表为空")
    return
  end
  
  self:Print("庆祝物品列表:")
  for i, item in ipairs(self.db.profile.lootCelebrationItems) do
    self:Print(i .. ". " .. item)
  end
  
  -- 使用 table.getn() 替代 #
  self:Print("共 " .. table.getn(self.db.profile.lootCelebrationItems) .. " 个物品")
end

-- 交易消息弹窗高亮提醒（新增）
function Automaton_CleanChat:PopupTradeMessage(msg)
    if not self.db.profile.tradePopup then return end
    -- 匹配中文交易消息格式：玩家A 将 物品 交易给了 玩家B。
    local pattern = "(.+) 将 (.+) 交易给了 (.+)。"
    local _, _, playerA, item, playerB = string.find(msg, pattern)
    if playerA and item and playerB then
        -- 获取高亮颜色（十六进制）
        local hexColor = RGBToHex(self.db.profile.highlightColour)
        -- 构造带颜色的弹窗消息
        local popupMsg = string.format("|cffff8800[交易提醒]|r |cff%s%s|r 将 |cff%s%s|r 交易给了 |cff%s%s|r",
            hexColor, playerA, hexColor, item, hexColor, playerB)
        -- 防重复弹窗（复用已有的ShouldShowPopup函数）
        if ShouldShowPopup(popupMsg) then
            UIErrorsFrame:AddMessage(popupMsg, 1.0, 0.5, 0.0, 1.0, 5.0) -- 橙色高亮，持续5秒
            PlaySound("FriendJoinGame")  -- 播放提示音
        end
    end
end

function Automaton_CleanChat:ChatMsgSystemHCMsg(t)
  local originalMsg = t
  local isDeathMessage = false
  
  if strfind(t, "A tragedy has") then
    isDeathMessage = true
    if strfind(t, "has fallen to") then
      local _, _, playertype, pname, plv, tname, tlv, zone = strfind(t, CHAT_HC_MSG_P1_KEY)
      if playertype and pname and plv and tname and tlv and zone then
        -- 使用不同的颜色为玩家名字、怪物名字和地点染色
        local hcHex = RGBToHex(self.db.profile.hcColour) -- 硬核标签颜色
        local playerHex = "068fff" -- 玩家名字颜色（蓝色）
        local npcHex = "ff9900" -- 怪物名字颜色（橙色）
        local zoneHex = "00ff00" -- 地点颜色（绿色）
        
        t = format(CHAT_HC_MSG_P1_VAR, 
          "|cfff86256" .. (CHAT_HC_MSG_DEATH_PLAYERTYPE[playertype] or playertype) .. "|r", -- 玩家类型
          "|cff" .. playerHex .. pname .. "|r", -- 玩家名字
          "|cff" .. zoneHex .. zone .. "|r", -- 地点
          "|cff" .. npcHex .. tlv .. "|r", -- 怪物等级
          "|cff" .. npcHex .. (Automaton and Automaton.NpcNametocn and Automaton.NpcNametocn(tname) or tname) .. "|r", -- 怪物名字
          "|cff" .. playerHex .. plv .. "|r") -- 玩家等级
      end
    elseif strfind(t, 'has fallen in PvP to') then
      local _, _, pname, plv, tname, tlv, zone = strfind(t, CHAT_HC_MSG_P3_KEY)
      if pname and plv and tname and tlv and zone then
        -- PvP死亡消息染色
        local hcHex = RGBToHex(self.db.profile.hcColour)
        local playerHex = "068fff" -- 玩家名字颜色
        local killerHex = "ff0000" -- 击杀者颜色（红色，因为是PvP）
        local zoneHex = "00ff00" -- 地点颜色
        
        t = format(CHAT_HC_MSG_P3_VAR, 
          "|cff" .. playerHex .. pname .. "|r", 
          "|cff" .. zoneHex .. zone .. "|r", 
          "|cff" .. killerHex .. tlv .. "|r", 
          "|cff" .. killerHex .. (Automaton and Automaton.NpcNametocn and Automaton.NpcNametocn(tname) or tname) .. "|r",
          "|cff" .. playerHex .. plv .. "|r")
      end
    elseif strfind(t, CHAT_HC_MSG_P4_KEY) then
      -- 自然死亡（溺水、火烧等）
      local _, _, playertype, pname, plv, result, zone = strfind(t, CHAT_HC_MSG_P4_KEY)
      if playertype and pname and plv and result and zone then
        local hcHex = RGBToHex(self.db.profile.hcColour)
        local playerHex = "068fff"
        local zoneHex = "00ff00"
        local reasonHex = "ffcc00" -- 死亡原因颜色（黄色）
        
        t = format(CHAT_HC_MSG_P4_VAR, 
          "|cfff86256" .. (CHAT_HC_MSG_DEATH_PLAYERTYPE[playertype] or playertype) .. "|r", 
          "|cff" .. playerHex .. pname .. "|r",
          "|cff" .. zoneHex .. zone .. "|r", 
          "|cff" .. reasonHex .. CHAT_HC_MSG_DEATH_REASOM[result] .. "|r", 
          "|cff" .. playerHex .. plv .. "|r")
      end
    end
  elseif strfind(t, "^悲剧发生了。") then
    isDeathMessage = true
    if strfind(t, CHAT_HC_MSG_P1_1_KEY) then
      local _, _, playertype, pname, plv, tname, tlv, zone = strfind(t, CHAT_HC_MSG_P1_1_KEY)
      if playertype and pname and plv and tname and tlv and zone then
        -- 中文版硬核死亡消息染色
        local hcHex = RGBToHex(self.db.profile.hcColour)
        local playerHex = "068fff"
        local npcHex = "ff9900"
        local zoneHex = "00ff00"
        
        t = format(CHAT_HC_MSG_P1_VAR, 
          "|cfff86256" .. (CHAT_HC_MSG_DEATH_PLAYERTYPE[playertype] or playertype) .. "|r",
          "|cff" .. playerHex .. pname .. "|r",
          "|cff" .. zoneHex .. zone .. "|r",
          "|cff" .. npcHex .. tlv .. "|r",
          "|cff" .. npcHex .. (Automaton and Automaton.NpcNametocn and Automaton.NpcNametocn(tname) or tname) .. "|r",
          "|cff" .. playerHex .. plv .. "|r")
      end
    end
    if strfind(t, CHAT_HC_MSG_P4_1_KEY) then
      local _, _, playertype, pname, plv, zone, result = strfind(t, CHAT_HC_MSG_P4_1_KEY)
      if playertype and pname and plv and result and zone then
        -- 中文版自然死亡消息染色
        local hcHex = RGBToHex(self.db.profile.hcColour)
        local playerHex = "068fff"
        local zoneHex = "00ff00"
        local reasonHex = "ffcc00"
        
        t = format(CHAT_HC_MSG_P4_VAR, 
          "|cfff86256" .. (CHAT_HC_MSG_DEATH_PLAYERTYPE[playertype] or playertype) .. "|r", 
          "|cff" .. playerHex .. pname .. "|r",
          "|cff" .. zoneHex .. zone .. "|r", 
          "|cff" .. reasonHex .. CHAT_HC_MSG_DEATH_REASOM[result] .. "|r", 
          "|cff" .. playerHex .. plv .. "|r")
      end
    end
  end
  
  -- 如果是硬核死亡消息且开启了硬核死亡弹窗功能，则显示弹窗
  -- 使用已经染色后的消息（t），它包含了所有颜色标签
  if isDeathMessage and self.db.profile.hcDeathPopup then
    local popupMsg = t
    
    -- 检查是否应该显示弹窗
    if ShouldShowPopup(popupMsg) then
      UIErrorsFrame:AddMessage(popupMsg, 1.0, 1.0, 0.0, 1.0, 5.0) -- 黄色，持续5秒
      PlaySound("FriendJoinGame");
    end
  end
  
  return t
end

function Automaton_CleanChat:AuxFilter(t)
  local ahitem
  for _, str in pairs({ ERR_AUCTION_SOLD_S, ERR_AUCTION_EXPIRED_S, ERR_AUCTION_WON_S }) do
    local pattern = string.gsub(str, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    pattern = string.gsub(pattern, "%%%%s", "(.+)")
    local _, _, item = string.find(t, "^" .. pattern .. "$")
    ahitem = item
    if ahitem then
      if not self.renderPass then PlaySound("AuctionWindowOpen") end
      return format(str, (Automaton and Automaton.ItemInfoLib and Automaton.ItemInfoLib.HexItemName and Automaton.ItemInfoLib:HexItemName(ahitem) or ahitem))
    end
  end
  return t
end

local function CleanChat_ClickInvite(msg, trail)
  if (trail == nil or trail == " " or trail == "") and arg2 ~= UnitName("player") and this.event ~= "CHAT_MSG_RAID" and this.event ~= "CHAT_MSG_RAID_LEADER" and this.event ~= "CHAT_MSG_RAID_WARNING" then
    CleanChat_INVITEFOUND = true;
    return " |Hinv:" .. arg2 .. "|h[|cffffff00" .. msg .. "|r]|h" .. " ";
  else
    return " " .. msg .. trail;
  end
end


function Automaton_CleanChat:OnMouseWheel()
  if IsShiftKeyDown() then
    if arg1 == 1 then
      this:ScrollToTop();
    else
      PlaySound("igChatBottom");
      this:ScrollToBottom();
    end
  else
    if arg1 == 1 then
      this:ScrollUp();
    else
      this:ScrollDown();
    end
  end
end

function Automaton_CleanChat:SetupMouseWheel()
  for i = 1, NUM_CHAT_WINDOWS do
    getglobal("ChatFrame" .. i):SetScript("OnMouseWheel", self.OnMouseWheel);
    getglobal("ChatFrame" .. i):EnableMouseWheel(true);
  end
end

--高亮玩家聊天
-- 移除CleanChat_PopupOnUpdated函数，不再需要

--cmd命令
function CleanChat_ChatCommand(msg)
  if CleanChatOptionsFrame:IsVisible() then
    CleanChatOptionsFrame:Hide();
  else
    CleanChatOptionsFrame:Show();
  end
end

function Automaton_CleanChat:SetupPrefix()
  CHAT_RAID_GET = "[团] %s:\32"
  CHAT_PARTY_GET = "[队] %s:\32"
  CHAT_OFFICER_GET = CHAT_OFFICER_GET;
  CHAT_GUILD_GET = "[会] %s:\32"
  CHAT_RAID_LEADER_GET = "[团长] %s:\32"
  CHAT_RAID_WARNING_GET = "|cffff0000[团队通知]|r %s:\32"
  CHAT_BATTLEGROUND_GET = "[战] %s:\32"
  CHAT_BATTLEGROUND_LEADER_GET = "[领袖] %s:\32"
end

local function EmptyReturn()
  if not this then return end
  this.CleanChat_UnitName = nil;
  this.CleanChat_Channelname = nil;
  this.CleanChatShort_Channelname = nil;
  --this.chatmsg = nil
end

-- ========== 修正2：删除原JumpCombatLog，改用IsCombatLogEvent ==========
local function IsCombatLogEvent(event)
    if not event then return false end
    return string.find(event, "CHAT_MSG_SPELL") or
           string.find(event, "CHAT_MSG_COMBAT") or
           string.find(event, "CHAT_MSG_MONSTER") or
           string.find(event, "_EMOTE")
end

-- 无用消息屏蔽（使用修正后的 filter 变量）
function Automaton_CleanChat:ShouldFilterDisplay(msg, frame)
  if frame and (frame.pfCombatLog or IsCombatLogEvent(frame.event)) then return false end
  if not self.runtimeActive or type(msg) ~= "string" then return false end
  for _, value in pairs(filter) do
    if string.find(msg, value, 1, true) then return true end
  end
  return false
end
local function MessageFilter(msg, frame)
  return not Automaton_CleanChat:ShouldFilterDisplay(msg, frame)
end

-- ========== 修正2（续）：重写 CleanChat_AddMessage ==========
function CleanChat_AddMessage(this, msg, r, g, b, id, extra)
    local original = Automaton_CleanChat.hooks[this].AddMessage
    -- 1. 战斗日志事件：直接调用原始方法，跳过所有增强功能
    if this.pfCombatLog or IsCombatLogEvent(this.event) then
        EmptyReturn()  -- 清理临时变量
        return original(this, msg, r, g, b, id, extra)
    end

    -- 2. 非战斗日志事件，执行原有增强逻辑
    if not MessageFilter(msg, this) then return end
    if true then
        local channelName = this.CleanChat_Channelname
        if channelName == nil then
            channelName = ""
        end

        -- 频道缩写
        if not Automaton_CleanChat.chatOwner and msg and channelName ~= "" then
            if channelName == "Hardcore" then
                -- 使用配置的硬核频道颜色
                local hcHex = RGBToHex(Automaton_CleanChat.db.profile.hcColour)
                local text_new = string.gsub(msg, "%[(.*)%]%s", "|cff" .. hcHex .. "[核] |r");
                if text_new ~= nil and msg ~= text_new then
                    msg = text_new;
                end
            elseif this.CleanChatShort_Channelname and this.CleanChat_Channelname then
                local num = gsub(msg, "^%[(%d+)%..+%].*", "%1");
                local pattern = num .. ". " .. this.CleanChat_Channelname
                local replacement = this.CleanChatShort_Channelname
                msg = gsub(msg, pattern, replacement, 1)
            end
        end

        -- 点选聊天框组队
        if (Automaton_CleanChat.db.profile.clickinvite and msg ~= nil and arg2 ~= nil) then
            CleanChat_INVITEFOUND = nil;
            if CleanChat_INVITEFOUND == nil then msg = string.gsub(msg, "%s+(invite)(.?)", CleanChat_ClickInvite, 1); end
            if CleanChat_INVITEFOUND == nil then msg = string.gsub(msg, "%s+(INVITE)(.?)", CleanChat_ClickInvite, 1); end
            if CleanChat_INVITEFOUND == nil then msg = string.gsub(msg, "%s+(inv)(.?)", CleanChat_ClickInvite, 1); end
            if CleanChat_INVITEFOUND == nil then msg = string.gsub(msg, "%s+(INV)(.?)", CleanChat_ClickInvite, 1); end
            if CleanChat_INVITEFOUND == nil and CleanChat_CUSTOM_INV ~= nil then
                for i = 0, table.getn(CleanChat_CUSTOM_INV) do
                    local keyword = CleanChat_CUSTOM_INV[i]
                    if CleanChat_INVITEFOUND == nil and type(keyword) == "string" and keyword ~= "" then
                        local ok, changed = pcall(string.gsub, msg, "%s+(" .. keyword .. ")(.?)", CleanChat_ClickInvite, 1)
                        if ok then msg = changed end
                    end
                end
            end
        end

        if strfind(msg, ".+ was added to your collection.") then
            msg = gsub(msg, "was added to your collection.", " |CFFFF00FF已添加到收藏|R")
        end

        -- Every 5 minutes remove old entries
        if GetTime() > nextPurgeCheck then
            nextPurgeCheck = GetTime() + PURGE_INTERVAL;
        end

        if not Automaton_CleanChat.chatOwner then msg = CleanChat_ChatAddTime(msg) end
    end

    -- 3. 最终调用原始方法显示消息
    return original(this, msg, r, g, b, id, extra)
end

-- 添加一个打印函数（如果不存在）
function Automaton_CleanChat:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc[CleanChat]|r " .. msg)
end

-- Restore only values still owned by this module; later wrappers are not removed.
function Automaton_CleanChat:ApplyVisuals()
  if not self.runtimeActive or self.chatOwner then return end
  if self.visuals and self.visuals.applied then return end
  self.visuals = self.visuals or {}
  local v = self.visuals
  v.applied, v.prefix, v.sticky, v.wheel, v.buttons = true, {}, {}, {}, {}
  local keys = { "CHAT_RAID_GET", "CHAT_PARTY_GET", "CHAT_OFFICER_GET", "CHAT_GUILD_GET", "CHAT_RAID_LEADER_GET",
    "CHAT_RAID_WARNING_GET", "CHAT_BATTLEGROUND_GET", "CHAT_BATTLEGROUND_LEADER_GET" }
  for _, key in ipairs(keys) do v.prefix[key] = { before = _G[key] } end
  self:SetupPrefix()
  for _, key in ipairs(keys) do v.prefix[key].applied = _G[key] end
  for _, name in ipairs({ "SAY", "EMOTE", "YELL", "PARTY", "GUILD", "OFFICER", "RAID", "RAID_WARNING", "BATTLEGROUND", "WHISPER", "CHANNEL" }) do
    local info = ChatTypeInfo[name]
    if info then v.sticky[name] = { before = info.sticky }; info.sticky = 1 end
  end
  for i = 1, NUM_CHAT_WINDOWS do
    local frame = getglobal("ChatFrame" .. i)
    if frame then
      self.wheelHooks = self.wheelHooks or {}
      local state = self.wheelHooks[frame]
      if not state then
        local before = frame:GetScript("OnMouseWheel")
        state = { before = before }
        state.applied = function()
          if self.runtimeActive and not self.chatOwner then return self:OnMouseWheel() end
          if before then return before() end
        end
        self.wheelHooks[frame] = state
      end
      v.wheel[frame] = state
      if frame:GetScript("OnMouseWheel") == state.before then frame:SetScript("OnMouseWheel", state.applied) end
      frame:EnableMouseWheel(true)
    end
    for _, suffix in ipairs({ "DownButton", "UpButton" }) do
      local button = getglobal("ChatFrame" .. i .. suffix)
      if button then v.buttons[button] = button:IsShown() and true or false; button:Hide() end
    end
  end
  self:ApplyChatFontHeights()
end
function Automaton_CleanChat:RestoreVisuals()
  local v = self.visuals
  if not v then return end
  for key, state in pairs(v.prefix or {}) do if _G[key] == state.applied then _G[key] = state.before end end
  for name, state in pairs(v.sticky or {}) do if ChatTypeInfo[name].sticky == 1 then ChatTypeInfo[name].sticky = state.before end end
  for frame, state in pairs(v.wheel or {}) do if frame:GetScript("OnMouseWheel") == state.applied then frame:SetScript("OnMouseWheel", state.before) end end
  if not (pfUI and pfUI.chat) then
    for button, shown in pairs(v.buttons or {}) do if shown and not button:IsShown() then button:Show() end end
  end
  if v.fontCaptured and CHAT_FONT_HEIGHTS == v.fontApplied then CHAT_FONT_HEIGHTS = v.fontBefore end
  self.visuals = nil
end
function Automaton_CleanChat:AddMessage(frame, message, r, g, b, id, extra)
  local original = self.hooks[frame].AddMessage
  if not self.runtimeActive or type(message) ~= "string" then return original(frame, message, r, g, b, id, extra) end
  return CleanChat_AddMessage(frame, message, r, g, b, id, extra)
end
