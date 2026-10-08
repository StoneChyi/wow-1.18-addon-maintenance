local L = AceLibrary("AceLocale-2.2"):new("Cursive")
function getWarlockSpells()
	return {
		[172] = { name = L["corruption"], rank = 1, duration = 12, variableDuration = true, darkHarvest = true, numTicks=4},
		[6222] = { name = L["corruption"], rank = 2, duration = 15, variableDuration = true, darkHarvest = true, numTicks=5 },
		[6223] = { name = L["corruption"], rank = 3, duration = 18, variableDuration = true, darkHarvest = true, numTicks=6 },
		[7648] = { name = L["corruption"], rank = 4, duration = 18, variableDuration = true, darkHarvest = true, numTicks=6 },
		[11671] = { name = L["corruption"], rank = 5, duration = 18, variableDuration = true, darkHarvest = true, numTicks=6 },
		[11672] = { name = L["corruption"], rank = 6, duration = 18, variableDuration = true, darkHarvest = true, numTicks=6 },
		[25311] = { name = L["corruption"], rank = 7, duration = 18, variableDuration = true, darkHarvest = true, numTicks=6 },

		[980] = { name = L["curse of agony"], rank = 1, duration = 24, variableDuration = true, darkHarvest = true, numTicks=12 },
		[1014] = { name = L["curse of agony"], rank = 2, duration = 24, variableDuration = true, darkHarvest = true, numTicks=12 },
		[6217] = { name = L["curse of agony"], rank = 3, duration = 24, variableDuration = true, darkHarvest = true, numTicks=12 },
		[11711] = { name = L["curse of agony"], rank = 4, duration = 24, variableDuration = true, darkHarvest = true, numTicks=12 },
		[11712] = { name = L["curse of agony"], rank = 5, duration = 24, variableDuration = true, darkHarvest = true, numTicks=12 },
		[11713] = { name = L["curse of agony"], rank = 6, duration = 24, variableDuration = true, darkHarvest = true, numTicks=12 },

		[18265] = { name = L["siphon life"], rank = 1, duration = 30, variableDuration = true, darkHarvest = true, numTicks=10 },
		[18879] = { name = L["siphon life"], rank = 2, duration = 30, variableDuration = true, darkHarvest = true, numTicks=10 },
		[18880] = { name = L["siphon life"], rank = 3, duration = 30, variableDuration = true, darkHarvest = true, numTicks=10 },
		[18881] = { name = L["siphon life"], rank = 4, duration = 30, variableDuration = true, darkHarvest = true, numTicks=10 },

		[52550] = { name = L["dark harvest"], rank = 1, duration = 8, variableDuration = true }, -- 保留暗影收割 by 武藤纯子酱 2026.3.20
		[52551] = { name = L["dark harvest"], rank = 2, duration = 8, variableDuration = true }, -- 保留暗影收割 by 武藤纯子酱 2026.3.20
		[52552] = { name = L["dark harvest"], rank = 3, duration = 8, variableDuration = true }, -- 保留暗影收割 by 武藤纯子酱 2026.3.20

		[603] = { name = L["curse of doom"], rank = 1, duration = 60 },

		[704] = { name = L["curse of recklessness"], rank = 1, duration = 120 },
		[7658] = { name = L["curse of recklessness"], rank = 2, duration = 120 },
		[7659] = { name = L["curse of recklessness"], rank = 3, duration = 120 },
		[11717] = { name = L["curse of recklessness"], rank = 4, duration = 120 },

		[17862] = { name = L["curse of shadow"], rank = 1, duration = 300 },
		[17937] = { name = L["curse of shadow"], rank = 2, duration = 300 },

		[1490] = { name = L["curse of the elements"], rank = 1, duration = 300 },
		[11721] = { name = L["curse of the elements"], rank = 2, duration = 300 },
		[11722] = { name = L["curse of the elements"], rank = 3, duration = 300 },

		[1714] = { name = L["curse of tongues"], rank = 1, duration = 30 },
		[11719] = { name = L["curse of tongues"], rank = 2, duration = 30 },

		[702] = { name = L["curse of weakness"], rank = 1, duration = 120 },
		[1108] = { name = L["curse of weakness"], rank = 2, duration = 120 },
		[6205] = { name = L["curse of weakness"], rank = 3, duration = 120 },
		[7646] = { name = L["curse of weakness"], rank = 4, duration = 120 },
		[11707] = { name = L["curse of weakness"], rank = 5, duration = 120 },
		[11708] = { name = L["curse of weakness"], rank = 6, duration = 120 },

		[18223] = { name = L["curse of exhaustion"], rank = 1, duration = 12 },

		[348] = { name = L["immolate"], rank = 1, duration = 15 },
		[707] = { name = L["immolate"], rank = 2, duration = 15 },
		[1094] = { name = L["immolate"], rank = 3, duration = 15 },
		[2941] = { name = L["immolate"], rank = 4, duration = 15 },
		[11665] = { name = L["immolate"], rank = 5, duration = 15 },
		[11667] = { name = L["immolate"], rank = 6, duration = 15 },
		[11668] = { name = L["immolate"], rank = 7, duration = 15 },
		[25309] = { name = L["immolate"], rank = 8, duration = 15 },

		[6789] = { name = L["death coil"], rank = 1, duration = 3, travelTime = true, variableDuration = true }, -- 添加动态监测 by 武藤纯子酱 2026.2.3
		[17925] = { name = L["death coil"], rank = 2, duration = 3, travelTime = true, variableDuration = true }, -- 添加动态监测 by 武藤纯子酱 2026.2.3
		[17926] = { name = L["death coil"], rank = 3, duration = 3, travelTime = true, variableDuration = true }, -- 添加动态监测 by 武藤纯子酱 2026.2.3

		[710] = { name = L["banish"], rank = 1, duration = 20, variableDuration = true }, -- 添加动态监测 by 武藤纯子酱 2026.2.3
		[18647] = { name = L["banish"], rank = 2, duration = 30, variableDuration = true }, -- 添加动态监测 by 武藤纯子酱 2026.2.3

		[5782] = { name = L["fear"], rank = 1, duration = 10, variableDuration = true }, -- 添加动态监测 by 武藤纯子酱 2026.2.3
		[6213] = { name = L["fear"], rank = 2, duration = 15, variableDuration = true }, -- 添加动态监测 by 武藤纯子酱 2026.2.3
		[6215] = { name = L["fear"], rank = 3, duration = 20, variableDuration = true }, -- 添加动态监测 by 武藤纯子酱 2026.2.3

		[58183] = { name = L["parasite of aln"], rank = 1, duration = 24, variableDuration = true }, -- 添加动态监测 by 武藤纯子酱 2026.4.3

		--诱惑（宠物技能） -by 武藤纯子酱 2025.8.30
		[6358] = { name = L["seduction"], rank = 1, duration = 14, variableDuration = true }, -- 添加动态监测 by 武藤纯子酱 2026.2.3
		--法术封锁（宠物技能） -by 武藤纯子酱 2025.8.30
		[19244] = { name = L["spell lock"], rank = 1, duration = 3, variableDuration = true }, -- 添加动态监测 by 武藤纯子酱 2026.2.3
		[19647] = { name = L["spell lock"], rank = 2, duration = 3, variableDuration = true }, -- 添加动态监测 by 武藤纯子酱 2026.2.3
	}
end
