local stf = strfind
local _G = getglobal
local tinsert = table.insert
local tremove = table.remove
local UN = UnitName
local strform = string.format
local flr = floor
local strgfind = string.gfind
local strfind = string.find
local GT = GetTime
local tnbr = tonumber

function MPOWA:IsMounted()
	local desc
	for i=0,31 do
		MPowa_Tooltip:ClearLines()
		MPowa_Tooltip:SetPlayerBuff(GetPlayerBuff(i, "HELPFUL|PASSIVE"))
		desc = MPowa_TooltipTextLeft2:GetText()
		if (not desc) then break end
		if stf(desc, MPOWA_SCRIPT_MOUNT_100) or stf(desc, MPOWA_SCRIPT_MOUNT_60) then
			self.mounted = true
			return
		end
	end
	self.mounted = false
end

local UnitInParty = UnitInParty
function MPOWA:InParty()
	return GetNumPartyMembers() > 0
end

function MPOWA:InBG()
	local status
	for i=1, 4 do
		status = GetBattlefieldStatus(i)
		if status == "active" then
			self.bg = true
			break
		end
	end
	self.bg = false
end

function MPOWA:InInstance()
	local zone = GetRealZoneText()
	if self.Zones[zone] then
		self.instance = true
	end
	self.instance = false
end

-- 法术施放监控集成条件函数
-- 这些函数与SkillCastMonitor.lua集成，用于监控法术施放事件
-- 使用方法：在MPOWA插件的"自定义条件"区域输入以下表达式之一

-- 示例1：监控特定法术"圣光闪现"是否施放成功
-- IsSpecificSpellCast("圣光闪现")
-- 
-- 示例2：使用组合条件监控
-- IsSpellCastSucceeded() and GetLastSpellName() == "圣光闪现"
-- 
-- 示例3：监控法术开始施放事件
-- IsSpellCastStart()
-- 
-- 示例4：监控任何法术施放成功
-- IsSpellCastSucceeded()
-- 
-- 调试说明：
-- 1. 输入/shm args 命令可以在聊天框显示更多调试参数
-- 2. 输入/shm allevents 命令可以显示所有法术相关事件的详细信息
-- 3. 在使用前，请确保MPOWA插件已启用自定义条件功能
-- 4. 法术名称必须完全匹配（包括大小写和特殊字符）

-- 检测法术是否开始施放
function IsSpellCastStart()
	if SkillCastMonitorEvents and SkillCastMonitorEvents.spellCastStart then
		-- 检查事件是否过期
		local currentTime = GetTime()
		if SkillCastMonitorEvents.eventTimer > 0 and 
		   currentTime - SkillCastMonitorEvents.eventTimer <= SkillCastMonitorEvents.eventDuration then
			return true
		end
	end
	return false
end

-- 法术监控函数 - 检测最近是否有法术施放成功
function IsSpellCastSucceeded()
    -- 检查是否有全局的SkillCastMonitorEvents变量
    if not SkillCastMonitorEvents then
        if SkillCastMonitorDebugAllEvents == 1 then
            DEFAULT_CHAT_FRAME:AddMessage("[SCM] 未找到SkillCastMonitorEvents变量", 1, 0, 0)
        end
        return false
    end
    
    -- 检查是否有spellCastSucceeded标志（变量名修复）
    if not SkillCastMonitorEvents.spellCastSucceeded then
        if SkillCastMonitorDebugAllEvents == 1 then
            DEFAULT_CHAT_FRAME:AddMessage("[SCM] 未检测到法术施放成功事件", 1, 0, 0)
        end
        return false
    end
    
    -- 检查事件是否在有效期内（默认5秒）
    local currentTime = GetTime()
    local isValid = false
    
    if SkillCastMonitorEvents.eventTimer > 0 then
        isValid = (currentTime - SkillCastMonitorEvents.eventTimer) < SkillCastMonitorEvents.eventDuration
        
        if SkillCastMonitorDebugAllEvents == 1 then
            local status = isValid and "有效" or "已过期"
            DEFAULT_CHAT_FRAME:AddMessage("[SCM] 法术施放成功状态: " .. status .. 
                                          " (时间差: " .. string.format("%.2f", currentTime - SkillCastMonitorEvents.eventTimer) .. "秒)", 
                                          isValid and 0 or 1, isValid and 1 or 0, isValid and 0 or 0)
        end
    else
        if SkillCastMonitorDebugAllEvents == 1 then
            DEFAULT_CHAT_FRAME:AddMessage("[SCM] 法术施放成功事件计时器未设置", 1, 0, 0)
        end
    end
    
    return isValid
end

-- 检测法术是否施放失败
function IsSpellCastFailed()
	if SkillCastMonitorEvents and SkillCastMonitorEvents.spellCastFailed then
		-- 检查事件是否过期
		local currentTime = GetTime()
		if SkillCastMonitorEvents.eventTimer > 0 and 
		   currentTime - SkillCastMonitorEvents.eventTimer <= SkillCastMonitorEvents.eventDuration then
			return true
		end
	end
	return false
end

-- 检测法术是否未命中
function IsSpellMissed()
	if SkillCastMonitorEvents and SkillCastMonitorEvents.spellMissed then
		-- 检查事件是否过期
		local currentTime = GetTime()
		if SkillCastMonitorEvents.eventTimer > 0 and 
		   currentTime - SkillCastMonitorEvents.eventTimer <= SkillCastMonitorEvents.eventDuration then
			return true
		end
	end
	return false
end

-- 检测近战攻击是否未命中
function IsSwingMissed()
	if SkillCastMonitorEvents and SkillCastMonitorEvents.swingMissed then
		-- 检查事件是否过期
		local currentTime = GetTime()
		if SkillCastMonitorEvents.eventTimer > 0 and 
		   currentTime - SkillCastMonitorEvents.eventTimer <= SkillCastMonitorEvents.eventDuration then
			return true
		end
	end
	return false
end

-- 检测指定事件是否发生
function IsSpecificSpellEvent(eventName)
	if SkillCastMonitorEvents and SkillCastMonitorEvents.lastEvent then
		local currentTime = GetTime()
		if SkillCastMonitorEvents.lastEvent == eventName and 
		   SkillCastMonitorEvents.eventTimer > 0 and 
		   currentTime - SkillCastMonitorEvents.eventTimer <= SkillCastMonitorEvents.eventDuration then
			return true
		end
	end
	return false
end

-- 检测指定法术的指定事件是否发生
function IsSpecificSpellEventForSpell(eventName, spellName)
	if SkillCastMonitorEvents and SkillCastMonitorEvents.lastEvent and SkillCastMonitorEvents.lastSpellName then
		local currentTime = GetTime()
		if SkillCastMonitorEvents.lastEvent == eventName and 
		   SkillCastMonitorEvents.lastSpellName == spellName and 
		   SkillCastMonitorEvents.eventTimer > 0 and 
		   currentTime - SkillCastMonitorEvents.eventTimer <= SkillCastMonitorEvents.eventDuration then
			return true
		end
	end
	return false
end

-- 检测是否有任意法术事件发生（最近的事件）
function HasRecentSpellEvent()
	if SkillCastMonitorEvents and SkillCastMonitorEvents.lastEvent then
		local currentTime = GetTime()
		if SkillCastMonitorEvents.eventTimer > 0 and 
		   currentTime - SkillCastMonitorEvents.eventTimer <= SkillCastMonitorEvents.eventDuration then
			return true
		end
	end
	return false
end

-- 获取最近的法术事件名称
function GetLastSpellEventName()
	if SkillCastMonitorEvents and SkillCastMonitorEvents.lastEvent then
		return SkillCastMonitorEvents.lastEvent
	end
	return nil
end

-- 法术监控函数 - 获取最近施放的法术名称
function GetLastSpellName()
    -- 检查是否有全局的SkillCastMonitorEvents变量
    if not SkillCastMonitorEvents then
        if SkillCastMonitorDebugAllEvents == 1 then
            DEFAULT_CHAT_FRAME:AddMessage("[SCM] 未找到SkillCastMonitorEvents变量", 1, 0, 0)
        end
        return nil
    end
    
    -- 返回最近的法术名称（使用点语法提高可读性）
    local spellName = SkillCastMonitorEvents.lastSpellName
    
    if SkillCastMonitorDebugAllEvents == 1 then
        if spellName then
            DEFAULT_CHAT_FRAME:AddMessage("[SCM] 最近的法术名称: " .. spellName, 0, 1, 0)
        else
            DEFAULT_CHAT_FRAME:AddMessage("[SCM] 未找到最近的法术名称", 1, 0, 0)
        end
    end
    
    return spellName
end

-- 获取最近事件的剩余持续时间
function GetSpellEventRemainingDuration()
	if SkillCastMonitorEvents and SkillCastMonitorEvents.eventTimer > 0 then
		local currentTime = GetTime()
		local remaining = SkillCastMonitorEvents.eventDuration - (currentTime - SkillCastMonitorEvents.eventTimer)
		if remaining > 0 then
			return remaining
		end
	end
	return 0
end

-- 设置事件持续时间（秒）
function SetSpellEventDuration(seconds)
	if SkillCastMonitorEvents and type(seconds) == "number" and seconds > 0 then
		SkillCastMonitorEvents.eventDuration = seconds
		return true
	end
	return false
end

-- 重置所有法术事件状态
function ResetSpellEvents()
	if SkillCastMonitorEvents then
		SkillCastMonitorEvents.lastEvent = nil
		SkillCastMonitorEvents.lastSpellName = nil
		SkillCastMonitorEvents.eventTimer = 0
		SkillCastMonitorEvents.spellCastStart = false
		SkillCastMonitorEvents.spellCastSucceeded = false
		SkillCastMonitorEvents.spellCastFailed = false
		SkillCastMonitorEvents.spellMissed = false
		SkillCastMonitorEvents.swingMissed = false
		return true
	end
	return false
end

-- 检查法术监控是否已启用
function IsSpellCastMonitorEnabled()
	return SkillCastMonitorEnabled and SkillCastMonitorEnabled == 1
end

-- 法术监控函数 - 检测特定法术是否成功施放
function IsSpecificSpellCast(spellName)
    -- 参数验证
    if not spellName or type(spellName) ~= "string" then
        if SkillCastMonitorDebugAllEvents == 1 then
            DEFAULT_CHAT_FRAME:AddMessage("[SCM] IsSpecificSpellCast函数参数错误: 法术名称必须是字符串", 1, 0, 0)
        end
        return false
    end
    
    -- 检查是否有全局的SkillCastMonitorEvents变量
    if not SkillCastMonitorEvents then
        if SkillCastMonitorDebugAllEvents == 1 then
            DEFAULT_CHAT_FRAME:AddMessage("[SCM] 未找到SkillCastMonitorEvents变量", 1, 0, 0)
        end
        return false
    end
    
    -- 首先检查是否有成功施放标志和最近的法术名称
    if not SkillCastMonitorEvents.spellCastSucceeded or not SkillCastMonitorEvents.lastSpellName then
        if SkillCastMonitorDebugAllEvents == 1 then
            if not SkillCastMonitorEvents.spellCastSucceeded then
                DEFAULT_CHAT_FRAME:AddMessage("[SCM] 未检测到法术施放成功标志", 1, 0, 0)
            end
            if not SkillCastMonitorEvents.lastSpellName then
                DEFAULT_CHAT_FRAME:AddMessage("[SCM] 未找到最近的法术名称", 1, 0, 0)
            end
        end
        return false
    end
    
    -- 检查法术名称是否匹配
    local nameMatches = (SkillCastMonitorEvents.lastSpellName == spellName)
    
    -- 检查事件是否在有效期内
    local isValid = false
    if SkillCastMonitorEvents.eventTimer > 0 then
        isValid = (GetTime() - SkillCastMonitorEvents.eventTimer) < SkillCastMonitorEvents.eventDuration
    end
    
    -- 完整检查：标志为true + 法术名称匹配 + 事件在有效期内
    local result = SkillCastMonitorEvents.spellCastSucceeded and nameMatches and isValid
    
    -- 调试信息
    if SkillCastMonitorDebugAllEvents == 1 then
        local status = result and "有效" or "无效"
        local nameStatus = nameMatches and "匹配" or "不匹配"
        local timeStatus = isValid and "在有效期内" or "已过期"
        
        local debugMsg = "[SCM] 特定法术施放检查: " .. spellName .. " - " .. status .. "\n"
        debugMsg = debugMsg .. "  - 成功标志: " .. (SkillCastMonitorEvents.spellCastSucceeded and "是" or "否") .. "\n"
        debugMsg = debugMsg .. "  - 法术名称: " .. SkillCastMonitorEvents.lastSpellName .. " (" .. nameStatus .. ")\n"
        
        if SkillCastMonitorEvents.eventTimer > 0 then
            local timeDiff = string.format("%.2f", GetTime() - SkillCastMonitorEvents.eventTimer)
            debugMsg = debugMsg .. "  - 时间状态: " .. timeDiff .. "秒前 (" .. timeStatus .. ")"
        else
            debugMsg = debugMsg .. "  - 时间状态: 无计时器"
        end
        
        DEFAULT_CHAT_FRAME:AddMessage(debugMsg, result and 0 or 1, result and 1 or 0, result and 0 or 0)
    end
    
    return result
end

-- 监控指定类型的法术事件（例如所有SPELLCAST_*事件）
function IsSpellEventOfType(eventType)
	if SkillCastMonitorEvents and SkillCastMonitorEvents.lastEvent then
		local currentTime = GetTime()
		local eventName = SkillCastMonitorEvents.lastEvent
		if strsub(eventName, 1, strlen(eventType)) == eventType and 
		   SkillCastMonitorEvents.eventTimer > 0 and 
		   currentTime - SkillCastMonitorEvents.eventTimer <= SkillCastMonitorEvents.eventDuration then
			return true
		end
	end
	return false
end