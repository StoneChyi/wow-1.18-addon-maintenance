-- ColorChat.lua
-- 自定义聊天颜色插件

-- 全局变量声明（仅声明，不初始化，避免覆盖已加载的变量）
ColorChat = {}
ColorChatDB = ColorChatDB or nil -- 仅声明，让VARIABLES_LOADED事件来处理实际初始化

ColorChat = {}

-- 创建主框架
local frame = CreateFrame("Frame", "ColorChatMainFrame")
frame:SetScript("OnLoad", ColorChat_OnLoad)
frame:SetScript("OnEvent", ColorChat_OnEvent)

-- 初始化函数
function ColorChat_OnLoad()
    -- 注册事件
    frame:RegisterEvent("VARIABLES_LOADED")
    frame:RegisterEvent("PLAYER_LOGOUT")
    
    -- 注册斜杠命令
    SlashCmdList["COLORCHAT"] = ColorChat_SlashCommand
    SLASH_COLORCHAT1 = "/cc"
    SLASH_COLORCHAT2 = "/colorchat"
    
    -- 保存原始的SendChatMessage函数并钩住
    ColorChat.originalSendChatMessage = SendChatMessage
    SendChatMessage = ColorChat_HookedSendChatMessage
    
    -- 显示加载信息
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFFColorChat插件已加载|r - 输入/colorchat打开设置")
end

-- 事件处理函数
function ColorChat_OnEvent(self, event, arg1)
    if event == "VARIABLES_LOADED" then
        -- 确保数据库已完全初始化
        if not ColorChatDB then
            ColorChatDB = {
                enabled = true,
                color = "FF0000",  -- 统一使用RGB格式默认红色
                -- 默认窗口位置
                configPoint = "CENTER",
                configRelativeTo = "UIParent",
                configRelativePoint = "CENTER",
                configX = 0,
                configY = 0
            }
        else
            -- 验证数据库结构的完整性
            if type(ColorChatDB.color) ~= "string" then
                ColorChatDB.color = tostring(ColorChatDB.color or "FF0000")
            end
            if ColorChatDB.enabled == nil then
                ColorChatDB.enabled = true
            end
            if not ColorChatDB.configPoint then
                ColorChatDB.configPoint = "CENTER"
                ColorChatDB.configRelativeTo = "UIParent"
                ColorChatDB.configRelativePoint = "CENTER"
                ColorChatDB.configX = 0
                ColorChatDB.configY = 0
            end
        end
        
        -- 在VARIABLES_LOADED事件中立即保存数据库，确保设置被持久化
        if SaveVariables then
            SaveVariables("ColorChatDB")
        end
        
        -- 创建配置窗口并更新颜色预览
        ColorChat_CreateConfigWindow()
        
        -- 强制立即更新颜色预览
        if ColorChat_UpdateColorPreview then
            ColorChat_UpdateColorPreview()
        end
    elseif event == "PLAYER_LOGOUT" then
        -- 确保在退出时保存设置
        if SaveVariables then
            SaveVariables("ColorChatDB")
        end
    end
end

-- 加载配置窗口位置
function LoadConfigPosition(frame)
    -- 确保frame和ColorChatDB存在
    if not frame then
        return
    end
    
    if not ColorChatDB then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", "UIParent", "CENTER", 0, 0)
        return
    end
    
    -- 确保位置配置存在且有效
    if not ColorChatDB.configPoint or not ColorChatDB.configRelativeTo or not ColorChatDB.configRelativePoint then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", "UIParent", "CENTER", 0, 0)
        
        -- 修复配置
        ColorChatDB.configPoint = "CENTER"
        ColorChatDB.configRelativeTo = "UIParent"
        ColorChatDB.configRelativePoint = "CENTER"
        ColorChatDB.configX = 0
        ColorChatDB.configY = 0
        
        -- 保存修复后的配置
        if SaveVariables then
            SaveVariables("ColorChatDB")
        end
        return
    end
    
    -- 获取配置
    local point = ColorChatDB.configPoint
    local relativeTo = ColorChatDB.configRelativeTo
    local relativePoint = ColorChatDB.configRelativePoint
    local x = ColorChatDB.configX or 0
    local y = ColorChatDB.configY or 0
    
    -- 应用位置
    frame:ClearAllPoints()
    frame:SetPoint(point, relativeTo, relativePoint, x, y)
end

-- 命令处理函数
function ColorChat_SlashCommand(msg)
    msg = msg or ""
    local cmd = string.lower(msg)
    
    if cmd == "" or cmd == "profile" then
        -- 显示/隐藏配置窗口
        if not ColorChatConfigFrame then
            ColorChat_CreateConfigWindow()
            -- 确保新创建的窗口正确显示
            if ColorChatConfigFrame then
                LoadConfigPosition(ColorChatConfigFrame)
                ColorChatConfigFrame:Show()
                return
            end
        end
        if ColorChatConfigFrame:IsShown() then
            ColorChatConfigFrame:Hide()
            DEFAULT_CHAT_FRAME:AddMessage("ColorChat配置窗口已隐藏")
        else
            LoadConfigPosition(ColorChatConfigFrame)
            ColorChatConfigFrame:Show()
        end
    elseif cmd == "stop" then
        ColorChat_ToggleStandby()
        -- 如果窗口已创建，更新按钮状态
        if ColorChatConfigFrame and ColorChatConfigFrame.toggleButton then
            ColorChatConfigFrame.toggleButton:SetText(ColorChatDB.enabled and "开启" or "关闭")
        end
    elseif cmd == "about" then
        ColorChat_ShowAbout()
    else
        ColorChat_ShowAbout()
    end
end

-- 聊天消息钩子函数
function ColorChat_HookedSendChatMessage(msg, chatType, language, target)
    if ColorChatDB.enabled then
        -- 检查消息是否以/开头（命令）
        if msg and (string.sub(msg, 1, 1) == "/" or string.sub(msg, 1, 1) == "`" or string.sub(msg, 1, 1) == "·" or string.sub(msg, 1, 1) == ".") then
            ColorChat.originalSendChatMessage(msg, chatType, language, target)
            return
        end
        -- 检测消息中是否包含现有颜色代码或装备链接
        if string.find(msg, "|c") or string.find(msg, "|Hitem:") or string.find(msg, "dkp奖励") then
            -- 包含其他颜色代码或装备链接，直接发送原始消息
            ColorChat.originalSendChatMessage(msg, chatType, language, target)
        else
            -- 添加完整的8位ARGB颜色代码（默认不透明）
            local coloredMsg = string.format("|cFF%s%s|r", ColorChatDB.color, msg)
            ColorChat.originalSendChatMessage(coloredMsg, chatType, language, target)
        end
    else
        ColorChat.originalSendChatMessage(msg, chatType, language, target)
    end
end

-- 切换插件状态
function ColorChat_ToggleStandby()
    ColorChatDB.enabled = not ColorChatDB.enabled
    local status = ColorChatDB.enabled and "|cFF00FF00激活|r" or "|cFFFF0000暂停|r"
    DEFAULT_CHAT_FRAME:AddMessage(string.format("ColorChat插件已%s", status))
    
    -- 立即保存设置
    if SaveVariables then
        SaveVariables("ColorChatDB")
    end
end

-- 显示关于信息
function ColorChat_ShowAbout()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFFColorChat v1.0|r - 自定义聊天颜色插件")
    DEFAULT_CHAT_FRAME:AddMessage("用法: /colorchat [profile|stop|about]")
    DEFAULT_CHAT_FRAME:AddMessage("- profile: 打开颜色配置面板")
    DEFAULT_CHAT_FRAME:AddMessage("- stop: 暂停/激活插件功能")
    DEFAULT_CHAT_FRAME:AddMessage("- about: 显示插件信息")
end

-- 打开颜色选择器
    function ColorChat_ToggleColorPicker()
        -- 确保ColorChatDB存在
        if not ColorChatDB then
            ColorChatDB = {
                enabled = true,
                color = "FF0000"
            }
        end
        
        -- 解析当前颜色值
        local function hexToRGB(hex) 
            -- 确保hex为字符串并移除#符号
            hex = tostring(hex or "FF0000")
            hex = string.gsub(hex, "#", "")
            -- 确保恰好6位RGB字符，不足补F，过长截断
            hex = string.sub(hex .. string.rep("F", 6), 1, 6)
              
            -- 提取RGB各通道
            return {
                r = (tonumber(string.sub(hex, 1, 2), 16) or 255)/255,
                g = (tonumber(string.sub(hex, 3, 4), 16) or 255)/255,
                b = (tonumber(string.sub(hex, 5, 6), 16) or 255)/255
            }
        end
          
        -- 统一使用RGB格式的颜色值
        local currentColor = ColorChatDB.color or "FF0000"
        -- 确保currentColor是字符串类型
        currentColor = tostring(currentColor)
        
        local rgb = hexToRGB(currentColor)
        
        -- 保存原始颜色值，用于取消操作
        local originalColor = currentColor
        
        -- 确保在任何情况下都能更新颜色预览
        local function forceUpdateColor()
            if ColorChat_UpdateColorPreview then
                ColorChat_UpdateColorPreview()
            end
        end
        
        -- 创建临时按钮对象
        local button = {
            r = rgb.r,
            g = rgb.g,
            b = rgb.b,
            swatchFunc = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                newR = newR or 1
                newG = newG or 1
                newB = newB or 1
                  
                -- 保存为RGB格式
                ColorChatDB.color = string.format("%02X%02X%02X", 
                    math.floor(newR * 255), 
                    math.floor(newG * 255), 
                    math.floor(newB * 255))
                  
                -- 立即保存变量
                if SaveVariables then
                    SaveVariables("ColorChatDB")
                end
                  
                -- 立即更新预览
                forceUpdateColor()
            end,
            cancelFunc = function()
                -- 恢复原始颜色值
                ColorChatDB.color = originalColor
                
                -- 立即保存变量
                if SaveVariables then
                    SaveVariables("ColorChatDB")
                end
                  
                -- 立即更新预览
                forceUpdateColor()
            end
        }
          
        -- 使用标准颜色选择器打开方式
        ColorPickerFrame.func = button.swatchFunc
        ColorPickerFrame.cancelFunc = button.cancelFunc -- 添加取消函数
        ColorPickerFrame.opacityFunc = nil -- 禁用透明度
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame:SetColorRGB(button.r, button.g, button.b)
        ColorPickerFrame:Show()
    end

-- 创建配置窗口
function ColorChat_CreateConfigWindow()
    -- 创建基础框架
    ColorChatConfigFrame = CreateFrame("Frame", "ColorChatConfigFrame", UIParent)
    LoadConfigPosition(ColorChatConfigFrame) -- 创建时立即加载位置
    ColorChatConfigFrame:SetWidth(240)
    ColorChatConfigFrame:SetHeight(80)
    
    -- 设置窗口背景
    ColorChatConfigFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    ColorChatConfigFrame:SetBackdropColor(0, 0, 0, 0.7)
    ColorChatConfigFrame:SetBackdropBorderColor(1, 1, 1, 1)
    
    -- 确保窗口在最上层
    ColorChatConfigFrame:SetFrameStrata("DIALOG")
    
    -- 启用窗口拖动
    ColorChatConfigFrame:SetMovable(true)
    ColorChatConfigFrame:EnableMouse(true)
    ColorChatConfigFrame:RegisterForDrag("LeftButton")
    ColorChatConfigFrame:SetScript("OnDragStart", function() this:StartMoving() end)
    ColorChatConfigFrame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        local point, _, relativePoint, xOfs, yOfs = this:GetPoint()
        
        -- 保存位置配置
        ColorChatDB.configPoint = point
        ColorChatDB.configRelativeTo = "UIParent"
        ColorChatDB.configRelativePoint = relativePoint
        ColorChatDB.configX = xOfs
        ColorChatDB.configY = yOfs
        
        -- 强制保存变量
        if _G.SaveVariables then
            _G.SaveVariables("ColorChatDB")
        end
    end)
    
    -- 使用安全的OnShow处理
    ColorChatConfigFrame:SetScript("OnShow", function(self)
        if self then
            LoadConfigPosition(self)
            -- 显示时更新颜色预览
            if ColorChat_UpdateColorPreview then
                ColorChat_UpdateColorPreview()
            end
        end
    end)
    
    -- 添加标题文本
    local title = ColorChatConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("ColorChat 设置")
    title:SetTextColor(1, 1, 1, 1)

    -- 添加关闭按钮
    local closeButton = CreateFrame("Button", nil, ColorChatConfigFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -4, -4)
    closeButton:SetWidth(24)
    closeButton:SetHeight(24)
    closeButton:SetScript("OnClick", function() ColorChatConfigFrame:Hide() end)
    
    -- 开关按钮
    ColorChatConfigFrame.toggleButton = CreateFrame("Button", nil, ColorChatConfigFrame, "UIPanelButtonTemplate")
    local toggleButton = ColorChatConfigFrame.toggleButton
    toggleButton:SetWidth(80)
    toggleButton:SetHeight(25)
    toggleButton:SetPoint("LEFT", 15, -10)
    toggleButton:SetText(ColorChatDB.enabled and "开启" or "关闭")
    toggleButton:SetScript("OnClick", function()
        ColorChat_ToggleStandby()
        toggleButton:SetText(ColorChatDB.enabled and "开启" or "关闭")
    end)
    
    -- 颜色预览框
    local colorPreview = CreateFrame("Button", nil, ColorChatConfigFrame)
    colorPreview:SetWidth(100)
    colorPreview:SetHeight(25)
    colorPreview:SetPoint("RIGHT", -20, -10)
    colorPreview:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    colorPreview:SetScript("OnClick", ColorChat_ToggleColorPicker)
    
    -- 将颜色预览框引用保存到配置窗口对象上
    ColorChatConfigFrame.colorPreview = colorPreview
    
    -- 更新颜色预览函数
    function ColorChat_UpdateColorPreview()
        -- 确保配置窗口存在
        if not ColorChatConfigFrame then
            return
        end
        
        -- 获取颜色预览框（从配置窗口中直接获取，避免作用域问题）
        local colorPreview = ColorChatConfigFrame.colorPreview
        if not colorPreview then
            -- 尝试在配置窗口中查找颜色预览框
            for _, child in ipairs({ColorChatConfigFrame:GetChildren()}) do
                if child:GetWidth() == 100 and child:GetHeight() == 25 and child:GetObjectType() == "Button" then
                    colorPreview = child
                    break
                end
            end
        end
        
        -- 确保颜色预览框存在
        if not colorPreview then
            return
        end
        
        -- 确保ColorChatDB存在
        if not ColorChatDB then
            ColorChatDB = {
                enabled = true,
                color = "FF0000"
            }
            if SaveVariables then
                SaveVariables("ColorChatDB")
            end
        end
        
        -- 获取当前颜色值，并进行类型检查
        local color = ColorChatDB.color
        if not color or type(color) ~= "string" or string.len(color) < 6 then
            color = "FF0000" -- 默认红色
            ColorChatDB.color = color -- 同步更新数据库
            if SaveVariables then
                SaveVariables("ColorChatDB")
            end
        end
        
        -- 使用Lua 5.0兼容的方式解析颜色值
        local r, g, b
        if color and string.len(color) >= 6 then
            -- 截取恰好6位字符用于RGB
            local rgbPart = string.sub(color, 1, 6)
            r = string.sub(rgbPart, 1, 2)
            g = string.sub(rgbPart, 3, 4)
            b = string.sub(rgbPart, 5, 6)
        else
            r = "FF"
            g = "00"
            b = "00"
        end
        
        -- 转换RGB值并进行有效性检查
        local rVal = tonumber(r, 16)
        local gVal = tonumber(g, 16)
        local bVal = tonumber(b, 16)
        
        -- 确保值是有效的数字
        if not rVal then rVal = 255 end
        if not gVal then gVal = 0 end
        if not bVal then bVal = 0 end
        
        -- 标准化到0-1范围
        rVal = rVal / 255
        gVal = gVal / 255
        bVal = bVal / 255
        
        -- 设置颜色预览框的背景颜色
        colorPreview:SetBackdropColor(rVal, gVal, bVal, 1.0)
        
        -- 如果存在纹理，也设置其颜色
        if colorPreview.texture then
            colorPreview.texture:SetTexture(rVal, gVal, bVal, 1.0)
        else
            -- 创建纹理并设置颜色
            colorPreview.texture = colorPreview:CreateTexture(nil, "BACKGROUND")
            colorPreview.texture:SetAllPoints()
            colorPreview.texture:SetTexture(rVal, gVal, bVal, 1.0)
        end
        
        -- 去除边框颜色（设置为透明）
        colorPreview:SetBackdropBorderColor(0, 0, 0, 0)
        
        -- 强制更新UI
        colorPreview:Show()
    end
    
    -- 初始更新颜色
    if ColorChat_UpdateColorPreview then
        ColorChat_UpdateColorPreview()
    end
end

-- 直接调用初始化函数
ColorChat_OnLoad()