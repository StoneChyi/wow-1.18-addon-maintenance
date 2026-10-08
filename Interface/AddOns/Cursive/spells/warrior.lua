local L = AceLibrary("AceLocale-2.2"):new("Cursive")
function getWarriorSpells()
	return {
		--撕裂
		[772] = { name = L["rend"], rank = 1, duration = 9, meleeBleed=true },
		[6546] = { name = L["rend"], rank = 2, duration = 12, meleeBleed=true },
		[6547] = { name = L["rend"], rank = 3, duration = 15, meleeBleed=true },
		[6548] = { name = L["rend"], rank = 4, duration = 18, meleeBleed=true },
		[11572] = { name = L["rend"], rank = 5, duration = 21, meleeBleed=true },
		[11573] = { name = L["rend"], rank = 6, duration = 21, meleeBleed=true },
		[11574] = { name = L["rend"], rank = 7, duration = 21, meleeBleed=true },
		
		--致死打击 -by 武藤纯子酱 2025.8.29
		[12294] = { name = L["mortal strike"], rank = 1, duration = 10, variableDuration = true },
		[21551] = { name = L["mortal strike"], rank = 2, duration = 10, variableDuration = true },
		[21552] = { name = L["mortal strike"], rank = 3, duration = 10, variableDuration = true },
		[21553] = { name = L["mortal strike"], rank = 4, duration = 10, variableDuration = true },			
			
		--破甲攻击 -by 武藤纯子酱 2025.8.29
		[7386] = { name = L["sunder armor"], rank = 1, duration = 30, variableDuration = true },
		[7405] = { name = L["sunder armor"], rank = 2, duration = 30, variableDuration = true },
		[8380] = { name = L["sunder armor"], rank = 3, duration = 30, variableDuration = true },
		[11596] = { name = L["sunder armor"], rank = 4, duration = 30, variableDuration = true },
		[11597] = { name = L["sunder armor"], rank = 5, duration = 30, variableDuration = true },			
			
		--反击 -by 武藤纯子酱 2025.8.29
		[19306] = { name = L["counterattack"], rank = 1, duration = 5, variableDuration = true },
		[20909] = { name = L["counterattack"], rank = 2, duration = 5, variableDuration = true },
		[20910] = { name = L["counterattack"], rank = 3, duration = 5, variableDuration = true },			
			
		--震荡猛击 -by 武藤纯子酱 2025.8.29
		[12809] = { name = L["concussion blow"], rank = 1, duration = 3, variableDuration = true },				
			
		--断筋 -by 武藤纯子酱 2025.8.29
		[1715] = { name = L["hamstring"], rank = 1, duration = 15, variableDuration = true },
		[7372] = { name = L["hamstring"], rank = 2, duration = 15, variableDuration = true },
		[7373] = { name = L["hamstring"], rank = 3, duration = 15, variableDuration = true },			
			
		--缴械 -by 武藤纯子酱 2025.8.29
		[676] = { name = L["disarm"], rank = 1, duration = 10, variableDuration = true },			
			
		--雷霆一击 -by 武藤纯子酱 2025.8.29
		[8147] = { name = L["thunderclap"], rank = 1, duration = 10, variableDuration = true },
		[8198] = { name = L["thunderclap"], rank = 2, duration = 14, variableDuration = true },
		[8204] = { name = L["thunderclap"], rank = 3, duration = 18, variableDuration = true },
		[8205] = { name = L["thunderclap"], rank = 4, duration = 22, variableDuration = true },
		[11580] = { name = L["thunderclap"], rank = 5, duration = 26, variableDuration = true },
		[11581] = { name = L["thunderclap"], rank = 6, duration = 30, variableDuration = true },			
			
		--挫志怒吼 -by 武藤纯子酱 2025.8.29
		[1160] = { name = L["demoralizing shout"], rank = 1, duration = 30, variableDuration = true },
		[6190] = { name = L["demoralizing shout"], rank = 2, duration = 30, variableDuration = true },
		[11554] = { name = L["demoralizing shout"], rank = 3, duration = 30, variableDuration = true },
		[11555] = { name = L["demoralizing shout"], rank = 4, duration = 30, variableDuration = true },
		[11556] = { name = L["demoralizing shout"], rank = 5, duration = 30, variableDuration = true },			
					
		--惩戒痛击 -by 武藤纯子酱 2025.8.29
		[7382] = { name = L["mocking blow"], rank = 1, duration = 6, variableDuration = true },
		[7400] = { name = L["mocking blow"], rank = 2, duration = 6, variableDuration = true },
		[7402] = { name = L["mocking blow"], rank = 3, duration = 6, variableDuration = true },
		[20559] = { name = L["mocking blow"], rank = 4, duration = 6, variableDuration = true },
		[20560] = { name = L["mocking blow"], rank = 5, duration = 6, variableDuration = true },			
			
		--破胆怒吼 -by 武藤纯子酱 2025.8.29
		[5246] = { name = L["intimidating shout"], rank = 1, duration = 8, variableDuration = true },			
			
		--嘲讽 -by 武藤纯子酱 2025.8.29
		[355] = { name = L["taunt"], rank = 1, duration = 3, variableDuration = true },			
			
		--刺耳怒吼 -by 武藤纯子酱 2025.8.29
		[12323] = { name = L["piercing howl"], rank = 1, duration = 6, variableDuration = true },						
			
		--复仇昏迷 -by 武藤纯子酱 2025.8.29
		[12798] = { name = L["revenge stun"], rank = 1, duration = 3, variableDuration = true },			
			
		--冲锋 -by 武藤纯子酱 2025.8.29
		[100] = { name = L["charge"], rank = 1, duration = 1, variableDuration = true },
		[6178] = { name = L["charge"], rank = 2, duration = 1, variableDuration = true },
		[11578] = { name = L["charge"], rank = 3, duration = 1, variableDuration = true },				
			
		--拦截 -by 武藤纯子酱 2025.8.29
		[20252] = { name = L["intercept"], rank = 1, duration = 3, variableDuration = true },
		[20616] = { name = L["intercept"], rank = 2, duration = 3, variableDuration = true },
		[20617] = { name = L["intercept"], rank = 3, duration = 3, variableDuration = true },				
	}
end
