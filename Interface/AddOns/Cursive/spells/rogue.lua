function getGougeDuration()
	-- Improved Gouge: +.5s per talent
	local _, _, _, _, count = GetTalentInfo(2, 1)
	if count and count > 0 then
		return 4 + (count * .5)
	end

	return 4
end

function getRuptureDuration()
	local duration = 6 + Cursive.curses.GetComboPointsUsed() * 2
	local _, _, _, _, count = GetTalentInfo(1, 10)
	if count and count > 0 then
		if count == 1 then -- 修改 1.18.1之后，盗贼血腥气息天赋 1点4秒，2点6秒 by 武藤纯子酱 2026.4.1
			return duration + 4
		else
			return duration + 6	
		end
	end

	return duration
end

function getKidneyShotDuration()
	return 1 + Cursive.curses.GetComboPointsUsed()
end

local L = AceLibrary("AceLocale-2.2"):new("Cursive")
function getRogueSpells()
	return {
		[2094] = { name = L["blind"], rank = 1, duration = 10 },
		[21060] = { name = L["blind"], rank = 1, duration = 10 },

		[6770] = { name = L["sap"], rank = 1, duration = 25 },
		[2070] = { name = L["sap"], rank = 2, duration = 35 },
		[11297] = { name = L["sap"], rank = 3, duration = 45 },

		[1776] = { name = L["gouge"], rank = 1, duration = 4, calculateDuration = getGougeDuration },
		[1777] = { name = L["gouge"], rank = 2, duration = 4, calculateDuration = getGougeDuration },
		[8629] = { name = L["gouge"], rank = 3, duration = 4, calculateDuration = getGougeDuration },
		[11285] = { name = L["gouge"], rank = 4, duration = 4, calculateDuration = getGougeDuration },
		[11286] = { name = L["gouge"], rank = 5, duration = 4, calculateDuration = getGougeDuration },

		[1943] = { name = L["rupture"], rank = 1, duration = 6, calculateDuration = getRuptureDuration, meleeBleed=true },
		[8639] = { name = L["rupture"], rank = 2, duration = 6, calculateDuration = getRuptureDuration, meleeBleed=true },
		[8640] = { name = L["rupture"], rank = 3, duration = 6, calculateDuration = getRuptureDuration, meleeBleed=true },
		[11273] = { name = L["rupture"], rank = 4, duration = 6, calculateDuration = getRuptureDuration, meleeBleed=true },
		[11274] = { name = L["rupture"], rank = 5, duration = 6, calculateDuration = getRuptureDuration, meleeBleed=true },
		[11275] = { name = L["rupture"], rank = 6, duration = 6, calculateDuration = getRuptureDuration, meleeBleed=true },

		[408] = { name = L["kidney shot"], rank = 1, duration = 1, calculateDuration = getKidneyShotDuration },
		[8643] = { name = L["kidney shot"], rank = 2, duration = 1, calculateDuration = getKidneyShotDuration },

		[8647] = { name = L["expose armor"], rank = 1, duration = 30 }, -- this is a shared debuff but almost always only done by 1 rogue
		[8649] = { name = L["expose armor"], rank = 2, duration = 30 },
		[8650] = { name = L["expose armor"], rank = 3, duration = 30 },
		[11197] = { name = L["expose armor"], rank = 4, duration = 30 },
		[11198] = { name = L["expose armor"], rank = 5, duration = 30 },

		[703] = { name = L["garrote"], rank = 1, duration = 18, meleeBleed=true },
		[8631] = { name = L["garrote"], rank = 2, duration = 18, meleeBleed=true },
		[8632] = { name = L["garrote"], rank = 3, duration = 18, meleeBleed=true },
		[8633] = { name = L["garrote"], rank = 4, duration = 18, meleeBleed=true },
		[11289] = { name = L["garrote"], rank = 5, duration = 18, meleeBleed=true },
		[11290] = { name = L["garrote"], rank = 6, duration = 18, meleeBleed=true },

		[2818] = { name = L["deadly poison"], rank = 1, duration = 12 },
		[2819] = { name = L["deadly poison ii"], rank = 2, duration = 12 },
		[11353] = { name = L["deadly poison iii"], rank = 3, duration = 12 },
		[11354] = { name = L["deadly poison iv"], rank = 4, duration = 12 },
		[25349] = { name = L["deadly poison v"], rank = 5, duration = 12 },

		[51922] = { name = L["corrosive poison"], rank = 1, duration = 12 },
		[52574] = { name = L["corrosive poison ii"], rank = 2, duration = 12 },

		[16511] = { name = L["hemorrhage"], rank = 1, duration = 15 },

		[1833] = { name = L["cheap shot"], rank = 1, duration = 4 },
		[14902] = { name = L["cheap shot"], rank = 1, duration = 4 },
		-- 新增 by 武藤纯子酱 2025.8.28
		[5760] = { name = L["mind-numbing poison"], rank = 1, duration = 10 },
		[8692] = { name = L["mind-numbing poison ii"], rank = 2, duration = 10 },	
		[11398] = { name = L["mind-numbing poison iii"], rank = 3, duration = 10 },

		[3409] = { name = L["crippling poison"], rank = 1, duration = 12 },
		[11201] = { name = L["crippling poison ii"], rank = 2, duration = 12 },

		[13218] = { name = L["wound poison"], rank = 1, duration = 15 },
		[13222] = { name = L["wound poison ii"], rank = 2, duration = 15 },
		[13223] = { name = L["wound poison iii"], rank = 3, duration = 15 },
		[13224] = { name = L["wound poison iv"], rank = 4, duration = 15 },	
	}
end
