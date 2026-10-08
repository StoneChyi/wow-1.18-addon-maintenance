-- 金币和银币
local diminfo_Gold = CreateFrame("Button", "diminfo_Gold", UIParent)
local GoldText = diminfo_Gold:CreateFontString("Text", "OVERLAY")
GoldText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
GoldText:SetPoint("LEFT", diminfo_Bag, "RIGHT", 20, 0)
diminfo_Gold:SetPoint("LEFT", diminfo_Bag, "RIGHT", 20, 0)
local Gold = diminfo_Gold:CreateTexture(nil, "OVERLAY")
Gold:SetTexture("Interface\\MoneyFrame\\UI-MoneyIcons")
Gold:SetWidth(12)
Gold:SetHeight(12)
Gold:SetPoint("LEFT", GoldText, "RIGHT", 2, 0)
Gold:SetTexCoord(0, 0.255, 0, 1)

local SilverText = diminfo_Gold:CreateFontString("SilverText", "OVERLAY")
SilverText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
SilverText:SetPoint("LEFT", Gold, "RIGHT", 2, 0)
local Silver = diminfo_Gold:CreateTexture(nil, "OVERLAY")
Silver:SetTexture("Interface\\MoneyFrame\\UI-MoneyIcons")
Silver:SetWidth(12)
Silver:SetHeight(12)
Silver:SetPoint("LEFT", SilverText, "RIGHT", 0, 0)
Silver:SetTexCoord(0.256, 0.511, 0, 1)

-- 新增铜币显示
local CopperText = diminfo_Gold:CreateFontString("CopperText", "OVERLAY")
CopperText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
CopperText:SetPoint("LEFT", Silver, "RIGHT", 2, 0)
local Copper = diminfo_Gold:CreateTexture(nil, "OVERLAY")
Copper:SetTexture("Interface\\MoneyFrame\\UI-MoneyIcons")
Copper:SetWidth(12)
Copper:SetHeight(12)
Copper:SetPoint("LEFT", CopperText, "RIGHT", 0, 0)
Copper:SetTexCoord(0.512, 0.767, 0, 1)

local function OnEvent()
	-- 记录收入与支出
	if event == "PLAYER_LOGIN" then
		diminfo_lastmoney = GetMoney()
		diminfo_income = 0
	elseif event == "PLAYER_MONEY" then
    	local diminfo_newmoney = GetMoney()
    	if diminfo_newmoney ~= diminfo_lastmoney then
    		local inc_dec = (diminfo_newmoney - diminfo_lastmoney)
    		diminfo_income = diminfo_income + inc_dec
            diminfo_lastmoney = diminfo_newmoney
        end
	end

	local totalMoney = GetMoney()
	local gold = floor(totalMoney / (COPPER_PER_SILVER * SILVER_PER_GOLD))	
	local silver = floor(math.mod(totalMoney, COPPER_PER_SILVER * SILVER_PER_GOLD) / COPPER_PER_SILVER)
	local copper = math.mod(totalMoney, COPPER_PER_SILVER)

	-- 根据金币数量决定显示方式
	if gold > 0 then
		-- 大于0金币时显示金币和银币
		GoldText:SetText(gold)
		SilverText:SetText(silver)
		CopperText:SetText("")
		
		-- 显示金币和银币图标
		Gold:Show()
		Silver:Show()
		Copper:Hide()
	else
		-- 等于0金币时显示银币和铜币
		GoldText:SetText("")
		SilverText:SetText(silver)
		CopperText:SetText(copper)
		
		-- 隐藏金币图标，显示银币和铜币图标
		Gold:Hide()
		Silver:Show()
		Copper:Show()
	end
	
	-- 调整主框架大小以适应新内容
	local totalWidth = GoldText:GetStringWidth() + SilverText:GetStringWidth() + CopperText:GetStringWidth() + 30
	diminfo_Gold:SetWidth(totalWidth)
	diminfo_Gold:SetHeight(12)
end

diminfo_Gold:SetScript("OnEnter", function()
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine("货币信息")
	GameTooltip:AddLine("左键:计算器", .3, 1, .6)
	if IsAddOnLoaded("Accountant") then
		GameTooltip:AddLine("右键:收支明细", .3, 1, .6)
	end
	if diminfo_income > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("本次登录净利润")
		SetTooltipMoney(GameTooltip, diminfo_income)
	end
	GameTooltip:Show()
end)
diminfo_Gold:SetScript("OnLeave", function() GameTooltip:Hide() end)

diminfo_Gold:RegisterEvent("PLAYER_LOGIN")
diminfo_Gold:RegisterEvent("PLAYER_MONEY")
diminfo_Gold:SetScript("OnEvent", OnEvent)
diminfo_Gold:SetScript("OnMouseDown", function()
	if arg1 == "LeftButton" then
		xcalc_windowdisplay()
	else
		if IsAddOnLoaded("Accountant") then
			AccountantButton_OnClick()
		end
	end
end)