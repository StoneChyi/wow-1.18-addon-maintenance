-- Shared resource-number layout. Generated ink metrics use Pillow's mm anchor
-- at 1000px, in the maintained client fonts. The 1.12 API cannot detect a font
-- replaced at the same path. Unknown paths/non-resource characters use zero
-- compensation. The actual loaded face/size always comes from GetFont.
-- Regenerate these metrics after replacing a measured font at the same path.
setfenv(1, pfUI:GetEnvironment())

-- BEGIN GENERATED RESOURCE FONT METRICS
local metrics = {
  ["fonts\\arialn.ttf"] = {
    ["0"] = {-243, 454},
    ["1"] = {-234, 444},
    ["2"] = {-243, 444},
    ["3"] = {-243, 454},
    ["4"] = {-239, 449},
    ["5"] = {-234, 454},
    ["6"] = {-243, 454},
    ["7"] = {-234, 449},
    ["8"] = {-243, 454},
    ["9"] = {-243, 454},
    ["/"] = {-297, 535},
    ["%"] = {-250, 462},
    ["."] = {322, 447},
    [","] = {322, 588},
    ["-"] = {126, 438},
  },
  ["fonts\\arkai_c.ttf"] = {
    ["0"] = {-243, 454},
    ["1"] = {-234, 444},
    ["2"] = {-243, 444},
    ["3"] = {-243, 454},
    ["4"] = {-239, 449},
    ["5"] = {-234, 454},
    ["6"] = {-243, 454},
    ["7"] = {-234, 449},
    ["8"] = {-243, 454},
    ["9"] = {-243, 454},
    ["/"] = {-297, 535},
    ["%"] = {-250, 462},
    ["."] = {322, 447},
    [","] = {322, 588},
    ["-"] = {126, 438},
  },
  ["fonts\\frizqt__.ttf"] = {
    ["0"] = {-243, 454},
    ["1"] = {-234, 444},
    ["2"] = {-243, 444},
    ["3"] = {-243, 454},
    ["4"] = {-239, 449},
    ["5"] = {-234, 454},
    ["6"] = {-243, 454},
    ["7"] = {-234, 449},
    ["8"] = {-243, 454},
    ["9"] = {-243, 454},
    ["/"] = {-297, 535},
    ["%"] = {-250, 462},
    ["."] = {322, 447},
    [","] = {322, 588},
    ["-"] = {126, 438},
  },
  ["fonts\\fzbwjw.ttf"] = {
    ["0"] = {-243, 454},
    ["1"] = {-234, 444},
    ["2"] = {-243, 444},
    ["3"] = {-243, 454},
    ["4"] = {-239, 449},
    ["5"] = {-234, 454},
    ["6"] = {-243, 454},
    ["7"] = {-234, 449},
    ["8"] = {-243, 454},
    ["9"] = {-243, 454},
    ["/"] = {-297, 535},
    ["%"] = {-250, 462},
    ["."] = {322, 447},
    [","] = {322, 588},
    ["-"] = {126, 438},
  },
  ["fonts\\fzjzjw.ttf"] = {
    ["0"] = {-272, 498},
    ["1"] = {-266, 491},
    ["2"] = {-266, 491},
    ["3"] = {-266, 491},
    ["4"] = {-266, 491},
    ["5"] = {-266, 491},
    ["6"] = {-266, 498},
    ["7"] = {-266, 491},
    ["8"] = {-266, 491},
    ["9"] = {-272, 491},
    ["/"] = {-266, 682},
    ["%"] = {-272, 497},
    ["."] = {350, 491},
    [","] = {350, 674},
    ["-"] = {122, 441},
  },
  ["fonts\\fzlbjw.ttf"] = {
    ["0"] = {-243, 454},
    ["1"] = {-234, 444},
    ["2"] = {-243, 444},
    ["3"] = {-243, 454},
    ["4"] = {-239, 449},
    ["5"] = {-234, 454},
    ["6"] = {-243, 454},
    ["7"] = {-234, 449},
    ["8"] = {-243, 454},
    ["9"] = {-243, 454},
    ["/"] = {-297, 535},
    ["%"] = {-250, 462},
    ["."] = {322, 447},
    [","] = {322, 588},
    ["-"] = {126, 438},
  },
  ["fonts\\fzxhjw.ttf"] = {
    ["0"] = {-243, 454},
    ["1"] = {-234, 444},
    ["2"] = {-243, 444},
    ["3"] = {-243, 454},
    ["4"] = {-239, 449},
    ["5"] = {-234, 454},
    ["6"] = {-243, 454},
    ["7"] = {-234, 449},
    ["8"] = {-243, 454},
    ["9"] = {-243, 454},
    ["/"] = {-297, 535},
    ["%"] = {-250, 462},
    ["."] = {322, 447},
    [","] = {322, 588},
    ["-"] = {126, 438},
  },
  ["fonts\\fzxhljw.ttf"] = {
    ["0"] = {-243, 454},
    ["1"] = {-234, 444},
    ["2"] = {-243, 444},
    ["3"] = {-243, 454},
    ["4"] = {-239, 449},
    ["5"] = {-234, 454},
    ["6"] = {-243, 454},
    ["7"] = {-234, 449},
    ["8"] = {-243, 454},
    ["9"] = {-243, 454},
    ["/"] = {-297, 535},
    ["%"] = {-250, 462},
    ["."] = {322, 447},
    [","] = {322, 588},
    ["-"] = {126, 438},
  },
  ["interface\\addons\\pfui\\fonts\\adobeblank.ttf"] = {
  },
  ["interface\\addons\\pfui\\fonts\\bignoodletitling.ttf"] = {
    ["0"] = {-450, 268},
    ["1"] = {-450, 268},
    ["2"] = {-450, 268},
    ["3"] = {-450, 268},
    ["4"] = {-450, 268},
    ["5"] = {-450, 268},
    ["6"] = {-450, 268},
    ["7"] = {-450, 268},
    ["8"] = {-450, 268},
    ["9"] = {-450, 268},
    ["/"] = {-500, 318},
    ["%"] = {-450, 268},
    ["."] = {146, 268},
    [","] = {144, 387},
    ["-"] = {-93, 268},
  },
  ["interface\\addons\\pfui\\fonts\\continuum.ttf"] = {
    ["0"] = {-324, 376},
    ["1"] = {-324, 376},
    ["2"] = {-324, 376},
    ["3"] = {-324, 376},
    ["4"] = {-324, 376},
    ["5"] = {-324, 376},
    ["6"] = {-324, 376},
    ["7"] = {-324, 376},
    ["8"] = {-324, 376},
    ["9"] = {-324, 376},
    ["/"] = {-324, 376},
    ["%"] = {-324, 376},
    ["."] = {255, 376},
    [","] = {253, 473},
    ["-"] = {51, 376},
  },
  ["interface\\addons\\pfui\\fonts\\diediedie.ttf"] = {
    ["0"] = {-393, 369},
    ["1"] = {-481, 369},
    ["2"] = {-337, 369},
    ["3"] = {-445, 380},
    ["4"] = {-398, 406},
    ["5"] = {-419, 369},
    ["6"] = {-310, 369},
    ["7"] = {-432, 369},
    ["8"] = {-380, 373},
    ["9"] = {-412, 369},
    ["/"] = {-503, 369},
    ["%"] = {-400, 458},
    ["."] = {151, 369},
    [","] = {123, 400},
    ["-"] = {-91, 369},
  },
  ["interface\\addons\\pfui\\fonts\\expressway.ttf"] = {
    ["0"] = {-324, 394},
    ["1"] = {-311, 381},
    ["2"] = {-324, 381},
    ["3"] = {-318, 387},
    ["4"] = {-311, 381},
    ["5"] = {-311, 387},
    ["6"] = {-316, 387},
    ["7"] = {-311, 381},
    ["8"] = {-317, 387},
    ["9"] = {-317, 386},
    ["/"] = {-310, 454},
    ["%"] = {-317, 388},
    ["."] = {266, 394},
    [","] = {276, 535},
    ["-"] = {61, 381},
  },
  ["interface\\addons\\pfui\\fonts\\homespun.ttf"] = {
    ["0"] = {-299, 401},
    ["1"] = {-299, 401},
    ["2"] = {-299, 401},
    ["3"] = {-299, 401},
    ["4"] = {-299, 401},
    ["5"] = {-299, 401},
    ["6"] = {-299, 401},
    ["7"] = {-299, 401},
    ["8"] = {-299, 401},
    ["9"] = {-299, 401},
    ["/"] = {-299, 401},
    ["%"] = {-299, 401},
    ["."] = {301, 401},
    [","] = {301, 500},
    ["-"] = {1, 401},
  },
  ["interface\\addons\\pfui\\fonts\\hooge.ttf"] = {
    ["0"] = {-312, 313},
    ["1"] = {-312, 313},
    ["2"] = {-312, 313},
    ["3"] = {-312, 313},
    ["4"] = {-312, 313},
    ["5"] = {-312, 313},
    ["6"] = {-312, 313},
    ["7"] = {-312, 313},
    ["8"] = {-312, 313},
    ["9"] = {-312, 313},
    ["/"] = {-312, 313},
    ["%"] = {-312, 313},
    ["."] = {188, 313},
    [","] = {188, 438},
    ["-"] = {-62, 313},
  },
  ["interface\\addons\\pfui\\fonts\\myriad-pro.ttf"] = {
    ["0"] = {-408, 258},
    ["1"] = {-400, 250},
    ["2"] = {-408, 250},
    ["3"] = {-408, 258},
    ["4"] = {-400, 250},
    ["5"] = {-400, 258},
    ["6"] = {-408, 258},
    ["7"] = {-400, 250},
    ["8"] = {-408, 258},
    ["9"] = {-408, 258},
    ["/"] = {-432, 290},
    ["%"] = {-411, 261},
    ["."] = {110, 258},
    [","] = {114, 375},
    ["-"] = {-57, 250},
  },
  ["interface\\addons\\pfui\\fonts\\pt-sans-narrow-bold.ttf"] = {
    ["0"] = {-343, 385},
    ["1"] = {-341, 371},
    ["2"] = {-343, 371},
    ["3"] = {-329, 385},
    ["4"] = {-334, 371},
    ["5"] = {-329, 385},
    ["6"] = {-343, 385},
    ["7"] = {-329, 371},
    ["8"] = {-343, 385},
    ["9"] = {-343, 385},
    ["/"] = {-341, 511},
    ["%"] = {-343, 385},
    ["."] = {231, 382},
    [","] = {233, 518},
    ["-"] = {25, 371},
  },
  ["interface\\addons\\pfui\\fonts\\pt-sans-narrow-regular.ttf"] = {
    ["0"] = {-341, 383},
    ["1"] = {-341, 371},
    ["2"] = {-341, 371},
    ["3"] = {-329, 383},
    ["4"] = {-340, 371},
    ["5"] = {-329, 383},
    ["6"] = {-341, 383},
    ["7"] = {-329, 371},
    ["8"] = {-341, 383},
    ["9"] = {-341, 383},
    ["/"] = {-341, 511},
    ["%"] = {-342, 383},
    ["."] = {270, 383},
    [","] = {273, 518},
    ["-"] = {51, 371},
  },
  ["interface\\addons\\pfui\\fonts\\robotomono.ttf"] = {
    ["0"] = {-333, 399},
    ["1"] = {-322, 389},
    ["2"] = {-332, 389},
    ["3"] = {-332, 399},
    ["4"] = {-322, 389},
    ["5"] = {-322, 399},
    ["6"] = {-328, 399},
    ["7"] = {-322, 389},
    ["8"] = {-332, 399},
    ["9"] = {-332, 395},
    ["/"] = {-322, 451},
    ["%"] = {-333, 400},
    ["."] = {298, 395},
    [","] = {297, 534},
    ["-"] = {46, 389},
  },
}
-- END GENERATED RESOURCE FONT METRICS
pfUI.api.ResourceBarFontMetrics = metrics

local function InkOffset(file, size, value)
  if type(file) ~= "string" or type(value) ~= "string" then return 0 end
  local path = string.lower((string.gsub(file, "/", "\\")))
  local glyphs = metrics[path]
  if not glyphs then return 0 end
  local top, bottom
  for i = 1, string.len(value) do
    local char = string.sub(value, i, i)
    if char ~= " " then
      local glyph = glyphs[char]
      if not glyph then return 0 end
      top = top and math.min(top, glyph[1]) or glyph[1]
      bottom = bottom and math.max(bottom, glyph[2]) or glyph[2]
    end
  end
  -- Pillow grows down from its mm anchor; positive WoW y moves up.
  return top and (top + bottom) * size / 2000 or 0
end

function pfUI.api.AlignResourceBarText(text, track, align, requestedSize)
  local file, size = text:GetFont()
  size = tonumber(size) or tonumber(requestedSize) or 12
  if size <= 0 or size ~= size or size == math.huge then size = 12 end
  align = type(align) == "string" and string.upper(align) or "CENTER"
  if align ~= "LEFT" and align ~= "RIGHT" then align = "CENTER" end
  local value = text:GetText() or ""
  local width = math.max(1, track:GetWidth())
  local height = math.max(track:GetHeight(), size + 4)
  local offset = InkOffset(file, size, value)
  local previous = text.resourceBarLayout
  if previous and previous.track == track and previous.width == width and previous.height == height
    and previous.align == align and previous.file == file and previous.size == size and previous.offset == offset then
    return offset
  end
  text:SetWidth(width)
  text:SetHeight(height)
  text:SetJustifyH(align)
  text:SetJustifyV("MIDDLE")
  text:ClearAllPoints()
  text:SetPoint(align, track, align, 0, offset)
  text.resourceBarLayout = {track = track, width = width, height = height, align = align,
    file = file, size = size, offset = offset}
  return offset
end
