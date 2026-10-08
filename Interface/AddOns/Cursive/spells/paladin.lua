local L = AceLibrary("AceLocale-2.2"):new("Cursive")
function getPaladinSpells()
	return {
		[2878] = { name = L["turn undead"], rank = 1, duration = 10 },
		[5627] = { name = L["turn undead"], rank = 2, duration = 15 },
		[10326] = { name = L["turn undead"], rank = 3, duration = 20 },

		[853] = { name = L["hammer of justice"], rank = 1, duration = 3 },
		[5588] = { name = L["hammer of justice"], rank = 2, duration = 4 },
		[5589] = { name = L["hammer of justice"], rank = 3, duration = 5 },
		[10308] = { name = L["hammer of justice"], rank = 4, duration = 6 },

		[20186] = { name = L["judgement of wisdom"], rank = 1, duration = 10 },
		[20354] = { name = L["judgement of wisdom"], rank = 2, duration = 10 },
		[20355] = { name = L["judgement of wisdom"], rank = 3, duration = 10 },
		[51751] = { name = L["judgement of wisdom"], rank = 4, duration = 10 },
		[51752] = { name = L["judgement of wisdom"], rank = 5, duration = 10 },

		[21183] = { name = L["judgement of the crusader"], rank = 1, duration = 10 },
		[20188] = { name = L["judgement of the crusader"], rank = 2, duration = 10 },
		[20300] = { name = L["judgement of the crusader"], rank = 3, duration = 10 },
		[20301] = { name = L["judgement of the crusader"], rank = 4, duration = 10 },
		[20302] = { name = L["judgement of the crusader"], rank = 5, duration = 10 },
		[20303] = { name = L["judgement of the crusader"], rank = 6, duration = 10 },		

		[20184] = { name = L["judgement of justice"], rank = 1, duration = 10 },

		[20267] = { name = L["judgement of light"], rank = 1, duration = 10 },
		[20341] = { name = L["judgement of light"], rank = 2, duration = 10 },
		[20342] = { name = L["judgement of light"], rank = 3, duration = 10 },
		[20343] = { name = L["judgement of light"], rank = 4, duration = 10 },
	}
end
