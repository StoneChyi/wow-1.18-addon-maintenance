-- ============================================================================
-- pfUI · chatcopy —— 聊天内容复制
-- ----------------------------------------------------------------------------
-- 架构：**独立复制窗口**（参考 CopyChat 的成熟做法，2026-09-13 重构）
--
-- 为什么不再"就地覆盖在聊天窗口上"：
--   旧实现把复制层做成 ChatFrame 的子对象，于是同时踩中三个本客户端特有的坑：
--     ① pfUI 的 fadeout 是 **C 侧渐隐**（chat.lua:531-536 只点火 SetFading + SetTimeVisible），
--        淡出**不经过 Lua 的 SetAlpha** ⇒ 覆盖 SetAlpha 拦不住；子对象乘性继承父帧 alpha，
--        静默满 fadetime 后整帧掉到 ~5%，复制层的黑底和文字一起消失
--        =「点复制后看不见字」。综合/战斗记录消息不断，计时器反复复位，所以只有它们一直好用。
--     ② 本客户端 EditBox 的**选区高亮消不掉**：诊断实测 SetHighlightTexture / SetHighlightColor /
--        SetSelectionColor 三个方法全「无」，而它是 C 侧画的**不透明 (96,96,96) 灰块、画在文字之上、
--        不吃父帧 alpha** ⇒ 为了 Ctrl+C 一拖选，被选中的几行必然变灰块盖住字
--        =「拖选时一大块灰挡住字」（录像定案帧 f021 像素级验证：块内逐行只有 1 种颜色、零字形）。
--     ③ 覆盖层挂 ChatFrame 就跟着它显隐/层序走；改挂面板又得自己管显隐，反复失手。
--
--   独立窗口从结构上一次解决三条：它不是聊天窗口的子对象 ⇒ 不继承渐隐、不参与聊天窗口的层序、
--   不受停靠/切标签影响；文字也不再需要"盖住灰块"这类花活。
--
-- 两条硬约束（本客户端实测，改动前务必保留）：
--   ⛔ EditBox / FontString 的字体必须**两步走**：先 SetFontObject 兜底，再 SetFont 覆盖。
--      只写 SetFont，一旦这台客户端不认就是"什么都不画"（黑底 + 没字）。
--   ⛔ 选区高亮消不掉 ⇒ 只能让 EditBox **整个不可见**（SetAlpha(0)），文字由上层 FontString 画；
--      并对 FontString 做**运行期自检**，画不出来就退回"EditBox 自己显示"
--      （宁可拖选发灰，也绝不出现"一片空白"）。
--
-- 命令：/pfchatcopy                     诊断（逐窗口历史/字体/剪贴板 API）
--       /pfchatcopy show                打开复制窗口
--       /pfchatcopy <n>                 打印窗口 n 的原文（竖线转义）
--       /pfchatcopy max <n>             每个窗口保留多少行（默认 200）
--       /pfchatcopy format all|plain    保留颜色 / 纯文本
--       /pfchatcopy clear               清空已捕获内容
--       /pfyy                           复制本次团队最近发送的 YY 号
-- ============================================================================
pfUI:RegisterModule("chatcopy", "vanilla:tbc", function ()
  local limit    = 200     -- 每个聊天窗口最多保留的行数
  local MIRROR_W = 566     -- 窗口内文字的排版宽度（改窗口宽度时同步）

  local win                -- 复制窗口（单例，首次点击才创建）
  local source             -- 当前显示的是哪个 ChatFrame
  local Fill, Open, Close, Cycle      -- 前置声明：按钮回调互相引用
  local UpdateYY, CopyYY
  local latestYY

  pfUI.chatcopy = pfUI.chatcopy or {}
  if not pfUI.chatcopy.format then pfUI.chatcopy.format = "all" end

  -- ==========================================================================
  -- 显示项：复制窗口里额外附加的信息 —— 时间戳 / 职业·等级
  -- --------------------------------------------------------------------------
  -- 存在 SavedVariables 的 `pfUI_cache` 里（**账号级**存档），所以不必动
  -- api/config.lua 与 modules/gui.lua —— 本模块的界面一直是斜杠命令。
  -- ⛔ 与 pfUI 聊天自带的同类开关**去重**：`chat.text.time` / `chat.text.playerlevel`
  --    打开时，捕获到的正文里**已经有**时间戳/等级了，再叠一遍就是一行两个。
  -- ==========================================================================
  pfUI_cache = pfUI_cache or {}
  local opts = pfUI_cache.chatcopy
  if not opts then opts = {}; pfUI_cache.chatcopy = opts end
  if not opts.time    then opts.time    = "1"        end   -- 时间戳开关
  if not opts.timefmt then opts.timefmt = "%H:%M:%S" end   -- strftime 格式
  if not opts.class   then opts.class   = "1"        end   -- 职业/等级标签开关

  -- ==========================================================================
  -- 一、捕获：把每个聊天窗口的消息另存一份
  -- ==========================================================================
  -- 频道色。上游是直接用 rgbhex(r,g,b) 把整行套色，但本客户端"世界"这类自定义频道的
  -- 颜色实测偏暗（暗红/暗灰），整行一包，在深色窗口上就是"看不见字"。
  -- 这里只做一件事：**太暗就换白** —— 牺牲一点保真，换"一定看得清"。
  local function ColorOf(r, g, b)
    local rgb = pfUI.api and pfUI.api.rgbhex
    if not (rgb and r and g and b) then return nil end

    local col = rgb(r, g, b)
    if not col or col == "" then return nil end

    local h  = string.sub(col, 3)                        -- col = "|cAARRGGBB"
    local rr = tonumber(string.sub(h, 3, 4), 16) or 255
    local gg = tonumber(string.sub(h, 5, 6), 16) or 255
    local bb = tonumber(string.sub(h, 7, 8), 16) or 255
    if (rr * .299 + gg * .587 + bb * .114) < 90 then return "|cffffffff" end
    return col
  end

  -- --------------------------------------------------------------------------
  -- 装饰：给每一行补上「时间戳」与「职业·等级」
  -- --------------------------------------------------------------------------
  -- 职业英文 token（libunitscan / pfUI_playerDB 里存的就是这个形态）→ 显示名（全称）
  local CLASS_NAME = {
    WARRIOR = "战士", MAGE = "法师", ROGUE = "盗贼", DRUID = "德鲁伊", HUNTER = "猎人",
    SHAMAN  = "萨满", PRIEST = "牧师", WARLOCK = "术士", PALADIN = "圣骑士",
  }
  if _G.GetLocale and _G.GetLocale() ~= "zhCN" then
    CLASS_NAME = {
      WARRIOR = "Warrior", MAGE = "Mage", ROGUE = "Rogue", DRUID = "Druid", HUNTER = "Hunter",
      SHAMAN  = "Shaman", PRIEST = "Priest", WARLOCK = "Warlock", PALADIN = "Paladin",
    }
  end

  -- pfUI 聊天自己的同类开关（读活值：profile 切换会换掉 pfUI_config）
  local function ChatText()
    return (pfUI_config and pfUI_config.chat and pfUI_config.chat.text) or {}
  end

  -- 时间戳的显示色：沿用 pfUI 聊天的 `chat.text.timecolor`（读一次缓存即可）
  local timeCol
  local function TimeCol()
    if timeCol then return timeCol end
    timeCol = "|cffb0b0b0"
    local rgb = pfUI.api and pfUI.api.rgbhex
    local r, g, b, a = strsplit(",", ChatText().timecolor or ".8,.8,.8,1")
    r, g, b, a = tonumber(r), tonumber(g), tonumber(b), tonumber(a)
    if rgb and r and g and b then
      local c = rgb(r, g, b, a)
      if c and c ~= "" then timeCol = c end
    end
    return timeCol
  end

  -- 捕获那一刻的时钟字符串（**必须**在消息到达时取；渲染时再取就成了"当前时间"）
  local function TimeNow()
    local ok, s = pcall(date, opts.timefmt)
    if ok and s then return s end
    return date("%H:%M:%S")
  end

  -- 职业/等级标签。数据源只用 libunitscan 的玩家库（`units.players = pfUI_playerDB`，
  -- 是 SavedVariables ⇒ 跨会话累积）。
  -- ⛔ 这里**绝不**调 GetPlayerLevel：它未命中时会扫一遍公会 + 好友名单，
  --    一屏 200 行会被拖到明显卡顿。库里没有就**不显示** ——
  --    等 /who、公会/队伍/好友事件把数据补进库，点一下「刷新」就有。
  -- memo：一次填充内的「名字 → 标签」备忘，避免同名重复解析。
  local function WhoTag(name, memo)
    if memo then
      local hit = memo[name]
      if hit ~= nil then
        if hit == "" then return nil end
        return hit
      end
    end

    local out    = ""
    local class, level = nil, nil
    if type(_G.GetUnitData) == "function" then
      class, level = GetUnitData(name)
    end

    -- ⛔ 1.12 的 `RAID_CLASS_COLORS[class]` 只有 {r,g,b}，**没有 `colorStr`**
    --    （colorStr 是 2.0 才加进 ColorMixin 的）。职业色一律走 `rgbhex(表)`，
    --    它返回 `|cAARRGGBB` **完整前缀**；不要再拼 "|c"..hex，
    --    否则 hex 取不到就永远落到兜底灰（本客户端实测）。
    local classHex, className
    if class and class ~= "" then
      local c   = _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[class]
      local rgb = pfUI.api and pfUI.api.rgbhex
      if c and rgb then classHex = rgb(c) end
      if not (classHex and classHex ~= "") then classHex = "|cff999999" end
      className = CLASS_NAME[class] or class
    end

    -- 等级：难度色（不去重，理由同 Decorate 里的时间戳：捕获的是原始文本）
    local levelStr
    if level and level > 0 then
      local lvcol = "|cffb0b0b0"
      local fn, rgb = _G.GetDifficultyColorChatMod, pfUI.api and pfUI.api.rgbhex
      if type(fn) == "function" and rgb then
        local ok, cc = pcall(fn, level, false)
        if ok and type(cc) == "table" and cc.r then lvcol = rgb(cc.r, cc.g, cc.b) end
      end
      levelStr = lvcol .. level .. "|r"
    end

    -- 拼成一对方括号：[60 法师]（等级在前、用难度色；职业全名在后、用职业色）
    -- ⚠️ levelStr 自身以 |c… 开头、|r 收尾，会把外层的职业色重置掉 ⇒
    --    等级后面必须再补一次 classHex，否则职业名与 "]" 会掉回频道色。
    if className then
      out = classHex .. "["
      if levelStr then out = out .. levelStr .. " " end
      out = out .. classHex .. className .. "]|r"
    elseif levelStr then
      out = levelStr
    end

    if memo then memo[name] = out end
    if out == "" then return nil end
    return out
  end

  -- 把一条历史记录渲染成"窗口里显示的那一行"（也是会被复制走的那一行）
  local function Decorate(e, memo)
    -- 兼容纯字符串条目（老写法 / 仿真脚本直接喂字符串时仍能跑）
    if type(e) ~= "table" then return e end

    local txt, col = e.txt or "", e.col or ""
    local C = ChatText()

    -- ① 时间戳前缀。括号沿用 pfUI 聊天自己的 `chat.text.timebracket`（默认 "[]"），
    --    这样复制框里长什么样、和聊天窗口里一致，不会一边圆括号一边方括号。
    -- ⛔ 这里**不做"pfUI 已开时间戳就去重"**（曾经写过，是错的）：
    --    pfUI 是在**模块加载期**把 `frame.AddMessage` 换成自己的解析函数
    --    （chat.lua:1281-1282），而本模块要到 PLAYER_ENTERING_WORLD 才在外层包一层
    --    ⇒ 我们捕获到的永远是**未经 pfUI 加工的原始文本**（时间戳/等级都还没有）。
    --    换句话说：聊天窗口里的时间戳是"显示层"产物，压根不会进 pfHistory，
    --    去重只会让用户在开着 pfUI 时间戳时**永远看不到**复制框的时间戳。
    if opts.time == "1" and e.t and e.t ~= "" then
      local br = C.timebracket or "[]"
      txt = TimeCol() .. string.sub(br, 1, 1) .. e.t .. string.sub(br, 2, 2) .. "|r " .. txt
    end

    -- ② 职业/等级：插在**第一个玩家名链接之前** ⇒ 读作 `[60 法师][小明]`。
    --    `tag` 自带 |r 收尾，会把颜色重置成默认 ⇒ 后面必须紧跟 `col` 把频道色接回来，
    --    否则玩家名与正文都会变成白色。
    --    ⚠️ 用函数式替换，避免标签里可能出现的 % 被 gsub 当成转义。
    if opts.class == "1" and e.name and e.name ~= "" then
      local tag = WhoTag(e.name, memo)
      if tag then
        txt = string.gsub(txt, "(|Hplayer:.-|h%[.-%]|h)", function(m)
          return tag .. col .. m
        end, 1)
      end
    end
    return txt
  end

  local function Capture(frame)
    local history = {}
    frame.pfHistory = history

    local AddMessage = frame.AddMessage
    frame.AddMessage = function(self, msg, r, g, b)
      if msg then
        -- 与上游算法一致：整行套频道色，并把行内的颜色复位 |r 也换成频道色，
        -- 这样"名字带色"的消息在复制框里整行仍保持同一个底色。
        local col  = ColorOf(r, g, b)
        local body = msg
        if col then
          -- Only an unpaired pipe starts a reset; paired pipes are literal text.
          body = col .. string.gsub(msg, "(|+)r", function(pipes)
            if math.mod(string.len(pipes), 2) == 0 then return pipes .. "r" end
            return string.sub(pipes, 1, -2) .. col
          end)
        end

        -- 顺手记下两件"只有此刻查得到"的东西：
        --   · 时间戳：必须取**消息到达这一刻**的时钟（渲染时再取就成了当前时间，没意义）
        --   · 发言者名：从玩家链接里取第一个（渲染时用它查职业/等级）
        local who
        for nm in string.gfind(body, "|Hplayer:(.-)|h") do who = nm break end
        if who then who = strsplit(":", who) end

        table.insert(history, 1, {
          txt  = body,
          col  = col or "",
          t    = TimeNow(),
          name = who,
        })
        while table.getn(history) > limit do table.remove(history) end
      end
      AddMessage(self, msg, r, g, b)
    end
  end

  -- 给所有还没有记录器的聊天窗口补挂一个（进服后又新开的标签也能被抓到）
  local function EnsureCapture()
    for i=1, (_G.NUM_CHAT_WINDOWS or 10) do
      local cf = _G["ChatFrame"..i]
      if cf and not cf.pfHistory then pcall(Capture, cf) end
    end
  end

  -- 保留既有 YY 预处理；复制显示单独使用下面的 PlainCopyLine。
  local function Strip(s)
    s = string.gsub(s, "|c%x%x%x%x%x%x%x%x", "")
    s = string.gsub(s, "|r", "")
    s = string.gsub(s, "|H[^|]*|h", "")
    s = string.gsub(s, "|h", "")
    s = string.gsub(s, "|T[^|]*|t", "")
    return s
  end

  -- 只接受 YY 标记紧跟的号码；空格可用于分组，不能把后面的普通文字跳过去。
  local function ExtractYY(message)
    local s = string.lower(Strip(message or ""))
    s = string.gsub(s, "　", " ")
    s = string.gsub(s, " ", " ")
    local from = 1
    while true do
      local a, b = string.find(s, "yy", from, true)
      if not a then return nil end
      local before = a > 1 and string.sub(s, a-1, a-1) or ""
      if not string.find(before, "[%a%d_]") then
        local tail = string.sub(s, b+1)
        -- 支持 YY号、YY频道、YY语音频道号、YY：等写法。
        for k=1, 6 do
          tail = string.gsub(tail, "^[ \t:：=＝%-]+", "")
          local changed = false
          local labels = {"频道号", "房间号", "频道", "房间", "号码", "语音", "号", "是", "为"}
          for j=1, table.getn(labels) do
            local label = labels[j]
            if string.sub(tail, 1, string.len(label)) == label then
              tail = string.sub(tail, string.len(label)+1)
              changed = true
              break
            end
          end
          if not changed then break end
        end
        local _, finish = string.find(tail, "^%d+[ \t%d]*")
        if finish then
          return (string.gsub(string.sub(tail, 1, finish), "[ \t]", ""))
        end
      end
      from = b+1
    end
  end

  -- UTF-8 字符与原来的颜色一起解析；选择索引按字符算，绝不切断汉字字节。
  local function Characters(s)
    local chars, colors, color, i = {}, {}, "", 1
    while i <= string.len(s) do
      local token = string.sub(s, i, i+1)
      local _, stop = string.find(s, "^|c%x%x%x%x%x%x%x%x", i)
      if token == "||" then
        table.insert(chars, "|"); colors[table.getn(chars)] = color; i = i+2
      elseif token == "|c" and stop then
        color = string.sub(s, i, stop); i = stop+1
      elseif token == "|r" then
        color = ""; i = i+2
      elseif token == "|H" or token == "|T" then
        local _, last = string.find(s, token == "|H" and "|h" or "|t", i+2, true)
        i = last and last+1 or i+2
      elseif token == "|h" then
        i = i+2
      else
        local byte = string.byte(s, i)
        local n = byte >= 240 and 4 or byte >= 224 and 3 or byte >= 192 and 2 or 1
        table.insert(chars, string.sub(s, i, i+n-1))
        colors[table.getn(chars)] = color
        i = i+n
      end
    end
    return chars, colors
  end

  local function EscapePipes(s)
    return (string.gsub(s, "|", "||"))
  end

  -- Share the selection tokenizer, retaining escaped pipes until copy export.
  local function PlainCopyLine(s)
    local chars = Characters(s)
    return EscapePipes(table.concat(chars))
  end

  -- 显式换行，让文字与拖选热区使用同一套排版。每个视觉行仅创建一个 FontString。
  local function LayoutLine(button, text, font, size, flags, y, allChars, rows)
    local base, rowBase = table.getn(allChars), table.getn(rows)
    local cached = button.textLayout
    if cached and cached.text == text and cached.font == font
      and cached.size == size and cached.flags == flags then
      for k=1, table.getn(cached.chars) do table.insert(allChars, cached.chars[k]) end
      for k=1, table.getn(cached.rows) do
        local row = cached.rows[k]
        table.insert(rows, {first=base+row.first, last=base+row.last, x=row.x,
          y=y+row.y, height=row.height, owner=button})
      end
      return cached.height
    end
    local chars, colors = Characters(text)
    local probe = win.measure
    probe:SetFontObject(ChatFontNormal)
    if font and size then probe:SetFont(font, size, flags) end
    local height = (tonumber(size) or 14) + 3
    local visual, x, start, run, color, rendered = 0, {0}, table.getn(allChars)+1, "", nil, {}
    local width, reliable = 0, true
    button.visual = button.visual or {}
    local function Flush()
      visual = visual+1
      local fs = button.visual[visual]
      if not fs then
        fs = button:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
        button.visual[visual] = fs
      end
      fs:SetFontObject(ChatFontNormal)
      if font and size then fs:SetFont(font, size, flags) end
      fs:ClearAllPoints()
      fs:SetPoint("TOPLEFT", button, "TOPLEFT", 0, -(visual-1)*height)
      fs:SetWidth(MIRROR_W+32)
      fs:SetHeight(height)
      fs:SetJustifyH("LEFT")
      fs:SetJustifyV("TOP")
      fs:SetTextColor(1, 1, 1, 1)
      fs:SetText(table.concat(rendered))
      fs:Show()
      table.insert(rows, {first=start, last=table.getn(allChars), x=x,
        y=y+(visual-1)*height, height=height, owner=button})
      x, run, color, rendered, width = {0}, "", nil, {}, 0
      start = table.getn(allChars)+1
    end
    for k=1, table.getn(chars) do
      local c = chars[k]
      if c == "\n" then
        Flush()
        table.insert(allChars, c)
        start = table.getn(allChars)+1
      else
        probe:SetText(EscapePipes(run .. c))
        local nextWidth = probe:GetStringWidth() or 0
        if nextWidth <= 0 then reliable = false; nextWidth = width + height*.6 end
        if nextWidth > MIRROR_W and run ~= "" then
          Flush()
          probe:SetText(EscapePipes(c))
          nextWidth = probe:GetStringWidth() or 0
          if nextWidth <= 0 then reliable = false; nextWidth = height*.6 end
        end
        run = run .. c
        if colors[k] ~= color then
          color = colors[k]
          table.insert(rendered, color ~= "" and color or "|r")
        end
        table.insert(rendered, EscapePipes(c))
        table.insert(allChars, c)
        width = nextWidth
        table.insert(x, width)
      end
    end
    Flush()
    for k=visual+1, table.getn(button.visual) do button.visual[k]:Hide() end
    button.fs:Hide()
    cached = {text=text, font=font, size=size, flags=flags, chars={}, rows={}, height=visual*height}
    for k=base+1, table.getn(allChars) do table.insert(cached.chars, allChars[k]) end
    for k=rowBase+1, table.getn(rows) do
      local row = rows[k]
      table.insert(cached.rows, {first=row.first-base, last=row.last-base,
        x=row.x, y=row.y-y, height=row.height})
    end
    -- 首帧字体尚未就绪时不缓存，OnShow 的延后填充会重新测量。
    button.textLayout = reliable and cached or nil
    return visual*height
  end

  local function TextAtCursor()
    if not win or not win.rows or table.getn(win.rows) == 0 then return nil end
    local cx, cy = GetCursorPosition()
    local scale = win.content:GetEffectiveScale()
    local left, top = win.content:GetLeft(), win.content:GetTop()
    if not left or not top then return nil end
    local x, y = cx/scale - left, top - cy/scale
    local row = win.rows[table.getn(win.rows)]
    for k=1, table.getn(win.rows) do
      if y < win.rows[k].y + win.rows[k].height then row = win.rows[k]; break end
    end
    local count = table.getn(row.x)-1
    for k=1, count do
      if x < (row.x[k]+row.x[k+1])/2 then return row.first+k-2 end
    end
    return row.last
  end

  local function PaintTextSelection()
    if not win or not win.rows then return end
    win.textHighlights = win.textHighlights or {}
    local a, b = win.textStart, win.textEnd
    if a and b and a > b then a, b = b, a end
    local used = 0
    for k=1, table.getn(win.rows) do
      local row = win.rows[k]
      local first, last = row.first-1, row.last
      if a and b and b > first and a < last then
        local left, right = math.max(a, first)-first+1, math.min(b, last)-first+1
        used = used+1
        local bg = win.textHighlights[used]
        if not bg then
          bg = win.content:CreateTexture(nil, "BACKGROUND")
          bg:SetTexture(.25, .45, .85, .55)
          win.textHighlights[used] = bg
        end
        bg:ClearAllPoints()
        bg:SetPoint("TOPLEFT", win.content, "TOPLEFT", row.x[left], -row.y)
        bg:SetWidth(math.max(1, row.x[right]-row.x[left]))
        bg:SetHeight(row.height)
        bg:Show()
      end
    end
    for k=used+1, table.getn(win.textHighlights) do win.textHighlights[k]:Hide() end
  end

  local function PartialText()
    if not win or not win.textStart or not win.textEnd or win.textStart == win.textEnd then return nil end
    local a, b = win.textStart, win.textEnd
    if a > b then a, b = b, a end
    local out = {}
    for k=a+1, b do table.insert(out, win.characters[k]) end
    return table.concat(out)
  end

  -- history 是"新→旧"（insert 到 1），显示要"旧→新"。
  -- 返回**行数组**（不是拼好的整串）：逐行渲染 + 按行选择都要按索引取行，
  -- 拼串只在真正要复制/打印时做（table.concat(lines, "\n")）。
  local function Compose(frame)
    local hist  = (frame and frame.pfHistory) or {}
    local n     = table.getn(hist)
    local plain = (pfUI.chatcopy.format == "plain")
    local memo  = {}          -- 本次填充内 名字→标签 的备忘（同名只解析一次）
    local out   = {}

    for k=1, n do
      local s = Decorate(hist[n - k + 1], memo)
      if plain then s = PlainCopyLine(s) end
      out[k] = s
    end
    return out, n
  end

  -- 复制到剪贴板。有 SetClipboardText 就直连（不选、不聚焦，最干净）；
  -- 没有就把文本塞进 EditBox 全选，让用户按 Ctrl+C（本客户端未知，两条都要留）。
  -- 返回 true = 已经复制好了；false = 走了 Ctrl+C 退路（调用方负责提示）。
  local function CopyText(text)
    if type(_G.SetClipboardText) == "function" then
      if pcall(_G.SetClipboardText, text) then return true end
    end
    return false
  end

  -- Keep the full requested text; readback checks the Ctrl+C buffer, not the OS clipboard.
  local function SetCopyBuffer(text)
    win.copyOriginal = text
    win.edit:SetText(text)
    if type(win.edit.GetText) ~= "function" then return end
    local ok, actual = pcall(win.edit.GetText, win.edit)
    if not ok or type(actual) ~= "string" then return end
    -- Clients may normalize line endings without losing any content.
    local expected = string.gsub(string.gsub(text, "\r\n", "\n"), "\r", "\n")
    actual = string.gsub(string.gsub(actual, "\r\n", "\n"), "\r", "\n")
    if actual == expected then return end
    if string.len(actual) < string.len(expected)
      and string.sub(expected, 1, string.len(actual)) == actual then
      return "Copy buffer incomplete: select less text and retry"
    end
    return "Copy buffer differs: select again and retry"
  end

  local function PrepareCopy(text)
    if CopyText(text) then return true end
    -- 保留可见文字与蓝色选区，只让透明 EditBox 接受 Ctrl+C，避开原生灰块。
    win.edit:SetAlpha(win.mirror == false and (win.lineCount or 0) > 0 and 1 or 0)
    local warning = SetCopyBuffer(text)
    win.edit:SetFocus()
    win.edit:HighlightText(0)
    return false, warning
  end

  -- ==========================================================================
  -- 二、复制窗口
  -- ==========================================================================
  local function Build()
    if win then return win end

    local f = CreateFrame("Frame", "pfChatCopyWindow", UIParent)
    f:SetWidth(640)
    f:SetHeight(420)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop",  function() this:StopMovingOrSizing() end)
    f:Hide()

    CreateBackdrop(f)
    if f.backdrop then
      f.backdrop:SetBackdropColor(0, 0, 0, .92)
      f.backdrop:SetBackdropBorderColor(.35, .35, .35, 1)
    end

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -10)
    f.title:SetText("|cffffd100" .. T["Chat Copy"] .. "|r")

    -- 滚动区：pfUI 原生滚动框（自带滑块 + 滚轮）
    -- ⚠️ 下边界必须**高于状态行**（58 > 状态行顶端 ~53）：
    --    之前给到 40，而状态行锚在 36、实际占到 ~49 ⇒ 内容滚到底时最后一行
    --    正好落进提示文字那一带，两排字叠在一起（2026-09-13 截图实证）。
    local scroll = CreateScrollFrame("pfChatCopyScroll", f)
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -30)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -26, 58)
    f.scroll = scroll

    -- 滚动子帧：高度 = 文字实际高度（Fill 里量出来再设）
    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(MIRROR_W)
    child:SetHeight(1)
    scroll:SetScrollChild(child)
    f.content = child
    f.measure = f:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
    f.measure:SetFontObject(ChatFontNormal)
    f.measure:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    f.measure:SetAlpha(0)

    -- ① 显示层：每条消息一个热区，每个视觉行一个 FontString。
    --    为什么拆行（2026-09-13）：
    --      · "只想复制其中几句"需要**按行**命中 —— 拆行后每行自带精确的 y 与高度，
    --        不必再用 GetCursorPosition + 缩放换算去反推行号（那种做法遇到长消息折行必然错位）；
    --      · 每行的点击热区就是这一行自己，点哪行就是哪行，零误差；
    --      · 行 FontString 放进**子 frame**（子 frame 一定画在父 frame 自己的区域之上），
    --        层级压在 EditBox 之上 ⇒ 无论下面的选区高亮是什么颜色，都盖不住字。
    local fsFrame = CreateFrame("Frame", nil, child)
    fsFrame:SetAllPoints(child)
    fsFrame:SetFrameLevel(child:GetFrameLevel() + 2)
    f.fsFrame = fsFrame

    f.hits = {}      -- 消息热区 Button 池（拖选文字 + 该消息的视觉行）

    -- 拖动选择字符；单击清除选区，Shift+单击扩展已有的文字选区。
    -- ⚠️ 用全局 this（本客户端 SetScript 回调不传 self），this.pfIndex = 行号。
    local function OnLineDown()
      if not win then return end
      local i = this.pfIndex
      if not i then return end
      if arg1 ~= "LeftButton" then return end
      win.edit:HighlightText(0, 0)
      win.edit:ClearFocus()
      local pos = TextAtCursor()
      if not pos then return end
      local cx, cy = GetCursorPosition()
      win.drag = {start=pos, x=cx, y=cy, shift=IsShiftKeyDown()}
      if win.drag.shift and win.textStart then
        win.drag.start = win.textStart
        win.drag.moved = true
      end
      win:SetScript("OnUpdate", function()
        if not win.drag then return end
        local x, y = GetCursorPosition()
        local d = win.drag
        if math.abs(x-d.x)+math.abs(y-d.y) >= 3 then d.moved = true end
        if not d.moved then return end
        -- 鼠标拖到边缘时继续滚动，能跨出当前可见的消息选择。
        local scale = win.scroll:GetEffectiveScale()
        local scrollY = y/scale
        if scrollY > win.scroll:GetTop() then win.scroll:Scroll(5)
        elseif scrollY < win.scroll:GetBottom() then win.scroll:Scroll(-5) end
        win.textStart, win.textEnd = d.start, TextAtCursor()
        win:PaintSelection()
      end)
    end

    local function OnLineUp(force)
      if not win or not win.drag or (not force and arg1 ~= "LeftButton") then return end
      local d = win.drag
      if d.moved then
        win.textStart, win.textEnd = d.start, TextAtCursor()
      else
        win.textStart, win.textEnd = nil, nil
      end
      win.drag = nil
      win:SetScript("OnUpdate", nil)
      win:PaintSelection()
      local text = PartialText()
      if text then
        -- 拖完即可按 Ctrl+C；有剪贴板扩展时也仍等用户点击复制，避免覆盖剪贴板。
        win.edit:SetAlpha(0)
        local warning = SetCopyBuffer(text)
        win.edit:SetFocus()
        win.edit:HighlightText(0)
        win.count:SetText(warning and ("|cffff8888" .. T[warning] .. "|r")
          or T["Text selected: Ctrl+C or Copy Selected"])
      end
    end

    -- 行上的滚轮：转发给滚动框。
    -- 行热区铺满了文字区，滚轮事件会落到鼠标下的那个 Button 上，
    -- 不转发的话"鼠标停在文字上就滚不动"。
    local function OnLineWheel()
      if win and win.scroll then win.scroll:Scroll((arg1 or 0) * 10) end
    end

    f.MakeLine = function(i)
      -- 父级必须是 fsFrame（不是 child）：退路形态要能**一次 Hide 掉所有行**，
      -- 否则 EditBox 的字会和行文字叠在一起。
      local b = CreateFrame("Button", nil, fsFrame)
      b:SetWidth(MIRROR_W)
      b:SetHeight(16)
      b:SetFrameLevel(fsFrame:GetFrameLevel() + 1)
      b.pfIndex = i

      b.fs = b:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
      b.fs:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
      b.fs:SetWidth(MIRROR_W)
      b.fs:SetJustifyH("LEFT")
      b.fs:SetJustifyV("TOP")
      b.fs:SetTextColor(1, 1, 1, 1)

      b:SetScript("OnMouseDown", OnLineDown)
      b:SetScript("OnMouseUp", OnLineUp)
      b:RegisterForDrag("LeftButton")
      b:SetScript("OnDragStart", function()
        if win and win.drag then win.drag.moved = true end
      end)
      b:SetScript("OnDragStop", function() OnLineUp(true) end)
      if b.EnableMouseWheel then b:EnableMouseWheel(1) end
      b:SetScript("OnMouseWheel", OnLineWheel)
      return b
    end

    -- ② EditBox：不再负责显示（文字由上面的逐行 FontString 画），只在两种情况下出场：
    --      · 没有 SetClipboardText 时的 **Ctrl+C 退路**（把文本塞进来 + 全选）；
    --      · 逐行渲染自检**没通过**时的**兜底显示**（宁可拖选发灰，也绝不出现一片空白）。
    --    层级压到最低（child 本身），保证任何情况下都不会盖住行文字。
    local edit = CreateFrame("EditBox", nil, child)
    edit:SetFrameLevel(child:GetFrameLevel())
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetTextColor(1, 1, 1, 1)
    edit:SetWidth(MIRROR_W)
    edit:SetHeight(1)
    edit:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)
    -- 0 = 不限制字数（上游复制框就是这么设的；不设可能被默认上限截断）
    if edit.SetMaxLetters then pcall(edit.SetMaxLetters, edit, 0) end
    -- 不接鼠标：文字区已被逐行热区铺满，剩下那点空白让滚轮落到滚动框上
    -- （EditBox 默认 EnableMouse，会把这部分滚轮事件吃掉）。SetFocus 是独立机制，不受影响。
    if edit.EnableMouse then pcall(edit.EnableMouse, edit, false) end
    edit:SetScript("OnEscapePressed", function()
      edit:HighlightText(0, 0)
      edit:ClearFocus()
      f:Hide()
    end)
    f.edit = edit

    -- 按钮
    local function Button(label, x, w, fn)
      local b = CreateFrame("Button", nil, f)
      b:SetHeight(20)
      b:SetWidth(w)
      b:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x, 12)
      CreateBackdrop(b, 2)
      if b.backdrop then
        b.backdrop:SetBackdropColor(.12, .12, .12, 1)
        b.backdrop:SetBackdropBorderColor(.45, .45, .45, 1)
      end
      b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      b.label:SetPoint("CENTER", b, "CENTER", 0, 0)
      b.label:SetText(label)
      b:SetScript("OnClick", fn)
      b:SetScript("OnEnter", function()
        if this.backdrop then this.backdrop:SetBackdropColor(.28, .28, .28, 1) end
      end)
      b:SetScript("OnLeave", function()
        if this.backdrop then this.backdrop:SetBackdropColor(.12, .12, .12, 1) end
      end)
      return b
    end

    -- 当前窗口的完整文本（行数组优先；退路形态下退回 EditBox 里的内容）
    -- ⚠️ 判据用 lineText 是否存在，不用"行数 > 0"：空窗口时行数组是空表，
    --    拼出来就是 ""，而**不能**退回 EditBox（那里可能还残留着别的内容）。
    f.Text = function()
      if win.lineText and win.lineCount then
        local text = table.concat(win.lineText, "\n")
        if win.plainFormat then return (string.gsub(text, "||", "|")) end
        return text
      end
      return (win.edit:GetText() or "")
    end

    -- 只复制鼠标选中的文字，不再回退到整条消息。
    f.SelectedText = function()
      return PartialText()
    end

    -- 重绘文字选区与状态行。
    f.PaintSelection = function()
      PaintTextSelection()
      local count = win.textStart and win.textEnd and math.abs(win.textEnd-win.textStart) or 0
      win.selCount = count
      local label = (win.lineCount or 0) .. " " .. T["lines"]
      if count > 0 then
        label = label .. "  |cff88ff88" .. T["Selected"] .. " " .. count .. " " .. T["chars"] .. "|r"
      end
      win.count:SetText(label)
    end

    local function DoCopy(text)
      if not text or string.len(text) == 0 then
        win.count:SetText("|cffff8888" .. T["Nothing to copy"] .. "|r")
        return
      end

      -- 首选剪贴板 API：不选、不聚焦，连一丝灰块都不会出现
      local copied, warning = PrepareCopy(text)
      if copied then
        win.count:SetText("|cff88ff88" .. T["Copied"] .. " " .. string.len(text) .. " " .. T["chars"] .. "|r")
        return
      end

      -- 没有剪贴板扩展时，透明 EditBox 已准备好，只需用户按 Ctrl+C。
      win.count:SetText(warning and ("|cffff8888" .. T[warning] .. "|r")
        or ("|cffffd100" .. T["Selected: press Ctrl+C"] .. "|r"))
    end

    f.btnCopy = Button(T["Copy All"], 12, 76, function()
      if win then DoCopy(win:Text()) end
    end)

    f.btnCopySel = Button(T["Copy Selected"], 92, 76, function()
      if not win then return end
      local text = win:SelectedText()
      if not text then
        win.count:SetText("|cffff8888" .. T["No text selected"] .. "|r")
        return
      end
      DoCopy(text)
    end)

    f.btnClearSel = Button(T["Clear Selection"], 172, 56, function()
      if not win then return end
      win.textStart, win.textEnd = nil, nil
      win.edit:HighlightText(0, 0)
      win.edit:ClearFocus()
      win:PaintSelection()
    end)

    f.btnNext    = Button(T["Switch Window"], 232, 76, function() Cycle() end)
    f.btnRefresh = Button(T["Refresh"],       312, 50, function() Fill() end)
    f.btnClose   = Button(T["Close"],         366, 50, function() Close() end)
    f.btnYY = Button(T["No raid YY"], 424, 190, function() CopyYY() end)
    f.Copy = DoCopy

    f.count = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.count:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 40)

    -- 静态操作提示：**右对齐**（不再是固定 x=250 左对齐）——
    -- 锚右下角后，无论左侧状态行多长（如"99 行  已选 3"）都不会撞上它；
    -- 纵坐标 40 = 状态行那一带，落在滚动区（下边界 58）之下，文字不再重叠。
    f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.hint:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -26, 40)
    f.hint:SetTextColor(.6, .6, .6, 1)
    f.hint:SetText(T["Drag to select text"])

    f:SetScript("OnHide", function()
      f.drag = nil
      f:SetScript("OnUpdate", nil)
      if pfChatCopyButton then
        pfChatCopyButton.state = false
        pfChatCopyButton.icon:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Disabled")
      end
      -- 收起时把焦点/选区一并清掉（否则拖选留下的灰色选区会挂在那里）
      if win and win.edit then
        pcall(win.edit.HighlightText, win.edit, 0, 0)
        pcall(win.edit.ClearFocus, win.edit)
      end
    end)

    -- ⚠️ 必须在**窗口已显示**时才填：
    --   本客户端"隐藏/未布局"的 frame，GetStringWidth / GetHeight 都不可信
    --    （和 GetLeft/GetTop 全 nil 是同一类行为）。自检要是拿着不可信的数字去判，
    --    首次打开就会被误判成"镜像画不出来"，直接退回带灰块的旧形态。
    --    所以：显隐归 OnShow，填充也归 OnShow；再补一次 2 帧后的重填，
    --    等客户端真正把布局算完，把镜像判定的结果钉死。
    f:SetScript("OnShow", function()
      pcall(Fill)
      this.ticks = 0
      this:SetScript("OnUpdate", function()
        if not this:IsShown() then this:SetScript("OnUpdate", nil) return end
        this.ticks = (this.ticks or 0) + 1
        if this.ticks >= 2 then
          this:SetScript("OnUpdate", nil)
          pcall(Fill)
        end
      end)
    end)

    win = f
    UpdateYY()
    return f
  end

  -- 把当前 source 的内容灌进窗口
  Fill = function()
    if not win or not source then return end

    -- 换窗口时清掉旧的字符选区，避免索引指向另一份聊天内容。
    if win.lastSource ~= source then
      win.lastSource = source
      win.textStart, win.textEnd, win.drag = nil, nil, nil
      win.edit:HighlightText(0, 0)
      win.edit:ClearFocus()
    end

    local lines, n = Compose(source)
    local changed = not win.lineText or n ~= win.lineCount
    if not changed then
      for i=1, n do if lines[i] ~= win.lineText[i] then changed = true; break end end
    end
    if changed then
      win.textStart, win.textEnd, win.drag = nil, nil, nil
      win.edit:HighlightText(0, 0)
      win.edit:ClearFocus()
    end
    win.characters, win.rows = {}, {}

    -- 字体必须两步走：先 FontObject 兜底（保证一定有字体），读得到有效字号再 SetFont 覆盖。
    -- ⛔ 顺序不能反、也不能省掉第一步：只 SetFont 一旦不生效 = 什么都不画。
    local font, size, flags = source:GetFont()
    local hasFont = font and size and tonumber(size) and tonumber(size) > 0

    local y, pool = 0, win.hits
    for i=1, n do
      local b = pool[i]
      if not b then b = win.MakeLine(i); pool[i] = b end
      b.pfIndex = i

      -- 字体两步走（同 EditBox 的规矩）
      pcall(b.fs.SetFontObject, b.fs, ChatFontNormal)
      if hasFont then pcall(b.fs.SetFont, b.fs, font, size, flags) end
      pcall(b.fs.SetTextColor, b.fs, 1, 1, 1, 1)

      -- ⚠️ 文本没变就别再 SetText：那会触发 FontString 重新排版，
      --    一次重填 200 行全量 SetText 在 1.12 上是肉眼可见的卡顿。
      --    高度同理缓存（只有换字/首次才重新量）。
      if i > 1 then table.insert(win.characters, "\n") end
      local h = LayoutLine(b, lines[i] or "", hasFont and font or nil,
        hasFont and tonumber(size) or nil, flags, y, win.characters, win.rows)
      b.pfH = h

      b:SetHeight(h)
      if b.pfY ~= y then
        b.pfY = y
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", win.content, "TOPLEFT", 0, -y)
      end
      b:Show()
      y = y + h
    end

    -- 多余的行收起来（池只增不减，避免反复创建销毁）
    local old = table.getn(pool)
    for i=n+1, old do
      if pool[i] then
        pool[i]:Hide()
        pool[i].pfIndex = nil
      end
    end

    win.lineText  = lines        -- 行文本：复制"全部/选中"都按索引从这里取，不再依赖 EditBox
    win.lineCount = n
    win.plainFormat = pfUI.chatcopy.format == "plain"
    if y < 1 then y = n * 15 + 8 end

    win.content:SetHeight(y)
    win.edit:SetHeight(y)

    -- 运行期自检 + 退路（这几种失败在客户端里全是**静默**的，只能填完之后验）：
    --   逐行画得出来 ⇒ 隐藏 EditBox（连选区灰块一起看不见），文字由行 FontString 提供；
    --   画不出来     ⇒ 退回"EditBox 自己显示"
    --                  （宁可拖选发灰，也绝不出现"一片空白"这种比原来更糟的回归）。
    local mirror = false
    if n > 0 and win.hits[1] then
      local probe = win.hits[1].visual[1]
      local _, fsSize = probe:GetFont()
      local fw = 0
      if probe.GetStringWidth then pcall(function() fw = probe:GetStringWidth() or 0 end) end
      mirror = (fsSize and fsSize > 0 and fw > 0) and true or false
    end
    win.mirror = mirror

    if mirror then
      win.fsFrame:Show()
      win.edit:SetAlpha(0)
      win.edit:EnableMouse(false)
    elseif n > 0 then
      win.fsFrame:Hide()
      win.edit:SetAlpha(1)
      win.edit:EnableMouse(true)
      win.edit:SetText(table.concat(lines, "\n"))
    else
      -- 空窗口：行都收起来了，但 EditBox 里可能还留着上一次的内容，
      -- 不对付它，"复制全部"就会拿到别的窗口的残留文本。
      win.fsFrame:Show()
      win.edit:SetAlpha(0)
      win.edit:SetText("")
    end

    -- 回到最顶（偏移 0，显示最旧的一行；想看最新的往下滑）。
    -- ⛔ 别改回"滚到最底"（SetVerticalScroll(GetVerticalScrollRange())）：
    --   本客户端布局未完成时 range 是旧值，等真正算完布局、range 变小时
    --   这个偏移不会自动回收 ⇒ 整个内容被平移出视口 ⇒ 打开窗口一片空白，
    --   要手动把滚动条拖回顶部才看得见（2026-10-12 用户实证）。
    --   偏移 0 不依赖任何 range 测量，永远落在可视区内。
    pcall(function()
      win.scroll:SetVerticalScroll(0)
      win.scroll:UpdateScrollState()
    end)

    -- 窗口名：pcall 保护 —— 拿不到名字不能连累整次填充
    local okName, nm = pcall(_G.GetChatWindowInfo, source:GetID())
    if not okName or not nm or nm == "" then nm = "Chat " .. source:GetID() end
    win.title:SetText("|cffffd100" .. T["Chat Copy"] .. "|r  |cffaaaaaa" .. nm .. "|r")
    win:PaintSelection()
  end

  Open = function(frame)
    local w = Build()

    -- 兜底：晚建的聊天窗口（进服后又新开的标签）也补挂记录器，否则它永远是空的
    EnsureCapture()

    source = frame or SELECTED_CHAT_FRAME or _G.ChatFrame1
    if not (source and source.pfHistory) then
      source = nil
      for i=1, (_G.NUM_CHAT_WINDOWS or 10) do
        local cf = _G["ChatFrame"..i]
        if cf and cf.pfHistory and table.getn(cf.pfHistory) > 0 then
          source = cf
          break
        end
      end
    end
    if not source then source = _G.ChatFrame1 end

    -- 显隐交给 Show，填充交给窗口的 OnShow（那里才是"已显示"的状态，量得准）。
    -- 已经开着就只重填，不重复 Show（Show 在已显示时不触发 OnShow）。
    if w:IsShown() then pcall(Fill) else w:Show() end

    if pfChatCopyButton then
      pfChatCopyButton.state = true
      pfChatCopyButton.icon:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    end
  end

  Close = function()
    if win then win:Hide() end
  end

  -- 在"有历史的窗口"之间循环切换（综合 / 战斗记录 / 世界 …）
  Cycle = function()
    if not win then return end
    local n  = _G.NUM_CHAT_WINDOWS or 10
    local id = (source and source:GetID()) or 0

    for k=1, n do
      id = id + 1
      if id > n then id = 1 end
      local cf = _G["ChatFrame"..id]
      if cf and cf.pfHistory and table.getn(cf.pfHistory) > 0 then
        source = cf
        break
      end
    end
    Fill()
  end

  -- 仅监听真实团队消息事件，世界/公会里的广告不会覆盖团队 YY。
  UpdateYY = function()
    if win and win.btnYY then
      win.btnYY.label:SetText(latestYY and ("YY: " .. latestYY) or T["No raid YY"])
    end
  end

  CopyYY = function()
    if not latestYY then
      if win then win.count:SetText(T["No raid YY"]) end
      return
    end
    if not win or not win:IsShown() then Open(SELECTED_CHAT_FRAME) end
    win.Copy(latestYY)
  end

  local yyEvents = CreateFrame("Frame")
  yyEvents:RegisterEvent("CHAT_MSG_RAID")
  yyEvents:RegisterEvent("CHAT_MSG_RAID_LEADER")
  yyEvents:RegisterEvent("CHAT_MSG_RAID_WARNING")
  yyEvents:RegisterEvent("RAID_ROSTER_UPDATE")
  yyEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
  yyEvents:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" or event == "RAID_ROSTER_UPDATE" then
      if not GetNumRaidMembers or GetNumRaidMembers() == 0 then
        latestYY = nil
        UpdateYY()
      end
      return
    end
    local number = ExtractYY(arg1)
    if number then
      latestYY = number
      UpdateYY()
    end
  end)
  _G.SLASH_PFYY1 = "/pfyy"
  _G.SlashCmdList["PFYY"] = function() CopyYY() end

  -- ==========================================================================
  -- 三、聊天面板上的小按钮（左键开/关复制窗口）
  -- ==========================================================================
  local events = CreateFrame("Frame")
  events:RegisterEvent("PLAYER_ENTERING_WORLD")
  events:SetScript("OnEvent", function()
    -- 给每个聊天窗口挂历史记录器（只挂一次）
    EnsureCapture()

    if pfUI.chat and pfUI.chat.left and not this.button then
      -- parent to pfUI.chat.left (stable), NOT panelTop:
      -- panelTop is shown/hidden + FCF_DockUpdate'd by the mouseover handler and
      -- jitters while chat content refreshes fast, making the button unclickable.
      local button = CreateFrame("Button", "pfChatCopyButton", pfUI.chat.left)
      button:SetPoint("TOPRIGHT", pfUI.chat.left, "TOPRIGHT", 0, -4)
      -- ⛔ 只注册左键：右键那套「聊天菜单」已按用户要求去掉
      --    （ChatMenu 会浮在聊天面板上，与复制按钮的用途重叠、容易误触）。
      button:RegisterForClicks("LeftButtonUp")
      button:SetWidth(16)
      button:SetHeight(16)
      button:SetAlpha(0)
      button.icon = button:CreateTexture(nil, "BACKGROUND")
      button.icon:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Disabled")
      button.icon:SetAllPoints()

      button:SetScript("OnClick", function()
        -- 左键：开/关**独立复制窗口**（内容 = 你正在看的那个聊天窗口）
        if win and win:IsShown() then
          Close()
        else
          Open(SELECTED_CHAT_FRAME)
        end
      end)

      -- 悬停只做提亮（按钮本身很淡），**不弹鼠标提示**
      button:SetScript("OnEnter", function()
        this:SetAlpha(1)
      end)

      -- 渐隐（平滑过渡到目标透明度）：
      --   复制窗口开着 → 1；鼠标悬停聊天面板 → 0.6；离开聊天区 → 0（与其他按钮一致）。
      -- 8/23 防抖修复把按钮父级从 panelTop（随悬停显隐）移到 pfUI.chat.left 后
      -- 按钮常驻显示，这里用 OnUpdate 插值补回渐隐观感。1.12 无动画组，手动插值。
      button.fadetarget = 0
      button:SetScript("OnLeave", function()
        this.fadetarget = MouseIsOver(pfUI.chat.left) and .6 or 0
        this:SetAlpha(this.fadetarget)
      end)

      button:SetScript("OnUpdate", function()
        if this.state then
          this.fadetarget = 1
        elseif MouseIsOver(pfUI.chat.left) then
          this.fadetarget = .6
        else
          this.fadetarget = 0
        end

        local cur, target = this:GetAlpha(), this.fadetarget
        if math.abs(target - cur) < .01 then return end

        -- 节流 ~25fps，指数逼近
        this.alphaTick = (this.alphaTick or 0) + arg1
        if this.alphaTick < .04 then return end
        this.alphaTick = 0
        this:SetAlpha(cur + (target - cur) * .25)
      end)

      this.button = button
    end

    this:UnregisterAllEvents()
  end)

  -- ==========================================================================
  -- 四、诊断与命令
  -- ==========================================================================
  local function ChainWalk(frame)
    local parts, n, eff = {}, 0, 1
    local f = frame
    while f and n < 8 do
      n = n + 1
      local a = (f.GetAlpha and f:GetAlpha()) or 1
      if type(a) == "number" and a > 0 and a < 1 then eff = eff * a end
      parts[n] = ((f.GetName and f:GetName()) or "?")
        .."(a=" .. (math.floor(a * 100) / 100)
        .. "," .. ((f.IsVisible and f:IsVisible()) and "可见" or "隐藏")
        .. ",lvl=" .. tostring((f.GetFrameLevel and f:GetFrameLevel()) or "?") .. ")"
      f = (f.GetParent and f:GetParent()) or nil
    end
    return table.concat(parts, " > "), eff
  end

  local function Diag()
    local out = DEFAULT_CHAT_FRAME

    for i=1, (_G.NUM_CHAT_WINDOWS or 10) do
      local cf = _G["ChatFrame"..i]
      if cf then
        local hist = cf.pfHistory
        local cnt  = hist and table.getn(hist) or 0
        local fsize = "?"
        if cf.GetFont then
          local _, sz = cf:GetFont()
          fsize = tostring(sz)
        end
        out:AddMessage("|cffffcc00[chatcopy]|r CF" .. i
          .. "｜历史=" .. cnt
          .. "｜字体=" .. fsize
          .. "｜可见=" .. (cf:IsVisible() and "是" or "否")
          .. ((SELECTED_CHAT_FRAME == cf) and "｜←当前" or ""))
      end
    end

    -- 窗口自身：开没开、镜像自检有没有过、剪贴板 API 在不在
    local ws = "未建"
    if win then
      local probe = (win.hits and win.hits[1] and win.hits[1].fs) or win.edit
      ws = (win:IsShown() and "开" or "关")
        .. "·逐行=" .. tostring(win.mirror) .. "(true=文字由逐行 FontString 画)"
        .. "·EditBoxα=" .. (win.edit and (math.floor(win.edit:GetAlpha() * 100) / 100) or "?")
        .. "·字号=" .. tostring(probe and select(2, probe:GetFont()))
        .. "·行数=" .. tostring(win.lineCount)
        .. "·选中=" .. tostring(win.selCount)
    end
    out:AddMessage("|cffffcc00[chatcopy]|r 窗口=" .. ws
      .. "｜来源=" .. tostring(source and source.GetName and source:GetName())
      .. "｜行数上限=" .. limit
      .. "｜格式=" .. tostring(pfUI.chatcopy.format)
      .. "｜显示项: time=" .. tostring(opts.time)
      .. "/class=" .. tostring(opts.class)
      .. "/timefmt=" .. tostring(opts.timefmt)
      .. "｜剪贴板: SetClipboardText=" .. tostring(_G.SetClipboardText and "有" or "无")
      .. "/GetClipboardText=" .. tostring(_G.GetClipboardText and "有" or "无"))

    -- EditBox 能力边界探测（一次问清，别一次猜一个）
    local names = {"SetHighlightTexture", "SetHighlightColor", "SetSelectionColor",
                   "HighlightText", "SetCursorPosition", "SetTextInsets", "EnableMouse", "SetFocus"}
    local pe = {}
    for k=1, table.getn(names) do
      local nm = names[k]
      pe[k] = nm .. "=" .. (((win and win.edit and win.edit[nm]) and "有") or "无")
    end
    out:AddMessage("|cffffcc00[chatcopy]|r EditBox: " .. table.concat(pe, " "))

    -- FontString 侧（逐行渲染能不能画，全看这些）
    local probe2 = (win and win.hits and win.hits[1] and win.hits[1].fs) or nil
    local names2 = {"SetFontObject", "SetFont", "GetFont", "GetStringWidth", "GetHeight"}
    local pf = {}
    for k=1, table.getn(names2) do
      local nm = names2[k]
      pf[k] = nm .. "=" .. (((probe2 and probe2[nm]) and "有") or "无")
    end
    out:AddMessage("|cffffcc00[chatcopy]|r FontString: " .. table.concat(pf, " "))

    local list = {}
    if SELECTED_CHAT_FRAME then table.insert(list, SELECTED_CHAT_FRAME) end
    if _G.ChatFrame3 and _G.ChatFrame3 ~= SELECTED_CHAT_FRAME then table.insert(list, _G.ChatFrame3) end
    for k=1, table.getn(list) do
      out:AddMessage("|cffffcc00[chatcopy]|r 链> " .. (ChainWalk(list[k])))
    end
  end

  _G.SLASH_PFCHATCOPY1 = "/pfchatcopy"
  _G.SlashCmdList["PFCHATCOPY"] = function(msg)
    local out = DEFAULT_CHAT_FRAME
    -- ⚠️ 用形参 msg，不要用全局 arg1：SlashCmdList 是按 func(msg) 调的
    msg = msg or _G.arg1 or ""
    msg = string.gsub(msg, "^%s*(.-)%s*$", "%1")

    if msg == "" then Diag() return end
    if msg == "show" or msg == "window" then Open(SELECTED_CHAT_FRAME) return end

    if msg == "clear" then
      for i=1, (_G.NUM_CHAT_WINDOWS or 10) do
        local cf = _G["ChatFrame"..i]
        if cf and cf.pfHistory then cf.pfHistory = {} end
      end
      if win then Fill() end
      out:AddMessage("|cffffcc00[chatcopy]|r " .. T["Cleared"])
      return
    end

    local _, _, fmt = string.find(msg, "^format%s+(%a+)$")
    if fmt then
      if fmt == "plain" or fmt == "all" then
        pfUI.chatcopy.format = fmt
        if win then Fill() end
      end
      out:AddMessage("|cffffcc00[chatcopy]|r format=" .. tostring(pfUI.chatcopy.format))
      return
    end

    local _, _, mx = string.find(msg, "^max%s+(%d+)$")
    if mx then
      local n = tonumber(mx)
      if n and n > 0 then limit = n end
      out:AddMessage("|cffffcc00[chatcopy]|r max=" .. limit)
      return
    end

    -- 显示项：时间戳 / 职业·等级（持久化在 pfUI_cache，账号级）
    -- ⚠️ 必须放在 format / max 之后：`^(%a+)%s+(%S+)$` 也能匹配 "format plain"，
    --    放前面会把它们截胡。
    -- ⚠️ 用 `string.find` 的捕获，**不用 `string.match`**：本客户端是 Lua 5.0，
    --    它的 string 库没有 match（WoW 只补了全局别名 strmatch，不一定挂在 string 表上）。
    local _, _, key, val = string.find(msg, "^(%a+)%s+(%S+)$")
    if key and (key == "time" or key == "class") then
      local on = (val == "on" or val == "1")
      if val == "on" or val == "off" or val == "1" or val == "0" then
        opts[key] = on and "1" or "0"
        if win then Fill() end
      end
      out:AddMessage("|cffffcc00[chatcopy]|r " .. key .. "=" .. tostring(opts[key]))
      return
    end

    if key == "timefmt" then
      opts.timefmt = val
      if win then Fill() end
      out:AddMessage("|cffffcc00[chatcopy]|r timefmt=" .. tostring(opts.timefmt))
      return
    end

    local n = tonumber(msg)
    if n and _G["ChatFrame"..n] then
      local lines, cnt = Compose(_G["ChatFrame"..n])
      local text = table.concat(lines, "\n")
      out:AddMessage("|cffffcc00[chatcopy]|r 窗口" .. n .. " 行数=" .. cnt
        .. " 前120字(竖线转义)：" .. (string.gsub(string.sub(text, 1, 120), "|", "||")))
      return
    end

    out:AddMessage("|cffffcc00[chatcopy]|r " .. T["Usage"]
      .. ": /pfchatcopy [show | clear | max <n> | format all|plain | time on|off | class on|off | timefmt <格式> | <窗口号>]")
  end

  ----------------------------------------------------------------------------
  -- /pfchatscan —— 列出所有压在 ChatFrame1 上方的可见 frame（挖"灰块/黑块"用）
  ----------------------------------------------------------------------------
  _G.SLASH_PFCHATSCAN1 = "/pfchatscan"
  _G.SlashCmdList["PFCHATSCAN"] = function()
    local out = DEFAULT_CHAT_FRAME
    local cf  = _G.ChatFrame1
    if not cf or not cf:GetLeft() then
      out:AddMessage("|cffffcc00[chatscan]|r ChatFrame1 无几何信息")
      return
    end

    local l, r, t, b = cf:GetLeft(), cf:GetRight(), cf:GetTop(), cf:GetBottom()
    out:AddMessage("|cffffcc00[chatscan]|r ChatFrame1 rect=" .. l .. "," .. t .. "," .. r .. "," .. b)

    for i=1, (_G.NUM_CHAT_WINDOWS or 10) do
      local frame = _G["ChatFrame"..i]
      if frame then
        local bgT = _G["ChatFrame"..i.."Background"]
        local bg  = "无"
        if bgT then bg = (bgT:IsShown() and "显示" or "隐藏") .. "/" .. tostring(bgT:GetTexture()) end
        out:AddMessage("|cffffcc00[chatscan]|r CF" .. i
          .. " rect=" .. tostring(frame:GetLeft()) .. "," .. tostring(frame:GetTop())
          .. "," .. tostring(frame:GetRight()) .. "," .. tostring(frame:GetBottom())
          .. " a=" .. (math.floor(frame:GetAlpha() * 100) / 100)
          .. " 可见=" .. (frame:IsVisible() and "是" or "否")
          .. " 背景=" .. bg)
      end
    end

    if pfUI.chat and pfUI.chat.left then
      local p = pfUI.chat.left
      local bdc = "无"
      if p.backdrop and p.backdrop.GetBackdropColor then
        local br, bgc, bb, ba = p.backdrop:GetBackdropColor()
        bdc = tostring(br) .. "," .. tostring(bgc) .. "," .. tostring(bb) .. "," .. tostring(ba)
          .. "(" .. (p.backdrop:IsShown() and "显示" or "隐藏") .. ")"
      end
      out:AddMessage("|cffffcc00[chatscan]|r pfChatLeft rect=" .. tostring(p:GetLeft())
        .. "," .. tostring(p:GetTop()) .. "," .. tostring(p:GetRight()) .. "," .. tostring(p:GetBottom())
        .. " 背景色=" .. bdc)
    end

    local count = 0
    if type(EnumerateFrames) == "function" then
      local fr = EnumerateFrames()
      while fr do
        local fl, frr, ft, fb = fr:GetLeft(), fr:GetRight(), fr:GetTop(), fr:GetBottom()
        if fr ~= cf and fr:IsVisible() and fl and frr and ft and fb
           and frr > l and fl < r and ft > b and fb < t then
          local nm    = fr:GetName()
          local hasbd = fr.GetBackdrop and fr:GetBackdrop() and true or false
          if hasbd or (nm and string.find(nm, "Chat", 1, true)) then
            local bds = ""
            if hasbd and fr.GetBackdropColor then
              local br, bgc, bb, ba = fr:GetBackdropColor()
              bds = " 背色=" .. tostring(br) .. "," .. tostring(bgc) .. "," .. tostring(bb) .. "," .. tostring(ba)
            end
            out:AddMessage("|cffffcc00[chatscan]|r " .. tostring(nm) .. " 背=" .. tostring(hasbd) .. bds
              .. " strata=" .. tostring(fr.GetFrameStrata and fr:GetFrameStrata())
              .. " lvl=" .. tostring(fr.GetFrameLevel and fr:GetFrameLevel())
              .. " a=" .. (math.floor(fr:GetAlpha() * 100) / 100)
              .. " rect=" .. fl .. "," .. ft .. "," .. frr .. "," .. fb)
            count = count + 1
          end
        end
        fr = EnumerateFrames(fr)
      end
    end
    out:AddMessage("|cffffcc00[chatscan]|r 命中 " .. count .. " 个")
  end
end)
