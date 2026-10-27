-- Resolve only exact spell names and validated IDs; do not scan the spell DB.
-- Optional libraries are consulted at call time so late loads remain visible.
local BS = AceLibrary("Babble-Spell-2.2")
local ICON_ROOT = "Interface\\Icons\\"
local QUESTION = ICON_ROOT .. "INV_Misc_QuestionMark"
local bookMiss, bookMissOrder = {}, {}
local BOOK_MISS_LIMIT, BOOK_MISS_SECONDS = 128, 1

local function usableTexture(value)
  if type(value) ~= "string" then return nil end
  value = string.gsub(value, "^%s*(.-)%s*$", "%1")
  if value == "" then return nil end
  -- 'pet' is an existing EavesDrop sentinel for SetPortraitTexture.
  if value == "pet" then return value end
  local normalized = string.lower(string.gsub(value, "/", "\\"))
  normalized = string.gsub(normalized, "%.blp$", "")
  if normalized == "interface\\icons" or normalized == "interface\\icons\\" or
      normalized == "inv_misc_questionmark" or
      normalized == "interface\\icons\\inv_misc_questionmark" then return nil end
  if not string.find(value, "\\", 1, true) and not string.find(value, "/", 1, true) then
    return ICON_ROOT .. value
  end
  return value
end

local function validId(id)
  return type(id) == "number" and id > 0 and id <= 4294967295 and id == math.floor(id)
end

local function fromId(id)
  if not validId(id) then return nil end
  -- Native nampower script functions are deliberately not wrapped in pcall:
  -- its documented Lua state pointer contract makes that unsafe.
  if type(GetSpellRecField) == "function" and type(GetSpellIconTexture) == "function" then
    local iconId = GetSpellRecField(id, "spellIconID")
    if validId(iconId) then
      local icon = usableTexture(GetSpellIconTexture(iconId))
      if icon then return icon end
    end
  end
  if type(SpellInfo) == "function" then
    local name, rank, texture = SpellInfo(id)
    return usableTexture(texture)
  end
end

local function fromSpellbook(name)
  if type(GetSpellIdForName) ~= "function" then return nil end
  local time = type(GetTime) == "function" and GetTime() or nil
  if type(time) ~= "number" or time * 0 ~= 0 then time = nil end
  local previous = time and bookMiss[name]
  if previous and time >= previous and time - previous < BOOK_MISS_SECONDS then return nil end
  local id = GetSpellIdForName(name)
  if validId(id) then
    if bookMiss[name] then
      bookMiss[name] = nil
      for i = 1, table.getn(bookMissOrder) do
        if bookMissOrder[i] == name then table.remove(bookMissOrder, i); break end
      end
    end
    return fromId(id)
  end
  if time then
    if not bookMiss[name] then
      if table.getn(bookMissOrder) >= BOOK_MISS_LIMIT then
        bookMiss[table.remove(bookMissOrder, 1)] = nil
      end
      table.insert(bookMissOrder, name)
    end
    bookMiss[name] = time
  end
end

function EavesDrop:ResolveSpellIcon(skill, texture, spellId, allowPlaceholder)
  local icon = usableTexture(texture)
  if icon then return icon end
  icon = fromId(spellId)
  if icon then return icon end

  if type(skill) == "string" and string.find(skill, "%S") then
    if BS and type(BS.GetSpellIcon) == "function" then
      icon = usableTexture(BS:GetSpellIcon(skill))
      if icon then return icon end
    end

    -- GetSpellIcon closes over DPSMateX's static local table. Its separate
    -- dynamic global table may have been built with incorrect icon IDs.
    local extra = DPSMateX and DPSMateX.BabbleSpellX
    if extra and type(extra.GetSpellIcon) == "function" then
      icon = usableTexture(extra:GetSpellIcon(skill))
      if icon then return icon end
    end

    if type(pfUI_locale) == "table" and type(GetLocale) == "function" then
      local locale = pfUI_locale[GetLocale()]
      local icons = locale and locale.icons
      if type(icons) == "table" then
        icon = usableTexture(icons[skill])
        if icon then return icon end
      end
    end

    -- Nampower searches the current spellbook only. This is not a scan of
    -- arbitrary IDs, nor a claim that every aura is in the player's book.
    icon = fromSpellbook(skill)
    if icon then return icon end
  end
  -- ParserLib uses numeric sentinels for melee and other non-spell events.
  -- Do not cover those events (or a summon notice with no skill) with '?'.
  if allowPlaceholder and (validId(spellId) or
      (type(skill) == "string" and string.find(skill, "%S"))) then return QUESTION end
end
