-- diminfo 信息条 —— 设置窗口 pfUI 皮肤
-- 20261027 可可慕斯
--
-- 说明：diminfo 的设置窗口（DimInfoOptions）不是登录时创建的，而是第一次
-- 执行 /dim、/diminfo 或右键信息条时才由 panel.lua 的 CreateOptionsFrame()
-- 现建。所以这里不在加载时直接换皮，而是挂到几个打开入口上：
--   1) 包装 SlashCmdList["DIMINFO"]
--   2) 给信息条 diminfopanel 的 OnMouseDown 追加后置钩子（右键入口）
--   3) 兜底轮询（0.5 秒 × 最多 120 次），发现窗口就把自己停掉
-- 窗口本身常驻内存，皮肤只做一次；显示时再补一遍子控件（行是动态建的）。
--
-- 调试：/run print(PF_DIMINFO_SKIN_RAN, PF_DIMINFO_SKIN_OK, PF_DIMINFO_SKIN_ERR)

local addon = "diminfo"

_G.PF_DIMINFO_SKIN_RAN = _G.PF_DIMINFO_SKIN_RAN or 0
_G.PF_DIMINFO_SKIN_OK  = _G.PF_DIMINFO_SKIN_OK or false
_G.PF_DIMINFO_SKIN_ERR = nil

local FS = 13
if C and C.global and tonumber(C.global.font_size) then
  FS = tonumber(C.global.font_size)
end

-- 后置钩子：保留插件原有 OnXxx，再追加自己的处理
local function PostHook(frame, script, func)
  if not frame or not frame.GetScript then return end
  local prev = frame:GetScript(script)
  frame:SetScript(script, function(a1, a2, a3, a4)
    if prev then prev(a1, a2, a3, a4) end
    func(a1, a2, a3, a4)
  end)
end

local function SetFontString(fs)
  if fs and fs.SetFont and pfUI and pfUI.font_default then
    pcall(fs.SetFont, fs, pfUI.font_default, FS, "OUTLINE")
  end
end

-- 勾选框：pfUI 底板默认外扩 4px，加上原生勾选贴图固定 32x32（不随框体缩放），
-- 会出现「深色大框 + 勾顶出框外压到文字」。这里统一缩到 16px 并把勾选贴图塞进框内。
local CHECK_SIZE = 16

local function FitCheckTexture(cb)
  local name = cb.GetName and cb:GetName()
  local chk = name and getglobal(name .. "Check")
  if not chk and cb.GetCheckedTexture then
    chk = cb:GetCheckedTexture()
  end
  if chk and chk.SetAllPoints then
    chk:ClearAllPoints()
    chk:SetAllPoints(cb)
  end
end

local function NormalizeCheckbox(cb)
  if not cb or not cb.backdrop then return end
  cb.backdrop:ClearAllPoints()
  cb.backdrop:SetPoint("TOPLEFT", cb, "TOPLEFT", -1, 1)
  cb.backdrop:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", 1, -1)
end

local function SkinCheckbox(cb)
  if not cb or cb.pfDiminfoCheck then return end
  cb.pfDiminfoCheck = true
  pcall(pfUI.api.SkinCheckbox, cb, CHECK_SIZE)
  FitCheckTexture(cb)
  NormalizeCheckbox(cb)
  -- 文字沿用插件原来的字号：这些勾选框的排版是按暴雪字号算的，换字体会串行
end

-- 拖拽幽灵框（DimInfoDragGhost）：第一次拖拽时才创建
local function SkinDragGhost()
  local ghost = getglobal("DimInfoDragGhost")
  if not ghost or ghost.pfDiminfo then return end
  ghost.pfDiminfo = true
  pcall(pfUI.api.StripTextures, ghost)
  pcall(pfUI.api.CreateBackdrop, ghost, nil, true)
  SetFontString(ghost.text)
end

-- 手写排版的两处微调（20261027 实测）：pfUI 的勾选框底板比暴雪原框略宽，
-- 两个勾选项的文字会压到方框右边缘；渐隐滑块整体又贴着上面的勾选项文字。
-- 这里只挪位置，且用「记下原始 x 再加偏移」的绝对值写法，重复打开不会越挪越远。
local function NudgeCheckboxLabel(cb, dx)
  if not cb then return end
  local name = cb.GetName and cb:GetName()
  local fs = name and getglobal(name .. "Text")
  if not fs or not fs.GetPoint then return end

  local p, rel, rp, x, y = fs:GetPoint()
  if not p then return end
  if fs.pfDimX == nil then fs.pfDimX = x or 0 end

  fs:ClearAllPoints()
  if rel then
    fs:SetPoint(p, rel, rp, fs.pfDimX + dx, y or 0)
  else
    fs:SetPoint(p, fs.pfDimX + dx, y or 0)
  end
end

local function ApplyLayoutTweaks()
  -- 1) 「时间模块显示秒」「渐隐模式」两个勾选文字右移 6px，离开方框
  NudgeCheckboxLabel(getglobal("DimInfoShowSecondsCheckbox"), 6)
  NudgeCheckboxLabel(getglobal("DimInfoFadeCheckbox"), 6)

  -- 2) 渐隐滑块（文字 + 进度条是一体的）整体下移 5px：原来 -8，改 -13
  local s = getglobal("DimInfoFadeSlider")
  local cb = getglobal("DimInfoFadeCheckbox")
  if s and cb and not s.pfDimAnchor then
    s.pfDimAnchor = true
    s:ClearAllPoints()
    s:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 0, -13)
  end
end

-- 遍历设置窗口里的按钮 / 滑动条 / 勾选框（可重复调用，逐个对象带幂等标记）
local function SkinControls(f)
  local api = pfUI.api

  for _, c in ipairs({f:GetChildren()}) do
    local ot = c.GetObjectType and c:GetObjectType()

    if ot == "Slider" then
      if not c.pfDiminfo then
        c.pfDiminfo = true
        pcall(api.SkinSlider, c)
      end

    elseif ot == "CheckButton" then
      SkinCheckbox(c)

    elseif ot == "Button" then
      -- 用 GetText() 的返回值判断，而不是判断「有没有 GetText 方法」：
      -- 本客户端里所有 Button 都带 GetText 方法，关闭按钮会误落到普通按钮分支，
      -- 被 SkinButton 做成 32x32 的空框——就是「看不到 X、还特别大」。
      local label
      if c.GetText then label = c:GetText() end
      if type(label) == "string" then
        label = string.gsub(label, "^%s*(.-)%s*$", "%1")
        if label == "" then label = nil end
      end

      -- 关闭按钮的判定：没文字，或者是 32x32 那种方按钮（设置窗口里的普通按钮
      -- 都是 70x20 / 80x22 的长条，高度不会到 28）。
      local w = (c.GetWidth and c:GetWidth()) or 0
      local h = (c.GetHeight and c:GetHeight()) or 0
      local isClose = (not label) or (w >= 28 and h >= 28)

      if isClose then
        -- UIPanelCloseButton（匿名、无文字）：换成 pfUI 样式的红叉
        -- 不用 pfUI.api.SkinCloseButton：它内部固定用全局贴图名
        -- "pfQuestionDialogCloseTex"，同名纹理重复创建可能拿不到区域（有框没 X）。
        -- 这里自己建一个匿名贴图。
        if not c.pfDiminfo then
          c.pfDiminfo = true
          pcall(api.SkinButton, c, 1, .25, .25)
          c:SetWidth(15)
          c:SetHeight(15)
          c:ClearAllPoints()
          c:SetPoint("TOPRIGHT", f, "TOPRIGHT", -3, -3)
          local x = c:CreateTexture(nil, "OVERLAY")
          x:SetTexture((pfUI.media and pfUI.media["img:close"]) or "Interface\\AddOns\\pfUI\\img\\close")
          x:SetVertexColor(1, .25, .25, 1)
          x:SetAllPoints(c)
        end
      elseif not c.pfDiminfo then
        -- UIPanelButtonTemplate 的普通按钮
        c.pfDiminfo = true
        pcall(api.SkinButton, c)
        if c.SetTextColor then c:SetTextColor(1, 1, 1, 1) end
      end

    elseif ot == "Frame" and c.GetName and c:GetName() == "DimInfoOptionsContent" then
      -- 列表容器：每行里有一个勾选框，行是 RefreshList 动态建的
      for _, row in ipairs({c:GetChildren()}) do
        for _, rc in ipairs({row:GetChildren()}) do
          if rc.GetObjectType and rc:GetObjectType() == "CheckButton" then
            SkinCheckbox(rc)
          end
        end

        if not row.pfDiminfoHook then
          row.pfDiminfoHook = true
          PostHook(row, "OnMouseDown", function() SkinDragGhost() end)
        end
      end
    end
  end

  -- 位置微调放在最后：此时插件的 RefreshList 已经跑完，锚点都是最终值
  pcall(ApplyLayoutTweaks)
end

local function SkinOptions()
  if not pfUI or not pfUI.api then return false end
  local f = getglobal("DimInfoOptions")
  if not f then return false end

  _G.PF_DIMINFO_SKIN_RAN = _G.PF_DIMINFO_SKIN_RAN + 1

  if not f.pfDiminfo then
    f.pfDiminfo = true

    local api = pfUI.api

    -- 主窗口：去掉自绘底板 + 四边金线，换成 pfUI 面板
    -- 用 legacy 模式（底板直接画在窗框上）：DimInfoOptions 是顶层 frameLevel=0 的框，
    -- pfUI 的独立 backdrop 子框在这种框上会被压到看不见，窗口会变成全透明。
    pcall(api.StripTextures, f)
    pcall(api.CreateBackdrop, f, nil, true)

    -- 标题条（唯一的匿名 30 像素高子 Frame）：换成 pfUI 头部条
    for _, c in ipairs({f:GetChildren()}) do
      if c.GetObjectType and c:GetObjectType() == "Frame"
        and c.GetName and not c:GetName() and c:GetHeight() == 30 then
        pcall(api.StripTextures, c)
        pcall(api.CreateBackdrop, c, nil, true)
        for _, r in ipairs({c:GetRegions()}) do
          if r.GetObjectType and r:GetObjectType() == "FontString" then
            SetFontString(r)
          end
        end
      end
    end

    -- 每次显示都补一遍子控件（首次打开、以及之后新增的行）
    PostHook(f, "OnShow", function() pcall(SkinControls, f) end)
  end

  SkinControls(f)
  return true
end

local function TrySkin()
  if not pfUI or not pfUI.api then return false end
  if not getglobal("DimInfoOptions") then return false end
  local ok, err = pcall(SkinOptions)
  if ok then
    _G.PF_DIMINFO_SKIN_OK = true
  else
    _G.PF_DIMINFO_SKIN_ERR = tostring(err)
  end
  return true
end

pfUI.addonskinner:RegisterSkin(addon, function()
  -- 只做一次性登记：后续靠下面的入口钩子
  pfUI.addonskinner:UnregisterSkin(addon)

  if C and C.addonskinner and C.addonskinner.disabled and C.addonskinner.disabled[addon] == "1" then
    return
  end

  -- 已经开过设置窗口的话直接换皮
  if TrySkin() then return end

  -- 入口 1：/dim /diminfo
  local cmd = SlashCmdList and SlashCmdList["DIMINFO"]
  if cmd and not SlashCmdList.pfDiminfoHooked then
    SlashCmdList.pfDiminfoHooked = true
    SlashCmdList["DIMINFO"] = function(msg)
      cmd(msg)
      pcall(TrySkin)
    end
  end

  -- 入口 2：右键信息条（左键也会走 OnMouseDown，这里只认右键）
  -- 本客户端部分脚本回调走参数、部分走全局，两个都判一下。
  local bar = getglobal("diminfopanel")
  if bar then
    PostHook(bar, "OnMouseDown", function(a1, a2)
      if a1 == "RightButton" or a2 == "RightButton" or arg1 == "RightButton" then
        pcall(TrySkin)
      end
    end)
  end

  -- 兜底：每 0.5 秒探一次，最多探 120 次（约 1 分钟）就自己收工。
  -- 上面两个入口钩子是主要路径，这里只防「第三种打开方式」。
  -- 注意：本客户端 OnUpdate 回调不传 elapsed（全局 arg1 是上个事件的残留值），
  -- 节流只能用 GetTime()，不能累加 arg1。
  local poll = CreateFrame("Frame", nil, UIParent)
  local last, tries = 0, 0
  poll:SetScript("OnUpdate", function()
    local now = GetTime()
    if now - last < 0.5 then return end
    last = now
    tries = tries + 1
    if TrySkin() or tries > 120 then
      this:SetScript("OnUpdate", nil)
    end
  end)
end)
