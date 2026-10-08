-- multi api compat
local compat = pfQuestCompat

-- default config
pfBrowser_fav = {["units"] = {}, ["objects"] = {}, ["items"] = {}, ["quests"] = {}}

local tooltip_limit = 5
local search_limit = 512

-- add database shortcuts
local items = pfDB["items"]["data"]
local units = pfDB["units"]["data"]
local objects = pfDB["objects"]["data"]
local refloot = pfDB["refloot"]["data"]
local quests = pfDB["quests"]["data"]
local zones = pfDB["zones"]["loc"]

local function ShowTooltip()
  if not this.tooltips then return end
  GameTooltip_SetDefaultAnchor(GameTooltip, this)
  GameTooltip:ClearLines()
  for k, v in pairs(this.tooltips) do
    if k == 1 then
      GameTooltip:AddLine(v, 1, 1, 1)
    else
      GameTooltip:AddLine(v)
    end
  end
  GameTooltip:Show()
end

local function EnableTooltips(frame, tooltips)
  frame.tooltips = tooltips
  frame:SetScript("OnEnter", ShowTooltip)
  frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function ResultButtonEnter()
  this.tex:SetTexture(1,1,1,.1)

  -- quest
  if this.btype == "quests" then
    pfDatabase:ShowExtendedTooltip(this.id, GameTooltip, this, "ANCHOR_LEFT", -10, -5)

  -- item
  elseif this.btype == "items" then
    GameTooltip:SetOwner(this, "ANCHOR_LEFT", -10, -5)
    GameTooltip:SetHyperlink("item:" .. this.id .. pfQuestCompat.itemsuffix)
    GameTooltip:Show()

  -- units / objects
  else
    local id = this.id
    local name = this.name
    local maps = {}
    GameTooltip:SetOwner(this, "ANCHOR_LEFT", -10, -5)
    GameTooltip:SetText(name, .3, 1, .8)
    if this.btype == "units" then
      local unitData = units[id]

      if unitData and unitData.lvl then
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(pfQuest_Loc["Level"], unitData.lvl, 1,1,.8, 1,1,1)
      end

      local reactionStringA = "|c00ff0000" .. pfQuest_Loc["Hostile"] .. "|r"
      local reactionStringH = "|c00ff0000" .. pfQuest_Loc["Hostile"] .. "|r"
      if unitData and unitData.fac then
        if unitData.fac == "AH" then
          reactionStringA = "|c0000ff00" .. pfQuest_Loc["Friendly"] .. "|r"
          reactionStringH = "|c0000ff00" .. pfQuest_Loc["Friendly"] .. "|r"
        elseif unitData.fac == "A" then
          reactionStringA = "|c0000ff00" .. pfQuest_Loc["Friendly"] .. "|r"
        elseif unitData.fac == "H" then
          reactionStringH = "|c0000ff00" .. pfQuest_Loc["Friendly"] .. "|r"
        end
      end
      GameTooltip:AddLine("\n" .. pfQuest_Loc["Reaction"], 1,1,.8)
      GameTooltip:AddDoubleLine(pfQuest_Loc["Alliance"], reactionStringA, 1,1,1, 0,0,0)
      GameTooltip:AddDoubleLine(pfQuest_Loc["Horde"], reactionStringH, 1,1,1, 0,0,0)
    end
    GameTooltip:AddLine("\n" .. pfQuest_Loc["Location"], 1,1,.8)
    if pfDB[this.btype]["data"][id] and pfDB[this.btype]["data"][id]["coords"] then
      for _, data in pairs(pfDB[this.btype]["data"][id]["coords"]) do
        maps[data[3]] = maps[data[3]] or { count = 0 }
        maps[data[3]].count = maps[data[3]].count + 1
      end
    end

    local unknown = true
    for zone, obj in pfQuest:SortedPairs(maps, "count", nil) do
      GameTooltip:AddDoubleLine(( zone and pfMap:GetMapNameByID(zone) or UNKNOWN), obj.count, 1,1,1, .3,1,.8)
      unknown = nil
    end

    if unknown then
      GameTooltip:AddLine(UNKNOWN, 1,.5,.5)
    end

    GameTooltip:Show()
  end
end

local function ResultButtonUpdate()
  this.refreshCount = this.refreshCount + 1

  if not this.itemColor then
    GameTooltip:SetHyperlink("item:" .. this.id .. pfQuestCompat.itemsuffix)
    GameTooltip:Hide()

    local _, _, itemQuality = GetItemInfo(this.id)
    if itemQuality then
      local r = ceil(ITEM_QUALITY_COLORS[itemQuality].r*255)
      local g = ceil(ITEM_QUALITY_COLORS[itemQuality].g*255)
      local b = ceil(ITEM_QUALITY_COLORS[itemQuality].b*255)
      this.itemColor = "|c" .. string.format("ff%02x%02x%02x", r, g, b)
    end
  end

  if this.itemColor then
    local custom = pfQuest_server["items"][this.id] and " [|cff33ffcc!|r]" or ""
    this.text:SetText(this.itemColor .."|Hitem:"..this.id..pfQuestCompat.itemsuffix.."|h[".. this.name.."]|h|r"..custom)
    this.text:SetWidth(this.text:GetStringWidth())
  end

  if this.refreshCount > 10 or this.itemColor then
    this:SetScript("OnUpdate", nil)
  end
end

local function ResultButtonClick()
  local meta = { ["addon"] = "PFDB" }

  if this.btype == "items" then
    local link = "item:"..this.id..pfQuestCompat.itemsuffix
    local text = ( this.itemColor or "|cffffffff" ) .."|H" .. link .. "|h["..this.name.."]|h|r"
    SetItemRef(link, text, arg1)
  elseif this.btype == "quests" then
    if IsShiftKeyDown() then
      pfQuestCompat.InsertQuestLink(this.id)
    elseif pfBrowser.selectState then
      local maps = pfDatabase:SearchQuest(this.name, meta)
      pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    else
      local maps = pfDatabase:SearchQuestID(this.id, meta)
      pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    end
  elseif this.btype == "units" then
    if pfBrowser.selectState then
      local maps = pfDatabase:SearchMob(this.name, meta)
      pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    else
      local maps = pfDatabase:SearchMobID(this.id, meta)
      pfMap:UpdateNodes()
      pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    end
  elseif this.btype == "objects" then
    if pfBrowser.selectState then
      local maps = pfDatabase:SearchObject(this.name, meta)
      pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    else
      local maps = pfDatabase:SearchObjectID(this.id, meta)
      pfMap:UpdateNodes()
      pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    end
  end
end

local function ResultButtonClickFav()
  local parent = this:GetParent()
  if pfBrowser_fav[parent.btype][parent.id] then
    pfBrowser_fav[parent.btype][parent.id] = nil
    this.icon:SetVertexColor(1,1,1,.1)
  else
    pfBrowser_fav[parent.btype][parent.id] = parent.name
    this.icon:SetVertexColor(1,1,1,1)
  end
end

local function ResultButtonLeave()
  if pfBrowser.selectState then
    pfBrowser.selectState = "clean"
  end

  if compat.mod(this:GetID(),2) == 1 then
    this.tex:SetTexture(1,1,1,.02)
  else
    this.tex:SetTexture(1,1,1,.04)
  end
  GameTooltip:Hide()
end

local function ResultButtonClickSpecial()
  local param = this:GetParent()[this.parameter]
  local meta = { ["addon"] = "PFDB" }
  local maps = {}
  if this.buttonType == "O" or this.buttonType == "U" then
    if this.selectState then
      maps = pfDatabase:SearchItem(this:GetParent().name, meta)
    else
      maps = pfDatabase:SearchItemID(param, meta, nil, {[this.buttonType]=true})
    end
  elseif this.buttonType == "V" then
    maps = pfDatabase:SearchVendor(param, meta)
  end
  pfMap:UpdateNodes()
  pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
end

-- 来源 tooltip 的行收集器：先收集全部来源再按掉率降序（同掉率按名字）排序，
-- 只画前 tooltip_limit 行。pairs() 是哈希序，边遍历边画会让截断结果不可预测——
-- 100% 的主要来源可能被 25% 的次要来源挤出显示。
local function SortedSourceRows(rows)
  table.sort(rows, function(a, b)
    local ca, cb = a.chance or -1, b.chance or -1
    if ca ~= cb then return ca > cb end
    return (a.name or "") < (b.name or "")
  end)

  for i = 1, table.getn(rows) do
    if i > tooltip_limit then break end
    GameTooltip:AddDoubleLine(rows[i].name, rows[i].zone, 1,1,1, .5,.5,.5)
  end

  if table.getn(rows) > tooltip_limit then
    GameTooltip:AddLine("\n" .. pfQuest_Loc["and"] .. " " .. (table.getn(rows) - tooltip_limit).." " .. pfQuest_Loc["others"],.8,.8,.8)
  end
end

local function ResultButtonEnterSpecial()
  local id = this:GetParent().id
  local rows, seen = {}, {}

  GameTooltip:SetOwner(pfBrowser, "ANCHOR_CURSOR")

  -- 同一实体可能同时出现在直接键与引用表里：去重，保留更高掉率
  local function collect(db, loc, entity, chance, suffix)
    if not db[entity] then return end
    if seen[entity] then
      if chance and (seen[entity].chance or -1) < chance then seen[entity].chance = chance end
      return
    end
    local zone = db[entity].coords and db[entity].coords[1] and db[entity].coords[1][3]
    local row = {
      name = (loc[entity] or UNKNOWN) .. (suffix or ""),
      zone = zone and pfMap:GetMapNameByID(zone) or UNKNOWN,
      chance = chance,
    }
    seen[entity] = row
    table.insert(rows, row)
  end

  -- unit / object：直接键与引用表相互独立——「命运」这类物品只有 R 没有直接 U，
  -- 原版把 R 展开嵌在直接键存在的分支里，这类物品的来源从来显示不出来
  if this.buttonType == "U" or this.buttonType == "O" then
    local db  = this.buttonType == "U" and units or objects
    local loc = this.buttonType == "U" and pfDB.units.loc or pfDB.objects.loc
    GameTooltip:SetText(pfQuest_Loc["Looted from"], .3, 1, .8)

    if items[id][this.buttonType] then
      for entity, chance in pairs(items[id][this.buttonType]) do
        collect(db, loc, entity, chance)
      end
    end

    -- reference tables
    if items[id]["R"] then
      for ref, chance in pairs(items[id]["R"]) do
        if refloot[ref] and refloot[ref][this.buttonType] then
          for entity in pairs(refloot[ref][this.buttonType]) do
            collect(db, loc, entity, chance)
          end
        end
      end
    end

  -- vendor（无掉率概念，按名字排序；限量商品沿用 "(数量)" 后缀）
  elseif this.buttonType == "V" then
    if items[id]["V"] then
      GameTooltip:SetText(pfQuest_Loc["Sold by"], .3, 1, .8)
      for unitID, sellcount in pairs(items[id]["V"]) do
        collect(units, pfDB.units.loc, unitID, nil,
          sellcount ~= 0 and " (" .. sellcount .. ")" or nil)
      end
    end
  end

  SortedSourceRows(rows)
  GameTooltip:Show()
end

local function ResultButtonLeaveSpecial()
  GameTooltip:Hide()
end

local function ResultButtonReload(self)
  self.idText:SetText("ID: " .. self.id)

  if pfQuest_config.showids == "1" then
    self.idText:Show()
  else
    self.idText:Hide()
  end

  self.itemColor = nil

  -- update faction
  if self.btype ~= "items" then
    self.factionA:Hide()
    self.factionH:Hide()

    local raceMask = pfDatabase:GetRaceMaskByID(self.id, self.btype)
    if (bit.band(77, raceMask) > 0)  or (raceMask == 0 and self.btype == "quests") then
      self.factionA:Show()
    end
    if (bit.band(178, raceMask) > 0)  or (raceMask == 0 and self.btype == "quests") then
      self.factionH:Show()
    end
  end

  -- activate fav buttons if needed
  if pfBrowser_fav and pfBrowser_fav[self.btype] and pfBrowser_fav[self.btype][self.id] then
    self.fav.icon:SetVertexColor(1,1,1,1)
  else
    self.fav.icon:SetVertexColor(1,1,1,.1)
  end

  -- actions by search type
  if self.btype == "quests" then
    self.name = pfDB[self.btype]["loc"][self.id]["T"]
    self.text:SetText("|cffffcc00|Hquest:0:0:0:0|h[" .. self.name .. "]|h|r")
  elseif self.btype == "units" or self.btype == "objects" then
    local level = pfDB[self.btype]["data"][self.id] and pfDB[self.btype]["data"][self.id]["lvl"] or ""
    if level and level ~= "" then level = " (" .. level .. ")" end
    self.text:SetText(self.name .. "|cffaaaaaa" .. level)

    if pfDB[self.btype]["data"][self.id] and pfDB[self.btype]["data"][self.id]["coords"] then
      self.text:SetTextColor(1,1,1)
    else
      self.text:SetTextColor(.5,.5,.5)
    end
  elseif self.btype == "items" then
    for _, key in ipairs({"U","O","V"}) do
      local has = items[self.id] and items[self.id][key]
      -- 纯引用表物品（只有 R 没有直接键）也该有骷髅/齿轮按钮
      if not has and key ~= "V" and items[self.id] and items[self.id]["R"] then
        for ref in pairs(items[self.id]["R"]) do
          if refloot[ref] and refloot[ref][key] then has = true break end
        end
      end
      if has then
        self[key]:Show()
      else
        self[key]:Hide()
      end
    end

    self.text:SetText("|cffff5555[?] |cffffffff" .. self.name)

    self.refreshCount = 0
    self:SetScript("OnUpdate", ResultButtonUpdate)
  end

  self.text:SetWidth(self.text:GetStringWidth())
  self:Show()
end

local function ResultButtonCreate(i, resultType)
  local f = CreateFrame("Button", nil, pfBrowser.tabs[resultType].list)
  f:SetPoint("TOPLEFT", pfBrowser.tabs[resultType].list, "TOPLEFT", 10, -i*30 + 5)
  f:SetPoint("BOTTOMRIGHT", pfBrowser.tabs[resultType].list, "TOPRIGHT", 10, -i*30 - 15)
  f:Hide()
  f:SetID(i)

  f.btype = resultType
  f.pfResultButton = true

  f.tex = f:CreateTexture("BACKGROUND")
  f.tex:SetAllPoints(f)
  f.tex:SetTexture(1,1,1, ( compat.mod(i,2) == 1 and .02 or .04))

  -- text properties
  f.text = f:CreateFontString("Caption", "LOW", "GameFontWhite")
  f.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
  f.text:SetAllPoints(f)
  f.text:SetJustifyH("CENTER")
  f.idText = f:CreateFontString("ID", "LOW", "GameFontDisable")
  f.idText:SetPoint("LEFT", f, "LEFT", 30, 0)

  -- favourite button
  f.fav = CreateFrame("Button", nil, f)
  f.fav:SetHitRectInsets(-3,-3,-3,-3)
  f.fav:SetPoint("LEFT", 0, 0)
  f.fav:SetWidth(16)
  f.fav:SetHeight(16)
  f.fav.icon = f.fav:CreateTexture("OVERLAY")
  f.fav.icon:SetTexture(pfQuestConfig.path.."\\img\\fav")
  f.fav.icon:SetAllPoints(f.fav)

  -- faction icons
  if resultType ~= "items" then
    f.factionA = f:CreateTexture("OVERLAY")
    f.factionA:SetTexture(pfQuestConfig.path.."\\img\\icon_alliance")
    f.factionA:SetWidth(16)
    f.factionA:SetHeight(16)
    f.factionA:SetPoint("RIGHT", -5, 0)
    f.factionH = f:CreateTexture("OVERLAY")
    f.factionH:SetTexture(pfQuestConfig.path.."\\img\\icon_horde")
    f.factionH:SetWidth(16)
    f.factionH:SetHeight(16)
    f.factionH:SetPoint("RIGHT", -24, 0)
  end

  -- drop, loot, vendor buttons
  if resultType == "items" then
    local buttons = {
      ["U"] = { ["offset"] = -5,  ["icon"] = "icon_npc",    ["parameter"] = "id",   },
      ["O"] = { ["offset"] = -24, ["icon"] = "icon_object", ["parameter"] = "id",   },
      ["V"] = { ["offset"] = -43, ["icon"] = "icon_vendor", ["parameter"] = "name", },
    }

    for button, settings in pairs(buttons) do
      f[button] = CreateFrame("Button", nil, f)
      f[button]:SetHitRectInsets(-3,-3,-3,-3)
      f[button]:SetPoint("RIGHT", settings.offset, 0)
      f[button]:SetWidth(16)
      f[button]:SetHeight(16)

      f[button].buttonType = button
      f[button].parameter = settings.parameter

      f[button].icon = f[button]:CreateTexture("OVERLAY")
      f[button].icon:SetAllPoints(f[button])
      f[button].icon:SetTexture(pfQuestConfig.path.."\\img\\"..settings.icon)

      f[button]:SetScript("OnEnter", ResultButtonEnterSpecial)
      f[button]:SetScript("OnLeave", ResultButtonLeaveSpecial)
      f[button]:SetScript("OnClick", ResultButtonClickSpecial)
    end
  end

  -- bind functions
  f.Reload = ResultButtonReload
  f:SetScript("OnLeave", ResultButtonLeave)
  f:SetScript("OnEnter", ResultButtonEnter)
  f:SetScript("OnClick", ResultButtonClick)
  f.fav:SetScript("OnClick", ResultButtonClickFav)

  return f
end

local function SelectView(view)
  for id, frame in pairs(pfBrowser.tabs) do
    pfUI.api.SetButtonFontColor(frame.button, 1,1,1,.7)
    frame:Hide()
  end
  pfUI.api.SetButtonFontColor(view.button, .2,1,.8,1)
  view.button:Hide()
  view.button:Show()
  view:Show()
end

-- sets the browser result values when they change
local function RefreshView(i, key, caption)
  pfBrowser.tabs[key].list:Hide()
  pfBrowser.tabs[key].list:SetHeight(i * 30 )
  pfBrowser.tabs[key].list:Show()
  pfBrowser.tabs[key].list:GetParent():SetScrollChild(pfBrowser.tabs[key].list)
  pfBrowser.tabs[key].list:GetParent():SetVerticalScroll(0)

  if not pfBrowser.tabs[key].list.warn then
    pfBrowser.tabs[key].list.warn = pfBrowser.tabs[key].list:CreateFontString("Caption", "LOW", "GameFontWhite")
    pfBrowser.tabs[key].list.warn:SetTextColor(1,.2,.2,1)
    pfBrowser.tabs[key].list.warn:SetJustifyH("CENTER")
    pfBrowser.tabs[key].list.warn:SetPoint("TOP", 5, -5)
    pfBrowser.tabs[key].list.warn:SetText("!! |cffffffff" .. pfQuest_Loc["Too many entries. Results shown"] .. ": " .. search_limit .. "|r !!")
  end

  if i >= search_limit then
    pfBrowser.tabs[key].list.warn:Show()
  else
    pfBrowser.tabs[key].list.warn:Hide()
  end

  pfBrowser.tabs[key].button:SetText(pfQuest_Loc[caption] .. " " .. "|cffaaaaaa(" .. (i >= search_limit and "*" or i) .. ")")
  for j=i+1, table.getn(pfBrowser.tabs[key].buttons) do
    if pfBrowser.tabs[key].buttons[j] then
      pfBrowser.tabs[key].buttons[j]:Hide()
      pfBrowser.tabs[key].buttons[j].id = nil
      pfBrowser.tabs[key].buttons[j].name = nil
    end
  end
end

-- sets up all the browse windows and their activation buttons
local function CreateBrowseWindow(fname, name, parent, anchor, x, y)
  if not parent.tabs then parent.tabs = {} end
  parent.tabs[fname] = pfUI.api.CreateScrollFrame(name, parent)
  parent.tabs[fname]:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -65)
  parent.tabs[fname]:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 45)
  parent.tabs[fname]:Hide()
  parent.tabs[fname].buttons = { }

  parent.tabs[fname].backdrop = CreateFrame("Frame", name .. "Backdrop", parent.tabs[fname])
  parent.tabs[fname].backdrop:SetFrameLevel(1)
  parent.tabs[fname].backdrop:SetPoint("TOPLEFT", parent.tabs[fname], "TOPLEFT", -5, 5)
  parent.tabs[fname].backdrop:SetPoint("BOTTOMRIGHT", parent.tabs[fname], "BOTTOMRIGHT", 5, -5)
  pfUI.api.CreateBackdrop(parent.tabs[fname].backdrop, nil, true)

  parent.tabs[fname].button = CreateFrame("Button", name .. "Button", parent)
  parent.tabs[fname].button:SetPoint(anchor, x, y)
  parent.tabs[fname].button:SetWidth(153)
  parent.tabs[fname].button:SetHeight(30)
  parent.tabs[fname].button:SetScript("OnClick", function()
    SelectView(parent.tabs[fname])
  end)

  if fname == "units" then
    EnableTooltips(parent.tabs[fname].button, {
      pfQuest_Loc["Units"],
      pfQuest_Loc["Display related creatures and NPCs"],
    })
  elseif fname == "objects" then
    EnableTooltips(parent.tabs[fname].button, {
      pfQuest_Loc["Objects"],
      pfQuest_Loc["Display related objects like ores, herbs, chests, etc."],
    })
  elseif fname == "items" then
    EnableTooltips(parent.tabs[fname].button, {
      pfQuest_Loc["Items"],
      pfQuest_Loc["Display related items"],
    })
  elseif fname == "quests" then
    EnableTooltips(parent.tabs[fname].button, {
      pfQuest_Loc["Quests"],
      pfQuest_Loc["Display related quests"],
    })
  end

  pfUI.api.SkinButton(parent.tabs[fname].button)
  parent.tabs[fname].list = pfUI.api.CreateScrollChild(name .. "Scroll", parent.tabs[fname])
  parent.tabs[fname].list:SetWidth(600)
end

-- browser window
pfBrowser = CreateFrame("Frame", "pfQuestBrowser", UIParent)
pfBrowser:Hide()
pfBrowser:SetWidth(640)
pfBrowser:SetHeight(480)
pfBrowser:SetPoint("CENTER", 0, 0)
pfBrowser:SetFrameStrata("FULLSCREEN_DIALOG")
pfBrowser:SetMovable(true)
pfBrowser:EnableMouse(true)
pfBrowser:RegisterEvent("PLAYER_ENTERING_WORLD")
pfBrowser:SetScript("OnEvent", function()
  -- show all favorites on login if configured
  if pfQuest_config.favonlogin == "1" then
    -- search units
    for id, name in pairs(pfBrowser_fav.units) do
      pfDatabase:SearchMobID(id)
    end

    -- search objects
    for id, name in pairs(pfBrowser_fav.objects) do
      pfDatabase:SearchObjectID(id)
    end

    -- search items
    for id, name in pairs(pfBrowser_fav.items) do
      pfDatabase:SearchItemID(id)
    end

    -- search quests
    for id, name in pairs(pfBrowser_fav.quests) do
      pfDatabase:SearchQuestID(id)
    end
  end
end)
pfBrowser:SetScript("OnMouseDown",function()
  this:StartMoving()
end)

pfBrowser:SetScript("OnMouseUp",function()
  this:StopMovingOrSizing()
end)

pfBrowser:SetScript("OnUpdate", function()
  -- multi-select handling
  if not this.selectState and IsControlKeyDown() and GetMouseFocus() and GetMouseFocus().pfResultButton then
    for id, frame in pairs(pfBrowser.tabs) do
      for id, button in pairs(frame.buttons) do
        if button.name == GetMouseFocus().name then
          button.tex:SetTexture(.3,1,.8,.4)
        end
      end
    end
    this.selectState = "active"

  elseif this.selectState and (this.selectState == "clean" or not IsControlKeyDown()) then
    for id, frame in pairs(pfBrowser.tabs) do
      for id, button in pairs(frame.buttons) do
        if compat.mod(button:GetID(),2) == 1 then
          button.tex:SetTexture(1,1,1,.02)
        else
          button.tex:SetTexture(1,1,1,.04)
        end
      end
    end
    this.selectState = nil
  end
end)

pfUI.api.CreateBackdrop(pfBrowser, nil, true, 0.75)
table.insert(UISpecialFrames, "pfQuestBrowser")

pfBrowser.title = pfBrowser:CreateFontString("Status", "LOW", "GameFontNormal")
pfBrowser.title:SetFontObject(GameFontWhite)
pfBrowser.title:SetPoint("TOP", pfBrowser, "TOP", 0, -8)
pfBrowser.title:SetJustifyH("LEFT")
pfBrowser.title:SetFont(pfUI.font_default, 14)
pfBrowser.title:SetText("|cff33ffccpf|rQuest")

pfBrowser.close = CreateFrame("Button", "pfQuestBrowserClose", pfBrowser)
pfBrowser.close:SetPoint("TOPRIGHT", -5, -5)
pfBrowser.close:SetHeight(20)
pfBrowser.close:SetWidth(20)
pfBrowser.close.texture = pfBrowser.close:CreateTexture("pfQuestionDialogCloseTex")
pfBrowser.close.texture:SetTexture(pfQuestConfig.path.."\\compat\\close")
pfBrowser.close.texture:ClearAllPoints()
pfBrowser.close.texture:SetVertexColor(1,.25,.25,1)
pfBrowser.close.texture:SetPoint("TOPLEFT", pfBrowser.close, "TOPLEFT", 4, -4)
pfBrowser.close.texture:SetPoint("BOTTOMRIGHT", pfBrowser.close, "BOTTOMRIGHT", -4, 4)
pfBrowser.close:SetScript("OnClick", function()
  this:GetParent():Hide()
end)
EnableTooltips(pfBrowser.close, {
  pfQuest_Loc["Close"],
  pfQuest_Loc["Hide browser window"],
})
pfUI.api.SkinButton(pfBrowser.close, 1, .5, .5)

pfBrowser.journal = CreateFrame("Button", "pfQuestJournalOpen", pfBrowser)
pfBrowser.journal:SetPoint("TOPRIGHT", -30, -5)
pfBrowser.journal:SetHeight(20)
pfBrowser.journal:SetWidth(20)
pfBrowser.journal.texture = pfBrowser.journal:CreateTexture("pfQuestionDialogCloseTex")
pfBrowser.journal.texture:SetTexture(pfQuestConfig.path.."\\img\\tracker_quests")
pfBrowser.journal.texture:ClearAllPoints()
pfBrowser.journal.texture:SetPoint("TOPLEFT", pfBrowser.journal, "TOPLEFT", 2, -2)
pfBrowser.journal.texture:SetPoint("BOTTOMRIGHT", pfBrowser.journal, "BOTTOMRIGHT", -2, 2)
pfBrowser.journal:SetScript("OnClick", function()
  if pfJournal:IsShown() then pfJournal:Hide() else pfJournal:Show() end
end)
EnableTooltips(pfBrowser.journal, {
  pfQuest_Loc["Journal"],
  pfQuest_Loc["Toggle completed quest browser"],
})
pfUI.api.SkinButton(pfBrowser.journal)

pfBrowser.clean = CreateFrame("Button", "pfQuestBrowserClean", pfBrowser)
pfBrowser.clean:SetPoint("TOPRIGHT", pfBrowser, "TOPRIGHT", -5, -30)
pfBrowser.clean:SetPoint("BOTTOMRIGHT", pfBrowser, "TOPRIGHT", 0, -55)
pfBrowser.clean:SetScript("OnClick", function()
  pfMap:DeleteNode("PFDB")
  pfMap:UpdateNodes()
end)
pfBrowser.clean.text = pfBrowser.clean:CreateFontString("Caption", "LOW", "GameFontWhite")
pfBrowser.clean.text:SetAllPoints(pfBrowser.clean)
pfBrowser.clean.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfBrowser.clean.text:SetText(pfQuest_Loc["Clean Map"])
local width = pfBrowser.clean.text:GetStringWidth() > 90 and pfBrowser.clean.text:GetStringWidth() + 20 or 90
pfBrowser.clean:SetWidth(width)
EnableTooltips(pfBrowser.clean, {
  pfQuest_Loc["Clean Map"],
  pfQuest_Loc["Remove all manually searched objects from the map"],
})
pfUI.api.SkinButton(pfBrowser.clean)

CreateBrowseWindow("units", "pfQuestBrowserUnits", pfBrowser, "BOTTOMLEFT", 5, 5)
CreateBrowseWindow("objects", "pfQuestBrowserObjects", pfBrowser, "BOTTOMLEFT", 164, 5)
CreateBrowseWindow("items", "pfQuestBrowserItems", pfBrowser, "BOTTOMRIGHT", -164, 5)
CreateBrowseWindow("quests", "pfQuestBrowserQuests", pfBrowser, "BOTTOMRIGHT", -5, 5)

SelectView(pfBrowser.tabs["units"])

-- display a custom list of entries inside the browser
-- list: array of { id = <dbid>, name = <displayname> }
-- searchType: one of "units", "objects", "items", "quests"
-- caption: locale key used for the tab button label
function pfBrowser:ShowList(list, searchType, caption)
  searchType = searchType or "units"
  caption = caption or "Units"

  -- show the browser first so the frame is laid out before we populate it.
  -- populating while hidden (and then calling Show in the same step) does not
  -- always trigger a redraw on the first call, which is why the list stayed
  -- empty until a second invocation. we wait until the browser is actually
  -- visible before populating.
  pfBrowser:Show()

  local populate = function()
    local i = 0
    for _, entry in pairs(list) do
      i = i + 1
      if i >= search_limit then break end
      pfBrowser.tabs[searchType].buttons[i] = pfBrowser.tabs[searchType].buttons[i] or ResultButtonCreate(i, searchType)
      pfBrowser.tabs[searchType].buttons[i].id = entry.id
      pfBrowser.tabs[searchType].buttons[i].name = entry.name
      pfBrowser.tabs[searchType].buttons[i]:Reload()
    end

    RefreshView(i, searchType, caption)
    SelectView(pfBrowser.tabs[searchType])

    local scroll = pfBrowser.tabs[searchType].list:GetParent()
    if scroll.UpdateScrollChildRect then scroll:UpdateScrollChildRect() end
  end

  if pfBrowser:IsShown() then
    populate()
  else
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function()
      if pfBrowser:IsShown() then
        this:SetScript("OnUpdate", nil)
        populate()
      end
    end)
  end
end

-- Multi-keyword search supporting map names, levels and name substrings.
--   "辛特兰 鹰" -> units in Hinterlands whose name contains 鹰
--   "辛特兰 31" -> units in Hinterlands whose level range includes 31
--   "鹰"        -> plain name substring search (legacy behaviour)
function pfBrowser:BuildSearch(text, searchType, custom)
  -- split the search text into whitespace-separated tokens
  local tokens = {}
  for token in string.gfind(text, "%S+") do
    table.insert(tokens, token)
  end

  local mapFilters, levelFilters, nameKeywords = {}, {}, {}
  for _, token in ipairs(tokens) do
    local asNum = tonumber(token)
    if asNum then
      table.insert(levelFilters, asNum)
    else
      local mapID = pfMap:GetMapIDByName(token)
      if mapID then
        table.insert(mapFilters, mapID)
      else
        table.insert(nameKeywords, token)
      end
    end
  end

  local data = {}

  -- base set: first name keyword via GetIDByName, otherwise all entries
  if table.getn(nameKeywords) > 0 then
    data = pfDatabase:GetIDByName(nameKeywords[1], searchType, true, custom) or {}
    -- post-filter by the remaining name keywords (substring match)
    if table.getn(nameKeywords) > 1 then
      local filtered = {}
      for id, name in pairs(data) do
        local ok = true
        for k = 2, table.getn(nameKeywords) do
          local kw = nameKeywords[k]
          if type(name) ~= "string" or not string.find(strlower(name), strlower(kw), 1, true) then
            ok = false
            break
          end
        end
        if ok then filtered[id] = name end
      end
      data = filtered
    end
  else
    for id, _ in pairs(pfDB[searchType]["data"]) do
      local loc = pfDB[searchType]["loc"][id]
      local nm = (searchType == "quests" and type(loc) == "table") and loc["T"] or loc
      data[id] = nm or UNKNOWN
    end
  end

  -- apply map filter (requires a coords entry matching the mapID)
  if table.getn(mapFilters) > 0 then
    local filtered = {}
    for id, name in pairs(data) do
      local entry = pfDB[searchType]["data"][id]
      local coords = entry and entry["coords"]
      if coords then
        for _, coord in pairs(coords) do
          local hit = false
          for _, mid in ipairs(mapFilters) do
            if coord[3] == mid then hit = true break end
          end
          if hit then filtered[id] = name break end
        end
      end
    end
    data = filtered
  end

  -- apply level filter (units only, inclusive range match)
  if table.getn(levelFilters) > 0 and searchType == "units" then
    local filtered = {}
    for id, name in pairs(data) do
      local unit = pfDB["units"]["data"][id]
      local lvl = unit and unit["lvl"]
      if lvl then
        local minlvl, maxlvl = string.match(lvl, "^(%d+)%s*-?%s*(%d*)$")
        minlvl = tonumber(minlvl)
        maxlvl = tonumber(maxlvl) or minlvl
        if minlvl then
          for _, l in ipairs(levelFilters) do
            if l >= minlvl and l <= maxlvl then
              filtered[id] = name
              break
            end
          end
        end
      end
    end
    data = filtered
  end

  return data, (table.getn(mapFilters) > 0)
end

pfBrowser.input = CreateFrame("EditBox", "pfQuestBrowserSearch", pfBrowser)
pfBrowser.input:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfBrowser.input:SetFontObject("GameFontDisable")
pfBrowser.input:SetAutoFocus(false)
pfBrowser.input:SetText(pfQuest_Loc["Search"])
pfBrowser.input:SetJustifyH("LEFT")
pfBrowser.input:SetPoint("TOPLEFT", pfBrowser, "TOPLEFT", 5, -30)
pfBrowser.input:SetPoint("BOTTOMRIGHT", pfBrowser.clean, "BOTTOMLEFT", -5, 0)
pfBrowser.input:SetTextInsets(24,12,4,4)

pfBrowser.input.searchIcon = pfBrowser.input:CreateTexture("$parentSearchIcon", "OVERLAY")
pfBrowser.input.searchIcon:SetTexture(pfQuestConfig.path.."\\img\\tracker_search")
pfBrowser.input.searchIcon:SetHeight(14)
pfBrowser.input.searchIcon:SetWidth(14)
pfBrowser.input.searchIcon:SetVertexColor(0.6, 0.6, 0.6)
pfBrowser.input.searchIcon:SetPoint("LEFT", pfBrowser.input, "LEFT", 6, 0)

pfBrowser.input.clearButton = CreateFrame("Button", "$parentClearButton", pfBrowser.input)
pfBrowser.input.clearButton:Hide()
pfBrowser.input.clearButton:SetHeight(17)
pfBrowser.input.clearButton:SetWidth(17)
pfBrowser.input.clearButton:SetPoint("RIGHT", pfBrowser.input, "RIGHT", -3, 0)
pfBrowser.input.clearButton.texture = pfBrowser.input.clearButton:CreateTexture(nil, "ARTWORK")
pfBrowser.input.clearButton.texture:SetTexture(pfQuestConfig.path.."\\img\\tracker_close")
pfBrowser.input.clearButton.texture:SetHeight(17)
pfBrowser.input.clearButton.texture:SetWidth(17)
pfBrowser.input.clearButton.texture:SetAlpha(0.5)
pfBrowser.input.clearButton.texture:SetPoint("TOPLEFT", pfBrowser.input.clearButton, "TOPLEFT", 0, 0)
pfBrowser.input.clearButton:SetScript("OnEnter", function()
  this.texture:SetAlpha(1.0)
end)
pfBrowser.input.clearButton:SetScript("OnLeave", function()
  this.texture:SetAlpha(0.5)
end)
pfBrowser.input.clearButton:SetScript("OnMouseDown", function()
  if this:IsEnabled() then
    this.texture:SetPoint("TOPLEFT", this, "TOPLEFT", 1, -1)
  end
end)
pfBrowser.input.clearButton:SetScript("OnMouseUp", function()
  this.texture:SetPoint("TOPLEFT", this, "TOPLEFT", 0, 0)
end)
pfBrowser.input.clearButton:SetScript("OnClick", function()
  PlaySound("igMainMenuOptionCheckBoxOn")
  pfBrowser.input:SetText("")
  --[[
  If there is no focus, then the ClearFocus() method does not call the OnEditFocusLost script.
  In 1.12, there is no HasFocus() method, so there is no way to check for focus. therefore,
  for ease of implementation and to avoid double calling the OnEditFocusLost script, I use the
  SetFocus() method to accurately ensure that the OnEditFocusLost script is called.
  --]]
  pfBrowser.input:SetFocus()
  pfBrowser.input:ClearFocus()
end)

pfBrowser.input:SetScript("OnEscapePressed", function() this:ClearFocus() end)
pfBrowser.input:SetScript("OnEnterPressed", function() this:ClearFocus() end)
pfBrowser.input:SetScript("OnEditFocusGained", function()
  this:HighlightText()
  this:SetFontObject("GameFontWhite")
  this.searchIcon:SetVertexColor(1.0, 1.0, 1.0)
  if this:GetText() == pfQuest_Loc["Search"] then this:SetText("") end
  this.clearButton:Show()
end)

pfBrowser.input:SetScript("OnEditFocusLost", function()
  this:HighlightText(0, 0)
  this:SetFontObject("GameFontDisable")
  this.searchIcon:SetVertexColor(0.6, 0.6, 0.6)
  if this:GetText() == "" then
    this:SetText(pfQuest_Loc["Search"])
    this.clearButton:Hide()
  end
end)

-- This script updates all the search tabs when the search text changes
pfBrowser.input:SetScript("OnTextChanged", function()
  local text = this:GetText()
  if (text == pfQuest_Loc["Search"]) then text = "" end

  local custom = string.find(text, "^custom:")
  text = string.gsub(text, "^custom:", "")

  -- a pure number in the search box is treated as a level search against the
  -- current map (e.g. "31" shows monsters whose level range includes 31).
  local levelSearch = tonumber(text)

  for _, caption in ipairs({"Units","Objects","Items","Quests"}) do
    local searchType = strlower(caption)
    local data

    if levelSearch and searchType == "units" then
      -- monsters in the current map whose level range includes the searched level
      data = {}
      local realZone = GetRealZoneText()
      local mapID = pfMap:GetMapIDByName(realZone) or pfMap:GetMapID(GetCurrentMapContinent(), GetCurrentMapZone())
      if mapID then
        local seen = {}
        for id, unit in pairs(pfDB["units"]["data"]) do
          local coords = unit["coords"]
          if coords then
            for _, coord in pairs(coords) do
              if coord[3] == mapID then
                local lvl = unit["lvl"]
                if lvl then
                  local minlvl, maxlvl = string.match(lvl, "^(%d+)%s*-?%s*(%d*)$")
                  minlvl = tonumber(minlvl)
                  maxlvl = tonumber(maxlvl) or minlvl
                  if minlvl and levelSearch >= minlvl and levelSearch <= maxlvl and not seen[id] then
                    seen[id] = true
                    data[id] = pfDB["units"]["loc"][id] or UNKNOWN
                  end
                end
                break
              end
            end
          end
        end
      end
      SelectView(pfBrowser.tabs["units"])
    elseif levelSearch then
      -- level search only applies to monsters; other tabs stay empty
      data = {}
    else
      -- multi-keyword search: map names + level + name substrings
      if (strlen(text) >= 3 or custom) then
        local data2, hasMap = pfBrowser:BuildSearch(text, searchType, custom)
        data = data2
        -- a location search (e.g. "辛特兰 鹰") should surface on the units
        -- tab, just like the numeric level search does.
        if hasMap and searchType == "units" then
          SelectView(pfBrowser.tabs["units"])
        end
      else
        data = pfBrowser_fav[searchType]
      end
    end

    local i = 0
    for id, text in pairs(data) do
      i = i + 1

      if i >= search_limit then break end
      pfBrowser.tabs[searchType].buttons[i] = pfBrowser.tabs[searchType].buttons[i] or ResultButtonCreate(i, searchType)
      pfBrowser.tabs[searchType].buttons[i].id = id
      pfBrowser.tabs[searchType].buttons[i].name = text
      pfBrowser.tabs[searchType].buttons[i]:Reload()
    end

    RefreshView(i, searchType, caption)
  end
end)

pfUI.api.CreateBackdrop(pfBrowser.input, nil, true)
