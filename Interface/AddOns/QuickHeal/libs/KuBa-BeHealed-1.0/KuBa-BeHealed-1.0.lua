--[[
Name: KuBa-BeHealed-1.0
Revision: $Rev: 10003 $
Author(s): Crazydru
Website: https://gitee.com/ku-ba
Description: 跟踪附近友方即将被治疗的法术。
Dependencies: AceLibrary, AceEvent-2.0
]]
-- 未安装SuperWoW
-- https://github.com/balakethelock/SuperWoW/wiki/Features
if not SUPERWOW_VERSION then
	DEFAULT_CHAT_FRAME:AddMessage("未检测到SuperWoW");
	return
end

-- 主要版本
local MAJOR_VERSION = "KuBa-BeHealed-1.0"
-- 次要版本
local MINOR_VERSION = "$Revision: 10003 $"

-- 检验AceLibrary
if not AceLibrary then
	error(MAJOR_VERSION .. " requires AceLibrary")
end

-- 检验AceEvent2.0
if not AceLibrary:HasInstance("AceEvent-2.0") then
	error(MAJOR_VERSION .. " requires AceEvent-2.0")
end

-- 检验版本（本库，单实例）
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then
	return
end

local Library = {}

--------------------------------
local healedData = {}
local target = {}

--排序施法中治疗信息
---@param targetGuid string 被治疗的Guid
local function DataSort(targetGuid)
	if not healedData[targetGuid] then
		return
	end
	local dataCounts = table.getn(healedData[targetGuid])
	for i = dataCounts, 1, -1 do
		if healedData[targetGuid][i].endTime < GetTime() then
			table.remove(healedData[targetGuid],i)
		end
	end
	table.sort(healedData[targetGuid],function(a, b)
		return a.endTime < b.endTime
	end)
end

--移除施法中治疗信息
---@param targetGuid string 被治疗的Guid
---@param casterGuid string 治疗者的Guid
local function DataRemove(targetGuid,casterGuid)
	if not healedData[targetGuid] or not casterGuid then
		return
	end
	local dataCounts = table.getn(healedData[targetGuid])
	for i = dataCounts, 1, -1 do
		if healedData[targetGuid][i].casterGuid == casterGuid then
			table.remove(healedData[targetGuid],i)
			return
		end
	end
end

--返回目标治疗队列第n位治疗信息
---@param targetGuid string 目标的Guid
---@param n number 队列中第n位，缺省位第1位
---@return integer|nil time 剩余施法时间
---@return string|nil casterGuid 第n位施法者的Guid
function Library:GetNextHealedTime(targetGuid,n)
	n = n or 1
	if healedData[targetGuid] and healedData[targetGuid][n] then 
		return healedData[targetGuid][n].endTime - GetTime(), healedData[targetGuid][n].casterGuid
	else
		return
	end
end

--返回施法者的在治疗列表中的顺位、剩余施法时间、治疗目标
---@param casterGuid string 施法者的Guid
---@return number|nil n number|nil 队列中顺位
---@return integer|nil time 剩余施法时间
---@return string|nil targetGuid 治疗目标
function Library:GetHealerCastData(casterGuid)
	local playerGuid
	if not casterGuid then
		if not playerGuid then
			_, playerGuid = UnitExists("player")
		end
		casterGuid = playerGuid
	end
	if target[casterGuid] then
		local targetGuid = target[casterGuid]
		for i = 1, table.getn(healedData[targetGuid]) do
			if healedData[targetGuid][i].casterGuid == casterGuid then
				return i, healedData[targetGuid][i].endTime - GetTime(), targetGuid
			end
		end
	else
		return
	end
end

function Library:PrintHealed(targetGuid)
	if not healedData[targetGuid] then
		return
	end
	local dataCounts = table.getn(healedData[targetGuid])
	for i = 1 , dataCounts do
		print(i, targetGuid, healedData[targetGuid][i].endTime)
	end
end


--监听施法，只处理友方对友方的施法
---@param casterGuid string 施法者Guid
---@param targetGuid string 目标Guid
---@param event string 施法事件
---@param spellId integer 施放法术ID
---@param castDuration integer 施法时长
function Library:UNIT_CASTEVENT(casterGuid, targetGuid, event, spellId, castDuration)
	if casterGuid and UnitIsFriend("player", casterGuid) then
		if event == "START" and targetGuid and UnitIsFriend("player", targetGuid) and castDuration > 0 then
			target[casterGuid] = targetGuid
			if not healedData[targetGuid] then
				healedData[targetGuid] = {}
			end
			local tbl = {
				casterGuid = casterGuid,
				targetGuid = targetGuid,
				spellId = spellId,
				endTime = castDuration / 1000 + GetTime(),
			}
			table.insert(healedData[targetGuid], tbl)
			DataSort(targetGuid)
		elseif event == "CAST" then
			if target[casterGuid] then
				DataRemove(target[casterGuid], casterGuid)
				target[casterGuid] = nil
			end
		elseif event == "FAIL" then
			if target[casterGuid] then
				DataRemove(target[casterGuid], casterGuid)
				target[casterGuid] = nil
			end
		end
	end
end
--------------------------------

-- 库激活
---@param self table 库自身对象
---@param oldLib table 旧版库对象
---@param oldDeactivate function 旧版库停用函数
local function activate(self, oldLib, oldDeactivate)
	-- 新版本使用
	Library = self

	-- 旧版本释放
	if oldLib then
		-- ...
	end

	-- 新版本初始化
	-- ...

	-- 旧版本停用
	if oldDeactivate then
		oldDeactivate(oldLib)
	end
end

-- 外部库加载
---@param self table 库自身对象
---@param major string 外部库主版本
---@param instance table 外部库实例
local function external(self, major, instance)
	if major == "AceEvent-2.0" then
		-- 混入事件
		instance:embed(self)
		-- 注册事件
		self:RegisterEvent("UNIT_CASTEVENT")
	end
end

-- 最终注册库
AceLibrary:Register(Library, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
---@diagnostic disable-next-line
Library = nil