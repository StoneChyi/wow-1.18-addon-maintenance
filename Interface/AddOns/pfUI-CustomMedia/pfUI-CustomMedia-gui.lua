-- pfUI-CustomMedia-gui.lua
-- 在 pfUI 设置界面内嵌「Custom Media」分类页：
-- 左侧新增一个页签，网格展示 bars/ 下全部 26 张材质缩略图，
-- 悬停显示名称/路径，点击直接应用到上方下拉选择的目标配置。
-- 仅依赖 pfUI 官方暴露的 pfUI.gui.CreateGUIEntry / CreateConfig，不改 pfUI 文件。

local addonpath
local tocs = { "", "-master", "-tbc", "-wotlk" }
for _, name in pairs(tocs) do
  local current = string.format("pfUI-CustomMedia%s", name)
  local _, title = GetAddOnInfo(current)
  if title then
    addonpath = "Interface\\AddOns\\" .. current
    break
  end
end

-- gui 模块被关闭 / pfUI 未加载时静默退出
if not pfUI or not pfUI.gui or not pfUI.gui.CreateGUIEntry then return end

-- 26 张材质清单（bars/ 目录，A-Z）
local textures = {}
for letter in string.gmatch("ABCDEFGHIJKLMNOPQRSTUVWXYZ", ".") do
  table.insert(textures, {
    path = addonpath .. "\\bars\\pfUI-" .. letter .. ".tga",
    name = "pfUI-" .. letter,
  })
end

local C = pfUI_config

-- 目标定义：write(tex) 写配置；live = UpdaterFunctions 键（即时刷新）
local targets = {
  player_hp = {
    label = "玩家 - 血条",
    write = function(tex) C.unitframes.player.bartexture = tex end,
    get = function() return C.unitframes.player.bartexture end,
    live = "player",
  },
  player_mp = {
    label = "玩家 - 能量条",
    write = function(tex) C.unitframes.player.pbartexture = tex end,
    get = function() return C.unitframes.player.pbartexture end,
    live = "player",
  },
  target_hp = {
    label = "目标 - 血条",
    write = function(tex) C.unitframes.target.bartexture = tex end,
    get = function() return C.unitframes.target.bartexture end,
    live = "target",
  },
  all_hp = {
    label = "全职业 - 血条",
    write = function(tex)
      for unit, cfg in pairs(C.unitframes) do
        if type(cfg) == "table" and cfg.bartexture then cfg.bartexture = tex end
      end
    end,
    get = function() return nil end,
    liveframes = true,
  },
  all_mp = {
    label = "全职业 - 能量条",
    write = function(tex)
      for unit, cfg in pairs(C.unitframes) do
        if type(cfg) == "table" and cfg.pbartexture then cfg.pbartexture = tex end
      end
    end,
    get = function() return nil end,
    liveframes = true,
  },
  castbar = {
    label = "施法条",
    write = function(tex) C.appearance.castbar.texture = tex end,
    get = function() return C.appearance.castbar.texture end,
  },
  nameplate = {
    label = "姓名板 - 血条",
    write = function(tex) C.nameplates.healthtexture = tex end,
    get = function() return C.nameplates.healthtexture end,
    live = "nameplates",
  },
  xpbar = {
    label = "经验条",
    write = function(tex) C.panel.xp.texture = tex end,
    get = function() return C.panel.xp.texture end,
    live = "xpbar",
  },
  tooltip = {
    label = "鼠标提示 - 状态条",
    write = function(tex) C.tooltip.statusbar.texture = tex end,
    get = function() return C.tooltip.statusbar.texture end,
  },
  global = {
    label = "全局（批量应用所有进度条）",
    write = function(tex)
      for unit, cfg in pairs(C.unitframes) do
        if type(cfg) == "table" then
          if cfg.bartexture then cfg.bartexture = tex end
          if cfg.pbartexture then cfg.pbartexture = tex end
          if cfg.threattexture then cfg.threattexture = tex end
        end
      end
      C.unitframes.druidmanatexture = tex
      C.unitframes.swingtimertexture = tex
      C.unitframes.raidmarkertexture = tex
      C.nameplates.healthtexture = tex
      C.appearance.castbar.texture = tex
      C.panel.xp.texture = tex
      C.tooltip.statusbar.texture = tex
    end,
    get = function() return nil end,
  },
}
local target_order = {
  "player_hp", "player_mp", "target_hp", "all_hp", "all_mp",
  "castbar", "nameplate", "xpbar", "tooltip", "global",
}

-- 下拉菜单条目（path:value 格式）
local target_menu = {}
for _, id in pairs(target_order) do
  table.insert(target_menu, id .. ":" .. targets[id].label)
end

-- 应用目标状态（本地，不写入 pfUI 存档）
local state = { target = "player_hp" }

pfUI.gui.CreateGUIEntry("自定义材质", nil, function()
  local content = this
  -- CreateConfig 在 pfUI gui.lua 里是文件级 local，仅通过 pfUI.gui.CreateConfig 暴露，
  -- 全局裸调会报 nil（实测 2026-09-18）
  local CreateConfig = pfUI.gui.CreateConfig

  -- 当前目标值命中高亮：青色边框；默认边框色取 pfUI 外观边框色
  local dbr, dbg, dbb, dba = strsplit(",", tostring(
    (C.appearance and C.appearance.border and C.appearance.border.color) or ""))
  dbr, dbg, dbb, dba = tonumber(dbr) or .4, tonumber(dbg) or .4, tonumber(dbb) or .4, tonumber(dba) or 1

  local swatches = {}
  local function SetSwatchBorder(swatch, r, g, b, a)
    if swatch.backdrop and swatch.backdrop.SetBackdropBorderColor then
      swatch.backdrop:SetBackdropBorderColor(r, g, b, a)
    end
  end

  local function UpdateHighlights()
    local cur = targets[state.target] and targets[state.target].get() or nil
    for _, swatch in pairs(swatches) do
      if cur == swatch.texpath then
        SetSwatchBorder(swatch, .2, 1, .8, 1)
        swatch.iscur = true
      else
        if swatch.iscur then SetSwatchBorder(swatch, dbr, dbg, dbb, dba) end
        swatch.iscur = nil
      end
    end
  end

  -- 点击应用：写配置 → 能即时刷新的走 UpdaterFunctions / 全部帧 UpdateConfig，
  -- 否则弹 pfUI 标准的「重载生效」询问框
  local function ApplyTexture(texpath)
    local t = targets[state.target]
    if not t then return end
    t.write(texpath)

    local refreshed = false
    if t.live and pfUI.gui.UpdaterFunctions and pfUI.gui.UpdaterFunctions[t.live] then
      refreshed = pcall(pfUI.gui.UpdaterFunctions[t.live])
    elseif t.liveframes and pfUI.uf and pfUI.uf.frames then
      local ok = true
      for _, f in ipairs(pfUI.uf.frames) do
        if f.UpdateConfig then
          local fok = pcall(f.UpdateConfig, f)
          if not fok then ok = false end
        end
      end
      refreshed = ok
    end

    if not refreshed then pfUI.gui:Reload() end
    UpdateHighlights()
  end

  -- 配置行（占用 content.objectCount 计数，缩略图网格排在其后）
  CreateConfig(nil, "Custom Media 材质预览（悬停看路径，点击应用）", nil, nil, "header")
  CreateConfig(function() UpdateHighlights() end, "应用目标", state, "target",
    "dropdown", target_menu)
  CreateConfig(nil) -- spacer

  -- 缩略图网格：4 列
  local top = (content.objectCount or 0) * -23 - 10
  local percol, sw, sh, gapx, gapy = 4, 128, 36, 8, 8

  for i, texinfo in ipairs(textures) do
    local col = math.mod(i - 1, percol)
    local row = math.floor((i - 1) / percol)

    local b = CreateFrame("Button", nil, content)
    b:SetWidth(sw)
    b:SetHeight(sh)
    b:SetPoint("TOPLEFT", content, "TOPLEFT", 10 + col * (sw + gapx), top - row * (sh + gapy))
    b.texpath = texinfo.path

    b.tex = b:CreateTexture(nil, "BACKGROUND")
    b.tex:SetTexture(texinfo.path)
    b.tex:SetPoint("TOPLEFT", b, "TOPLEFT", 3, -3)
    b.tex:SetWidth(sw - 6)
    b.tex:SetHeight(sh - 16)

    b.label = b:CreateFontString("Status", "OVERLAY", "GameFontNormalSmall")
    b.label:SetPoint("BOTTOM", b, "BOTTOM", 0, 2)
    b.label:SetText(texinfo.name)

    if pfUI.api and pfUI.api.CreateBackdrop then pfUI.api.CreateBackdrop(b) end

    b:SetScript("OnEnter", function()
      SetSwatchBorder(this, 1, 1, 1, 1)
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:AddLine(this.texpath and string.gsub(this.texpath, "Interface\\\\AddOns\\\\", "") or "")
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function()
      if this.iscur then
        SetSwatchBorder(this, .2, 1, .8, 1)
      else
        SetSwatchBorder(this, dbr, dbg, dbb, dba)
      end
      GameTooltip:Hide()
    end)
    b:SetScript("OnClick", function()
      ApplyTexture(this.texpath)
    end)

    table.insert(swatches, b)
  end

  UpdateHighlights()
end)
