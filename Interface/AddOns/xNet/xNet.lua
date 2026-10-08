local f = CreateFrame("Frame", "xNETFrame", UIParent)
f:SetWidth(250)
f:SetHeight(24)
f:SetPoint("CENTER", 0, 150)
f:SetMovable(true)

local Text = f:CreateFontString(nil, "OVERLAY")
Text:SetFont(STANDARD_TEXT_FONT, 24, "OUTLINE")
Text:SetPoint("CENTER", 0, 0)
Text:Hide()

local t = 0

local visibleLowHealth = false
local visibleLowNet = false
local lowNetMessage = ""

local function Show(msg)
	Text:SetText(msg)
	Text:Show()
	f:EnableMouse(true)
end

local function Hide()
	Text:Hide()
	f:EnableMouse(false)
end

local function OnUpdate()
	local _, _, lag = GetNetStats()
	if lag < 300 then
		visibleLowNet = false
		t = 0
		lowNetMessage = ""
	elseif (lag >= 300 and lag < 500) then
		t = 0
		visibleLowNet = true
		lowNetMessage = "|cff0CD809" .. format("%.0f", lag) .. "|rms 延迟，注意安全"
	elseif (lag >= 500 and lag < 1000) then
		t = 0
		visibleLowNet = true
		lowNetMessage = "|cffE8DA0F" .. format("%.0f", lag) .. "|rms 延迟，注意安全！"
	else
		visibleLowNet = true
		lowNetMessage = "|cffD80909" .. format("%.0f", lag) .. "|rms 延迟，非常危险！！！！！"
		local now = time()
		if (now - t > 10) then
			PlaySound("RaidWarning", "SFX")
			t = now
		end
	end

	if visibleLowNet or visibleLowHealth then
		local msg = ""
		if visibleLowNet then
			msg = lowNetMessage .. "|N"
		end
		if visibleLowHealth then
			msg = msg .. "|cffD80909" .. "低血量警告"
		end
		Show(msg)
	else
		Hide()
	end
end

local function OnMouseDown()
	if (arg1 == "LeftButton") then
		f:StartMoving()
	end
end

local function OnMouseUp()
	if (arg1 == "LeftButton") then
		f:StopMovingOrSizing()
	end
end


local lastSelfHealthPercentage = 0

-- 低于30%血量提醒
local threshold = 0.3

local function OnEvent()
	if event == "UNIT_HEALTH" and arg1 == "player" then
		local healthAmount = UnitHealth("player");
		local healthPercentage = healthAmount / UnitHealthMax("player");
		visibleLowHealth = healthPercentage < threshold
		if visibleLowHealth and lastSelfHealthPercentage >= threshold then
			PlaySound("RaidWarning", "SFX")
		end
		lastSelfHealthPercentage = healthPercentage
	end
end

f:RegisterEvent("UNIT_HEALTH")
f:SetScript("OnEvent", OnEvent)
f:SetScript("OnUpdate", OnUpdate)
f:SetScript("OnMouseDown", OnMouseDown)
f:SetScript("OnMouseUp", OnMouseUp)
