if not Cursive.nampower then
	return
end

-- add (1) for first stack of buffs/debuffs
-- other addons already do this, avoid having to parse both formats
-- 修改中文支持 by 武藤纯子酱 2025.8.28
if GetLocale() and GetLocale() == "zhCN" then
	AURAADDEDOTHERHELPFUL = "%s获得了%s的效果（1）。"
	AURAADDEDOTHERHARMFUL = "%s受到了%s效果的影响（1）。"
	AURAADDEDSELFHARMFUL = "你受到了%s效果的影响（1）。"
	AURAADDEDSELFHELPFUL = "你获得了%s的效果（1）。"
else
	AURAADDEDOTHERHELPFUL = "%s gains %s (1)."
	AURAADDEDOTHERHARMFUL = "%s is afflicted by %s (1)."
	AURAADDEDSELFHARMFUL = "You are afflicted by %s (1)."
	AURAADDEDSELFHELPFUL = "You gain %s (1)."
end

Cursive.core = CreateFrame("Frame", "Cursive", UIParent)

Cursive.core.tooltipScan = CreateFrame("GameTooltip", "CursiveTooltipScan", UIParent, "GameTooltipTemplate")

Cursive.core.guids = {}

Cursive.core.add = function(unit)
	local guid = GetUnitGUID(unit)

	if guid and not UnitIsDead(unit) then
		Cursive.core.guids[guid] = GetTime()
	end
end

Cursive.core.addGuid = function(guid)
	if UnitExists(guid) and not UnitIsDead(guid) then
		Cursive.core.guids[guid] = GetTime()
	end
end

Cursive.core.remove = function(guid)
	Cursive.core.guids[guid] = nil
end

Cursive.core.enable = function()
	-- unitstr
	Cursive.core:RegisterEvent("PLAYER_TARGET_CHANGED")
	-- arg1
  Cursive.core:RegisterEvent("UNIT_COMBAT_GUID") -- this can get called with player/target/raid1 etc
  Cursive.core:RegisterEvent("UNIT_MODEL_CHANGED_GUID")
end

Cursive.core.disable = function()
	Cursive.core:UnregisterAllEvents()
	Cursive.core.guids = {}
end

Cursive.core:SetScript("OnEvent", function()
	if event == "PLAYER_TARGET_CHANGED" then
		this.add("target")
	else
		-- arg1 is guid
		this.addGuid(arg1)
	end
end)