pfUI:RegisterModule("unlock", "vanilla:tbc", function ()
  local rawborder, default_border = GetBorderSize()

  -- grouped frames
  local clusters = {
    -- Name            Shift  Ctrl
    { "pfCombo",          5       },
    { "pfRaidPet",        40,   5 },
    { "pfRaid",           40,   5 },
    { "pfGroup",          4       },
    { "pfLootRollFrame",  4       },
  }

  local anchors = {
    "TOPLEFT", "TOP", "TOPRIGHT", "RIGHT", "BOTTOMRIGHT", "BOTTOM", "BOTTOMLEFT", "LEFT", "CENTER"
  }


  local spanframe = CreateFrame("Frame", "pfUnlockSelector", UIParent)
  spanframe:Hide()

  -- frame labels and their config section relation
  local frame_configs = {
    -- unitframes
    ["Player"]             = { T["Unit Frames"], T["Player"] },
    ["Target"]             = { T["Unit Frames"], T["Target"] },
    ["TargetTarget"]       = { T["Unit Frames"], T["Target-Target"] },
    ["TargetTargetTarget"] = { T["Unit Frames"], T["Target-Target-Target"] },
    ["Pet"]                = { T["Unit Frames"], T["Pet"] },
    ["PetTarget"]          = { T["Unit Frames"], T["Pet-Target"] },
    ["Focus"]              = { T["Unit Frames"], T["Focus"] },

    -- combopoints
    ["Combo%d"]       = { T["Unit Frames"], T["General"] },

    -- groupframes
    ["Raid%d"]        = { T["Unit Frames"], T["Raid"] },
    ["Raid%d%d"]      = { T["Unit Frames"], T["Raid"] },
    ["RaidPet%d"]     = { T["Unit Frames"], T["Raid"] },
    ["RaidPet%d%d"]   = { T["Unit Frames"], T["Raid"] },
    ["Group%d"]       = { T["Unit Frames"], T["Group"] },
    ["Party%dTarget"] = { T["Unit Frames"], T["Group-Target"] },
    ["PartyPet%d"]    = { T["Unit Frames"], T["Group-Pet"] },

    -- chat
    ["ChatLeft"]      = { T["Chat"], nil },
    ["ChatRight"]     = { T["Chat"], nil },
    ["ChatInputBox"]  = { T["Chat"], nil },

    -- loot
    ["LootRollFrame%d"] = { T["Loot"], nil },

    -- panel
    ["PanelLeft"]        = { T["Panel"], T["General"] },
    ["PanelRight"]       = { T["Panel"], T["General"] },
    ["PanelMinimap"]     = { T["Panel"], T["General"] },
    ["PanelMicroButton"] = { T["Panel"], T["General"] },

    -- actionbar
    ["ActionBarMain"]        = { T["Actionbar"], T["Main Actionbar"]},
    ["ActionBarPaging"]      = { T["Actionbar"], T["Paging Actionbar"]},
    ["ActionBarRight"]       = { T["Actionbar"], T["Right Actionbar"]},
    ["ActionBarVertical"]    = { T["Actionbar"], T["Vertical Actionbar"]},
    ["ActionBarLeft"]        = { T["Actionbar"], T["Left Actionbar"]},
    ["ActionBarTop"]         = { T["Actionbar"], T["Top Actionbar"]},
    ["ActionBarStanceBar1"]  = { T["Actionbar"], T["Stance Bar 1"]},
    ["ActionBarStanceBar2"]  = { T["Actionbar"], T["Stance Bar 2"]},
    ["ActionBarStanceBar3"]  = { T["Actionbar"], T["Stance Bar 3"]},
    ["ActionBarStanceBar4"]  = { T["Actionbar"], T["Stance Bar 4"]},
    ["ActionBarStances"]     = { T["Actionbar"], T["Stance/Shapeshift Actionbar"]},
    ["ActionBarPet"]         = { T["Actionbar"], T["Pet Actionbar"]},

    -- castbar
    ["TargetCastbar"]  = { T["Castbar"], nil },
    ["PlayerCastbar"]  = { T["Castbar"], nil },
    ["FocusCastbar"]   = { T["Castbar"], nil },

    -- minimap
    ["Minimap"]        = { T["Minimap"], T["Minimap"] },
    ["UITracking"]     = { T["Minimap"], T["Minimap"] },

    ["pfLootFrame"] = { T["Loot"], T["Loot Frame"] },

    -- buffs
    ["BuffFrame"]      = { T["Buffs"], T["Buff/Debuff Icons"] },
    ["DebuffFrame"]    = { T["Buffs"], T["Buff/Debuff Icons"] },

    -- buffbars
    ["PlayerBuffBar"]   = { T["Buffs"], T["Player Buff Bar"] },
    ["PlayerDebuffBar"] = { T["Buffs"], T["Player Debuff Bar"] },
    ["TargetDebuffBar"] = { T["Buffs"], T["Target Debuff Bar"] },
  }

  local function GetFrames()
    -- Return frames based on Ctrl and Shift state
    -- 'this'   [frame]       the base frame
    -- return   [list]        all frames that should be selected

    local frame = this.frame
    local frames = { frame }

    if IsShiftKeyDown() or IsControlKeyDown() then
      -- search and add clustered frames
      for id, cluster in pairs(clusters) do
        local len = strlen(cluster[1])
        local name = frame:GetName()
        -- prefix match + digit boundary: the character right after the
        -- prefix must be a digit, so cluster "pfRaid" does not swallow
        -- "pfRaidPetN" frames (and vice versa).
        if strsub(name,0,len) == cluster[1] and strfind(strsub(name,len+1,len+1), "%d") then
          if IsShiftKeyDown() and cluster[2] then
            for i = 1, cluster[2] do
              -- _G guard: pet frames only exist up to raidpetmax, absent
              -- globals must not enter the selection (table.insert + nil
              -- holes are unreliable on Lua 5.0).
              if _G[cluster[1] .. i] and _G[cluster[1] .. i] ~= frame then
                table.insert(frames, _G[cluster[1] .. i])
              end
            end
          elseif IsControlKeyDown() and cluster[3] then
            local id = tonumber(strsub(frame:GetName(),len+1,len+2))

            local b = 1
            for i = cluster[3]+1, cluster[2], cluster[3] do
              b = ( id >= i ) and i or b
            end

            for i = b, b + cluster[3] - 1 do
              if _G[cluster[1] .. i] ~= frame then
                table.insert(frames, _G[cluster[1] .. i])
              end
            end
          end
        end
      end
    end

    return frames
  end

  local function DraggerOnUpdate()
    this.text:SetAlpha(this.text:GetAlpha() -0.05)
    if this.text:GetAlpha() < 0.1 then
      this.text:SetText(strsub(this:GetParent():GetName(),3))
      this.text:SetAlpha(1)
      this:SetScript("OnUpdate", function() return end)
    end
  end

  local function SaveScale(frame, scale)
    -- 缩放会导致模块位置漂移：本客户端 SetPoint 偏移按 frame 自身 scale 缩放
    -- （offset×scale = 父级空间位移），只改 scale 不动偏移，模块必然跑位。
    -- 修复与 map.lua 世界地图 Ctrl+滚轮缩放（实测不漂移）一致：
    -- 保持原锚点不变，偏移按 oldscale/newscale 比例补偿，再设新 scale。
    local oldscale = frame:GetScale()
    local point, relativeTo, relativePoint, offx, offy = frame:GetPoint()

    if point and offx and offy then
      frame:SetPoint(point, relativeTo, relativePoint, offx*oldscale/scale, offy*oldscale/scale)
    end
    frame:SetScale(scale)

    if not C.position[frame:GetName()] then
      C.position[frame:GetName()] = {}
    end
    C.position[frame:GetName()]["scale"] = scale

    frame.drag.text:SetText(T["Scale"] .. ": " .. scale)
    frame.drag.text:SetAlpha(1)

    frame.drag:SetScript("OnUpdate", DraggerOnUpdate)
  end

  local function SavePosition(frame)
    SaveMovable(frame)
    UpdateMovable(frame)
  end

  local function DrawGrid()
    local grid = CreateFrame("Frame", this:GetName() .. "Grid", pfUI.unlock)
    grid:SetAllPoints(this)

    local size = 1
    local line = {}

    local width = GetScreenWidth()
    local height = GetScreenHeight()

    local ratio = width / GetScreenHeight()
    local rheight = GetScreenHeight() * ratio

    local wStep = width / 128
    local hStep = rheight / 128

    -- vertical lines
    for i = 0, 128 do
      if i == 128 / 2 then
        line = grid:CreateTexture(nil, 'BORDER')
        line:SetTexture(.1, .5, .4)
      else
        line = grid:CreateTexture(nil, 'BACKGROUND')
        line:SetTexture(0, 0, 0, .5)
      end
      line:SetPoint("TOPLEFT", grid, "TOPLEFT", i*wStep - (size/2), 0)
      line:SetPoint('BOTTOMRIGHT', grid, 'BOTTOMLEFT', i*wStep + (size/2), 0)
    end

    -- horizontal lines
    for i = 1, floor(height/hStep) do
      if i == floor(height/hStep / 2) then
        line = grid:CreateTexture(nil, 'BORDER')
        line:SetTexture(.1, .5, .4)
      else
        line = grid:CreateTexture(nil, 'BACKGROUND')
        line:SetTexture(0, 0, 0)
      end

      line:SetPoint("TOPLEFT", grid, "TOPLEFT", 0, -(i*hStep) + (size/2))
      line:SetPoint('BOTTOMRIGHT', grid, 'TOPRIGHT', 0, -(i*hStep + size/2))
    end

    return grid
  end

  local function GetConfigTable(dlabel)
    local cat, conf = nil, nil
    for label, config in pairs(frame_configs) do
      if string.gsub(dlabel, label, "") == "" then
        cat, conf = config[1], config[2]
      end
    end

    return cat, conf
  end

  local function OpenConfigDialog(category, view)
    pfUI.gui:Show()

    if not pfUI.gui.frames[category] then return end
    pfUI.gui.frames[category]:Click()

    if not view or not pfUI.gui.frames[category][view] then return end
    pfUI.gui.frames[category][view]:Click()
  end

  local function UpdateDockValues()
    if not pfUI.unlock.dock:IsShown() then return end

    local dock = pfUI.unlock.dock
    local drag = dock.parent
    local frame = drag.frame

    -- update dock position
    SetAutoPoint(dock, drag, default_border*2+2)

    -- update dock entries
    dock.title:SetText(drag.label)
    if pfUI_config["position"] and pfUI_config["position"][drag.fname] and pfUI_config["position"][drag.fname]["xpos"] then
      dock.xcoord:SetText(pfUI_config["position"][drag.fname]["xpos"])
      dock.ycoord:SetText(pfUI_config["position"][drag.fname]["ypos"])
      local anchor = pfUI_config["position"][drag.fname]["anchor"] or "TOPLEFT"

      for id, k in pairs(anchors) do
        -- get human readable
        local value, text = strsplit(":", k)
        text = text or value

        if value == anchor then
          UIDropDownMenu_SetSelectedID(pfUI.unlock.dock.anchor, id, 0)
          UIDropDownMenu_SetText(text, pfUI.unlock.dock.anchor)
        end
      end

      dock.reset:SetText(T["Reset"])

      dock.up:Enable()
      dock.down:Enable()
      dock.left:Enable()
      dock.right:Enable()

      dock.up.texture:SetVertexColor(1,.8,0)
      dock.down.texture:SetVertexColor(1,.8,0)
      dock.left.texture:SetVertexColor(1,.8,0)
      dock.right.texture:SetVertexColor(1,.8,0)
    else
      dock.reset:SetText(T["Unlock"])
      dock.xcoord:SetText(T["N/A"])
      dock.ycoord:SetText(T["N/A"])

      dock.up:Disable()
      dock.down:Disable()
      dock.left:Disable()
      dock.right:Disable()

      dock.up.texture:SetVertexColor(.4,.4,.4)
      dock.down.texture:SetVertexColor(.4,.4,.4)
      dock.left.texture:SetVertexColor(.4,.4,.4)
      dock.right.texture:SetVertexColor(.4,.4,.4)
    end

    -- update config button
    local cat, conf = GetConfigTable(drag.label)
    if cat then
      dock.config:Enable()
    else
      dock.config:Disable()
    end
  end

  local function SetDockToFrame(frame)
    if pfUI.unlock.dock.parent then
      -- reset previous border color
      CreateBackdrop(pfUI.unlock.dock.parent, nil, nil, .8)
    end

    -- add the new frame
    pfUI.unlock.dock.parent = frame

    if frame then
      pfUI.unlock.dock.parent.backdrop:SetBackdropBorderColor(.2,1,.8,1)
      pfUI.unlock.dock:Show()
      UpdateDockValues()
    else
      pfUI.unlock.dock:Hide()
    end
  end

  ---------------------------------------------------------------------------
  -- 吸附对齐（unlock snap）
  -- 解锁模式拖动模块时，模块的 左/中/右（及 上/中/下）会与其它可见模块、
  -- 屏幕边缘 / 中线对齐：**拖动过程中只画参考线**（提示"松手会吸到这里"），
  -- **松手时**才真正把模块挪到对齐位置。按住 Alt 拖动可临时关闭。
  --
  -- ⚠️ 为什么不在拖动过程中移动模块：
  --    1.12 客户端的拖拽是 `frame:StartMoving()` 建立的客户端内部状态，任何
  --    `SetPoint` 都会打断它 —— 一旦被打断，模块就"粘"在第一次触发吸附的位置上，
  --    表现为"所有模块基本都不能移动"（实测两轮，用光标位移兜底也救不回来）。
  --    所以拖动期间**一次 SetPoint 都不调**，手感与没开吸附时完全一致；
  --    对齐只在 DragStop 做一次（那时拖拽状态已结束，SetPoint 最干净）。
  --
  -- 坐标统一换算到「UI 单位」再比较（= GetScreenWidth/GetScreenHeight 所在空间）：
  --     ui = frame:GetLeft() * frame:GetScale()
  -- 与 api.lua 的 ConvertFrameAnchor / GetBestAnchor 换算方式完全一致，
  -- 因此各模块 scale 不同时也不会错位。SetPoint 的偏移量单位是「自身单位」，
  -- 所以 偏移增量 = UI 单位增量 / 自身 scale。
  --
  -- ⚠️ 下面 SNAP-BEGIN/END 之间的代码被 .workbuddy/sim_unlock_snap.js 抽取后离线仿真，
  --    移动/改写该段后请同步跑该仿真。
  --[[SNAP-BEGIN]]
  ---------------------------------------------------------------------------
  local SNAP_DEFAULT = 8                        -- 默认吸附距离（UI 单位，手动输入）

  local snaptargets = {}                        -- 吸附目标矩形（UI 单位）
  local snapowner                               -- 正在拖动的 drag 按钮
  local snapdriver                              -- OnUpdate 驱动器（仅拖动期间显示）
  local snapframe, snapvline, snaphline         -- 参考线载体与两条线
  local snapedge = {}                           -- 屏幕矩形（UI 单位）

  -- 读取配置：是否开启吸附 + 吸附距离（按住 Alt 临时关闭）
  local function SnapEnabled()
    if C.global.unlock_snap == "0" then return false end
    if IsAltKeyDown() then return false end

    local limit = tonumber(C.global.unlock_snap_distance) or SNAP_DEFAULT
    if limit < 1 then limit = SNAP_DEFAULT end

    return true, limit
  end

  -- 屏幕矩形（UI 单位）
  local function SnapScreen()
    local l, r, t, b = UIParent:GetLeft(), UIParent:GetRight(), UIParent:GetTop(), UIParent:GetBottom()

    if not (l and r and t and b) then
      l, r, t, b = 0, GetScreenWidth(), GetScreenHeight(), 0
    end

    return l, r, t, b
  end

  -- 模块矩形换算成 UI 单位；几何缺失（未布局的帧）返回 nil
  local function SnapRect(frame)
    local scale = frame:GetScale() or 1
    local l, r, t, b = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()

    if not (l and r and t and b) then return nil end

    return l * scale, r * scale, t * scale, b * scale
  end

  -- 收集吸附目标：屏幕 + 其它可见模块（本次拖动选中的模块已打 snapignore 排除）
  local function SnapCollect()
    snaptargets = {}

    local l, r, t, b = SnapScreen()
    snapedge = { left = l, right = r, top = t, bottom = b, cx = (l + r) / 2, cy = (t + b) / 2, screen = true }
    snaptargets[1] = snapedge

    for name, frame in pairs(pfUI.movables) do
      frame = frame or _G[name]

      if frame and not frame.snapignore and frame:IsShown() then
        local fl, fr, ft, fb = SnapRect(frame)

        if fl then
          snaptargets[table.getn(snaptargets) + 1] = {
            left = fl, right = fr, top = ft, bottom = fb,
            cx = (fl + fr) / 2, cy = (ft + fb) / 2,
          }
        end
      end
    end
  end

  -- 在一条轴上找最近的可吸附位置
  -- m1/m2/m3 = mover 的 起点/中点/终点；k1/k2/k3 = 目标矩形上对应的坐标键
  -- 候选 5 种：
  --   ① 起点↔目标起点  ② 中点↔目标中点  ③ 终点↔目标终点   （同位对齐）
  --   ④ 起点↔目标终点  ⑤ 终点↔目标起点                   （相邻贴合）
  -- ④⑤ 就是「拖动作条2 到动作条1 旁边／上下，自动贴上去拼齐」——只做①②③的话，
  -- 两条动作条上下紧挨（上沿贴下沿）这种最常见的摆法反而吸不住（实测踩到）。
  local function SnapAxis(m1, m2, m3, k1, k2, k3, limit)
    local best, bestdist = nil, nil

    for id = 1, table.getn(snaptargets) do
      local tgt = snaptargets[id]
      local c1, c2, c3 = tgt[k1], tgt[k2], tgt[k3]

      for c = 1, 5 do
        local mv, cand

        if c == 1 then
          mv, cand = m1, c1
        elseif c == 2 then
          mv, cand = m2, c2
        elseif c == 3 then
          mv, cand = m3, c3
        elseif c == 4 then
          mv, cand = m1, c3
        else
          mv, cand = m3, c1
        end

        local d = cand - mv
        local ad = d < 0 and -d or d

        if ad <= limit and (not bestdist or ad < bestdist) then
          bestdist = ad
          best = { delta = d, at = cand, tgt = tgt }
        end
      end
    end

    return best
  end

  local function SnapLineCreate()
    if snapframe then return end

    snapframe = CreateFrame("Frame", "pfUnlockSnapLines", UIParent)
    snapframe:SetAllPoints(UIParent)
    snapframe:SetFrameStrata("FULLSCREEN_DIALOG")
    -- 全屏帧绝不参与鼠标事件：万一它吃掉鼠标，所有模块都会拖不动
    snapframe:EnableMouse(false)
    snapframe:Hide()

    snapvline = snapframe:CreateTexture(nil, "OVERLAY")
    snapvline:SetTexture(.2, 1, .8, .9)
    snapvline:Hide()

    snaphline = snapframe:CreateTexture(nil, "OVERLAY")
    snaphline:SetTexture(.2, 1, .8, .9)
    snaphline:Hide()
  end

  -- 在模块当前位置上找它该吸到哪里（纯只读，不改任何东西）
  -- 返回 SnapAxis 的两条轴结果 + 模块矩形（UI 单位）；开关关闭/几何缺失/没得吸 → nil
  local function SnapFind(frame)
    local on, limit = SnapEnabled()
    if not on then return nil end

    local l, r, t, b = SnapRect(frame)
    if not l then return nil end

    local w, h = r - l, t - b
    local sx = SnapAxis(l, l + w / 2, r, "left", "cx", "right", limit)
    local sy = SnapAxis(b, b + h / 2, t, "bottom", "cy", "top", limit)

    if not sx and not sy then return nil end

    return sx, sy, l, r, t, b
  end

  -- 拖动中的每帧：**只画参考线**，绝不移动模块。
  -- ⚠️ 拖动期间任何 SetPoint 都会打断客户端的拖拽状态（StartMoving 建立的），
  --    模块会"粘"在第一次触发吸附的位置上再也拖不动 —— 前两版就是这么坏的。
  local function SnapUpdate()
    local drag = snapowner
    if not drag then return end

    local frame = drag.frame
    if not frame then return end

    local sx, sy, l, r, t, b = SnapFind(frame)

    if not sx and not sy then
      if snapframe and snapframe:IsShown() then snapframe:Hide() end
      return
    end

    local w, h = r - l, t - b

    -- 参考线：竖线标 X 对齐，横线标 Y 对齐，长度覆盖两个模块
    SnapLineCreate()
    local sl, _, st = SnapScreen()
    local mvl, mvr, mvt, mvb = l, r, t, b
    local any = false

    if sx then
      local ot, ob = sx.tgt.top, sx.tgt.bottom
      if sx.tgt.screen then ot, ob = mvt, mvb end

      local ytop = (mvt > ot) and mvt or ot
      local ybot = (mvb < ob) and mvb or ob

      snapvline:ClearAllPoints()
      -- Y 偏移：SetPoint 的 y 向上为正，而 st - ytop 是"距屏幕顶部的距离"，
      -- 所以必须写成 (ytop - st) 才是屏幕坐标 ytop 处的偏移
      snapvline:SetPoint("TOPLEFT", snapframe, "TOPLEFT", sx.at - sl, ytop - st)
      snapvline:SetWidth(1)
      snapvline:SetHeight(ytop - ybot)
      snapvline:Show()
      any = true
    else
      snapvline:Hide()
    end

    if sy then
      local xl, xr = sy.tgt.left, sy.tgt.right
      if sy.tgt.screen then xl, xr = mvl, mvr end
      if mvl < xl then xl = mvl end
      if mvr > xr then xr = mvr end

      snaphline:ClearAllPoints()
      snaphline:SetPoint("TOPLEFT", snapframe, "TOPLEFT", xl - sl, sy.at - st)
      snaphline:SetWidth(xr - xl)
      snaphline:SetHeight(1)
      snaphline:Show()
      any = true
    else
      snaphline:Hide()
    end

    if any then snapframe:Show() else snapframe:Hide() end
  end

  -- 开始拖动：排除选择集（它们会跟着主帧一起移动），收集目标并启动参考线驱动
  local function SnapStart(drag)
    -- 先清掉历史残留：上一次拖动若中途报错，SnapStop 没跑到，snapignore 会永久留在
    -- 那些帧上（它们就再也不参与吸附了）。这里按"先全清、再标记本次选择集"来做，幂等。
    for name, frame in pairs(pfUI.movables) do
      frame = frame or _G[name]
      if frame then frame.snapignore = nil end
    end

    local sel = pfUI.unlock.selection
    for id = 1, table.getn(sel) do
      if sel[id] then sel[id].snapignore = true end
    end

    -- 被拖的主帧自己绝不作为吸附目标（正常情况下它已在 selection 里，双保险）
    if drag and drag.frame then drag.frame.snapignore = true end

    snapowner = drag
    SnapCollect()

    if not snapdriver then
      snapdriver = CreateFrame("Frame")
      snapdriver:Hide()
      snapdriver:EnableMouse(false)
      snapdriver:SetScript("OnUpdate", SnapUpdate)
    end

    snapdriver:Show()
  end

  local function SnapStop()
    local sel = pfUI.unlock and pfUI.unlock.selection

    if sel then
      for id = 1, table.getn(sel) do
        if sel[id] then sel[id].snapignore = nil end
      end
    end

    -- 主帧若因异常不在 selection 里，它的 snapignore 也要清掉
    if snapowner and snapowner.frame then snapowner.frame.snapignore = nil end

    snapowner = nil
    snaptargets = {}

    if snapdriver then snapdriver:Hide() end
    if snapframe then snapframe:Hide() end
  end

  -- 松手时对齐：把模块挪到参考线位置 —— 整条链路上**唯一**移动模块的地方。
  -- 必须在 SnapStop 之前算（SnapStop 会清掉 snaptargets 与 snapignore）。
  local function SnapFinish()
    local drag = snapowner
    local frame = drag and drag.frame
    local sx, sy

    if frame then sx, sy = SnapFind(frame) end

    SnapStop()

    if not frame or (not sx and not sy) then return end

    -- 几何缺失的帧不动：ConvertFrameAnchor 会兜底返回 (anchor, 0, 0)，
    -- 真写下去等于把它瞬移到屏幕角落（DragStop 的保存循环也是同样跳过）。
    if not (frame:GetLeft() and frame:GetTop() and frame:GetRight() and frame:GetBottom()) then return end

    local scale = frame:GetScale()

    if not scale or scale == 0 then scale = 1 end

    -- ⚠️ 这里**不能**拿 `frame:GetPoint()` 的返回值去 SetPoint：本客户端上它的返回值
    --    不可信（可能什么都不返回，也可能把非 region / 非锚点串当作 relativeTo /
    --    relativePoint 返回，前者的空值守卫拦不住后者）—— 实测直接抛
    --    "Usage: pfActionBarPet:SetPoint("point" [, region or nil] [, "relativePoint"] [, ...])"。
    -- 改用与下面 DragStop「save all frame positions」完全一致的绝对定位：
    -- anchor 经 ConvertFrameAnchor 收敛到 9 种之一，偏移量单位为「自身单位」，
    -- 因此 UI 单位的吸附增量要除以自身 scale。
    local anchor, x, y = ConvertFrameAnchor(frame, "TOPLEFT")

    frame:ClearAllPoints()
    frame:SetPoint(anchor, UIParent, anchor,
                   x + (sx and sx.delta or 0) / scale,
                   y + (sy and sy.delta or 0) / scale)
  end
  --[[SNAP-END]]

  local function DraggerOnMouseWheel()
    local frame = this.frame
    local scale = round(frame:GetScale() + arg1/10, 1)

    pfUI.unlock.selection = GetFrames()
    for id, frame in pairs(pfUI.unlock.selection) do
      SaveScale(frame, scale)
      -- 缩放后位置已重锚，必须同步持久化（SaveMovable 存新偏移），
      -- 否则 /reload 后 LoadMovable 用旧偏移 + 新 scale，模块会再次漂移
      SavePosition(frame)
    end

    -- repaint hackfix for panels
    if pfUI.panel and pfUI.chat then
      pfUI.panel.left:SetScale(pfUI.chat.left:GetScale())
      pfUI.panel.right:SetScale(pfUI.chat.right:GetScale())
    end

    if frame.OnMove then frame:OnMove() end
    QueueFunction(UpdateDockValues)
  end

  local function DraggerOnDragStart()
    local frame = this.frame

    pfUI.unlock.selection = GetFrames()

    for id, frame in pairs(pfUI.unlock.selection) do
      frame:StartMoving()
      frame:StopMovingOrSizing()
      frame.drag.backdrop:SetBackdropBorderColor(.2,1,.8,1)
    end

    local anchor, _, _, xpos, ypos = frame:GetPoint()
    -- ⚠️ 1.12 下 GetPoint() 可能什么都不返回（帧无锚点 / 刚做过 StartMoving+StopMovingOrSizing），
    -- xpos/ypos 会是 nil。这里**保持原样**存下来（补 0 会掩盖"没拿到锚点"这个事实，
    -- 让停止端的差值算成垃圾值），判空交给 DraggerOnDragStop。
    frame.oldPos = { xpos, ypos, anchor }
    frame:StartMoving()

    -- 启动吸附对齐（会先排除本次选择集，它们跟随主帧移动）
    SnapStart(this)

    if frame.OnMove then frame:OnMove() end
  end

  local function DraggerOnDragStop()
    local frame = this.frame
    local name = this.fname

    -- 先结束客户端的拖拽状态，再按最终位置对齐一次。
    -- （拖动期间我们一次 SetPoint 都没调，所以此刻的几何就是玩家最后看到的位置；
    --   拖拽状态结束后再 SetPoint 也最干净，两者不会互相打断。）
    frame:StopMovingOrSizing()
    SnapFinish()

    -- calculate and move selection offsets
    -- ⚠️ 起始锚点没拿到时（GetPoint 返回 nil）算出来的 diff 是垃圾值，会把整组模块一起推走
    -- → 这种情况直接按 0 位移处理，各帧保持自己当前位置（0 在 Lua 里为真，故用真值判断）。
    local diffxpos, diffypos = 0, 0

    if frame.oldPos and frame.oldPos[1] and frame.oldPos[2] then
      local anchor, xpos, ypos = ConvertFrameAnchor(frame, frame.oldPos[3])
      diffxpos = frame.oldPos[1] - xpos
      diffypos = frame.oldPos[2] - ypos
    end

    for id, frame in pairs(pfUI.unlock.selection) do
      frame:SetParent("UIParent")
      if frame:GetName() ~= name then
        local anchor, _, _, xpos, ypos = frame:GetPoint()

        -- 无锚点的帧（GetPoint 返回 nil）不参与整组位移，否则算术/SetPoint 报错
        if xpos and ypos then
          frame:SetPoint(anchor or "TOPLEFT", xpos - diffxpos, ypos - diffypos)
        end
      end
    end

    -- detect best anchor
    local bestanchor = "TOPLEFT"
    local left, top, right, bottom
    spanframe:ClearAllPoints()

    for id, frame in pairs(pfUI.unlock.selection) do
      -- ⚠️ 1.12：隐藏/未布局的帧几何全为 nil。nil 参与 `<`/`>` 比较会报错，
      -- 而把 spanframe 锚到这种帧上会让它自己也没有几何 → 下面 GetBestAnchor 返回 nil
      -- → SetPoint(nil, ...) 报 "Usage: xxx:SetPoint(...)"（实测报在 pfActionBarPet）。
      -- 所以几何不全的帧整体跳过，不污染 spanframe。
      local fl, ft, fr, fb = frame:GetLeft(), frame:GetTop(), frame:GetRight(), frame:GetBottom()

      if fl and ft and fr and fb then
        if not left or fl < left then
          spanframe:SetPoint("LEFT", frame, "LEFT", 0, 0)
          left = fl
        end
        if not top or ft > top then
          spanframe:SetPoint("TOP", frame, "TOP", 0, 0)
          top = ft
        end
        if not right or fr > right then
          spanframe:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
          right = fr
        end
        if not bottom or fb < bottom then
          spanframe:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
          bottom = fb
        end
      end
    end
    bestanchor = GetBestAnchor(spanframe) or "TOPLEFT"

    -- save all frame positions
    for id, frame in pairs(pfUI.unlock.selection) do
      CreateBackdrop(frame.drag, nil, nil, .8)

      -- 几何缺失的帧不重定位：ConvertFrameAnchor 的兜底会返回 (anchor, 0, 0)，
      -- 直接写下去等于把它瞬移到角落并存进存档（位置被写坏），不如跳过、保留原位置。
      if frame:GetLeft() and frame:GetTop() and frame:GetRight() and frame:GetBottom() then
        -- A manually selected anchor must survive later drags, including group moves.
        local position = C.position[frame:GetName()]
        local anchor, x, y = ConvertFrameAnchor(frame,
          position and position.anchor_manual or bestanchor)
        frame:ClearAllPoints()
        frame:SetPoint(anchor, UIParent, anchor, x, y)
        SavePosition(frame)
      end
    end

    this.backdrop:SetBackdropBorderColor(1,1,1,1)
    UpdateDockValues()
  end

  local function DraggerOnClick()
    if arg1 == "RightButton" then
      -- add dockframe to the dragger to show advanced options
      if pfUI.unlock.dock.parent == this and pfUI.unlock.dock:IsShown() then
        SetDockToFrame(nil)
      else
        SetDockToFrame(this)
      end
      return
    elseif arg1 == "MiddleButton" then
      -- reset positions of dragger and all connected frames
      pfUI.unlock.selection = GetFrames()
      for id, frame in pairs(pfUI.unlock.selection) do
        pfUI_config["position"][frame:GetName()] = nil
        UpdateMovable(frame)

        if frame.OnMove then frame:OnMove() end
      end
      UpdateDockValues()
    end
  end

  local function DraggerOnEnter()
    if pfUI.unlock.dock.parent ~= this then
      this.backdrop:SetBackdropBorderColor(1,1,1,1)
    end
  end

  local function DraggerOnLeave()
    if pfUI.unlock.dock.parent ~= this then
      CreateBackdrop(this, nil, nil, .8)
    end
  end

  local function CreateDragger(f)
    local fname = f:GetName()
    local label = string.sub(fname, 1, 2) == "pf" and strsub(fname,3) or fname

    local d = CreateFrame("Button", fname .. "Drag", f)
    d:RegisterForClicks("MiddleButtonUp", "RightButtonUp")
    d:RegisterForDrag("LeftButton")
    d:SetAllPoints(f)
    d:SetAlpha(1)
    d:EnableMouseWheel(1)

    d:SetFrameLevel(128)

    d.text = d:CreateFontString("Status", "LOW", "GameFontNormal")
    d.text:SetFont(pfUI.font_default, C.global.font_size, "OUTLINE")
    d.text:ClearAllPoints()
    d.text:SetAllPoints(d)
    d.text:SetPoint("CENTER", 0, 0)
    d.text:SetFontObject(GameFontWhite)

    d.frame = f
    d.fname = fname
    d.label = label

    if d:GetHeight() > (2 * d:GetWidth()) then
      label = strvertical(label)
    end

    d.text:SetText(label)

    d:SetScript("OnMouseWheel", DraggerOnMouseWheel)
    d:SetScript("OnDragStart", DraggerOnDragStart)
    d:SetScript("OnDragStop", DraggerOnDragStop)
    d:SetScript("OnClick", DraggerOnClick)
    d:SetScript("OnEnter", DraggerOnEnter)
    d:SetScript("OnLeave", DraggerOnLeave)

    CreateBackdrop(d, nil, nil, .8)
    return d
  end

  table.insert(UISpecialFrames, "pfUnlock")
  pfUI.unlock = CreateFrame("Button", "pfUnlock", UIParent)
  pfUI.unlock.selection = {}
  pfUI.unlock:Hide()
  pfUI.unlock:SetAllPoints(WorldFrame)
  pfUI.unlock:SetFrameStrata("BACKGROUND")
  pfUI.unlock:SetScript("OnClick", function()
    this:Hide()
  end)

  pfUI.unlock:SetScript("OnShow", function()
    if this.skip then this.skip = nil return end
    if InCombatLockdown and InCombatLockdown() then
      DEFAULT_CHAT_FRAME:AddMessage(ERR_NOT_IN_COMBAT, 1, .2, .2)
      this.skip = true
      this:Hide()
      return
    end

    this.grid = this.grid or DrawGrid()

    for name, frame in pairs(pfUI.movables) do
      local frame = frame or _G[name]

      -- Recomputed on every unlock: a stale "true" left over from a previous
      -- session would make OnHide close the frame again even when it was
      -- legitimately visible this time (e.g. a loot window that happened to
      -- be open when unlock mode was entered).
      frame.hideLater = not frame:IsShown()
      frame.drag = frame.drag or CreateDragger(frame)
      frame:SetMovable(true)
      frame.drag:Show()
      frame:Show()
    end

    local txt = T["Unlock Mode allows you to move, scale and reset frames:\n\n|cff33ffcc[Left Click]|r Drag Frame\n|cff33ffcc[Middle Click]|r Reset Frame\n|cff33ffcc[Right Click]|r Option Box\n\nHold |cff33ffcc[Shift]|r to select all frames of the same kind\nHold |cff33ffcc[Ctrl]|r to select all frames of the same group\n\n|cff33ffcc[Scroll]|r to change the scale of a frame\n\n|cff33ffcc[Click]|r on an empty area or press |cff33ffcc[Esc]|r to exit\n"]
    txt = txt .. "\n|cff33ffcc[Alt]|r " .. T["Drag without snapping"] .. "\n"
    txt = txt .. T["Snap Hint"] .. "\n"
    CreateInfoBox(txt, 15, pfUI.unlock, 180)
    pfUI.gui:Hide()
  end)

  pfUI.unlock:SetScript("OnHide", function()
    if this.skip then this.skip = nil return end
    if InCombatLockdown and InCombatLockdown() then
      this.skip = true
      this:Show()
      return
    end

    -- 退出解锁模式时收尾吸附（清 snapignore / 隐藏驱动与参考线）
    SnapStop()

    for name, frame in pairs(pfUI.movables) do
      local frame = frame or _G[name]

      if frame.hideLater == true then frame:Hide() end
      frame:StopMovingOrSizing()
      frame:SetMovable(false)
      frame.drag:Hide()
      UpdateMovable(frame)
    end

    SetDockToFrame(nil)
    pfUI.unlock:Hide()
    pfUI.gui:Show()
  end)

  -- dock frame
  pfUI.unlock.dock = CreateFrame("Button", "pfUnlockDock", pfUI.unlock)
  pfUI.unlock.dock:SetWidth(150)
  pfUI.unlock.dock:SetHeight(160)
  pfUI.unlock.dock:SetFrameStrata("FULLSCREEN_DIALOG")
  pfUI.unlock.dock:Hide()
  CreateBackdrop(pfUI.unlock.dock)

  -- title
  pfUI.unlock.dock.title = pfUI.unlock.dock:CreateFontString("Status", "DIALOG", "GameFontNormal")
  pfUI.unlock.dock.title:SetTextColor(1,1,1,1)
  pfUI.unlock.dock.title:SetFont(pfUI.font_default, C.global.font_size + 2, "OUTLINE")
  pfUI.unlock.dock.title:SetJustifyH("left")
  pfUI.unlock.dock.title:SetPoint("TOP", 0, -5)

  -- anchor
  pfUI.unlock.dock.anchor = CreateFrame("Frame", "pfUIUnlockAnchorDropDownMenu", pfUI.unlock.dock, "UIDropDownMenuTemplate")
  pfUI.unlock.dock.anchor:ClearAllPoints()
  pfUI.unlock.dock.anchor:SetPoint("TOP", 0, -25)

  UIDropDownMenu_SetWidth(120, pfUI.unlock.dock.anchor)
  UIDropDownMenu_SetButtonWidth(120, pfUI.unlock.dock.anchor)
  UIDropDownMenu_JustifyText("RIGHT", pfUI.unlock.dock.anchor)
  UIDropDownMenu_Initialize(pfUI.unlock.dock.anchor, function()
    local info = {}
    for id, k in pairs(anchors) do
      -- get human readable
      local value, text = strsplit(":", k)
      local id = id
      text = text or value

      info.text = text
      info.checked = false
      info.func = function()
        UIDropDownMenu_SetSelectedID(pfUI.unlock.dock.anchor, id, 0)
        UIDropDownMenu_SetText(text, pfUI.unlock.dock.anchor)

        local frame = pfUI.unlock.dock.parent.frame
        local anchor, x, y = ConvertFrameAnchor(frame, text)
        frame:ClearAllPoints()
        frame:SetPoint(anchor, UIParent, anchor, x, y)

        SavePosition(frame)
        C.position[frame:GetName()].anchor_manual = anchor
        UpdateDockValues()
      end

      UIDropDownMenu_AddButton(info)
    end
  end)

  SkinDropDown(pfUI.unlock.dock.anchor)

  -- x coordinates
  pfUI.unlock.dock.xcoordcap = pfUI.unlock.dock:CreateFontString("Status", "DIALOG", "GameFontNormal")
  pfUI.unlock.dock.xcoordcap:SetFont(pfUI.font_default, C.global.font_size, "OUTLINE")
  pfUI.unlock.dock.xcoordcap:SetJustifyH("LEFT")
  pfUI.unlock.dock.xcoordcap:SetPoint("TOPLEFT", 5, -63)
  pfUI.unlock.dock.xcoordcap:SetText("X:")
  pfUI.unlock.dock.xcoord = CreateFrame("EditBox", nil, pfUI.unlock.dock)
  pfUI.unlock.dock.xcoord:SetTextInsets(5, 5, 5, 5)
  pfUI.unlock.dock.xcoord:SetJustifyH("CENTER")
  pfUI.unlock.dock.xcoord:SetWidth(45)
  pfUI.unlock.dock.xcoord:SetHeight(18)
  pfUI.unlock.dock.xcoord:SetPoint("TOPLEFT", pfUI.unlock.dock, "TOPLEFT", 20, -60)
  pfUI.unlock.dock.xcoord:SetFontObject(GameFontNormal)
  pfUI.unlock.dock.xcoord:SetAutoFocus(false)

  pfUI.unlock.dock.xcoord:SetScript("OnEnterPressed", function(self)
    local newXPos = tonumber(this:GetText())
    if newXPos then
      local frame = pfUI.unlock.dock.parent.frame
      local anchor, _, _, xpos, ypos = frame:GetPoint()
      frame:SetPoint(anchor, newXPos, ypos)
      SavePosition(frame)
    else
      UpdateDockValues()
    end
    this:ClearFocus()
  end)

  pfUI.unlock.dock.xcoord:SetScript("OnTextChanged", function(self)
    if tonumber(this:GetText()) then
      this:SetTextColor(1,1,1,1)
    else
      this:SetTextColor(1,.3,.3,1)
    end
  end)

  CreateBackdrop(pfUI.unlock.dock.xcoord, nil, true)

  -- y coordinates
  pfUI.unlock.dock.ycoordcap = pfUI.unlock.dock:CreateFontString("Status", "DIALOG", "GameFontNormal")
  pfUI.unlock.dock.ycoordcap:SetFont(pfUI.font_default, C.global.font_size, "OUTLINE")
  pfUI.unlock.dock.ycoordcap:SetText("Y:")
  pfUI.unlock.dock.ycoordcap:SetJustifyH("LEFT")
  pfUI.unlock.dock.ycoordcap:SetPoint("TOPLEFT", 75, -63)
  pfUI.unlock.dock.ycoord = CreateFrame("EditBox", nil, pfUI.unlock.dock)
  pfUI.unlock.dock.ycoord:SetTextInsets(5, 5, 5, 5)
  pfUI.unlock.dock.ycoord:SetJustifyH("CENTER")
  pfUI.unlock.dock.ycoord:SetWidth(45)
  pfUI.unlock.dock.ycoord:SetHeight(18)
  pfUI.unlock.dock.ycoord:SetPoint("TOPLEFT", pfUI.unlock.dock, "TOPLEFT", 90, -60)
  pfUI.unlock.dock.ycoord:SetFontObject(GameFontNormal)
  pfUI.unlock.dock.ycoord:SetAutoFocus(false)

  pfUI.unlock.dock.ycoord:SetScript("OnEnterPressed", function(self)
    local newYPos = tonumber(this:GetText())
    if newYPos then
      local frame = pfUI.unlock.dock.parent.frame
      local anchor, _, _, xpos, ypos = frame:GetPoint()
      frame:SetPoint(anchor, xpos, newYPos)
      SavePosition(frame)
    else
      UpdateDockValues()
    end
    this:ClearFocus()
  end)

  pfUI.unlock.dock.ycoord:SetScript("OnTextChanged", function(self)
    if tonumber(this:GetText()) then
      this:SetTextColor(1,1,1,1)
    else
      this:SetTextColor(1,.3,.3,1)
    end
  end)

  CreateBackdrop(pfUI.unlock.dock.ycoord, nil, true)

  -- reset button
  pfUI.unlock.dock.reset = CreateFrame("Button", "pfDragDockReset", pfUI.unlock.dock, "UIPanelButtonTemplate")
  pfUI.unlock.dock.reset:SetHeight(18)
  pfUI.unlock.dock.reset:SetPoint("TOPLEFT", 5, -85)
  pfUI.unlock.dock.reset:SetPoint("TOPRIGHT", -5, -85)
  pfUI.unlock.dock.reset:SetScript("OnClick", function()
    local frame = pfUI.unlock.dock.parent.frame

    if this:GetText() == T["Reset"] then
      pfUI_config["position"][frame:GetName()] = nil
      frame:ClearAllPoints()
      UpdateMovable(frame)
    else
      frame:StartMoving()
      frame:StopMovingOrSizing()
      SavePosition(frame)
    end

    if frame.OnMove then frame:OnMove() end

    QueueFunction(SetDockToFrame, pfUI.unlock.dock.parent)
  end)
  SkinButton(pfUI.unlock.dock.reset,.2,1,.8)

  -- move left
  pfUI.unlock.dock.left = CreateFrame("Button", "pfDragDockPosUp", pfUI.unlock.dock, "UIPanelButtonTemplate")
  pfUI.unlock.dock.left:SetHeight(18)
  pfUI.unlock.dock.left:SetWidth(18)
  pfUI.unlock.dock.left:SetPoint("TOP", -50, -110)
  pfUI.unlock.dock.left.texture = pfUI.unlock.dock.left:CreateTexture("arrow")
  pfUI.unlock.dock.left.texture:SetTexture(pfUI.media["img:left"])
  pfUI.unlock.dock.left.texture:ClearAllPoints()
  pfUI.unlock.dock.left.texture:SetPoint("TOPLEFT", pfUI.unlock.dock.left, "TOPLEFT", 4, -2)
  pfUI.unlock.dock.left.texture:SetPoint("BOTTOMRIGHT", pfUI.unlock.dock.left, "BOTTOMRIGHT", -4, 2)
  pfUI.unlock.dock.left:SetScript("OnClick", function()
    local frame = pfUI.unlock.dock.parent.frame
    local anchor, _, _, xpos, ypos = frame:GetPoint()
    frame:SetPoint(anchor or "TOPLEFT", xpos - 1, ypos)
    SavePosition(frame)
    UpdateDockValues()
  end)
  SkinButton(pfUI.unlock.dock.left,.2,1,.8)

  -- move right
  pfUI.unlock.dock.right = CreateFrame("Button", "pfDragDockPosUp", pfUI.unlock.dock, "UIPanelButtonTemplate")
  pfUI.unlock.dock.right:SetHeight(18)
  pfUI.unlock.dock.right:SetWidth(18)
  pfUI.unlock.dock.right:SetPoint("TOP", -25, -110)
  pfUI.unlock.dock.right.texture = pfUI.unlock.dock.right:CreateTexture("arrow")
  pfUI.unlock.dock.right.texture:SetTexture(pfUI.media["img:right"])
  pfUI.unlock.dock.right.texture:ClearAllPoints()
  pfUI.unlock.dock.right.texture:SetPoint("TOPLEFT", pfUI.unlock.dock.right, "TOPLEFT", 4, -2)
  pfUI.unlock.dock.right.texture:SetPoint("BOTTOMRIGHT", pfUI.unlock.dock.right, "BOTTOMRIGHT", -4, 2)
  pfUI.unlock.dock.right:SetScript("OnClick", function()
    local frame = pfUI.unlock.dock.parent.frame
    local anchor, _, _, xpos, ypos = frame:GetPoint()
    frame:SetPoint(anchor or "TOPLEFT", xpos + 1, ypos)
    SavePosition(frame)
    UpdateDockValues()
  end)
  SkinButton(pfUI.unlock.dock.right,.2,1,.8)

  -- move up
  pfUI.unlock.dock.up = CreateFrame("Button", "pfDragDockPosUp", pfUI.unlock.dock, "UIPanelButtonTemplate")
  pfUI.unlock.dock.up:SetHeight(18)
  pfUI.unlock.dock.up:SetWidth(18)
  pfUI.unlock.dock.up:SetPoint("TOP", 25, -110)
  pfUI.unlock.dock.up.texture = pfUI.unlock.dock.up:CreateTexture("arrow")
  pfUI.unlock.dock.up.texture:SetTexture(pfUI.media["img:up"])
  pfUI.unlock.dock.up.texture:ClearAllPoints()
  pfUI.unlock.dock.up.texture:SetPoint("TOPLEFT", pfUI.unlock.dock.up, "TOPLEFT", 4, -2)
  pfUI.unlock.dock.up.texture:SetPoint("BOTTOMRIGHT", pfUI.unlock.dock.up, "BOTTOMRIGHT", -4, 2)
  pfUI.unlock.dock.up:SetScript("OnClick", function()
    local frame = pfUI.unlock.dock.parent.frame
    local anchor, _, _, xpos, ypos = frame:GetPoint()
    frame:SetPoint(anchor or "TOPLEFT", xpos, ypos + 1)
    SavePosition(frame)
    UpdateDockValues()
  end)
  SkinButton(pfUI.unlock.dock.up,.2,1,.8)

  -- move down
  pfUI.unlock.dock.down = CreateFrame("Button", "pfDragDockPosUp", pfUI.unlock.dock, "UIPanelButtonTemplate")
  pfUI.unlock.dock.down:SetHeight(18)
  pfUI.unlock.dock.down:SetWidth(18)
  pfUI.unlock.dock.down:SetPoint("TOP", 50, -110)
  pfUI.unlock.dock.down.texture = pfUI.unlock.dock.down:CreateTexture("arrow")
  pfUI.unlock.dock.down.texture:SetTexture(pfUI.media["img:down"])
  pfUI.unlock.dock.down.texture:ClearAllPoints()
  pfUI.unlock.dock.down.texture:SetPoint("TOPLEFT", pfUI.unlock.dock.down, "TOPLEFT", 4, -2)
  pfUI.unlock.dock.down.texture:SetPoint("BOTTOMRIGHT", pfUI.unlock.dock.down, "BOTTOMRIGHT", -4, 2)
  pfUI.unlock.dock.down:SetScript("OnClick", function()
    local frame = pfUI.unlock.dock.parent.frame
    local anchor, _, _, xpos, ypos = frame:GetPoint()
    frame:SetPoint(anchor or "TOPLEFT", xpos, ypos - 1)
    SavePosition(frame)
    UpdateDockValues()
  end)
  SkinButton(pfUI.unlock.dock.down,.2,1,.8)

  -- open config
  pfUI.unlock.dock.config = CreateFrame("Button", "pfDragDockConfigOpen", pfUI.unlock.dock, "UIPanelButtonTemplate")
  pfUI.unlock.dock.config:SetHeight(18)
  pfUI.unlock.dock.config:SetPoint("BOTTOMLEFT", 5, 5)
  pfUI.unlock.dock.config:SetPoint("BOTTOMRIGHT", -5, 5)
  pfUI.unlock.dock.config:SetText(T["Configure"])
  pfUI.unlock.dock.config:SetScript("OnClick", function()
    local cat, conf = GetConfigTable(pfUI.unlock.dock.parent.label)
    if cat then OpenConfigDialog(cat, conf) end
  end)
  SkinButton(pfUI.unlock.dock.config,.2,1,.8)
end)
