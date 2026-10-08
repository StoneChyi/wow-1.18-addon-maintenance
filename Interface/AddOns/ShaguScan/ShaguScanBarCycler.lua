-- （保留文件开头的模块注册，确保模块先被识别）
if ShaguScan.disabled then return end
local cycle = {}
ShaguScan.cycle = cycle  -- 提前注册，确保模块被识别
cycle.state = {}

-- （调试函数不变）
local function debug(msg)
  local time = date("%H:%M:%S")
  DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ShaguScan.cycle " .. time .. "]|r " .. tostring(msg))
end

-- 【关键修改1：增强依赖检查，明确等待其他模块加载】
-- 检查所有必要模块是否已加载并初始化完成
local function checkAllDependenciesReady()
  -- 1. 检查核心模块是否存在
  if not ShaguScan then
    debug("等待核心模块加载：ShaguScan 不存在")
    return false
  end
  if ShaguScan.disabled then
    debug("核心模块已禁用，无法加载")
    return false
  end

  -- 2. 检查core模块（全局变量+数据结构）
  if not ShaguScan.core or not ShaguScan.core.guids then
    debug("等待core模块加载：ShaguScan.core 未初始化")
    return false
  end

  -- 3. 检查ui模块（全局变量+窗口框架）
  -- 注意：ui.frames是在ui.lua的OnUpdate中动态创建的，需要等待其初始化
  if not ShaguScan.ui then
    debug("等待ui模块加载：ShaguScan.ui 不存在")
    return false
  end
  if not ShaguScan.ui.frames then
    debug("等待ui模块初始化：ShaguScan.ui.frames 未创建")
    return false
  end

  -- 4. 检查配置数据（确保global.lua已加载）
  if not ShaguScan_db or not ShaguScan_db.config then
    debug("等待配置加载：ShaguScan_db 未初始化")
    return false
  end

  -- 所有依赖就绪
  debug("所有模块依赖检查通过")
  return true
end

-- （以下函数：initState、hookUpdate、CycleTarget、setupKeyBindings 保持不变）
local function initState(windowTitle)
  -- 原逻辑不变...
end

local function hookUpdate()
  -- 原逻辑不变...
end

function cycle.CycleTarget(windowTitle)
  -- 原逻辑不变...
end

local function setupKeyBindings()
  -- 原逻辑不变...
end

-- 【关键修改2：延迟初始化，循环等待依赖就绪】
local function init()
  debug("开始等待所有模块加载...")

  -- 创建延迟检查定时器
  local loader = CreateFrame("Frame")
  local checkInterval = 0.5  -- 每0.5秒检查一次
  local maxWaitTime = 30     -- 最大等待30秒（避免无限等待）
  local elapsed = 0

  loader:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta

    -- 超时处理
    if elapsed >= maxWaitTime then
      debug("初始化超时：30秒内未检测到所有模块加载")
      loader:Hide()
      return
    end

    -- 检查依赖是否就绪
    if checkAllDependenciesReady() then
      -- 所有模块加载完成，执行初始化
      hookUpdate()
      setupKeyBindings()
      debug("所有模块加载完成，Cycle模块初始化成功")
      loader:Hide()
    else
      -- 未就绪，继续等待（每5秒提示一次，避免刷屏）
      if math.floor(elapsed) % 5 == 0 then
        debug("仍在等待其他模块加载...（已等待 " .. math.floor(elapsed) .. " 秒）")
      end
    end
  end)
end

-- 【关键修改3：触发延迟初始化】
-- 监听玩家进入世界事件，但不立即初始化，而是启动等待逻辑
local starter = CreateFrame("Frame")
starter:RegisterEvent("PLAYER_ENTERING_WORLD")
starter:SetScript("OnEvent", function()
  debug("检测到玩家进入世界，开始等待所有模块加载")
  init()  -- 启动延迟初始化逻辑
  starter:UnregisterAllEvents()
end)

debug("ShaguScan.cycle模块已注册，等待其他模块加载后初始化")