-- Notes
-- Following datas are not being syncronized.
-- Threat
-- Fails
local DPSMateX = DPSMateX

local pid = 0
local time, iterator, voteStarter = 0, 1, false
local t = {}
local strgsub = string.gsub
local strgfind = string.gfind
local tinsert = table.insert
local tremove = table.remove
local tnbr = tonumber

--local SDM = SendAddonMessage
local function SDM(a,b,c,d)
	if DPSMateX.Settings["sync"] then
		SendAddonMessage(a, b, c, d)
	end
end

local func = function(c) tinsert(t,c) end
local LastMouseover = nil
local DB = DPSMateX.DB
local Buffer = {}
local sname = GetRealmName()
local GT = GetTime
local Arrays = {
	[1] = {}, -- Damage
	[2] = {}, -- Damage Taken
	[3] = {}, -- EDD
	[4] = {}, -- EDT
	[5] = {}, -- Healing done
	[6] = {}, -- E Healing done
	[7] = {}, -- Healing taken
	[8] = {}, -- E Healing taken
	[9] = {}, -- Overhealing done
	[10] = {}, -- Absorbs
	[11] = {}, -- Deaths
	[12] = {}, -- Interrupts
	[13] = {}, -- Dispels
	[14] = {}, -- Auras
	[15] = {}, -- O Healing taken
	[16] = {} -- Threat
}
DPSMateX.Sync.synckey = ""
local sKey = DPSMateX.SYNCVERSION
local pairs = pairs
local UnitName = UnitName
local UnitIsPlayer = UnitIsPlayer
local ceil = ceil
local user, userid, userid2, userid3, userid4, ab, abid, usid
local trivial, lesstrivial, important, Execute = nil, nil, nil, {}

local strsub = string.sub
local strfind = string.find
local UnitAffectingCombat = UnitAffectingCombat

-- Beginn Functions

function DPSMateX.Sync:OnLoad()
	pid = DPSMateX.CacheUser[DPSMateX.Parser.playername][1]
	Execute = {}
	for cat, val in pairs(important) do
		Execute[cat..sKey] = val
	end
end

local co, cou = 1, 1
local updater = 0
function DPSMateX.Sync:OnUpdate()
	if DPSMateX.Settings["sync"] then
		time=time+arg1
		if time<30 then
			if iterator==1 then
				Buffer = {}
				Buffer[1] = {"DPSMateX_SyncStatus", "1"}
				cou = 1
				co = 1
				self:DMGDoneAllOut()
				self:DMGDoneAbilityOut()
				self:DMGDoneStatOut()
				iterator = 2
			elseif time>=3 and iterator==2 then
				self:HealingAllOut(DPSMateX.DBCache.EHealing, "E")
				self:HealingAbilityOut(DPSMateX.DBCache.EHealing, "E")
				self:HealingStatOut(DPSMateX.DBCache.EHealing, "E")
				self:AbsorbsOut() 
				self:AbsorbsStatOut()
				iterator = 3
			elseif time>=6 and iterator==3 then
				self:AurasOut()
				self:DeathsAllOut()
				self:DeathsOut()
				self:DispelsOut()
				iterator = 4
			elseif time>=9 and iterator==4 then
				self:EDAllOut(DPSMateX.DBCache.EDD, "D")
				self:EDAbilityOut(DPSMateX.DBCache.EDD, "D")
				self:EDStatOut(DPSMateX.DBCache.EDD, "D")
				iterator = 5
			elseif time>=12 and iterator==5 then
				self:HealingAllOut(DPSMateX.DBCache.THealing, "T")
				self:HealingAbilityOut(DPSMateX.DBCache.THealing, "T")
				self:HealingStatOut(DPSMateX.DBCache.THealing, "T")
				self:InterruptsAllOut()
				self:InterruptsAbilityOut()
				iterator = 6
			elseif time>=15 and iterator==6 then
				self:DMGTakenAllOut()
				self:DMGTakenAbilityOut()
				self:DMGTakenStatOut()
				iterator = 7
			elseif time>=18 and iterator==7 then
				self:HealingAllOut(DPSMateX.DBCache.EHealingTaken, "ETaken")
				self:HealingTakenAbilityOut(DPSMateX.DBCache.EHealingTaken, "E")
				self:HealingTakenStatOut(DPSMateX.DBCache.EHealingTaken, "ETaken")
				self:HealingAllOut(DPSMateX.DBCache.OverhealingTaken, "OTaken")
				self:HealingTakenAbilityOut(DPSMateX.DBCache.OverhealingTaken, "O")
				self:HealingTakenStatOut(DPSMateX.DBCache.OverhealingTaken, "OTaken")
				iterator = 8
			elseif time>=21 and iterator==8 then
				self:HealingAllOut(DPSMateXOverhealing, "O")
				self:HealingAbilityOut(DPSMateXOverhealing, "O")
				self:HealingStatOut(DPSMateXOverhealing, "O")
				iterator = 9
			elseif time>=24 and iterator==9 then
				self:HealingAllOut(DPSMateX.DBCache.HealingTaken, "TTaken")
				self:HealingTakenAbilityOut(DPSMateX.DBCache.HealingTaken, "T")
				self:HealingTakenStatOut(DPSMateX.DBCache.HealingTaken, "TTaken")
				iterator = 10
			elseif time>=27 and iterator==10 then
				self:EDAllOut(DPSMateX.DBCache.EDT, "T")
				self:EDAbilityOut(DPSMateX.DBCache.EDT, "T")
				self:EDStatOut(DPSMateX.DBCache.EDT, "T")
				iterator = 11
			elseif time>=30 and iterator==11 then
				self:ThreatOut()
				self:ThreatStatsOut()
				Buffer[cou] = {"DPSMateX_SyncStatus", "0"}
				cou = cou + 1
			end
		elseif time>180 then
			iterator, time = 1, 0
		end
		if Buffer[co] and updater>0.1 and not UnitAffectingCombat("player") then
			SDM(Buffer[co][1]..sKey, Buffer[co][2], "RAID")
			Buffer[co] = nil
			co = co + 1
			updater = 0
		end
		updater = updater + arg1
	else
		iterator, time = 1, 0
	end
	self:DismissVote(arg1)
end

----------------------------------------------------------------------------------
--------------                       GENERAL                        --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:GetSummarizedTable(arr)
	local newArr, i, dmg, time, dis = {}, 1, 0, nil, 1
	local TL = DPSMateX:TableLength(arr)
	if TL>100 then dis = floor(TL/100) end
	for cat, val in pairs(arr) do
		if dis>1 then
			dmg=dmg+val[2]
			if time then
				if i>dis and (val[1]-time)>0 then
					tinsert(newArr, {(val[1]+time)/2, dmg/(val[1]-time)}) -- last time val // subtracting from each other to get the time in which the damage is being done
					time, dmg, i = nil, 0, 1
				end
			else
				time=val[1]
			end
		else
			tinsert(newArr, val)
		end
		i=i+1
	end
	return newArr
end

function DPSMateX.Sync:Vote()
	DPSMateX_Vote:Hide()
	SDM("DPSMateX_Vote"..DPSMateX.SYNCVERSION, nil, "RAID")
end

local voteCount = 1
local participants = 1
local abort = 0
function DPSMateX.Sync:StartVote()
	if not voteStarter then
		self.synckey = DPSMateX.Parser.playername..(random(1,1000))
		SDM("DPSMateX_StartVote"..DPSMateX.SYNCVERSION, nil, "RAID")
		voteStarter = true
		participants = 1
	else
		DPSMateX:SendMessage(DPSMateX.L["votestartederror"])
	end
end

function DPSMateX.Sync:CountVote()
	if voteStarter then
		voteCount=voteCount+1
		if voteCount >= (participants/2) then
			SDM("DPSMateX_VoteSuccess"..DPSMateX.SYNCVERSION, self.synckey, "RAID")
			sKey = DPSMateX.SYNCVERSION..self.synckey
			Execute = {}
			for cat, val in pairs(important) do
				Execute[cat..sKey] = val
			end
			voteStarter = false
			voteCount = 1
			participants = 1
			local num = GetNumRaidMembers()
			if num > 0 then
				for i=1, num-1 do
					SDM("DPSMateX_SyncTimer"..DPSMateX.SYNCVERSION, UnitName("raid"..i)..","..(ceil(i/8)*30 - 30)..",", "RAID")
				end
			end
			DB.MainUpdate = ceil(num/8)*30 - 30
			self:VoteSuccess()
		end
	end
end

local voteTime = 0
function DPSMateX.Sync:DismissVote(elapsed)
	if voteStarter then
		voteTime=voteTime+elapsed
		if voteTime>=30 then
			SDM("DPSMateX_VoteFail"..DPSMateX.SYNCVERSION, nil, "RAID")
			voteStarter = false
			voteCount = 1
			voteTime = 0
			participants = 1
			self.synckey = ""
			sKey = DPSMateX.SYNCVERSION..self.synckey
			DPSMateX:SendMessage(DPSMateX.L["votefailederror"])
		elseif voteTime>=3 and participants==1 then
			voteStarter = false
			voteCount = 1
			voteTime = 0
			self:VoteSuccess()
		end
	end
end

function DPSMateX.Sync:VoteSuccess(key)
	DPSMateX:SendMessage(DPSMateX.L["votesuccess"])
	self.synckey = key or ""
	sKey = DPSMateX.SYNCVERSION..self.synckey
	Execute = {}
	for cat, val in pairs(important) do
		Execute[cat..sKey] = val
	end
	DPSMateX.DB.MainUpdate = 75
	self.Async, iterator, time = false, 1, 0
	UpTime = -5
	Buffer = {}
	co, cou = 1, 1
	Arrays = {
		[1] = {}, -- Damage
		[2] = {}, -- Damage Taken
		[3] = {}, -- EDD
		[4] = {}, -- EDT
		[5] = {}, -- Healing done
		[6] = {}, -- E Healing done
		[7] = {}, -- Healing taken
		[8] = {}, -- E Healing taken
		[9] = {}, -- Overhealing done
		[10] = {}, -- Absorbs
		[11] = {}, -- Deaths
		[12] = {}, -- Interrupts
		[13] = {}, -- Dispels
		[14] = {}, -- Auras
		[15] = {}, -- O Healing taken
		[16] = {} -- Threat
	}
	DPSMateX.Options:PopUpAccept(true, true)
end

function DPSMateX.Sync:SetTimer(arg2)
	t = {}
	strgsub(arg2, "(.-),", func)
	if t[1] == DPSMateX.Parser.playername then
		DB.MainUpdate = tnbr(t[2])
	end
end

function DPSMateX.Sync:CountParticipants()
	if voteStarter then
		participants=participants+1
	end
end

function DPSMateX.Sync:Participate()
	SDM("DPSMateX_Participate"..DPSMateX.SYNCVERSION, nil, "RAID")
end

function DPSMateX.Sync:ReceiveStartVote() 
	self:Participate()
	if DPSMateX.Settings["dataresetssync"] == 3 then
		DPSMateX_Vote:Show()
	elseif DPSMateX.Settings["dataresetssync"] == 1 then
		self:Vote()
	end
end

function DPSMateX.Sync:AbortVote()
	if IsPartyLeader() or IsRaidOfficer() then
		SDM("DPSMateX_AbortVote"..DPSMateX.SYNCVERSION, "NaN", "RAID")
		DPSMateX:SendMessage(DPSMateX.L["resetaborted"])
	end
end

function DPSMateX.Sync:ReceiveAbort()
	DPSMateX:SendMessage(DPSMateX.L["resetaborted"])
	abort = GetTime()
	participants = 1000000
	voteCount = 1
end

local bc, am = 0, 1
function DPSMateX.Sync:HelloWorld()
	if (GetTime()-bc)>=3 then
		bc = GetTime()
		am = 1
		SDM("DPSMateX_HelloWorld", "NaN", "RAID")
	end
end

function DPSMateX.Sync:GreetBack()
	SDM("DPSMateX_Greet", DPSMateX.SYNCVERSION, "RAID")
end

local old = 0
function DPSMateX.Sync:ReceiveGreet(arg2, arg4)
	if (GetTime()-bc)<=3 then
		DPSMateX:SendMessage(am..". "..arg4.." (v"..arg2..")")
		am = am + 1
	else
		if (GetTime()-old)>=3 then
			local ver = tnbr(strsub(arg2, strfind(arg2, "%d+")) or 0)
			if ver>DPSMateX.VERSION then
				DPSMateX:SendMessage(DPSMateX.L["versionisold"])
				old = GetTime()
			end
		end
	end
end

----------------------------------------------------------------------------------
--------------                       SYNC IN                        --------------                                  
----------------------------------------------------------------------------------

DPSMateX.Sync.CHAT_MSG_ADDON = function(arg1,arg2,arg3,arg4) -- DB.loaded part? Add scripts at the end of db load up
	if DPSMateX.Settings["sync"] then
		if arg4 == DPSMateX.Parser.playername then return end 
		if Execute[arg1] then
			Execute[arg1](this, arg2,arg4)
			return
		end
		if lesstrivial[arg1] then
			lesstrivial[arg1](this, arg2,arg4)
			return
		end
		if trivial[arg1] then
			trivial[arg1](this, arg2,arg4)
			return
		end
	else
		if arg1=="DPSMateX"..sKey then
			Execute[arg1](this, arg2, arg4)
		end
	end
end

DPSMateX.Sync.UPDATE_MOUSEOVER_UNIT = function()
	LastMouseover = UnitName("mouseover")
end

function DPSMateX.Sync:SyncStatus(arg2, arg4) 
	if arg2 == "0" then
		usid = DB:BuildUser(arg4)
		if Arrays[1][usid] then DPSMateX.DBCache.DamageDone[1][usid] = Arrays[1][usid] end
		if Arrays[2][usid] and ((DPSMateX.ModuleNames["damagetaken"])) then DPSMateX.DBCache.DamageTaken[1][usid] = Arrays[2][usid] else Arrays[2][usid] = nil end
		if  DPSMateX.ModuleNames["enemydamagedone"] then
			for cat, val in pairs(Arrays[3]) do
				if val[usid] then
					if not DPSMateX.DBCache.EDD[1][cat] then DPSMateX.DBCache.EDD[1][cat] = {} end
					DPSMateX.DBCache.EDD[1][cat][usid] = val[usid]
				end
			end
		else
			Arrays[3][usid] = nil
		end
		for cat, val in pairs(Arrays[4]) do
			if val[usid] then
				if not DPSMateX.DBCache.EDT[1][cat] then DPSMateX.DBCache.EDT[1][cat] = {} end
				DPSMateX.DBCache.EDT[1][cat][usid] = val[usid]
			end
		end
		if Arrays[5][usid] and ( (DPSMateX.ModuleNames["healing"])) then DPSMateX.DBCache.THealing[1][usid] = Arrays[5][usid] else Arrays[5][usid] = nil end
		if Arrays[6][usid] and ( (DPSMateX.ModuleNames["effectivehealing"] or DPSMateX.ModuleNames["healingandabsorbs"])) then DPSMateX.DBCache.EHealing[1][usid] = Arrays[6][usid] else Arrays[6][usid] = nil end
		if Arrays[7][usid] and ( (DPSMateX.ModuleNames["healingtaken"] or DPSMateX.ModuleNames["healing"])) then DPSMateX.DBCache.HealingTaken[1][usid] = Arrays[7][usid] else Arrays[7][usid] = nil end
		if Arrays[8][usid] and ( (DPSMateX.ModuleNames["effectivehealingtaken"] or DPSMateX.ModuleNames["effectivehealing"] or DPSMateX.ModuleNames["healingandabsorbs"])) then DPSMateX.DBCache.EHealingTaken[1][usid] = Arrays[8][usid] else Arrays[8][usid] = nil end
		if Arrays[9][usid] and ( (DPSMateX.ModuleNames["overhealing"])) then DPSMateXOverhealing[1][usid] = Arrays[9][usid] else Arrays[9][usid] = nil end 
		if Arrays[10][usid] and ( (DPSMateX.ModuleNames["absorbs"] or DPSMateX.ModuleNames["absorbstaken"] or DPSMateX.ModuleNames["healingandabsorbs"])) then DPSMateX.DBCache.Absorbs[1][usid] = Arrays[10][usid] else Arrays[10][usid] = nil end
		if Arrays[11][usid] and ( (DPSMateX.ModuleNames["deaths"])) then DPSMateX.DBCache.Deaths[1][usid] = Arrays[11][usid] else Arrays[11][usid] = nil end
		if Arrays[12][usid] and ( (DPSMateX.ModuleNames["interrupts"])) then DPSMateX.DBCache.Interrupts[1][usid] = Arrays[12][usid] else Arrays[12][usid] = nil end
		if Arrays[13][usid] and ( (DPSMateX.ModuleNames["decurses"] or DPSMateX.ModuleNames["curepoison"] or DPSMateX.ModuleNames["liftmagic"] or DPSMateX.ModuleNames["curedisease"] or DPSMateX.ModuleNames["dispels"])) then DPSMateX.DBCache.Dispels[1][usid] = Arrays[13][usid] else Arrays[13][usid] = nil end
		if Arrays[14][usid] and ( (DPSMateX.ModuleNames["aurasgained"])) then DPSMateX.DBCache.AurasGained[1][usid] = Arrays[14][usid] else Arrays[14][usid] = nil end
		if Arrays[15][usid] and ( (DPSMateX.ModuleNames["overhealing"] or DPSMateX.ModuleNames["OHealingTaken"])) then DPSMateX.DBCache.OverhealingTaken[1][usid] = Arrays[15][usid] else Arrays[15][usid] = nil end
		if Arrays[16][usid] and ( (DPSMateX.ModuleNames["threats"])) then DPSMateX.DBCache.Threat[1][usid] = Arrays[16][usid] else Arrays[16][usid] = nil end
		DB.NeedUpdate = true
	else
		local usid = DB:BuildUser(arg4)
		for i=1, 16 do
			Arrays[i][usid] = nil
		end
	end
end

----------------------------------------------------------------------------------
--------------                    DAMAGE DONE                       --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:DMGDoneAllIn(arg2, arg4)
	userid = DB:BuildUser(arg4)
	t = {}
	strgsub(arg2, "(.-),", func)
	Arrays[1][userid] = {
		i = tnbr(t[1]),
	}
end

function DPSMateX.Sync:DMGDoneStatIn(arg2, arg4)
	userid = DB:BuildUser(arg4)
	t = {}
	strgsub(arg2, "(.-),", func)
	abid = DB:BuildAbility(t[3])
	t[1] = tnbr(t[1])
	if t[1]>DPSMateX.CombatTime["total"] and (t[1]>5*DPSMateX.CombatTime["total"] or t[1]>20000) then return end
	if not Arrays[1][userid] then return end
	if not Arrays[1][userid][abid] then return end
	if t[1]>DPSMateX.CombatTime["total"] then DPSMateX.CombatTime["total"]=t[1] end
end

function DPSMateX.Sync:DMGDoneAbilityIn(arg2, arg4)
	userid = DB:BuildUser(arg4)
	t = {}
	strgsub(arg2, "(.-),", func)

	if not Arrays[1][userid] then return end
	Arrays[1][userid][DB:BuildAbility(t[1])] = {
		[1] = tnbr(t[2]),
		[2] = tnbr(t[3]),
		[3] = tnbr(t[4]),
		[4] = tnbr(t[5]),
		[5] = tnbr(t[6]),
		[6] = tnbr(t[7]),
		[7] = tnbr(t[8]),
		[8] = tnbr(t[9]),
		[9] = tnbr(t[10]),
		[10] = tnbr(t[11]),
		[11] = tnbr(t[12]),
		[12] = tnbr(t[13]),
		[13] = tnbr(t[14]),
		[14] = tnbr(t[15]),
		[15] = tnbr(t[16]),
		[16] = tnbr(t[17]),
		[17] = tnbr(t[18]),
		[18] = tnbr(t[19]),
		[19] = tnbr(t[20]),
		[20] = tnbr(t[21]),
		[21] = tnbr(t[22]),
		[22] = tnbr(t[23]),

	}
end

----------------------------------------------------------------------------------
--------------                    DAMAGE TAKEN                      --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:DMGTakenAllIn(arg2, arg4)
	userid = DPSMateX.CacheUser[arg4][1]
	t = {}
	strgsub(arg2, "(.-),", func)
	Arrays[2][userid] = {
		i = tnbr(t[1]),
	}
end

function DPSMateX.Sync:DMGTakenStatIn(arg2, arg4)
	userid = DPSMateX.CacheUser[arg4][1]
	t = {}
	strgsub(arg2, "(.-),", func)
	abid = DB:BuildAbility(t[3])
	userid2 = DB:BuildUser(t[4])
	if not Arrays[2][userid] then return end
	if not Arrays[2][userid][userid2][abid] then return end
	if not Arrays[2][userid][userid2][abid] then return end
	t[1] = tnbr(t[1])
	if t[1]>DPSMateX.CombatTime["total"] and (t[1]>5*DPSMateX.CombatTime["total"] or t[1]>20000) then return end
	if t[1]>DPSMateX.CombatTime["total"] then DPSMateX.CombatTime["total"]=t[1] end
end

function DPSMateX.Sync:DMGTakenAbilityIn(arg2, arg4)
	t = {}
	strgsub(arg2, "(.-),", func)
	userid2, userid = DB:BuildUser(t[1]), DPSMateX.CacheUser[arg4][1]
	if not Arrays[2][userid] then return end
	if not Arrays[2][userid][userid2] then
		Arrays[2][userid][userid2] = {}
	end
	Arrays[2][userid][userid2][DB:BuildAbility(t[2])] = {
		[1] = tnbr(t[3]),
		[2] = tnbr(t[4]),
		[3] = tnbr(t[5]),
		[4] = tnbr(t[6]),
		[5] = tnbr(t[7]),
		[6] = tnbr(t[8]),
		[7] = tnbr(t[9]),
		[8] = tnbr(t[10]),
		[9] = tnbr(t[11]),
		[10] = tnbr(t[12]),
		[11] = tnbr(t[13]),
		[12] = tnbr(t[14]),
		[13] = tnbr(t[15]),
		[14] = tnbr(t[16]),
		[15] = tnbr(t[17]),
		[16] = tnbr(t[18]),
		[17] = tnbr(t[19]),
		[18] = tnbr(t[20]),
		[19] = tnbr(t[21]),
		[20] = tnbr(t[22]),
		[21] = tnbr(t[23]),
		[22] = tnbr(t[24]),
		[23] = tnbr(t[25]),

	}
end

----------------------------------------------------------------------------------
--------------                 ENEMY DAMAGE TAKEN                   --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:EDAllIn(arr, arg2, arg4)
	t = {}
	strgsub(arg2, "(.-),", func)
	userid = DB:BuildUser(t[1])
	if not Arrays[arr][userid] then
		Arrays[arr][userid] = {}
	end
	Arrays[arr][userid][DPSMateX.CacheUser[arg4][1]] = {
		i = tnbr(t[2]),
	}
end

function DPSMateX.Sync:EDStatIn(arr, arg2, arg4)
	t = {}
	strgsub(arg2, "(.-),", func)
	userid, userid2, abid = DB:BuildUser(t[1]), DPSMateX.CacheUser[arg4][1], DB:BuildAbility(t[4])
	if not Arrays[arr][userid] then return end
	if not Arrays[arr][userid][userid2] then return end
	if not Arrays[arr][userid][userid2][abid] then return end
	t[2] = tnbr(t[2])
	if t[2]>DPSMateX.CombatTime["total"] and (t[2]>5*DPSMateX.CombatTime["total"] or t[2]>20000) then return end
	if t[2]>DPSMateX.CombatTime["total"] then DPSMateX.CombatTime["total"]=t[2] end
end

function DPSMateX.Sync:EDAbilityIn(arr, arg2, arg4)
	t = {}
	strgsub(arg2, "(.-),", func)
	userid, userid2 = DB:BuildUser(t[1]), DPSMateX.CacheUser[arg4][1]
	if not Arrays[arr][userid] then return end
	if not Arrays[arr][userid][userid2] then return end
	Arrays[arr][userid][userid2][DB:BuildAbility(t[2])] = {
		[1] = tnbr(t[3]),
		[2] = tnbr(t[4]),
		[3] = tnbr(t[5]),
		[4] = tnbr(t[6]),
		[5] = tnbr(t[7]),
		[6] = tnbr(t[8]),
		[7] = tnbr(t[9]),
		[8] = tnbr(t[10]),
		[9] = tnbr(t[11]),
		[10] = tnbr(t[12]),
		[11] = tnbr(t[13]),
		[12] = tnbr(t[14]),
		[13] = tnbr(t[15]),
		[14] = tnbr(t[16]),
		[15] = tnbr(t[17]),
		[16] = tnbr(t[18]),
		[17] = tnbr(t[19]),
		[18] = tnbr(t[20]),
		[19] = tnbr(t[21]),
		[20] = tnbr(t[22]),
		[21] = tnbr(t[23]),
		[22] = tnbr(t[24]),

	}
end

----------------------------------------------------------------------------------
--------------                        Healing                       --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:HealingAllIn(arg2, arg4, arr)
	t = {}
	strgsub(arg2, "(.-),", func)
	Arrays[arr][DB:BuildUser(arg4)] = {
		i = tnbr(t[2]),
	}
end

function DPSMateX.Sync:HealingStatIn(arg2, arg4, arr)
	userid = DB:BuildUser(arg4)
	t = {}
	strgsub(arg2, "(.-),", func)
	abid = DB:BuildAbility(t[3])
	t[1] = tnbr(t[1])
	if not Arrays[arr][userid] then return end
	if not Arrays[arr][userid][abid] then return end
	if t[1]>DPSMateX.CombatTime["total"] and (t[1]>5*DPSMateX.CombatTime["total"] or t[1]>20000) then return end
	if t[1]>DPSMateX.CombatTime["total"] then DPSMateX.CombatTime["total"]=t[1] end
end

function DPSMateX.Sync:HealingAbilityIn(arg2, arg4, arr)
	userid = DB:BuildUser(arg4)
	t = {}
	strgsub(arg2, "(.-),", func)
	if not Arrays[arr][userid] then return end
	Arrays[arr][userid][DB:BuildAbility(t[1])] = {
		[1] = tnbr(t[2]),
		[2] = tnbr(t[3]),
		[3] = tnbr(t[4]),
		[4] = tnbr(t[5]),
		[5] = tnbr(t[6]),
		[6] = tnbr(t[7]),
		[7] = tnbr(t[8]),
		[8] = tnbr(t[9]),
		[9] = tnbr(t[10]),

	}
end

----------------------------------------------------------------------------------
--------------                    Healing taken                     --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:HealingTakenStatIn(arg2, arg4, arr)
	userid = DB:BuildUser(arg4)
	t = {}
	strgsub(arg2, "(.-),", func)
	abid = DB:BuildAbility(t[3])
	userid2 = DB:BuildUser(t[4])
	t[1] = tnbr(t[1])
	if not Arrays[arr][userid] then return end
	if not Arrays[arr][userid][userid2] then return end
	if not Arrays[arr][userid][userid2][abid] then return end
	if t[1]>DPSMateX.CombatTime["total"] and (t[1]>5*DPSMateX.CombatTime["total"] or t[1]>20000) then return end
	if t[1]>DPSMateX.CombatTime["total"] then DPSMateX.CombatTime["total"]=t[1] end
end

function DPSMateX.Sync:HealingTakenAbilityIn(arg2, arg4, arr)
	t = {}
	strgsub(arg2, "(.-),", func)
	userid, userid2 = DB:BuildUser(arg4), DB:BuildUser(t[1])
	if not Arrays[arr][userid] then return end
	if not Arrays[arr][userid][userid2] then
		Arrays[arr][userid][userid2] = {}
	end
	Arrays[arr][userid][userid2][DB:BuildAbility(t[2])] = {
		[1] = tnbr(t[3]),
		[2] = tnbr(t[4]),
		[3] = tnbr(t[5]),
		[4] = tnbr(t[6]),
		[5] = tnbr(t[7]),
		[6] = tnbr(t[8]),
		[7] = tnbr(t[9]),
		[8] = tnbr(t[10]),
		[9] = tnbr(t[11]),

	}
end

----------------------------------------------------------------------------------
--------------                        Absorbs                       --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:iAbsorbsIn(arg2, arg4) 
	t = {}
	strgsub(arg2, "(.-),", func)
	userid, userid2, userid3 = DPSMateX.CacheUser[arg4][1], DB:BuildUser(t[1]), DB:BuildAbility(t[2])
	if not Arrays[10][userid] then
		Arrays[10][userid] = {}
	end
	if not Arrays[10][userid][userid2] then
		Arrays[10][userid][userid2] = {
			i = {},
		}
	end
	if not Arrays[10][userid][userid2][userid3] then
		Arrays[10][userid][userid2][userid3] = {}
	end
	Arrays[10][userid][userid2][userid3][tnbr(t[3])] = {
		i = {
			[1] = tnbr(t[4]),
			[2] = tnbr(t[5]),
			[3] = tnbr(t[6]),
			[4] = tnbr(t[7]),
		},
	}
end

function DPSMateX.Sync:AbsorbsStatIn(arg2, arg4)
	t = {}
	strgsub(arg2, "(.-),", func)
	userid, userid2 = DPSMateX.CacheUser[arg4][1], DB:BuildUser(t[1])
	if not DPSMateX.DBCache.Absorbs[1][userid] then return end
	if not DPSMateX.DBCache.Absorbs[1][userid][userid2] then return end
	t[2] = tnbr(t[2])
	if t[2]>DPSMateX.CombatTime["total"] and (t[2]>5*DPSMateX.CombatTime["total"] or t[2]>20000) then return end
	if t[4] then
		tinsert(Arrays[10][userid][userid2]["i"], {t[2], tnbr(t[3]), tnbr(t[4]), tnbr(t[5])})
	else
		tinsert(Arrays[10][userid][userid2]["i"], {t[2], tnbr(t[3]), tnbr(t[4])})
	end
	if t[2]>DPSMateX.CombatTime["total"] then DPSMateX.CombatTime["total"]=t[2] end
end

function DPSMateX.Sync:AbsorbsIn(arg2, arg4) 
	t = {}
	strgsub(arg2, "(.-),", func)
	userid, userid2, userid3, userid4 = DPSMateX.CacheUser[arg4][1], DB:BuildUser(t[1]), DB:BuildAbility(t[2]), DB:BuildUser(t[4])
	local val = tnbr(t[3])
	if not Arrays[10][userid] then return end
	if not Arrays[10][userid][userid2] then return end
	if not Arrays[10][userid][userid2][userid3] then Arrays[10][userid][userid2][userid3] = {} end
	if not Arrays[10][userid][userid2][userid3][val] then Arrays[10][userid][userid2][userid3][val] = {} end
	if not Arrays[10][userid][userid2][userid3][val][userid4] then Arrays[10][userid][userid2][userid3][val][userid4] = {} end
	Arrays[10][userid][userid2][userid3][val][userid4][tnbr(t[5])] = tnbr(t[6])
	DB.NeedUpdate = true
end

----------------------------------------------------------------------------------
--------------                        Deaths                        --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:DeathsAllIn(arg2, arg4) 
	t = {}
	strgsub(arg2, "(.-),", func)
	userid = DPSMateX.CacheUser[arg4][1]
	if not Arrays[11][userid] then
		Arrays[11][userid] = {}
	end
	Arrays[11][userid][tnbr(t[2])] = {
		i = {
			[1] = tnbr(t[3]),
			[2] = t[4],
		},
	}
end

function DPSMateX.Sync:DeathsIn(arg2, arg4)
	t = {}
	strgsub(arg2, "(.-),", func)
	t[1] = tnbr(t[1])
	userid = DB:BuildUser(arg4)
	if not Arrays[11][userid] then return end
	if not Arrays[11][userid][t[1]] then return end
	Arrays[11][userid][t[1]][tnbr(t[2])] = {
		[1] = DB:BuildUser(t[3]),
		[2] = DB:BuildAbility(t[4]),
		[3] = tnbr(t[5]),
		[4] = tnbr(t[6]),
		[5] = tnbr(t[7]),
		[6] = tnbr(t[8]),
		[7] = t[9],
	}
end

----------------------------------------------------------------------------------
--------------                     Interrupts                       --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:InterruptsAllIn(arg2, arg4)
	t = {}
	strgsub(arg2, "(.-),", func)
	Arrays[12][DPSMateX.CacheUser[arg4][1]] = {
		i = {
			[1] = tnbr(t[2]),
			[2] = {}
		},
	}
end

function DPSMateX.Sync:InterruptsAbilityIn(arg2, arg4)
	t = {}
	strgsub(arg2, "(.-),", func)
	userid, userid2, userid3 = DPSMateX.CacheUser[arg4][1],DB:BuildAbility(t[1]), DB:BuildUser(t[2])
	if not Arrays[12][userid] then return end
	if not Arrays[12][userid][userid2] then
		Arrays[12][userid][userid2] = {}
	end
	if not Arrays[12][userid][userid2][userid3] then
		Arrays[12][userid][userid2][userid3] = {}
	end
	Arrays[12][userid][userid2][userid3][DB:BuildAbility(t[3])] = tnbr(t[4])
end

----------------------------------------------------------------------------------
--------------                        Dispels                       --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:iDispelsIn(arg2, arg4)
	t = {}
	strgsub(arg2, "(.-),", func)
	userid = DPSMateX.CacheUser[arg4][1]
	if not Arrays[13][userid] then Arrays[13][userid] = {i={[1]=0,[2]={}}} end
	Arrays[13][userid]["i"][1] = tnbr(arg2);
end

function DPSMateX.Sync:DispelsIn(arg2, arg4)
	t = {}
	strgsub(arg2, "(.-),", func)
	userid, userid2, userid3 = DPSMateX.CacheUser[arg4][1], DB:BuildAbility(t[1]), DB:BuildUser(t[2])
	if not Arrays[13][userid] then Arrays[13][DPSMateX.CacheUser[arg4][1]] = {i={[1]=0,[2]={}}} end
	if not Arrays[13][userid][userid2] then
		Arrays[13][userid][userid2] = {}
	end
	if not Arrays[13][userid][userid2][userid3] then
		Arrays[13][userid][userid2][userid3] = {}
	end
	Arrays[13][userid][userid2][userid3][DB:BuildAbility(t[3])] = tnbr(t[4])
end

----------------------------------------------------------------------------------
--------------                        Auras                         --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:AurasAllIn(arg2, arg4)
	t = {}
	strgsub(arg2, "(.-),", func)
	userid, userid2 = DPSMateX.CacheUser[arg4][1], DB:BuildAbility(t[1])
	if not Arrays[14][userid] then
		Arrays[14][userid] = {}
	end
	Arrays[14][userid][userid2] = {
		[1] = {},
		[2] = {},
		[3] = {},
		[4] = false,
		[5] = tnbr(t[2]),
		[6] = tnbr(t[3]),
	}
	if t[2]=="1" then
		Arrays[14][userid][userid2][4] = true
	end
end

function DPSMateX.Sync:AurasStartEndIn(arg2, arg4, prefix)
	t = {}
	strgsub(arg2, "(.-),", func)
	abid = DB:BuildAbility(t[1])
	if not Arrays[14][DPSMateX.CacheUser[arg4][1]] then return end
	if not Arrays[14][DPSMateX.CacheUser[arg4][1]][abid] then return end
	Arrays[14][DPSMateX.CacheUser[arg4][1]][abid][prefix][tnbr(t[2])] = tnbr(t[3])
end

function DPSMateX.Sync:AurasCauseIn(arg2, arg4)
	t = {}
	strgsub(arg2, "(.-),", func)
	userid, abid = DPSMateX.CacheUser[arg4][1], DB:BuildAbility(t[1])
	if not Arrays[14][userid] then return end
	if not Arrays[14][userid][abid] then return end
	Arrays[14][userid][abid][3][DB:BuildUser(t[2])] = tnbr(t[3])
end

----------------------------------------------------------------------------------
--------------                       SYNC OUT                       --------------                                  
----------------------------------------------------------------------------------

local LastDecursive = nil
if Dcr_Cast_CureSpell then
	local OldDCR_CAST = Dcr_Cast_CureSpell
	DPSMateX.Parser.DCR_CAST = function(spellID, Unit, AfflictionType, ClearCurrentTarget)
		LastDecursive = UnitName(Unit)
		OldDCR_CAST(spellID, Unit, AfflictionType, ClearCurrentTarget)
	end
	Dcr_Cast_CureSpell = DPSMateX.Parser.DCR_CAST
end

function DPSMateX.Parser:GetTarget()
	local target = LastDecursive
	if not target then
		if UnitIsPlayer("target") then
			target = UnitName("target")
		else
			target = LastMouseover
		end
	end
	return target
end
local GetTargetP = DPSMateX.Parser.GetTarget

-- Hooking useaction function in order to get the owner of the spell.
DPSMateX.Sync.OverTimeDispels = {
	["Abolish Poison"] = true,
	["Abolish Disease"] = true,
}
DPSMateX.Sync.AbsorbAbilities = {
	["Greater Fire Protection Potion"] = true,
	["Greater Frost Protection Potion"] = true,
	["Greater Nature Protection Potion"] = true,
	["Greater Holy Protection Potion"] = true,
	["Greater Shadow Protection Potion"] = true,
	["Greater Arcane Protection Potion"] = true,
	["Power Word: Shield"] = true,
	["Ice Barrier"] = true,
	["The Burrower's Shell"] = true,
	["Aura of Protection"] = true,
	["Damage Absorb"] = true,
	["Physical Protection"] = true,
	["Harm Prevention Belt"] = true,
	["Mana Shield"] = true,
	["Frost Protection"] = true,
	["Frost Resistance"] = true,
	["Frost Ward"] = true,
	["Fire Protection"] = true,
	["Fire Ward"] = true,
	["Nature Protection"] = true,
	["Shadow Protection"] = true,
	["Arcane Protection"] = true,
	["Holy Protection"] = true,
}
DPSMateX.Sync.OtherAbilities = {
	["Banish"] = true,
	["Curse of Recklessness"] = true,
	["Curse of the Elements"] = true,
	["Curse of Tongues"] = true,
	["Curse of Shadow"] = true,
}
DPSMateX.Parser.SendSpell = {}

--[[
local oldUseAction = UseAction
DPSMateX.Parser.UseAction = function(slot, checkCursor, onSelf)
	DPSMateX_Tooltip:ClearLines()
	DPSMateX_Tooltip:SetAction(slot)
	local aura = DPSMateX_TooltipTextLeft1:GetText()
	local target = GetTargetP()
	if aura and target and (DPSMateX.Sync.OverTimeDispels[aura] or DPSMateX.Sync.AbsorbAbilities[aura] or DPSMateX.Sync.OtherAbilities[aura]) and not DPSMateX.Parser.SendSpell[aura] then
		SDM("DPSMateX"..sKey, aura..","..target..",", "RAID")
		DPSMateX.Parser.SendSpell[aura] = true
	end
	if aura then
		local time = GetTime()
		DB:AwaitAfflicted(DPSMateX.Parser.playername, aura, UnitName("target"), time)
		if DPSMateX.Parser.Dispels[aura] then DB:AwaitHotDispel(aura, target, DPSMateX.Parser.playername, time) end
		DB:AwaitingBuff(DPSMateX.Parser.playername, aura, target, time)
		DB:AwaitingAbsorbConfirmation(DPSMateX.Parser.playername, aura, target, time)
	end
	oldUseAction(slot, checkCursor, onSelf)
end
--UseAction = DPSMateX.Parser.UseAction

-- Hooking CastSpellByName function in order to get the owner of the spell.
local oldCastSpellByName = CastSpellByName
DPSMateX.Parser.CastSpellByName = function(spellName, onSelf)
	local target = GetTargetP()
	if target and (DPSMateX.Sync.OverTimeDispels[spellName] or DPSMateX.Sync.AbsorbAbilities[spellName] or DPSMateX.Sync.OtherAbilities[spellName]) and not DPSMateX.Parser.SendSpell[spellName] then 
		SDM("DPSMateX"..sKey, spellName..","..target..",", "RAID")
		DPSMateX.Parser.SendSpell[spellName] = true
	end
	local time = GetTime()
	DB:AwaitAfflicted(DPSMateX.Parser.playername, spellName, UnitName("target"), time)
	if DPSMateX.Parser.Dispels[spellName] then DB:AwaitHotDispel(spellName, target, DPSMateX.Parser.playername, time) end
	DB:AwaitingBuff(DPSMateX.Parser.playername, spellName, target, time)
	DB:AwaitingAbsorbConfirmation(DPSMateX.Parser.playername, spellName, target, time)
	oldCastSpellByName(spellName, onSelf)
end
--CastSpellByName = DPSMateX.Parser.CastSpellByName

-- Hooking CastSpell function in order to get the owner of the spell.
local oldCastSpell = CastSpell
DPSMateX.Parser.CastSpell = function(spellID, spellbookType)
	local spellName, spellRank = GetSpellName(spellID, spellbookType)
	local target = GetTargetP()
	if target and (DPSMateX.Sync.OverTimeDispels[spellName] or DPSMateX.Sync.AbsorbAbilities[spellName] or DPSMateX.Sync.OtherAbilities[spellName]) and not DPSMateX.Parser.SendSpell[spellName] then 
		SDM("DPSMateX"..sKey, spellName..","..target..",", "RAID")
		DPSMateX.Parser.SendSpell[spellName] = true
	end
	local time = GetTime()
	DB:AwaitAfflicted(DPSMateX.Parser.playername, spellName, UnitName("target"), time)
	if DPSMateX.Parser.Dispels[spellName] then DB:AwaitHotDispel(spellName, target, DPSMateX.Parser.playername, time) end
	DB:AwaitingBuff(DPSMateX.Parser.playername, spellName, target, time)
	DB:AwaitingAbsorbConfirmation(DPSMateX.Parser.playername, spellName, target, time)
	oldCastSpell(spellID, spellbookType)
end
--CastSpell = DPSMateX.Parser.CastSpell
--]]

----------------------------------------------------------------------------------
--------------                     DAMAGE DONE                      --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:DMGDoneAllOut()
	if DPSMateX.DBCache.DamageDone[1][pid] then
		Buffer[cou] = {"DPSMateX_DMGDoneAll", DPSMateX.DBCache.DamageDone[1][pid]["i"]..","}
		cou = cou + 1
	end
end

function DPSMateX.Sync:DMGDoneStatOut()
	-- Amount/time plots are disabled; cumulative ability packets remain.
end

function DPSMateX.Sync:DMGDoneAbilityOut()
	if not DPSMateX.DBCache.DamageDone[1][pid] then return end
	for cat, val in pairs(DPSMateX.DBCache.DamageDone[1][pid]) do
		if cat~="i" then
			Buffer[cou] = {"DPSMateX_DMGDoneAbility", DPSMateX:GetAbilityById(cat)..","..val[1]..","..val[2]..","..val[3]..","..ceil(val[4])..","..val[5]..","..val[6]..","..val[7]..","..ceil(val[8])..","..val[9]..","..val[10]..","..val[11]..","..val[12]..","..val[13]..","..val[14]..","..val[15]..","..val[16]..","..ceil(val[17])..","..val[18]..","..val[19]..","..val[20]..","..ceil(val[21])..","..val[22]..","}
			cou = cou + 1
		end
	end
end

----------------------------------------------------------------------------------
--------------                    DAMAGE TAKEN                      --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:DMGTakenAllOut()
	if DPSMateX.DBCache.DamageTaken[1][pid] then
		Buffer[cou] = {"DPSMateX_DMGTakenAll", DPSMateX.DBCache.DamageTaken[1][pid]["i"]..","}
		cou = cou + 1
	end
end

function DPSMateX.Sync:DMGTakenStatOut()
	-- Amount/time plots are disabled; cumulative ability packets remain.
end

function DPSMateX.Sync:DMGTakenAbilityOut()
	if not DPSMateX.DBCache.DamageTaken[1][pid] then return end
	for cat, val in pairs((DPSMateX.DBCache.DamageTaken[1][pid])) do
		if cat~="i" then
			for ca, va in pairs(val) do
				Buffer[cou] = {"DPSMateX_DMGTakenAbility", DPSMateX:GetUserById(cat)..","..DPSMateX:GetAbilityById(ca)..","..va[1]..","..va[2]..","..va[3]..","..ceil(va[4])..","..va[5]..","..va[6]..","..va[7]..","..ceil(va[8])..","..va[9]..","..va[10]..","..va[11]..","..va[12]..","..va[13]..","..ceil(va[14])..","..va[15]..","..va[16]..","..va[17]..","..ceil(va[18])..","..va[19]..","..va[20]..","..va[21]..","..va[22]..","..ceil(va[23])..","}
				cou = cou + 1
			end
		end
	end
end

----------------------------------------------------------------------------------
--------------                 ENEMY DAMAGE TAKEN                   --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:EDAllOut(arr, prefix)
	for cat, val in pairs(arr[1]) do
		if val[pid] then
			Buffer[cou] = {"DPSMateX_ED"..prefix.."All", DPSMateX:GetUserById(cat)..","..val[pid]["i"]..","}
			cou = cou + 1
		end
	end
end

function DPSMateX.Sync:EDStatOut(arr, prefix)
	-- Amount/time plots are disabled; cumulative ability packets remain.
end

function DPSMateX.Sync:EDAbilityOut(arr, prefix)
	local npc
	for cat, val in pairs((arr[1])) do
		npc = DPSMateX:GetUserById(cat)
		if val[pid] then
			for ca, va in pairs(val[pid]) do
				if ca~="i" then
					Buffer[cou] = {"DPSMateX_ED"..prefix.."Ability", npc..","..DPSMateX:GetAbilityById(ca)..","..va[1]..","..va[2]..","..va[3]..","..ceil(va[4])..","..va[5]..","..va[6]..","..va[7]..","..ceil(va[8])..","..va[9]..","..va[10]..","..va[11]..","..va[12]..","..va[13]..","..va[14]..","..va[15]..","..va[16]..","..ceil(va[17])..","..va[18]..","..va[19]..","..va[20]..","..ceil(va[21])..","..va[22]..","}
					cou = cou + 1
				end
			end
		end
	end
end

----------------------------------------------------------------------------------
--------------                       Healing                        --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:HealingAllOut(arr, prefix)
	if arr[1][pid] then
		Buffer[cou] = {"DPSMateX_"..prefix.."HealingAll", DPSMateX.Parser.playerclass..","..arr[1][pid]["i"]..","}
		cou = cou + 1
	end
end

function DPSMateX.Sync:HealingStatOut(arr, prefix)
	-- Amount/time plots are disabled; cumulative ability packets remain.
end

function DPSMateX.Sync:HealingAbilityOut(arr, prefix)
	if not arr[1][pid] then return end
	for cat, val in pairs(arr[1][pid]) do
		if cat~="i" then
			Buffer[cou] = {"DPSMateX_"..prefix.."HealingAbility", DPSMateX:GetAbilityById(cat)..","..val[1]..","..val[2]..","..val[3]..","..ceil(val[4])..","..ceil(val[5])..","..val[6]..","..val[7]..","..val[8]..","..val[9]..","}
			cou = cou + 1
		end
	end
end

----------------------------------------------------------------------------------
--------------                    Healing taken                     --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:HealingTakenStatOut(arr, prefix)
	-- Amount/time plots are disabled; cumulative ability packets remain.
end

function DPSMateX.Sync:HealingTakenAbilityOut(arr, prefix)
	if not arr[1][pid] then return end
	for cat, val in pairs(arr[1][pid]) do
		if cat~="i" then
			for ca, va in pairs(val) do
				Buffer[cou] = {"DPSMateX_"..prefix.."HealingTakenAbility", DPSMateX:GetUserById(cat)..","..DPSMateX:GetAbilityById(ca)..","..va[1]..","..va[2]..","..va[3]..","..ceil(va[4])..","..ceil(va[5])..","..va[6]..","..va[7]..","..va[8]..","..va[9]..","}
				cou = cou + 1
			end
		end
	end
end

----------------------------------------------------------------------------------
--------------                        Absorbs                       --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:AbsorbsOut() 
	if not DPSMateX.DBCache.Absorbs[1][pid] then return end
	local owner, ab
	for cat, val in pairs(DPSMateX.DBCache.Absorbs[1][pid]) do -- owner
		owner = DPSMateX:GetUserById(cat)
		for ca, va in pairs(val) do -- ability
			ab = DPSMateX:GetAbilityById(ca)
			if ca~="i" then
				for c, v in pairs(va) do -- each one
					for ce, ve in pairs(v) do -- enemy
						if ce=="i" then
							Buffer[cou] = {"DPSMateX_iAbsorbs", owner..","..ab..","..c..","..(ve[1] or 0)..","..(ve[2] or 0)..","..(ve[3] or 0)..","..(ve[4] or 0)..","}
							cou = cou + 1
						else
							for cet, vel in pairs(ve) do
								Buffer[cou] = {"DPSMateX_Absorbs", owner..","..ab..","..c..","..DPSMateX:GetUserById(ce)..","..cet..","..vel..","}
								cou = cou + 1
							end
						end
					end
				end
			end
		end
	end
end

function DPSMateX.Sync:AbsorbsStatOut()
	if not DPSMateX.DBCache.Absorbs[1][pid] then return end
	local owner
	for cat, val in pairs(DPSMateX.DBCache.Absorbs[1][pid]) do -- owner
		owner = DPSMateX:GetUserById(cat)
		for ca, va in pairs(val["i"]) do
			if va[4] then
				Buffer[cou] = {"DPSMateX_AbsorbsStat", owner..","..va[1]..","..va[2]..","..va[3]..","..va[4]..","}
				cou = cou + 1
			else
				Buffer[cou] = {"DPSMateX_AbsorbsStat", owner..","..va[1]..","..va[2]..","..va[3]..","}
				cou = cou + 1
			end
		end
	end
end

----------------------------------------------------------------------------------
--------------                        Deaths                        --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:DeathsAllOut()
	if not DPSMateX.DBCache.Deaths[1][pid] then return end
	for cat, val in pairs(DPSMateX.DBCache.Deaths[1][pid]) do -- death count
		Buffer[cou] = {"DPSMateX_DeathsAll", DPSMateX.Parser.playerclass..","..cat..","..val["i"][1]..","..val["i"][2]..","}
		cou = cou + 1
	end
end

function DPSMateX.Sync:DeathsOut()
	if not DPSMateX.DBCache.Deaths[1][pid] then return end
	for cat, val in pairs(DPSMateX.DBCache.Deaths[1][pid]) do -- death count
		for ca, va in pairs(val) do -- each part
			if ca~="i" then -- Testing if this prevents the error
				Buffer[cou] = {"DPSMateX_Deaths", cat..","..ca..","..DPSMateX:GetUserById(va[1])..","..DPSMateX:GetAbilityById(va[2])..","..va[3]..","..va[4]..","..va[5]..","..va[6]..","..va[7]..","}
				cou = cou + 1
			end
		end
	end
end

----------------------------------------------------------------------------------
--------------                     Interrupts                       --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:InterruptsAllOut()
	if DPSMateX.DBCache.Interrupts[1][pid] then
		Buffer[cou] = {"DPSMateX_InterruptsAll", DPSMateX.Parser.playerclass..","..DPSMateX.DBCache.Interrupts[1][pid]["i"][1]..","}
		cou = cou + 1
	end
end

function DPSMateX.Sync:InterruptsAbilityOut()
	if not DPSMateX.DBCache.Interrupts[1][pid] then return end
	for cat, val in pairs(DPSMateX.DBCache.Interrupts[1][pid]) do
		if cat~="i" then
			for ca, va in pairs(val) do
				for c, v in pairs(va) do
					Buffer[cou] = {"DPSMateX_InterruptsAbility", DPSMateX:GetAbilityById(cat)..","..DPSMateX:GetUserById(ca)..","..DPSMateX:GetAbilityById(c)..","..v..","}
					cou = cou + 1
				end
			end
		end
	end
end

----------------------------------------------------------------------------------
--------------                        Dispels                       --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:DispelsOut()
	if not DPSMateX.DBCache.Dispels[1][pid] then return end
	local ab, user
	for cat, val in pairs(DPSMateX.DBCache.Dispels[1][pid]) do -- Ability
		if cat=="i" then
			Buffer[cou] = {"DPSMateX_iDispels", val[1]}
			cou = cou + 1
		else
			ab = DPSMateX:GetAbilityById(cat)
			for ca, va in pairs(val) do -- Target
				user = DPSMateX:GetUserById(ca)
				for c, v in pairs(va) do -- Ability
					Buffer[cou] = {"DPSMateX_Dispels", ab..","..user..","..DPSMateX:GetAbilityById(c)..","..v..","}
					cou = cou + 1
				end
			end
		end
	end
end

----------------------------------------------------------------------------------
--------------                        Auras                         --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:AurasOut()
	if not DPSMateX.DBCache.AurasGained[1][pid] then return end
	local p = 0
	local ability
	for cat, val in pairs(DPSMateX.DBCache.AurasGained[1][pid]) do -- ability
		if val[4] then p = 1 end
		ability = DPSMateX:GetAbilityById(cat)
		Buffer[cou] = {"DPSMateX_AurasAll", ability..","..p..","..val[5]..","..val[6]..","}
		cou = cou + 1
		for ca, va in pairs(val[1]) do
			Buffer[cou] = {"DPSMateX_AurasStart", ability..","..ca..","..va..","}
			cou = cou + 1
		end
		for ca, va in pairs(val[2]) do
			Buffer[cou] = {"DPSMateX_AurasEnd", ability..","..ca..","..va..","}
			cou = cou + 1
		end
		for ca, va in pairs(val[3]) do
			Buffer[cou] = {"DPSMateX_AurasCause", ability..","..DPSMateX:GetUserById(ca)..","..va..","}
			cou = cou + 1
		end
	end
end

----------------------------------------------------------------------------------
--------------                       Threat                         --------------                                  
----------------------------------------------------------------------------------

function DPSMateX.Sync:ThreatIn(arg2,arg4)
	if not arg2 then return end
	for cat, val in pairs(loadstring("return {"..arg2.."}")()) do
		for ca, va in pairs(val) do
			for c,v in pairs(va) do
				DB:Threat(arg4, cat, ca, v, 1)
			end
		end
	end
end

function DPSMateX.Sync:ThreatOut()
	if not DPSMateX.DBCache.Threat[1][pid] then return end
	local tar
	for cat, val in pairs(DPSMateX.DBCache.Threat[1][pid]) do
		tar = DPSMateX:GetUserById(cat)
		for ca, va in pairs(val) do
			Buffer[cou] = {"DPSMateX_Threat", tar..","..DPSMateX:GetAbilityById(ca)..","..va[1]..","..va[2]..","..va[3]..","..va[4]..","}
			cou = cou + 1
		end
	end
end

function DPSMateX.Sync:ThreatStatsOut()
	if not DPSMateX.DBCache.Threat[1][pid] then return end
	local tar, ability, a, i
	for cat, val in pairs(DPSMateX.DBCache.Threat[1][pid]) do
		tar = DPSMateX:GetUserById(cat)
		for ca, va in pairs(val) do
			ability, a = DPSMateX:GetAbilityById(ca), {}
			for c,v in pairs(va["i"]) do
				i = 1
				while true do
					if (not a[i]) then
						tinsert(a, i, {c,v})
						break
					else
						if c<=a[i][1] then
							tinsert(a, i, {c,v})
							break
						end
					end
					i=i+1
				end
			end
			for c, v in pairs(self:GetSummarizedTable(a)) do
				Buffer[cou] = {"DPSMateX_ThreatStats", tar..","..ability..","..v[1]..","..v[2]..","}
				cou = cou + 1
			end
		end
	end
end

function DPSMateX.Sync:ThreatAllIn(arg2, arg4)
	t = {}
	strgsub(arg2, "(.-),", func)
	local usid, abid, piid = DB:BuildUser(t[1]), DB:BuildAbility(t[2]), DB:BuildUser(arg4)
	if not Arrays[16][piid] then
		Arrays[16][piid] = {}
	end
	if not Arrays[16][piid][usid] then
		Arrays[16][piid][usid] = {}
	end
	if not Arrays[16][piid][usid][abid] then
		Arrays[16][piid][usid][abid] = {
			[1] = tnbr(t[3]),
			[2] = tnbr(t[4]),
			[3] = tnbr(t[5]),
			[4] = tnbr(t[6]),
			["i"] = {}
		}
	end
end

function DPSMateX.Sync:ThreatStatsIn(arg2,arg4)
	t = {}
	strgsub(arg2, "(.-),", func)
	local usid, abid, piid = DB:BuildUser(t[1]), DB:BuildAbility(t[2]), DB:BuildUser(arg4)
	if not Arrays[16][piid] then
		return
	end
	if not Arrays[16][piid][usid] then
		return
	end
	t[3] = tnbr(t[3])
	Arrays[16][piid][usid][abid]["i"][t[3]] = tnbr(t[4])
	if t[3]>DPSMateX.CombatTime["total"] then DPSMateX.CombatTime["total"]=t[3] end
end

trivial = {
	["DPSMateX_HelloWorld"] = function(this) this:GreetBack() end,
	["DPSMateX_Greet"] = function(this, arg2,arg4) this:ReceiveGreet(arg2, arg4) end,
	["KLHTMHOOK"] = function(this, arg2,arg4) this:ThreatIn(arg2,arg4) end
}

lesstrivial = {
	["DPSMateX_AbortVote"..DPSMateX.SYNCVERSION] = function(this) this:ReceiveAbort() end,
	["DPSMateX_Vote"..DPSMateX.SYNCVERSION] = function(this) this:CountVote() end,
	["DPSMateX_StartVote"..DPSMateX.SYNCVERSION] = function(this) this:ReceiveStartVote() end,
	["DPSMateX_VoteSuccess"..DPSMateX.SYNCVERSION] = function(this, arg2) this:VoteSuccess(arg2) end,
	["DPSMateX_VoteFail"..DPSMateX.SYNCVERSION] = function(this) DPSMateX:SendMessage(DPSMateX.L["votefailederror"]) end,
	["DPSMateX_Participate"..DPSMateX.SYNCVERSION] = function(this) this:CountParticipants() end,
	["DPSMateX_SyncTimer"..DPSMateX.SYNCVERSION] = function(this, arg2) this:SetTimer(arg2) end,
}

important = {
	["DPSMateX"] = function(this, arg2,arg4) 
		t = {}
		strgsub(arg2, "(.-),", func) -- name, aura, target, time
		t[3] = GT()
		DB:AwaitAfflicted(arg4, t[1], t[2], t[3])
		if DPSMateX.Parser.HotDispels[t[1]] then DB:AwaitHotDispel(t[1], t[2], arg4, t[3]) end
		DB:AwaitingBuff(arg4, t[1], t[2], t[3])
		DB:AwaitingAbsorbConfirmation(arg4, t[1], t[2], t[3])
	end,
	["DPSMateX_DMGDoneAll"] = function(this, arg2,arg4) this:DMGDoneAllIn(arg2, arg4) end,
	["DPSMateX_DMGDoneStat"] = function(this, arg2,arg4) this:DMGDoneStatIn(arg2, arg4) end,
	["DPSMateX_DMGDoneAbility"] = function(this, arg2,arg4) this:DMGDoneAbilityIn(arg2, arg4) end,
	["DPSMateX_EHealingAll"] = function(this, arg2,arg4) this:HealingAllIn(arg2, arg4, 6) end,
	["DPSMateX_EHealingStat"] = function(this, arg2,arg4) this:HealingStatIn(arg2, arg4, 6) end,
	["DPSMateX_EHealingAbility"] = function(this, arg2,arg4) this:HealingAbilityIn(arg2, arg4, 6) end,
	["DPSMateX_THealingAll"] = function(this, arg2,arg4) this:HealingAllIn(arg2, arg4, 5) end,
	["DPSMateX_THealingStat"] = function(this, arg2,arg4) this:HealingStatIn(arg2, arg4, 5) end,
	["DPSMateX_THealingAbility"] = function(this, arg2,arg4) this:HealingAbilityIn(arg2, arg4, 5) end,
	["DPSMateX_OHealingAll"] = function(this, arg2,arg4) this:HealingAllIn(arg2, arg4, 9) end,
	["DPSMateX_OHealingStat"] = function(this, arg2,arg4) this:HealingStatIn(arg2, arg4, 9) end,
	["DPSMateX_OHealingAbility"] = function(this, arg2,arg4) this:HealingAbilityIn(arg2, arg4, 9) end,
	["DPSMateX_TTakenHealingAll"] = function(this, arg2,arg4) this:HealingAllIn(arg2, arg4, 7) end,
	["DPSMateX_TTakenHealingStat"] = function(this, arg2,arg4) this:HealingTakenStatIn(arg2, arg4, 7) end,
	["DPSMateX_THealingTakenAbility"] = function(this, arg2,arg4) this:HealingTakenAbilityIn(arg2, arg4, 7) end,
	["DPSMateX_ETakenHealingAll"] = function(this, arg2,arg4) this:HealingAllIn(arg2, arg4, 8) end,
	["DPSMateX_ETakenHealingStat"] = function(this, arg2,arg4) this:HealingTakenStatIn(arg2, arg4, 8) end,
	["DPSMateX_EHealingTakenAbility"] = function(this, arg2,arg4) this:HealingTakenAbilityIn(arg2, arg4, 8) end,
	["DPSMateX_OTakenHealingAll"] = function(this, arg2,arg4) this:HealingAllIn(arg2, arg4, 15) end,
	["DPSMateX_OTakenHealingStat"] = function(this, arg2,arg4) this:HealingTakenStatIn(arg2, arg4, 15) end,
	["DPSMateX_OHealingTakenAbility"] = function(this, arg2,arg4) this:HealingTakenAbilityIn(arg2, arg4, 15) end,
	["DPSMateX_Absorbs"] = function(this, arg2,arg4) this:AbsorbsIn(arg2, arg4) end,
	["DPSMateX_iAbsorbs"] = function(this, arg2,arg4) this:iAbsorbsIn(arg2, arg4) end,
	["DPSMateX_Dispels"] = function(this, arg2,arg4) this:DispelsIn(arg2, arg4) end,
	["DPSMateX_iDispels"] = function(this, arg2,arg4) this:iDispelsIn(arg2, arg4) end,
	["DPSMateX_DMGTakenAll"] = function(this, arg2,arg4) this:DMGTakenAllIn(arg2, arg4) end,
	["DPSMateX_DMGTakenStat"] = function(this, arg2,arg4) this:DMGTakenStatIn(arg2, arg4) end,
	["DPSMateX_DMGTakenAbility"] = function(this, arg2,arg4) this:DMGTakenAbilityIn(arg2, arg4) end,
	["DPSMateX_EDTAll"] = function(this, arg2,arg4) this:EDAllIn(4, arg2, arg4) end,
	["DPSMateX_EDTAbility"] = function(this, arg2,arg4) this:EDAbilityIn(4, arg2, arg4) end,
	["DPSMateX_EDTStat"] = function(this, arg2,arg4) this:EDStatIn(4, arg2, arg4) end,
	["DPSMateX_EDDAll"] = function(this, arg2,arg4) this:EDAllIn(3, arg2, arg4) end,
	["DPSMateX_EDDAbility"] = function(this, arg2,arg4) this:EDAbilityIn(3, arg2, arg4) end,
	["DPSMateX_EDDStat"] = function(this, arg2,arg4) this:EDStatIn(3, arg2, arg4) end,
	["DPSMateX_DeathsAll"] = function(this, arg2,arg4) this:DeathsAllIn(arg2, arg4) end,
	["DPSMateX_Deaths"] = function(this, arg2,arg4) this:DeathsIn(arg2, arg4) end,
	["DPSMateX_InterruptsAll"] = function(this, arg2,arg4) this:InterruptsAllIn(arg2, arg4) end,
	["DPSMateX_InterruptsAbility"] = function(this, arg2,arg4) this:InterruptsAbilityIn(arg2, arg4) end,
	["DPSMateX_AurasAll"] = function(this, arg2,arg4) this:AurasAllIn(arg2, arg4) end,
	["DPSMateX_AurasStart"] = function(this, arg2,arg4) this:AurasStartEndIn(arg2, arg4, 1) end,
	["DPSMateX_AurasEnd"] = function(this, arg2,arg4) this:AurasStartEndIn(arg2, arg4, 2) end,
	["DPSMateX_AurasCause"] = function(this, arg2,arg4) this:AurasCauseIn(arg2, arg4) end,
	["DPSMateX_SyncStatus"] = function(this, arg2,arg4) this:SyncStatus(arg2, arg4) end,
	["DPSMateX_Threat"] = function(this, arg2,arg4) this:ThreatAllIn(arg2, arg4) end,
	["DPSMateX_ThreatStats"] = function(this, arg2,arg4) this:ThreatStatsIn(arg2, arg4) end,
}