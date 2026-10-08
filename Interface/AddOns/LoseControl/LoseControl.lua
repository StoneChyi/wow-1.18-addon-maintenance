local L = "LoseControl"
local BS = AceLibrary("Babble-Spell-2.2");
local CC      = "CC"
local Silence = "Silence"
local Root    = "Root"
local Snare   = "Snare"

--[[
	SaySapped: Says "Sapped!" when you get sapped allowing you to notify nearby players about it.
	Also works for many other CCs.
	Author: Coax  - Nostalrius PvP
	Translate and rework by: CFM - LH
	Original idea: Bitbyte of Icecrown
--]]

-- Slash Command
SLASH_LOSECONTROL1 = '/losecontrol'
SLASH_LOSECONTROL2 = '/lc'
function SlashCmdList.LOSECONTROL(msg, editbox)
	local cmd, arg = string.match(msg, "^(%S*)%s*(.-)$")
	
	if cmd == "unlock" then
		-- 解锁模式，显示图标并允许移动
		LCPlayer:Show()
		LCPlayer.texture:SetTexture("Interface\\Icons\\Spell_Nature_Polymorph")
		LCPlayer:SetMovable(true)
		LCPlayer:EnableMouse(true)
		LCPlayer:RegisterForDrag("LeftButton")
		LCPlayer:SetScript("OnDragStart", function()
			this:StartMoving()
		end)
		LCPlayer:SetScript("OnDragStop", function()
			this:StopMovingOrSizing()
			-- 保存位置
			local point, _, relativePoint, xOfs, yOfs = this:GetPoint()
			if not LoseControlDB then LoseControlDB = {} end
			LoseControlDB.point = point
			LoseControlDB.relativePoint = relativePoint
			LoseControlDB.xOfs = xOfs
			LoseControlDB.yOfs = yOfs
		end)
		DEFAULT_CHAT_FRAME:AddMessage("|cffffff55LoseControl: 解锁模式已启动，可拖动图标")
		return
	elseif cmd == "lock" then
		-- 锁定模式，隐藏图标并重置拖动状态
		LCPlayer:Hide()
		LCPlayer:ResetDragState()
		DEFAULT_CHAT_FRAME:AddMessage("|cffffff55LoseControl: 已锁定并隐藏图标")
		return
	elseif cmd == "size" then
		-- 调整图标大小
		local size = tonumber(arg)
		if size and size >= 20 and size <= 200 then
			LCPlayer:SetWidth(size)
			LCPlayer:SetHeight(size)
			if not LoseControlDB then LoseControlDB = {} end
			LoseControlDB.size = size
			DEFAULT_CHAT_FRAME:AddMessage("|cffffff55LoseControl: 图标大小已设置为 "..size)
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cffffff55LoseControl: 请输入有效的大小值(20-200)，例如: /lc size 50")
		end
		return
	elseif cmd == "alpha" then
		-- 调整图标透明度
		local alpha = tonumber(arg)
		if alpha and alpha >= 0 and alpha <= 1 then
			LCPlayer:SetAlpha(alpha)
			if not LoseControlDB then LoseControlDB = {} end
			LoseControlDB.alpha = alpha
			DEFAULT_CHAT_FRAME:AddMessage("|cffffff55LoseControl: 图标透明度已设置为 "..alpha)
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cffffff55LoseControl: 请输入有效的透明度值(0-1)，例如: /lc alpha 0.8")
		end
		return
  	elseif SaySappedConfig then
		SaySappedConfig = false
		DEFAULT_CHAT_FRAME:AddMessage(SS_DISABLED)
	else
		SaySappedConfig = true
		DEFAULT_CHAT_FRAME:AddMessage(SS_ENABLED)
	end
end

if GetLocale()=="zhCN" then
    SS_Sapped='被闷棍了！'
    SS_SpellSap='闷棍'
    SS_Loaded='|cffffff55LoseControl: 控制技能提示已加载，使用 /lc 开关提示。'
    SS_SELFHARMFULL='你受到了'
    SS_DISABLED='|cffffff55LoseControl: 自动喊话已关闭！'
    SS_ENABLED='|cffffff55LoseControl: 自动喊话已开启！'
else
    SS_Sapped='Sapped!'
    SS_SpellSap=' Sap.'
    SS_Loaded='|cffffff55LoseControl: Loaded. Use /lc to toggle.'
    SS_SELFHARMFULL='You are'
    SS_DISABLED='|cffffff55LoseControl: Auto-announce disabled!'
    SS_ENABLED='|cffffff55LoseControl: Auto-announce enabled!'
end

local SaySapped = CreateFrame("Frame",nil,UIParent)
SaySapped:RegisterEvent("ADDON_LOADED")

SaySapped:SetScript("OnEvent", function()
	if arg1 == "LoseControl" then
		DEFAULT_CHAT_FRAME:AddMessage(SS_Loaded)
		if not SaySappedConfig then
			SaySappedConfig = true;
		end
		
		-- 加载保存的位置和大小
		if LoseControlDB then
			if LoseControlDB.point then
				LCPlayer:ClearAllPoints()
				LCPlayer:SetPoint(LoseControlDB.point, UIParent, LoseControlDB.relativePoint, LoseControlDB.xOfs, LoseControlDB.yOfs)
			end
			
			-- 加载保存的大小
			if LoseControlDB.size then
				LCPlayer:SetWidth(LoseControlDB.size)
				LCPlayer:SetHeight(LoseControlDB.size)
			end
			
			-- 加载保存的透明度
			if LoseControlDB.alpha then
				LCPlayer:SetAlpha(LoseControlDB.alpha)
			end
		end
		
		SaySapped.checkbuff = CreateFrame("Frame")
		SaySapped.checkbuff:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
		SaySapped.checkbuff:SetScript("OnEvent", function()
			if string.find(arg1, SS_SELFHARMFULL) then
				SaySapped_FilterDebuffs(arg1)
			end
		end)
	end
end)

function SaySapped_FilterDebuffs(spell)
    if (string.find(spell, SS_SpellSap) or string.find(spell, "闷棍")) and SaySappedConfig then
        SendChatMessage(SS_Sapped,"SAY")
        DEFAULT_CHAT_FRAME:AddMessage(SS_Sapped)
    end
end

local spellIds = {
    -- 通用
	["眩晕"] = CC,
    ["沉默"] = Silence,
    ["定身"] = Root,
	["投网"] = Root,
    ["妖术"] = CC,
    
    -- 德鲁伊
    ["野性冲锋效果"] = Root,
    ["休眠"] = CC,
    ["突袭"] = CC,
    ["纠缠根须"] = Root,
    
    -- 猎人
    ["冰冻陷阱"] = CC,
    ["胁迫"] = CC,
    ["驱散野兽"] = CC,
    ["驱散射击"] = CC,
    ["翼龙钉刺"] = CC,
    
    -- 法师
    ["冰霜新星"] = Root,
    ["变形术"] = CC,
    ["冰冻"] = Root,
    ["冰锥术"] = Snare,
    ["法术反制 - 沉默"] = Silence,
    
    -- 圣骑士
    ["制裁之锤"] = CC,
    ["忏悔"] = CC,
    
    -- 牧师
    ["精神控制"] = CC,
    ["心灵尖啸"] = CC,
    ["沉默"] = Silence,
    ["昏阙"] = CC,
    
    -- 盗贼
    ["致盲"] = CC,
    ["偷袭"] = CC,
    ["凿击"] = CC,
    ["肾击"] = CC,
    ["闷棍"] = CC,
    
    -- 术士
    ["死亡缠绕"] = CC,
    ["恐惧"] = CC,
    ["恐惧嚎叫"] = CC,
    ["诱惑"] = CC,
    
    -- 战士
    ["冲锋击昏"] = CC,
    ["拦截昏迷"] = CC,
    ["破胆怒吼"] = CC,
    ["刺耳怒吼"] = Snare,
    ["致死打击"] = Snare,
    
    -- 种族技能
    ["战争践踏"] = CC,
    
    -- 其他
    ["寒冰爆炸"] = CC,
    ["迅猛踢击"] = CC,
    ["鞭笞"] = CC,
    ["水晶凝视"] = CC,
    ["蛛网"] = Root,
    ["恐吓"] = CC,
    ["恐惧尖啸"] = CC,
    ["闪电冻结"] = CC,
    ["击倒"] = CC,
    ["网"] = Root,
    ["闪光炸弹"] = CC,
    ["鲁莽冲锋"] = CC,
}

	LCPlayer = CreateFrame("Frame", "LoseControlPlayer", pfUI and UIParent or ActionButtonTemplate)
	LCPlayer:SetHeight(50)
	LCPlayer:SetWidth(50)
	LCPlayer:SetPoint("CENTER", 0,0)
	LCPlayer:RegisterEvent("UNIT_AURA")
	LCPlayer:RegisterEvent("PLAYER_AURAS_CHANGED")
	
	-- 添加重置拖动状态的函数
	function LCPlayer:ResetDragState()
		self:SetMovable(false)
		self:EnableMouse(false)
		self:SetScript("OnDragStart", nil)
		self:SetScript("OnDragStop", nil)
	end

	if pfUI then
		-- 使用 pfUI 样式
		pfUI.api.CreateBackdrop(LCPlayer, nil, true)
		LCPlayer.texture = LCPlayer:CreateTexture(nil, "ARTWORK")
		LCPlayer.texture:SetTexCoord(.08, .92, .08, .92)
		LCPlayer.texture:SetPoint("TOPLEFT", LCPlayer, "TOPLEFT", 2, -2)
		LCPlayer.texture:SetPoint("BOTTOMRIGHT", LCPlayer, "BOTTOMRIGHT", -2, 2)
		
		-- 定义不同控制类型的颜色
		LCPlayer.colors = {
			[CC] = {1, 0.2, 0.2},      -- 红色 - 眩晕
			[Silence] = {0.2, 0.2, 1},  -- 蓝色 - 沉默
			[Root] = {1, 0.7, 0.1},     -- 橙色 - 定身
			[Snare] = {0.7, 0.7, 0.7}   -- 灰色 - 减速
		}

		-- 直接使用 pfUI 的边框
		LCPlayer.border = LCPlayer.backdrop
	else
		-- 使用原始样式
		LCPlayer.texture = LCPlayer:CreateTexture(LCPlayer, "BACKGROUND")
		LCPlayer.texture:SetAllPoints(LCPlayer)
	end

	LCPlayer.cooldown = CreateFrame("Model", "Cooldown", LCPlayer, "CooldownFrameTemplate")
	LCPlayer.cooldown:SetAllPoints(pfUI and LCPlayer.texture or LCPlayer)
	LCPlayer.maxExpirationTime = 0
	LCPlayer:Hide()
	LCPlayer:SetScript("OnEvent", function()
		if event=="UNIT_AURA" and arg1 ~= "player" then return end
		local spellFound = false
		for i=1, 16 do
			local texture = UnitDebuff("player", i)
			GameTooltip:ClearLines()
			GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
			GameTooltip:SetUnitDebuff("player", i)
			local buffName = GameTooltipTextLeft1:GetText()
			GameTooltip:Hide()
			if spellIds[buffName] then
				spellFound = true
				for j=0, 31 do
					local buffTexture = GetPlayerBuffTexture(j)
					if texture == buffTexture then
						local expirationTime = GetPlayerBuffTimeLeft(j)
						LCPlayer:Show()
						LCPlayer.texture:SetTexture(buffTexture)
						LCPlayer.cooldown:SetModelScale(2)
						
						-- 设置边框颜色
						if pfUI and LCPlayer.colors[spellIds[buffName]] then
							local color = LCPlayer.colors[spellIds[buffName]]
							LCPlayer:SetBackdropBorderColor(color[1], color[2], color[3], 1)
						end
						if LCPlayer.maxExpirationTime <= expirationTime then
							CooldownFrame_SetTimer(LCPlayer.cooldown, GetTime(), expirationTime, 1)
							LCPlayer.maxExpirationTime = expirationTime
						end
						return
					end
				end
			end
		end
		if spellFound == false then
			LCPlayer.maxExpirationTime = 0
			LCPlayer:Hide()
		end
	end)
