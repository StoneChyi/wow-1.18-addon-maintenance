-- Keep target auras from covering the independently positioned target chain.
pfUI:RegisterModule("targetlayout", "vanilla:tbc", function()
  if C.unitframes.disable == "1" then return end

  local layout = { states = {} }
  pfUI.uf.targetlayout = layout

  -- Compare rectangles in screen space, including each frame's effective scale.
  local function Rect(frame)
    if not frame or not frame:IsShown() then return end
    local s = frame:GetEffectiveScale()
    local l, b, r, t = frame:GetLeft(), frame:GetBottom(), frame:GetRight(), frame:GetTop()
    if not s or s <= 0 or not l or not b or not r or not t then return end
    return { l = l*s, b = b*s, r = r*s, t = t*s, scale = s }
  end

  local function Overlap(a, b, gap)
    return a.l < b.r + gap and a.r > b.l - gap
      and a.b < b.t + gap and a.t > b.b - gap
  end

  function layout:Restore(frame)
    if not self.states[frame] then return end
    LoadMovable(frame)
    self.states[frame] = nil
  end

  function layout:RestoreAll()
    if InCombatLockdown and InCombatLockdown() then return end
    for frame in pairs(self.states) do self:Restore(frame) end
  end

  -- LoadMovable is the authority for manual anchors and initial defaults.
  -- Never save a temporary displacement, or depend on 1.12 GetPoint tuples.
  function layout:Base(frame)
    local state = self.states[frame]
    local current = Rect(frame)
    if state then
      local saved = C.position[frame:GetName()] or {}
      if not current or state.xpos ~= saved.xpos or state.ypos ~= saved.ypos
        or state.anchor ~= saved.anchor or state.parent ~= saved.parent or state.savedscale ~= saved.scale
        or current.scale ~= state.actual.scale or current.l ~= state.actual.l
        or current.b ~= state.actual.b or current.r ~= state.actual.r or current.t ~= state.actual.t then
        self:Restore(frame)
        current = Rect(frame)
      else
        return state.base
      end
    end
    return current
  end

  local function AddAuras(list, frame)
    if not frame or not frame:IsShown() then return end
    for _, kind in ipairs({ "buffs", "debuffs" }) do
      for _, icon in pairs(frame[kind] or {}) do
        local rect = Rect(icon)
        if rect then table.insert(list, rect) end
      end
    end
  end

  -- Normally move down only. At the screen bottom, use a free side or above
  -- the whole target block rather than letting screen clamping undo the fix.
  local function Destination(base, obstacles, gap)
    local hit, bottom, left, right, top = false, base.t, base.l, base.r, base.t
    for _, rect in ipairs(obstacles) do
      if Overlap(base, rect, gap) then hit = true end
      if base.l < rect.r + gap and base.r > rect.l - gap then
        bottom = math.min(bottom, rect.b - gap)
      end
      left, right, top = math.min(left, rect.l), math.max(right, rect.r), math.max(top, rect.t)
    end
    if not hit then return 0, 0 end
    local dx, dy = 0, bottom - base.t
    if base.b + dy >= gap then return dx, dy end

    local screen = Rect(UIParent)
    if not screen then return 0, 0 end
    local width, height = base.r-base.l, base.t-base.b
    local toleft, toright = left-gap-base.r, right+gap-base.l
    if base.r + toright <= screen.r-gap
      and (base.l + toleft < screen.l+gap or math.abs(toright) <= math.abs(toleft)) then
      return toright, 0
    elseif base.l + toleft >= screen.l+gap then
      return toleft, 0
    elseif top+gap+height <= screen.t-gap then
      return 0, top+gap-base.b
    end
    -- No free rectangle exists within the screen for this extreme layout.
    return 0, 0
  end

  function layout:Place(frame, base, obstacles, gap)
    local dx, dy = Destination(base, obstacles, gap)
    local state = self.states[frame]
    if dx == 0 and dy == 0 then
      self:Restore(frame)
      return
    end
    if state and state.dx == dx and state.dy == dy then return end

    frame:ClearAllPoints()
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", (base.l+dx)/base.scale, (base.b+dy)/base.scale)
    local saved = C.position[frame:GetName()] or {}
    self.states[frame] = {
      base = base, actual = Rect(frame), dx = dx, dy = dy,
      xpos = saved.xpos, ypos = saved.ypos, anchor = saved.anchor,
      parent = saved.parent, savedscale = saved.scale,
    }
    -- A not-yet-laid-out frame must not leave a partial displacement behind.
    if not self.states[frame].actual then self:Restore(frame) end
  end

  function layout:Update()
    if InCombatLockdown and InCombatLockdown() then return end
    if pfUI.unlock and pfUI.unlock:IsShown() then self:RestoreAll() return end

    local target, child, grandchild = pfUI.uf.target, pfUI.uf.targettarget, pfUI.uf.targettargettarget
    local targetrect = Rect(target)
    if not targetrect then self:RestoreAll() return end
    local children = { child, grandchild }
    local gap = 4 * UIParent:GetEffectiveScale()
    local obstacles = {}
    AddAuras(obstacles, target)
    local childbase

    -- Sparse child lists (disabled ToT with enabled ToTTT) are intentional.
    for index = 1, 2 do
      local frame = children[index]
      if frame then
        local base = self:Base(frame)
        if index == 1 then childbase = base end
        if base and base.t <= targetrect.b + gap then
          local relevant = {}
          for _, rect in ipairs(obstacles) do table.insert(relevant, rect) end
          -- Do not newly collide with the target body during fallback placement.
          table.insert(relevant, targetrect)
          if index == 2 and childbase and base.t <= childbase.b + gap then
            local childrect = Rect(child)
            if childrect then table.insert(relevant, childrect) end
            AddAuras(relevant, child)
          end
          self:Place(frame, base, relevant, gap)
        else
          self:Restore(frame)
        end
      end
    end
  end

  -- Reuse the UF driver; read rendered icons, never rescan unit aura data.
  HookScript(pfUI.uf, "OnUpdate", function()
    local now = GetTime()
    if now < (layout.nextUpdate or 0) then return end
    layout.nextUpdate = now + .2
    layout:Update()
  end)

  if pfUI.unlock then
    -- Pre-hook: restore BEFORE unlock builds draggers and enables saving.
    local previous = pfUI.unlock:GetScript("OnShow")
    pfUI.unlock:SetScript("OnShow", function()
      layout:RestoreAll()
      if previous then previous() end
    end)
    HookScript(pfUI.unlock, "OnHide", function() layout:Update() end)
  end
end)
