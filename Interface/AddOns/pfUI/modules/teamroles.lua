-- Unified team-role management. Personal maintenance: StoneChyi & Codex.
-- pfUI supplies the only editor; shared service owns all records and queries.
pfUI:RegisterModule("teamroles", "vanilla", function()
  if pfUI.teamroles then return end
  local H = { rows = {}, ordered = {}, positions = {}, styled = {}, fonts = {}, offset = 0, unknownFirst = true }
  pfUI.teamroles = H
  local OWNER, ROWS, HEIGHT = "pfUI.teamroles", 12, 26
  local names = { TANK = "坦克", HEALER = "治疗", DAMAGER = "输出" }
  local styles = { MELEE = "近战", RANGED = "远程" }
  local states = { queued = "等待查询", pending = "查询中", complete = "已识别",
    timeout = "查询超时", invalid = "待重新识别", incomplete = "数据未收齐",
    offline = "离线", paused = "已暂停", stale = "等待更新", combat = "战斗缓存" }
  local sources = { manual = "本队修正", talent = "天赋", talents = "天赋",
    class = "职业基础", unavailable = "信息不足", unknown = "信息不足" }

  local function Service() return SC_TeamRolesService end
  local function Truth(v) return v ~= nil and v ~= false and v ~= 0 end
  local function Uncertain(rec)
    local s = Service()
    if not rec.overrideRole and s and type(s.IsFresh) == "function" and not s:IsFresh(rec) then return true end
    return not rec.role or rec.role == "UNKNOWN" or rec.provisional or rec.confidence ~= "high"
  end
  local function Text(parent, value, size)
    local t = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t:SetFontObject(GameFontNormal)
    if not t:SetFont(pfUI.font_default or STANDARD_TEXT_FONT, size or 11, "OUTLINE") then
      t:SetFontObject(GameFontNormal)
    end
    t:SetJustifyH("LEFT"); t:SetText(value or "")
    table.insert(H.fonts, { t, size or 11 })
    return t
  end
  local function Button(parent, caption, width, action)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(width); b:SetHeight(24)
    CreateBackdrop(b, nil, true)
    table.insert(H.styled, b)
    b.label = Text(b, caption, 11)
    b.label:SetPoint("CENTER", b, "CENTER", 0, 0)
    b:SetScript("OnClick", action)
    b:SetScript("OnEnter", function() this.label:SetTextColor(1, .8, .4) end)
    b:SetScript("OnLeave", function() this.label:SetTextColor(1, 1, 1) end)
    return b
  end
  local function Same(a, b)
    return a and b and a.name == b.name and a.key == b.key and a.class == b.class
  end
  local function Snapshot(rec)
    return rec and { name = rec.name, key = rec.key, class = rec.class, unit = rec.unit }
  end
  local function Current(selected)
    local s = Service()
    if not selected or not s or type(s.GetInfo) ~= "function" then return nil end
    local rec = s:GetInfo(selected.unit) or s:GetInfo(selected.name)
    if not Same(rec, selected) or not rec.unit or not Truth(UnitExists(rec.unit))
      or UnitName(rec.unit) ~= rec.name then return nil end
    local _, class = UnitClass(rec.unit)
    if class ~= rec.class then return nil end
    return rec
  end
  local function Feedback(text)
    if H.frame then H.frame.feedback:SetText(text or "") end
  end
  local function Summary(rec)
    local tabs = rec.tabs
    if tabs and tabs[1] and tabs[2] and tabs[3] then
      return tostring(tabs[1].points or 0) .. "/" .. tostring(tabs[2].points or 0) .. "/" .. tostring(tabs[3].points or 0)
    end
    return "待获取"
  end
  function H:Refresh()
    local f = self.frame
    if not f or not f:IsShown() then return end
    local s = Service()
    local roster = s and s.GetRoster and s:GetRoster() or {}
    local n = math.min(table.getn(roster), 40)
    for k in pairs(self.positions) do self.positions[k] = nil end
    for i = 1, n do self.ordered[i] = roster[i]; self.positions[roster[i]] = i end
    for i = table.getn(self.ordered), n + 1, -1 do self.ordered[i] = nil end
    if self.unknownFirst then
      table.sort(self.ordered, function(a, b)
        local ua, ub = Uncertain(a), Uncertain(b)
        if ua ~= ub then return ua end
        return self.positions[a] < self.positions[b]
      end)
    end
    self.offset = math.max(0, math.min(self.offset, math.max(0, n - ROWS)))
    local known, pending = 0, 0
    for _, rec in ipairs(self.ordered) do
      if not Uncertain(rec) then known = known + 1 end
      if rec.queryState == "pending" or rec.queryState == "queued" then pending = pending + 1 end
    end
    if self.selected and not Current(self.selected) then self.selected = nil end
    f.status:SetText(s and ("已识别 " .. known .. " / " .. n .. " · 待确认 " .. (n - known)
      .. (pending > 0 and " · 自动补全中" or "")) or "共享职责服务尚未就绪")
    f.range:SetText(n == 0 and "0 / 0" or ((self.offset + 1) .. "–" .. math.min(n, self.offset + ROWS) .. " / " .. n))
    for i, row in ipairs(self.rows) do
      local rec = self.ordered[self.offset + i]
      row.record = rec
      if rec then
        row.name:SetText(rec.name or "")
        local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[rec.class]
        row.name:SetTextColor(color and color.r or 1, color and color.g or 1, color and color.b or 1)
        row.role:SetText(names[rec.role] and (names[rec.role] .. (Uncertain(rec) and "?" or "")) or "待确认")
        row.role:SetTextColor(Uncertain(rec) and .95 or .6, Uncertain(rec) and .7 or .9, Uncertain(rec) and .35 or .7)
        row.style:SetText(styles[rec.style] or "—")
        row.talents:SetText(Summary(rec))
        local source = sources[rec.source] or (Uncertain(rec) and "自动推测" or "自动识别")
        local state = states[rec.queryState]
        row.state:SetText(source .. (rec.order and " · " .. rec.order .. "T" or "") .. (state and " · " .. state or ""))
        if Same(self.selected, rec) then row.selection:Show() else row.selection:Hide() end
        row:Show()
      else row.selection:Hide(); row:Hide() end
    end
    f.selected:SetText(self.selected and ("当前队员：" .. self.selected.name) or "选中队员后可修正；所有插件立即共用同一结果。")
    f.unknown.label:SetText(self.unknownFirst and "待确认优先 [开]" or "待确认优先 [关]")
    local selected = Current(self.selected)
    for key, button in pairs(self.actions) do
      local available = selected and (key ~= "order" or (selected.role == "TANK" and selected.order))
      if available then button:Enable(); button.label:SetTextColor(1, 1, 1)
      else button:Disable(); button.label:SetTextColor(.4, .4, .4) end
    end
    if selected then f.refreshSelected:Enable() else f.refreshSelected:Disable() end
  end
  local function Apply(kind)
    local s, rec = Service(), Current(H.selected)
    if not s or not rec then H.selected = nil; H:Refresh(); Feedback("队员已变化，请重新选择当前队员。"); return end
    local ok, reason
    if kind == "refresh" then ok, reason = s:Refresh(rec.unit)
    elseif kind == "main" then
      ok, reason = s:SetOverride(rec.unit, "TANK", "MELEE")
      if ok ~= false then ok, reason = s:SetTankOrder(rec.unit, 1) end
    elseif kind == "order" then ok, reason = s:SetTankOrder(rec.unit, nil)
    elseif kind == "auto" then ok, reason = s:SetOverride(rec.unit, nil, nil)
    elseif kind == "melee" then ok, reason = s:SetOverride(rec.unit, "DAMAGER", "MELEE")
    elseif kind == "ranged" then ok, reason = s:SetOverride(rec.unit, "DAMAGER", "RANGED")
    else ok, reason = s:SetOverride(rec.unit, kind, kind == "TANK" and "MELEE" or nil) end
    H:Refresh(); Feedback(ok == false and (reason or "暂时无法修改") or "已更新本队职责。")
  end
  local function Wheel()
    H.offset = H.offset + (arg1 > 0 and -1 or 1)
    H:Refresh()
  end
  function H:Create()
    if self.frame then return end
    local f = CreateFrame("Frame", "pfTeamRoles", UIParent)
    self.frame = f
    f:Hide()
    f:SetWidth(680); f:SetHeight(556)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("DIALOG"); f:SetMovable(true); f:EnableMouse(true)
    f:RegisterForDrag("LeftButton"); f:EnableMouseWheel(true)
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    f:SetScript("OnMouseWheel", Wheel)
    CreateBackdrop(f, nil, true)
    table.insert(H.styled, f)
    if f.SetClampedToScreen then f:SetClampedToScreen(true) end
    table.insert(UISpecialFrames, "pfTeamRoles")
    f.title = Text(f, "团队职责", 14); f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -12)
    f.close = Button(f, "×", 23, function() f:Hide() end)
    f.close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -9, -8)
    f.status = Text(f, "", 11); f.status:SetPoint("TOPLEFT", f, "TOPLEFT", 19, -40)
    f.status:SetWidth(638); f.status:SetHeight(18)
    for _, spec in ipairs({ {"姓名", 22}, {"职责", 156}, {"方式", 225}, {"天赋", 282}, {"来源 / 状态", 377} }) do
      local t = Text(f, spec[1], 10); t:SetPoint("TOPLEFT", f, "TOPLEFT", spec[2], -75)
      t:SetTextColor(.65, .7, .75)
    end
    for i = 1, ROWS do
      local row = CreateFrame("Button", nil, f)
      self.rows[i] = row
      row:SetWidth(640); row:SetHeight(HEIGHT)
      row:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -96 - (i - 1) * HEIGHT)
      row:EnableMouseWheel(true); row:SetScript("OnMouseWheel", Wheel)
      row.selection = row:CreateTexture(nil, "BACKGROUND")
      row.selection:SetAllPoints(row); row.selection:SetTexture(.5, .7, 1, .12); row.selection:Hide()
      for _, spec in ipairs({ {"name", 4, 126}, {"role", 138, 62}, {"style", 207, 50}, {"talents", 264, 88}, {"state", 359, 276} }) do
        local t = Text(row, "", 11); row[spec[1]] = t
        t:SetPoint("LEFT", row, "LEFT", spec[2], 0); t:SetWidth(spec[3]); t:SetHeight(15)
      end
      row:SetScript("OnMouseDown", function() this.pressed = Snapshot(this.record) end)
      row:SetScript("OnClick", function()
        local pressed = this.pressed; this.pressed = nil
        if pressed and not Same(pressed, this.record) then return end
        if not Current(Snapshot(this.record)) then Feedback("队员已变化，请等待列表更新。"); return end
        H.selected = Snapshot(this.record); Feedback(""); H:Refresh()
      end)
    end
    f.range = Text(f, "", 10); f.range:SetPoint("TOPRIGHT", f, "TOPRIGHT", -22, -414)
    f.range:SetTextColor(.6, .65, .7)
    f.selected = Text(f, "", 11); f.selected:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -439)
    f.selected:SetWidth(640); f.selected:SetHeight(18)
    self.actions = {}
    local x = 18
    for _, spec in ipairs({ {"TANK", "坦克", 64}, {"HEALER", "治疗", 64}, {"melee", "近战输出", 80},
      {"ranged", "远程输出", 80}, {"auto", "恢复自动", 80}, {"main", "设为主T", 80}, {"order", "清除顺位", 80} }) do
      local key = spec[1]
      local b = Button(f, spec[2], spec[3], function() Apply(key) end)
      b:SetPoint("TOPLEFT", f, "TOPLEFT", x, -466); self.actions[key] = b; x = x + spec[3] + 7
    end
    f.refresh = Button(f, "补全 / 刷新团队", 142, function()
      local s = Service()
      local ok, reason
      if not s then Feedback("共享职责服务尚未就绪。"); return end
      ok, reason = s:Refresh()
      H:Refresh(); Feedback(ok == false and (reason or "暂时无法刷新") or "已请求按需补全；战斗中使用缓存。")
    end)
    f.refresh:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -499)
    f.refreshSelected = Button(f, "刷新选中队员", 128, function() Apply("refresh") end)
    f.refreshSelected:SetPoint("LEFT", f.refresh, "RIGHT", 9, 0)
    f.unknown = Button(f, "", 145, function() H.unknownFirst = not H.unknownFirst; H.offset = 0; H:Refresh() end)
    f.unknown:SetPoint("LEFT", f.refreshSelected, "RIGHT", 9, 0)
    f.credit = Text(f, "StoneChyi & Codex", 10); f.credit:SetTextColor(.5, .55, .6)
    f.credit:SetPoint("TOPRIGHT", f, "TOPRIGHT", -20, -506)
    f.feedback = Text(f, "", 10); f.feedback:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -534)
    f.feedback:SetWidth(640); f.feedback:SetHeight(15); f.feedback:SetTextColor(.7, .75, .8)
    f:SetScript("OnShow", function()
      for _, styled in ipairs(H.styled) do CreateBackdrop(styled, nil, true) end
      for _, font in ipairs(H.fonts) do
        font[1]:SetFontObject(GameFontNormal)
        if not font[1]:SetFont(pfUI.font_default or STANDARD_TEXT_FONT, font[2], "OUTLINE") then
          font[1]:SetFontObject(GameFontNormal)
        end
      end
      local s = Service()
      if s then s:Acquire(OWNER); s:Subscribe(OWNER, function() H:Refresh() end) end
      H:Refresh()
    end)
    f:SetScript("OnHide", function()
      local s = Service()
      if s then s:Unsubscribe(OWNER); s:Release(OWNER) end
    end)
  end
  function pfUI:OpenTeamRoles(name)
    H:Create(); H.frame:Show()
    local s = Service()
    if name and s then
      H.selected = Snapshot(s:GetInfo(name)); H:Refresh()
    end
  end
  pfUI.api.OpenTeamRoles = function(name) pfUI:OpenTeamRoles(name) end
  SLASH_PFUITEAMROLES1 = "/scroles"
  SlashCmdList.PFUITEAMROLES = function() pfUI:OpenTeamRoles() end
  function H:RegisterGUI()
    if self.guiReady or not pfUI.gui or not pfUI.gui.CreateGUIEntry then return end
    pfUI.gui.CreateGUIEntry("团队职责", nil, function()
      pfUI.gui.CreateConfig(nil, "自动识别与全插件共用", nil, nil, "header")
      pfUI.gui.CreateConfig(nil, "打开团队职责", nil, nil, "button", function() pfUI:OpenTeamRoles() end)
    end)
    self.guiReady = true
  end
  H:RegisterGUI()
  local showGUI = pfUI.ShowGUI
  if showGUI then
    function pfUI:ShowGUI()
      local result = showGUI(self); H:RegisterGUI(); return result
    end
  end
end)
