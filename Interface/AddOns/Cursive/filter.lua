if not Cursive.nampower then
	return
end

local filter = {
}

filter.attackable = function(unit)
	return UnitCanAttack("player", unit) and true or false
end

filter.player = function(unit)
	return UnitIsPlayer(unit) and true or false
end

filter.notplayer = function(unit)
	return not UnitIsPlayer(unit) and true or false
end

filter.infight = function(unit)
	return UnitAffectingCombat(unit) and true or false
end

filter.hascurse = function(unit)
	return Cursive.curses:HasAnyCurse(unit) and true or false
end

filter.alive = function(unit)
	return not UnitIsDead(unit) and true or false
end

filter.range = function(unit)
	if IsSpellInRange then
		-- 16707 is hex which has 45 yd range
		return IsSpellInRange(16707, unit) == 1 and true or false
	else
		return CheckInteractDistance(unit, 4) and true or false
	end
end

filter.icon = function(unit)
	return GetRaidTargetIndex(unit) and true or false
end

filter.normal = function(unit)
	local elite = UnitClassification(unit)
	return elite == "normal" and true or false
end

filter.elite = function(unit)
	local elite = UnitClassification(unit)
	return (elite == "elite" or elite == "rareelite") and true or false
end

filter.hostile = function(unit)
	return UnitIsEnemy("player", unit) and true or false
end

filter.notignored = function(unit)
	if not Cursive.db.profile.ignorelist or table.getn(Cursive.db.profile.ignorelist) == 0 then
		return true
	end

	local unitName = UnitName(unit)
	if not unitName then
		return true
	end
	for _, str in ipairs(Cursive.db.profile.ignorelist) do
		if string.find(string.lower(unitName), string.lower(str), nil, not Cursive.db.profile.ignorelistuseregex) then
			return false
		end
	end
	return true
end
-- 新增 by 武藤纯子酱 2025.8.28
filter.distance = function(unit)
	local distance = 0
	
	if pcall(UnitXP, "nop", "nop") then
		distance = UnitXP("distanceBetween", "player", unit)
	end
	
	if distance and Cursive.db.profile.filterdistance then
		return distance <= Cursive.db.profile.filterdistance
	else
		return false
	end
end

filter.insight = function(unit)
	if pcall(UnitXP, "nop", "nop") then
		return UnitXP("inSight", "player", unit) and true or false
	else
		return true
	end
end

filter.maxhealth = function(unit)
	local unithealthmax = UnitHealthMax(unit)/10000
	
	if unithealthmax and Cursive.db.profile.filtermaxhealth then
		if unithealthmax > Cursive.db.profile.filtermaxhealth then
			return true
		else
			return false
		end
	else
		return false
	end
end

Cursive.filter = filter

function Cursive:ShouldDisplayGuid(guid)
	-- never display units that don't exist
	if not UnitExists(guid) then
		return false
	end

	-- never display dead units
	if not Cursive.filter.alive(guid) then
		return false
	end

	local targetGuid = GetUnitGUID("target")

	-- always show target if attackable
	if (targetGuid == guid) and filter.attackable(guid) then
		return true
	end

	-- always show raid marks if attackable and not in combat or this guid is affecting combat
	if filter.icon(guid) and filter.attackable(guid) and (not UnitAffectingCombat("player") or UnitAffectingCombat(guid)) then
		return true
	end

	if Cursive.db.profile.filterincombat and not filter.infight(guid) then
		return false
	end

	if Cursive.db.profile.filterhascurse and not filter.hascurse(guid) then
		return false
	end

	if Cursive.db.profile.filterhostile and not filter.hostile(guid) then
		return false
	end

	if Cursive.db.profile.filterattackable and not filter.attackable(guid) then
		return false
	end

	if Cursive.db.profile.filterrange and not filter.range(guid) then
		return false
	end

	if Cursive.db.profile.filterraidmark and not filter.icon(guid) then
		return false
	end

	if Cursive.db.profile.filterplayer and not filter.player(guid) then
		return false
	end

	if Cursive.db.profile.filternotplayer and not filter.notplayer(guid) then
		return false
	end

	if Cursive.db.profile.filterignored and not filter.notignored(guid) then
		return false
	end
	
	if Cursive.db.profile.filterdistance and not filter.distance(guid) then -- 新增 by 武藤纯子酱 2025.9.2
		return false
	end	

	if Cursive.db.profile.filterinsight and not filter.insight(guid) then -- 新增 by 武藤纯子酱 2025.9.2
		return false
	end

	if Cursive.db.profile.filtermaxhealth and not filter.maxhealth(guid) then -- 新增 by 武藤纯子酱 2025.9.2
		return false
	end	

	return true
end
