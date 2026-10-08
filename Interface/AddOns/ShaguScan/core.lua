if ShaguScan.disabled then return end

local core = CreateFrame("Frame", nil, WorldFrame)

core.guids = {} -- 已收集的GUID
core.max_guids = 10 -- 最多收集10个对象

core.add = function(unit)
  -- 优化：参数验证，避免不必要的处理
  if not unit or type(unit) ~= "string" then return end
  
  local exists, guid = UnitExists(unit)
  if not exists or not guid then return end
  
  local now = GetTime()
  -- 优化：增加更新时间间隔到2秒，减少频繁更新
  if core.guids[guid] and (now - core.guids[guid] < 2) then
    return
  end
  
  -- 如果该GUID已存在，直接更新时间戳（保持在已收集列表中）
  if core.guids[guid] then
    core.guids[guid] = now
    return
  end
  
  -- 检查是否已达到最大收集数量
  local guids_count = 0
  for _ in pairs(core.guids) do guids_count = guids_count + 1 end
  
  -- 如果未达到最大数量，直接添加
  if guids_count < core.max_guids then
    core.guids[guid] = now
    return
  end
  
  -- 已达到最大数量，执行智能替换逻辑
  -- 1. 计算当前单位的优先级分数
  local function getUnitPriority(check_unit)
    local score = 0
    -- 战斗中的单位优先级高
    if UnitAffectingCombat(check_unit) then score = score + 100 end
    -- 攻击玩家的单位优先级高
    if UnitExists(check_unit.."target") and UnitIsUnit(check_unit.."target", "player") then score = score + 50 end
    -- 精英单位优先级高
    local classification = UnitClassification(check_unit)
    if classification == "worldboss" then score = score + 30
    elseif classification == "rareelite" then score = score + 20
    elseif classification == "elite" then score = score + 10 end
    return score
  end
  
  -- 2. 计算当前单位的优先级
  local current_priority = getUnitPriority(unit)
  
  -- 3. 找到最低优先级的单位进行替换
  local lowest_priority_guid
  local lowest_priority_score = 9999
  local oldest_time = nil
  
  for g in pairs(core.guids) do
    -- 先检查单位是否仍然存在
    if not UnitExists(g) then
      -- 不存在的单位直接替换
      core.guids[g] = nil
      core.guids[guid] = now
      return
    end
    
    -- 计算现有单位的优先级
    local existing_priority = getUnitPriority(g)
    local existing_time = core.guids[g]
    
    -- 比较优先级，相同优先级则比较时间
    if existing_priority < lowest_priority_score or 
       (existing_priority == lowest_priority_score and (not oldest_time or existing_time < oldest_time)) then
      lowest_priority_guid = g
      lowest_priority_score = existing_priority
      oldest_time = existing_time
    end
  end
  
  -- 4. 只有当当前单位优先级高于或等于最低优先级单位时才替换
  if lowest_priority_guid and current_priority >= lowest_priority_score then
    core.guids[lowest_priority_guid] = nil
    core.guids[guid] = now
  end
end


  


-- unitstr
core:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
core:RegisterEvent("PLAYER_TARGET_CHANGED")
core:RegisterEvent("PLAYER_ENTERING_WORLD")
-- 移除：UNIT_HAPPINESS（宠物快乐度，非核心）、UNIT_MODEL_CHANGED（模型变化，非必要）等
-- core:RegisterEvent("UNIT_HAPPINESS")
-- core:RegisterEvent("UNIT_MODEL_CHANGED")
-- arg1
core:RegisterEvent("UNIT_COMBAT")
--core:RegisterEvent("UNIT_HAPPINESS")
--core:RegisterEvent("UNIT_MODEL_CHANGED")
core:RegisterEvent("UNIT_PORTRAIT_UPDATE")
core:RegisterEvent("UNIT_FACTION")
core:RegisterEvent("UNIT_FLAGS")
core:RegisterEvent("UNIT_AURA")
core:RegisterEvent("UNIT_HEALTH")
core:RegisterEvent("UNIT_CASTEVENT")

core:SetScript("OnEvent", function()
  if event == "UPDATE_MOUSEOVER_UNIT" then
    this.add("mouseover")
  elseif event == "PLAYER_ENTERING_WORLD" then
    this.add("player")
  elseif event == "PLAYER_TARGET_CHANGED" then
    this.add("target")
  else
    -- 对其他事件（如 UNIT_*），先检查 arg1 是否为有效单位
    if arg1 and UnitExists(arg1) then
      this.add(arg1)
    end
  end
end)
--新增 OnUpdate 脚本，定期（如每 5 秒）检查 core.guids，删除超过阈值时间（如 30 秒）未更新的 GUID（认为单位已远离），避免表无限膨胀。
-- 优化：更高效的OnUpdate清理逻辑
core:SetScript("OnUpdate", function()
  -- 1. 动态调整清理频率（根据游戏状态）
  local interval = 30 -- 默认30秒清理一次
  if UnitAffectingCombat("player") then
    interval = 10 -- 战斗中缩短至10秒，加速过期单位清理
  elseif IsResting() then
    interval = 60 -- 休息状态延长至60秒，减少资源消耗
  end

  -- 2. 按动态间隔执行清理
  if (this.tick or 0) > GetTime() then return end
  this.tick = GetTime() + interval

  -- 3. 过期时间动态调整（战斗中更严格）
  local expireTime = GetTime() - (UnitAffectingCombat("player") and 10 or 60)
  
  -- 4. 优化的清理逻辑：同时检查单位是否仍然存在
  local unitsToRemove = {}
  
  -- 先收集要移除的GUID，避免在遍历中修改表
  for guid, time in pairs(core.guids) do
    -- 如果单位不存在或时间过期，标记为移除
    if not UnitExists(guid) or time < expireTime then
      unitsToRemove[guid] = true
    end
  end
  
  -- 批量移除标记的GUID
  for guid in pairs(unitsToRemove) do
    core.guids[guid] = nil
  end
  
  -- 5. 额外检查：如果仍然超过最大数量，移除最旧的单位
  local guids_count = 0
  for _ in pairs(core.guids) do guids_count = guids_count + 1 end
  
  while guids_count > core.max_guids do
    local oldest_guid, oldest_time
    for g, t in pairs(core.guids) do
      if not oldest_time or t < oldest_time then
        oldest_guid, oldest_time = g, t
      end
    end
    
    if oldest_guid then
      core.guids[oldest_guid] = nil
      guids_count = guids_count - 1
    else
      break
    end
  end
end)


ShaguScan.core = core
