pfUI:RegisterModule("actionbar_glow", "vanilla", function ()
  --[[ 动作条技能边框高亮（学习 WeakestAuras 的 SubGlow 实现思路）
    渲染（学自 WeakestAuras/SubGlow.lua）：
      - 辉光是按钮上的独立边框层（edgeFile=img:glow），不做遮罩不挡图标
      - 所有辉光由一个共享 ticker 驱动呼吸脉冲，无辉光时 ticker 停转，空闲零开销
    触发源：
      - 冷却就绪：GetActionCooldown 由长冷却（>= procglow_cdmin，排除 GCD）归零
        且 IsUsableAction 时点亮；再次进入冷却（使用后）自动熄灭
      - 被动触发：战斗日志 CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS（你获得了X）
        点亮规则映射的技能按钮；CHAT_MSG_SPELL_AURA_GONE_SELF（X消退）熄灭。
        模式串优先取自客户端全局字符串（本地化无关），并内置 zh/en 兜底
    配置（C.bars）：
      procglow_enable / procglow_cd / procglow_cdmin / procglow_cdcolor
      procglow_proccolor / procglow_rule1..3（格式：触发Buff=技能1,技能2）
  ]]

  -- 与 actionbar.lua 保持一致的按钮命名（仅玩家动作条 1-10，跳过姿态/宠物栏）
  local barnames = { [1] = "Main", [2] = "Paging", [3] = "Right", [4] = "Vertical",
    [5] = "Left", [6] = "Top", [7] = "StanceBar1", [8] = "StanceBar2",
    [9] = "StanceBar3", [10] = "StanceBar4" }

  local PULSE_SPEED, PULSE_MIN, PULSE_MAX = 4.5, 0.35, 0.85
  local CD_SCAN_INTERVAL = 0.2
  local RULE_CHECK_INTERVAL = 1.0
  local CD_MIN_DEFAULT = 3   -- 小于该时长的冷却（如 GCD）不触发就绪高亮
  local SCAN_PER_FRAME = 5   -- 每帧最多扫描的动作技能名个数

  local CDCOLOR = { 0.7, 1, 0.25, 1 }   -- 冷却就绪默认色（绿）
  local PROCCOLOR = { 1, 0.8, 0.2, 1 }  -- 被动触发默认色（金）
  local backdrop_glow = { edgeFile = pfUI.media["img:glow"], edgeSize = 12 }

  -- 状态缓存
  local cdstate = {}     -- [slot] = "cool" 上次处于冷却中
  local cddur = {}       -- [slot] = 上次观察到的冷却时长
  local lasttex = {}     -- [slot] = 上次图标（变化则重置该槽位）
  local glowstate = {}   -- [slot] = "cd" | "proc"
  local slotspell = {}   -- [slot] = 小写动作技能名（tooltip 扫描缓存）
  local scanqueue = {}   -- [slot] = true 待扫描技能名的槽位
  local btnframes = {}   -- [slot] = 按钮帧（false 表示不存在）
  local buffrules = {}   -- [小写规则buff名] = { 小写技能名, ... }
  local activebuffs = {} -- [小写规则buff名] = true 当前身上的触发 buff
  local rulesraw = nil   -- 上次解析的规则原文（用于热更新检测）

  local glowframes = {}  -- 当前点亮的辉光帧集合
  local glowcount = 0
  local ticker = nil
  local scanner = libtipscan and libtipscan:GetScanner("actionbarglow") or nil

  local function trim(s)
    return string.gsub(s, "^%s*(.-)%s*$", "%1")
  end

  local function GetColor(cfgname, default)
    local r, g, b, a = strsplit(",", tostring(C.bars[cfgname] or ""))
    r, g, b, a = tonumber(r), tonumber(g), tonumber(b), tonumber(a)
    if not r or not g or not b then
      return default[1], default[2], default[3], default[4]
    end
    return r, g, b, a or 1
  end

  -- 呼吸脉冲 ticker（学 WA：只有存在点亮的辉光时才运行）
  local function StartTicker()
    if ticker then return end
    ticker = CreateFrame("Frame", "pfActionBarGlowTicker", UIParent)
    ticker:SetScript("OnUpdate", function()
      local alpha = PULSE_MIN + (PULSE_MAX - PULSE_MIN) * (math.sin(GetTime() * PULSE_SPEED) * 0.5 + 0.5)
      for gf in pairs(glowframes) do
        if gf.lit then gf:SetAlpha(alpha) end
      end
      if glowcount <= 0 then
        this:SetScript("OnUpdate", nil)
        ticker = nil
      end
    end)
  end

  local function GetGlowFrame(f)
    if not f.procglow then
      f.procglow = CreateFrame("Frame", nil, f)
      f.procglow:SetBackdrop(backdrop_glow)
      f.procglow:SetPoint("TOPLEFT", f, "TOPLEFT", -3, 3)
      f.procglow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 3, -3)
      f.procglow:Hide()
    end
    return f.procglow
  end

  local function GetButtonFrame(slot)
    local cached = btnframes[slot]
    if cached ~= nil then
      if cached == false then return nil end
      return cached
    end
    local bar = math.ceil(slot / 12)
    local j = slot - (bar - 1) * 12
    local f = _G[string.format("pfActionBar%sButton%d", barnames[bar], j)]
    if f and f.slot == slot then
      btnframes[slot] = f
      return f
    end
    btnframes[slot] = false
    return nil
  end

  local function ClearGlow(slot)
    local f = btnframes[slot]
    local gf = f and f.procglow
    if gf and gf.lit then
      gf.lit = nil
      gf:SetAlpha(1)
      gf:Hide()
      glowframes[gf] = nil
      glowcount = glowcount - 1
      if glowcount < 0 then glowcount = 0 end
    end
    glowstate[slot] = nil
  end

  local function LightGlow(slot, cfgname, default)
    local f = GetButtonFrame(slot)
    if not f then return end
    local gf = GetGlowFrame(f)
    local r, g, b, a = GetColor(cfgname, default)
    gf:SetBackdropBorderColor(r, g, b, a)
    if not gf.lit then
      gf.lit = true
      gf:SetAlpha(PULSE_MAX)
      gf:Show()
      glowframes[gf] = true
      glowcount = glowcount + 1
      StartTicker()
    end
  end

  -- 规则解析：格式 "触发Buff=技能1,技能2"，三条规则（procglow_rule1..3）
  local function ParseRules()
    local raw = string.format("%s;%s;%s",
      tostring(C.bars.procglow_rule1 or ""),
      tostring(C.bars.procglow_rule2 or ""),
      tostring(C.bars.procglow_rule3 or ""))
    if raw == rulesraw then return end
    rulesraw = raw

    -- 卸载旧规则仍点亮的触发辉光
    for k in pairs(activebuffs) do activebuffs[k] = nil end
    for slot in pairs(glowstate) do
      if glowstate[slot] == "proc" then ClearGlow(slot) end
    end
    for k in pairs(buffrules) do buffrules[k] = nil end

    for rule in string.gmatch(raw, "[^;]+") do
      -- string.find 带捕获（Lua 5.0 安全写法，等价 string.match）
      local _, _, buff, spells = string.find(rule, "^(.-)=(.+)$")
      if buff and spells then
        buff = string.lower(trim(buff))
        if buff ~= "" then
          local list = {}
          for spell in string.gmatch(spells, "[^,]+") do
            spell = string.lower(trim(spell))
            if spell ~= "" then table.insert(list, spell) end
          end
          if table.getn(list) > 0 then buffrules[buff] = list end
        end
      end
    end
  end

  -- 动作技能名扫描（tooltip 第 1 行），供触发规则映射槽位
  local function ScanSlotSpell(slot)
    if not scanner then return end
    if not HasAction(slot) then
      slotspell[slot] = nil
      return
    end
    scanner:SetAction(slot)
    local name = scanner:Line(1)
    slotspell[slot] = name and string.lower(trim(name)) or nil
  end

  local function ProcessScanQueue()
    if not next(scanqueue) then return end
    local n = 0
    for slot in pairs(scanqueue) do
      scanqueue[slot] = nil
      ScanSlotSpell(slot)
      n = n + 1
      if n >= SCAN_PER_FRAME then break end
    end
  end

  -- 让指定技能的所有槽位点亮/熄灭触发辉光
  local function ProcLightSpell(spell)
    for slot = 1, 120 do
      if slotspell[slot] == spell and glowstate[slot] ~= "proc" then
        glowstate[slot] = "proc"
        LightGlow(slot, "procglow_proccolor", PROCCOLOR)
      end
    end
  end

  local function ProcClearSpell(spell)
    for slot = 1, 120 do
      if slotspell[slot] == spell and glowstate[slot] == "proc" then
        ClearGlow(slot)
      end
    end
  end

  -- 战斗日志消息 → buff 名（本地化模式串）
  local gainpatterns, fadepatterns
  local function BuildPatterns()
    gainpatterns, fadepatterns = {}, {}
    local g = _G.AURAADDEDSELFHELPFUL
    if g then table.insert(gainpatterns, "^" .. string.gsub(g, "%%s", "(.+)")) end
    table.insert(gainpatterns, "^你获得了(.+)效果")
    table.insert(gainpatterns, "^You gain (.+)")
    local fs = _G.AURAREMOVEDSELF
    if fs then table.insert(fadepatterns, "^" .. string.gsub(fs, "%%s", "(.+)")) end
    table.insert(fadepatterns, "^(.+)效果从你身上消失")
    table.insert(fadepatterns, "^(.+) fades from you")
  end

  local function ExtractBuff(msg, patterns)
    for _, pat in pairs(patterns) do
      local _, _, m = string.find(msg, pat)
      if m then return trim(m) end
    end
    return nil
  end

  local function MatchRule(buffname)
    local lower = string.lower(buffname)
    for rule, spells in pairs(buffrules) do
      -- 双向子串匹配：兼容"效果"后缀、rank 等差异
      if string.find(lower, rule, 1, true) or string.find(rule, lower, 1, true) then
        return rule, spells
      end
    end
    return nil
  end

  local function ProcActivate(buffname)
    local rule, spells = MatchRule(buffname)
    if not rule then return end
    if not activebuffs[rule] then
      activebuffs[rule] = true
      for _, s in pairs(spells) do ProcLightSpell(s) end
    end
  end

  local function OnBuffGain(msg)
    local buffname = ExtractBuff(msg, gainpatterns)
    if not buffname then return end
    ProcActivate(buffname)
  end

  local function OnBuffFade(msg)
    local buffname = ExtractBuff(msg, fadepatterns)
    if not buffname then return end
    local rule, spells = MatchRule(buffname)
    if rule and activebuffs[rule] then
      activebuffs[rule] = nil
      -- 仅当没有其它激活规则仍映射同一技能时才熄灭
      for _, s in pairs(spells) do
        local still = false
        for r2, s2 in pairs(buffrules) do
          if activebuffs[r2] then
            for _, x in pairs(s2) do
              if x == s then still = true end
            end
          end
        end
        if not still then ProcClearSpell(s) end
      end
    end
  end

  -- 进服/换图后一次性核对当前身上的增益（处理日志之外的既有 buff）
  local buffcheck_pending = nil
  local function CheckCurrentBuffs()
    if not scanner or next(buffrules) == nil then return end
    for i = 1, 24 do
      local tex = UnitBuff("player", i)
      if not tex then break end
      scanner:SetUnitBuff("player", i, "HELPFUL")
      local name = scanner:Line(1)
      if name then ProcActivate(trim(name)) end
    end
  end

  -- 冷却就绪 + 图标变化 + 扫描队列 的周期扫描
  local lastcd, lastrule = 0, 0
  local function UpdateAll(now)
    if now - lastrule >= RULE_CHECK_INTERVAL then
      lastrule = now
      ParseRules()
    end

    local cdmin = tonumber(C.bars.procglow_cdmin) or CD_MIN_DEFAULT
    local cdon = C.bars.procglow_cd == "1"

    for slot = 1, 120 do
      local tex = GetActionTexture(slot)
      if tex ~= lasttex[slot] then
        lasttex[slot] = tex
        cdstate[slot] = nil
        cddur[slot] = nil
        slotspell[slot] = nil
        if glowstate[slot] == "cd" then ClearGlow(slot) end
        if HasAction(slot) then scanqueue[slot] = true end
      end

      local start, duration = GetActionCooldown(slot)
      if duration and duration > 0 then
        cdstate[slot] = "cool"
        cddur[slot] = duration
        -- 进入冷却 = 已使用，任何辉光熄灭
        if glowstate[slot] then ClearGlow(slot) end
      elseif cdstate[slot] == "cool" and cddur[slot] and cddur[slot] >= cdmin then
        cdstate[slot] = "ready"
        if cdon and IsUsableAction(slot) then
          glowstate[slot] = "cd"
          LightGlow(slot, "procglow_cdcolor", CDCOLOR)
        end
      elseif not cdon and glowstate[slot] == "cd" then
        ClearGlow(slot)
      end
    end
  end

  -- 主监控帧
  local monitor = CreateFrame("Frame", "pfActionBarGlowMonitor", UIParent)
  monitor:SetScript("OnUpdate", function()
    local now = GetTime()
    if now - lastcd < CD_SCAN_INTERVAL then return end
    lastcd = now

    if C.bars.procglow_enable ~= "1" then
      if glowcount > 0 then
        for slot in pairs(glowstate) do ClearGlow(slot) end
      end
      return
    end

    UpdateAll(now)
    ProcessScanQueue()

    -- 扫描队列清空后做一次既有 buff 核对
    if buffcheck_pending and next(scanqueue) == nil then
      buffcheck_pending = nil
      CheckCurrentBuffs()
    end
  end)

  -- 事件帧
  local events = CreateFrame("Frame", "pfActionBarGlowEvents", UIParent)
  events:RegisterEvent("PLAYER_ENTERING_WORLD")
  events:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
  events:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")
  events:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
      BuildPatterns()
      -- 全量重置（换图/进服）
      for slot in pairs(glowstate) do glowstate[slot] = nil end
      for gf in pairs(glowframes) do
        gf.lit = nil
        gf:SetAlpha(1)
        gf:Hide()
      end
      for k in pairs(glowframes) do glowframes[k] = nil end
      glowcount = 0
      for k in pairs(cdstate) do cdstate[k] = nil end
      for k in pairs(cddur) do cddur[k] = nil end
      for k in pairs(lasttex) do lasttex[k] = nil end
      for k in pairs(slotspell) do slotspell[k] = nil end
      for k in pairs(scanqueue) do scanqueue[k] = nil end
      for k in pairs(activebuffs) do activebuffs[k] = nil end
      btnframes = {}
      rulesraw = nil
      for slot = 1, 120 do
        if HasAction(slot) then scanqueue[slot] = true end
      end
      buffcheck_pending = true
    elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" and arg1 then
      if C.bars.procglow_enable == "1" then
        ParseRules()
        OnBuffGain(arg1)
      end
    elseif event == "CHAT_MSG_SPELL_AURA_GONE_SELF" and arg1 then
      if C.bars.procglow_enable == "1" then
        ParseRules()
        OnBuffFade(arg1)
      end
    end
  end)
end)
