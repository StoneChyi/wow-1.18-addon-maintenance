local L = AceLibrary("AceLocale-2.2"):new("Cursive")
function getShamanSpells()
	return {
		[8050] = { name = L["flame shock"], rank = 1, duration = 15, variableDuration = true },
		[8052] = { name = L["flame shock"], rank = 2, duration = 15, variableDuration = true },
		[8053] = { name = L["flame shock"], rank = 3, duration = 15, variableDuration = true },
		[10447] = { name = L["flame shock"], rank = 4, duration = 15, variableDuration = true },
		[10448] = { name = L["flame shock"], rank = 5, duration = 15, variableDuration = true },
		[29228] = { name = L["flame shock"], rank = 6, duration = 15, variableDuration = true },
		--新增 冰霜震击、妖术追踪 by 武藤纯子酱 2025.8.28			
		[8056] = { name = L["frost shock"], rank = 1, duration = 8, variableDuration = true },
		[8058] = { name = L["frost shock"], rank = 2, duration = 8, variableDuration = true },
		[10472] = { name = L["frost shock"], rank = 3, duration = 8, variableDuration = true },
		[10473] = { name = L["frost shock"], rank = 4, duration = 8, variableDuration = true },	
		
		[45504] = { name = L["hex"], rank = 1, duration = 4, variableDuration = true },	
	}
end
