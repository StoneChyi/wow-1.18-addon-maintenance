-- 添加屏蔽关键词状态 by 武藤纯子酱 2025.12.30
Meeting.blockWords = MEETING_DB.blockWords or {}
Meeting.blockDropdownState = {}  -- 屏蔽词下拉窗口状态
-- 在文件开头添加多选状态变量和下拉窗口状态 by 武藤纯子酱 2025.9.22
Meeting.multiSelect = {}
Meeting.searchInfo.codes = {}  -- 改为存储多个代码
Meeting.dropdownState = {}     -- 下拉窗口状态
-- 添加搜索文本状态 by 武藤纯子酱 2025.9.24
Meeting.searchInfo.text = ""   -- 搜索文本
Meeting.searchInfo.isComposing = false  -- 是否正在输入中文
Meeting.searchInfo.lastSearchText = ""  -- 上次搜索的文本
Meeting.searchInfo.timer = nil  -- 延迟搜索的计时器
local Menu = AceLibrary("Dewdrop-2.0")
local browserFrame = Meeting.GUI.CreateFrame({
    parent = Meeting.MainFrame,
    width = 782,
    height = 382,
    anchor = {
        point = "TOPLEFT",
        relative = Meeting.MainFrame,
        relativePoint = "TOPLEFT",
        x = 18,
        y = -40
    }
})
Meeting.BrowserFrame = browserFrame
browserFrame:EnableMouse(true)
browserFrame:EnableMouseWheel(true)
local activityTypeTextFrame = Meeting.GUI.CreateText({
    parent = browserFrame,
    text = "活动：",
    fontSize = 14,
    width = 42,
    height = 24,
    anchor = {
        point = "TOPLEFT",
        relative = browserFrame,
        relativePoint = "TOPLEFT",
        y = -18
    }
})
Meeting.searchInfo.category = ""
Meeting.searchInfo.code = ""
local matchs = {}
-- 修改 SetMathcKeyWords 函数支持跨类别多选 by 武藤纯子酱 2025.9.22
function SetMathcKeyWords(nonRaidOnly)
    matchs = {}
    local nomatchs = {}  -- 存储排除关键词
    
    -- 添加任务链接匹配条件
    if Meeting.searchInfo.code == "QuestLink" then
        table.insert(matchs, "|Hquest:")
        return matchs, nomatchs
    end
    
    -- 处理多选情况 - 支持跨类别选择
    if next(Meeting.searchInfo.codes) then
        -- 遍历所有选中的活动代码
        for activityKey, isSelected in pairs(Meeting.searchInfo.codes) do
            if isSelected then
                -- 在所有类别中查找匹配的活动
                for _, category in ipairs(Meeting.Categories) do
                    for _, activity in ipairs(category.children) do
                        if activity.key == activityKey and (not nonRaidOnly or category.key ~= "RAID") then
                            -- 添加匹配关键词
                            if activity.match then
                                for _, match in ipairs(activity.match) do
                                    table.insert(matchs, match)
                                end
                            end
                            
                            -- 添加排除关键词
                            if activity.nomatch then
                                for _, nomatch in ipairs(activity.nomatch) do
                                    table.insert(nomatchs, nomatch)
                                end
                            end
                            break
                        end
                    end
                end
            end
        end
    elseif Meeting.searchInfo.code ~= "" then
        -- 单个选择的情况
        local info = Meeting.GetActivityInfo(Meeting.searchInfo.code)
        if nonRaidOnly and Meeting.GetActivityCategory(info.key).key == "RAID" then return matchs, nomatchs end
        if info.match then
            for _, v in ipairs(info.match) do
                table.insert(matchs, v)
            end
        end
        if info.nomatch then
            for _, v in ipairs(info.nomatch) do
                table.insert(nomatchs, v)
            end
        end
    end
    
    return matchs, nomatchs
end
-- Filter callbacks share the actual input reference; changing filters preserves search text.
local searchInput
local function ApplyFilter()
    Meeting.searchInfo.code = ""
    Meeting.searchInfo.category = ""
    local count, only = 0, nil
    for code in pairs(Meeting.searchInfo.codes) do count = count + 1; only = code end
    local label = "全部团本 / 首领"
    if count == 1 then
        label = only == "RAID" and "全部团本" or (only == "BOSS" and "全部世界首领" or Meeting.GetActivityInfo(only).name)
    elseif count > 1 and not (count == 2 and Meeting.searchInfo.codes.RAID and Meeting.searchInfo.codes.BOSS) then
        label = "已选 "..count.." 项"
    end
    MeetingBworserSelectButton:SetText(label)
    Meeting.BrowserFrame:UpdateList(true)
end
local options = { type = "group", args = {
    ALL = { order = 1, type = "toggle", name = "全部团本和世界首领",
        get = function() return not next(Meeting.searchInfo.codes) end,
        set = function() Meeting.searchInfo.codes = {}; ApplyFilter(); Menu:Close() end },
    DONE = { order = 9, type = "execute", name = "完成", func = function() Menu:Close() end },
} }
for index, category in ipairs(Meeting.Categories) do
    if Meeting.IsSupportedCategory(category.key) then
        local group = category
        local children = {}
        children.ALL = { order = 1, type = "toggle", name = "全部"..group.name,
            get = function() return Meeting.searchInfo.codes[group.key] or false end,
            set = function()
                local selected = not Meeting.searchInfo.codes[group.key]
                for _, child in ipairs(group.children) do Meeting.searchInfo.codes[child.key] = nil end
                Meeting.searchInfo.codes[group.key] = selected or nil
                ApplyFilter()
            end }
        for childIndex, child in ipairs(group.children) do
            local code, name = child.key, child.name
            children[code] = { order = childIndex + 1, type = "toggle", name = name,
                get = function() return Meeting.searchInfo.codes[group.key] or Meeting.searchInfo.codes[code] or false end,
                set = function(checked)
                    if Meeting.searchInfo.codes[group.key] then
                        Meeting.searchInfo.codes[group.key] = nil
                        for _, info in ipairs(group.children) do Meeting.searchInfo.codes[info.key] = true end
                    end
                    Meeting.searchInfo.codes[code] = checked or nil
                    ApplyFilter()
                end }
        end
        options.args[group.key] = { order = index, type = "group", name = group.name, args = children }
    end
end

-- 修改 selectButton 的点击事件 by 武藤纯子酱 2025.9.22
local selectButton = Meeting.GUI.CreateButton({
    name = "MeetingBworserSelectButton",
    parent = browserFrame,
    text = "全部团本 / 首领",
    type = Meeting.GUI.BUTTON_TYPE.PRIMARY,
    width = 164,
    height = 24,
    anchor = {
        point = "TOPLEFT",
        relative = activityTypeTextFrame,
        relativePoint = "TOPRIGHT",
        x = 10,
        y = 4
    },
    click = function()
        if Meeting.dropdownState.isOpen then
            Menu:Close()
            Meeting.dropdownState.isOpen = false
        else
            Menu:Open(this)
            Meeting.dropdownState.isOpen = true
        end
    end
})
-- 添加搜索框 by 武藤纯子酱 2025.9.24
searchInput = Meeting.GUI.CreateInput({
    parent = browserFrame,
    width = 210,
    height = 24,
    anchor = {
        point = "TOPLEFT",
        relative = selectButton,
        relativePoint = "TOPRIGHT",
        x = 14,
        y = 0
    },
    placeholder = "搜索活动说明...",
    limit = 50,
    multiLine = false
})
Meeting.GUI.SetBackground(searchInput, Meeting.GUI.Theme.Black, Meeting.GUI.Theme.White)

-- 搜索框文本变化事件 - 修复删除字符残留问题
searchInput:SetScript("OnTextChanged", function()
    local text = this:GetText()
    if text and text ~= "" then
        text = string.lower(text)
        text = string.gsub(text, "^%s*(.-)%s*$", "%1")

        -- 取消之前的延迟搜索计时器
        if Meeting.searchInfo.timer then
            Meeting.searchInfo.timer:Cancel()
            Meeting.searchInfo.timer = nil
        end

        -- 本客户端输入法在输入框内合成（拼音字母会先以英文形式进入输入框），与主动输入英文无法区分；
        -- 任何文本变化一律走延迟搜索，避免实时刷新打断输入法合成。回车/失焦/搜索按钮会立即强制完成搜索
        Meeting.searchInfo.isComposing = true
        Meeting.searchInfo.lastSearchText = text

        -- 延迟5秒执行搜索，避免拼音干扰
        Meeting.searchInfo.timer = C_Timer.NewTimer(5, function()
            if Meeting.searchInfo.lastSearchText == text then
                Meeting.searchInfo.text = text
                Meeting.searchInfo.isComposing = false
                Meeting.BrowserFrame:UpdateList(true)
            end
        end)
    else
        -- 文本为空时立即搜索
        Meeting.searchInfo.text = ""
        Meeting.searchInfo.isComposing = false

        -- 取消之前的计时器
        if Meeting.searchInfo.timer then
            Meeting.searchInfo.timer:Cancel()
            Meeting.searchInfo.timer = nil
        end

        Meeting.BrowserFrame:UpdateList(true)
    end
end)
-- 修改输入法开始合成事件
-- 1.12 脚本不能依赖形参（此客户端会把框体作为第一参数传入，形参收到的是 table），输入的字符在全局 arg1 中
searchInput:SetScript("OnChar", function()
    local char = arg1
    -- 检测到中文字符输入开始
    if type(char) == "string" and string.byte(char) > 127 then
        Meeting.searchInfo.isComposing = true
    else
        -- 英文字符，立即处理
        Meeting.searchInfo.isComposing = false

        -- 取消之前的延迟搜索
        if Meeting.searchInfo.timer then
            Meeting.searchInfo.timer:Cancel()
            Meeting.searchInfo.timer = nil
        end
    end
end)
-- 修改输入法结束合成事件
searchInput:SetScript("OnEditFocusLost", function()
    -- 此处覆盖了 GUI.CreateInput 设置的失焦脚本，需自行维护焦点标志
    this._focus = false

    -- 取消之前的延迟搜索
    if Meeting.searchInfo.timer then
        Meeting.searchInfo.timer:Cancel()
        Meeting.searchInfo.timer = nil
    end
    
    -- 输入框失去焦点时，强制完成搜索
    if Meeting.searchInfo.isComposing then
        local text = this:GetText()
        if text then
            text = string.lower(text)
            text = string.gsub(text, "^%s*(.-)%s*$", "%1")
            Meeting.searchInfo.text = text
            Meeting.searchInfo.isComposing = false
            Meeting.BrowserFrame:UpdateList(true)
        end
    end
end)
-- 修改回车键确认搜索
searchInput:SetScript("OnEnterPressed", function()
    -- 取消之前的延迟搜索
    if Meeting.searchInfo.timer then
        Meeting.searchInfo.timer:Cancel()
        Meeting.searchInfo.timer = nil
    end
    
    local text = this:GetText()
    if text then
        text = string.lower(text)
        text = string.gsub(text, "^%s*(.-)%s*$", "%1")
        Meeting.searchInfo.text = text
        Meeting.searchInfo.isComposing = false
        Meeting.BrowserFrame:UpdateList(true)
    end
    this:ClearFocus()
end)
-- 修改搜索按钮点击事件
local searchButton = Meeting.GUI.CreateButton({
    parent = browserFrame,
    text = "搜索",
    width = 60,
    height = 24,
    anchor = {
        point = "TOPLEFT",
        relative = searchInput,
        relativePoint = "TOPRIGHT",
        x = 5,
        y = 0
    },
    click = function()
        -- 取消之前的延迟搜索
        if Meeting.searchInfo.timer then
            Meeting.searchInfo.timer:Cancel()
            Meeting.searchInfo.timer = nil
        end
        
        local text = searchInput:GetText()
        if text then
            text = string.lower(text)
            text = string.gsub(text, "^%s*(.-)%s*$", "%1")
            Meeting.searchInfo.text = text
            Meeting.searchInfo.isComposing = false
            Meeting.BrowserFrame:UpdateList(true)
        end
    end
})
-- 修改清空搜索按钮
local clearSearchButton = Meeting.GUI.CreateButton({
    parent = browserFrame,
    text = "清空",
    width = 48,
    height = 24,
    anchor = {
        point = "TOPLEFT",
        relative = searchButton,
        relativePoint = "TOPRIGHT",
        x = 5,
        y = 0
    },
    click = function()
        -- 取消之前的延迟搜索
        if Meeting.searchInfo.timer then
            Meeting.searchInfo.timer:Cancel()
            Meeting.searchInfo.timer = nil
        end
        
        Meeting.searchInfo.text = ""
        Meeting.searchInfo.isComposing = false
        searchInput:SetText("")
        Meeting.BrowserFrame:UpdateList(true)
    end
})

-- 添加屏蔽关键词按钮 by 武藤纯子酱 2025.12.30
local blockButton = Meeting.GUI.CreateButton({
    name = "MeetingBlockButton",
    parent = browserFrame,
    text = "屏蔽词",
    type = Meeting.GUI.BUTTON_TYPE.NORMAL,
    width = 64,
    height = 24,
    anchor = {
        point = "TOPLEFT",
        relative = clearSearchButton,
        relativePoint = "TOPRIGHT",
        x = 14,
        y = 0
    },
    click = function()
        if Meeting.blockDropdownState.isOpen then
            Menu:Close()
            Meeting.blockDropdownState.isOpen = false
        else
            -- 创建屏蔽词菜单
            local blockOptions = {
                type = 'group',
                args = {
                    TITLE = {
                        order = 1,
                        type = "header",
                        name = "屏蔽关键词管理",
                    },
                    ADD_BLOCK = {
                        order = 5,
                        type = "execute",  -- 改为execute，然后弹出输入框
                        name = "添加屏蔽词",
                        desc = "输入要屏蔽的关键词",
                        func = function()
                            -- 创建添加屏蔽词的输入对话框
                            local dialog = Meeting.GUI.CreateDialog({
                                parent = Meeting.BrowserFrame,
                                anchor = {
                                    point = "CENTER",
                                    relative = Meeting.BrowserFrame,
                                    relativePoint = "CENTER",
                                    x = 0,
                                    y = 0
                                },
                                title = "添加屏蔽词",
                                width = 300,
                                height = 100,
                                onCustomFrame = function(parent, anchor)
                                    local frame = Meeting.GUI.CreateFrame({
                                        parent = parent,
                                        width = 280,
                                        height = 40,
                                        anchor = {
                                            point = "TOPLEFT",
                                            relative = anchor,
                                            relativePoint = "BOTTOMLEFT",
                                            x = 0,
                                            y = -10
                                        }
                                    })
                                    
                                    local input = Meeting.GUI.CreateInput({
                                        parent = frame,
                                        width = 280,
                                        height = 20,
                                        anchor = {
                                            point = "TOPLEFT",
                                            relative = frame,
                                            relativePoint = "TOPLEFT",
                                            x = 0,
                                            y = 0
                                        },
                                        limit = 50,
                                        multiLine = false
                                    })
                                    Meeting.GUI.SetBackground(input, Meeting.GUI.Theme.Black, Meeting.GUI.Theme.White)
                                    input:SetFocus()
                                    
                                    return frame
                                end,
                                _confirm = function()
                                    local input = this:GetParent():GetChildren()
                                    while input and not input.GetText do
                                        input = input:GetChildren()
                                    end
                                    if input and input.GetText then
                                        local value = input:GetText()
                                        if value and value ~= "" then
                                            value = string.trim(value)
                                            local exists = false
                                            for _, word in ipairs(Meeting.blockWords) do
                                                if word == value then
                                                    exists = true
                                                    break
                                                end
                                            end
                                            
                                            if not exists then
                                                table.insert(Meeting.blockWords, value)
                                                MEETING_DB.blockWords = Meeting.blockWords
                                                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00集合石|r: 已添加屏蔽词: " .. value)
                                                
                                                -- 重新过滤活动列表
                                                Meeting:ReFilterActivities()
                                            else
                                                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000集合石|r: 屏蔽词已存在: " .. value)
                                            end
                                        end
                                    end
									Menu:Close()
                                end
                            })
                            dialog:SetPoint("CENTER", Meeting.BrowserFrame, "CENTER", 0, 0)
                        end
                    },
                    CLEAR_ALL = {
                        order = 10,
                        type = "execute",
                        name = "清空所有屏蔽词",
                        desc = "清空所有已设置的屏蔽词",
                        func = function()
                            Meeting.blockWords = {}
                            MEETING_DB.blockWords = Meeting.blockWords
                            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00集合石|r: 已清空所有屏蔽词")
                            Meeting:ReFilterActivities()
							Menu:Close()
                        end,
                    },
                    RESET = {
                        order = 15,
                        type = "execute",
                        name = "重置屏蔽词",
                        desc = "重置屏蔽词至初始状态",
                        func = function()
							MEETING_DB.blockWords = { -- 新增重置默认屏蔽词 by 武藤纯子酱 2025.12.30
								'加速器',
								'淘宝',
								'代充',
								'代练'
							}
							Meeting.blockWords = MEETING_DB.blockWords -- 新增读取配置文件中的屏蔽关键词 by 武藤纯子酱 2025.12.30
                            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00集合石|r: 已重置屏蔽词")
                            Meeting:ReFilterActivities()
							Menu:Close()
                        end,
                    },
                    SEPARATOR1 = {
                        order = 20,
                        type = "header",
                        name = " ",
                    },
                    LIST_TITLE = {
                        order = 25,
                        type = "header",
                        name = "当前屏蔽词 (" .. table.getn(Meeting.blockWords) .. "个)",
                    },
                }
            }
            
            -- 动态添加当前屏蔽词列表
            local order = 50
            for i, word in ipairs(Meeting.blockWords) do
				local blockword = word
                blockOptions.args["BLOCK_" .. i] = {
                    order = order,
                    type = "execute",
                    name = word,
                    desc = "点击删除此屏蔽词",
                    func = function()
						local found = false
						for i, word in ipairs(Meeting.blockWords) do
							if word == blockword then
								table.remove(Meeting.blockWords, i)
								found = true
								break
							end
						end
                        MEETING_DB.blockWords = Meeting.blockWords
                        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00集合石|r: 已删除屏蔽词: " .. blockword)
                        Meeting:ReFilterActivities()
                    end,
                }
                order = order + 1
            end
            
            -- 如果没有屏蔽词，显示提示
            if table.getn(Meeting.blockWords) == 0 then
                blockOptions.args.NO_BLOCKS = {
                    order = 55,
                    type = "header",
                    name = "|cffcccccc暂无屏蔽词|r",
                }
            end
            
            -- 注册并打开菜单
            Menu:Register(this,
                'children', function()
                    Menu:FeedAceOptionsTable(blockOptions)
                end,
                'cursorX', true,
                'cursorY', true,
                'dontHook', true,
                'onClose', function()
                    Meeting.blockDropdownState.isOpen = false
                end
            )
            
            Menu:Open(this)
            Meeting.blockDropdownState.isOpen = true
        end
    end
})

-- 修改菜单注册，添加关闭时的回调 by 武藤纯子酱 2025.9.22
Menu:Register(selectButton,
    'children', function()
        Menu:FeedAceOptionsTable(options)
    end,
    'cursorX', true,
    'cursorY', true,
    'dontHook', true,
    'onClose', function()
        Meeting.dropdownState.isOpen = false
    end
)

local refreshButton = Meeting.GUI.CreateButton({
    parent = browserFrame,
    text = "刷新",
    type = Meeting.GUI.BUTTON_TYPE.SUCCESS,
    width = 80,
    height = 24,
    anchor = {
        point = "TOPRIGHT",
        relative = browserFrame,
        relativePoint = "TOPRIGHT",
        x = 0,
        y = -14
    },
    click = function()
        Meeting.BrowserFrame:UpdateList(true)
    end
})

local activityListHeaderFrame = Meeting.GUI.CreateFrame({
    parent = browserFrame,
    width = 746,
    height = 28,
    background = Meeting.GUI.Theme.LightBrown,
    anchor = {
        point = "TOPLEFT",
        relative = browserFrame,
        relativePoint = "TOPLEFT",
        x = 18,
        y = -56
    }
})

local activityTypeText = Meeting.GUI.CreateText({
    parent = activityListHeaderFrame,
    text = "副本 / 首领",
    fontSize = 14,
    width = 148,
    height = 24,
    anchor = {
        point = "TOPLEFT",
        relative = activityListHeaderFrame,
        relativePoint = "TOPLEFT",
    }
})

local modeText = Meeting.GUI.CreateText({
    parent = activityListHeaderFrame,
    text = "模式",
    fontSize = 14,
    width = 32,
    height = 24,
    anchor = {
        point = "TOPLEFT",
        relative = activityTypeText,
        relativePoint = "TOPRIGHT",
    }
})

local membersText = Meeting.GUI.CreateText({
    parent = activityListHeaderFrame,
    text = "人数",
    fontSize = 14,
    width = 56,
    height = 24,
    anchor = {
        point = "TOPLEFT",
        relative = modeText,
        relativePoint = "TOPRIGHT",

    }
})

local leaderText = Meeting.GUI.CreateText({
    parent = activityListHeaderFrame,
    text = "团长",
    fontSize = 14,
    width = 96,
    height = 24,
    anchor = {
        point = "TOPLEFT",
        relative = membersText,
        relativePoint = "TOPRIGHT",
    }
})

local commentText = Meeting.GUI.CreateText({
    parent = activityListHeaderFrame,
    text = "说明",
    fontSize = 14,
    width = 352,
    height = 24,
    anchor = {
        point = "TOPLEFT",
        relative = leaderText,
        relativePoint = "TOPRIGHT",
    }
})

local actionText = Meeting.GUI.CreateText({
    parent = activityListHeaderFrame,
    text = "操作",
    fontSize = 14,
    width = 62,
    height = 24,
    anchor = {
        point = "TOPLEFT",
        relative = commentText,
        relativePoint = "TOPRIGHT",
    }
})

local hoverBackgrop = {
    edgeFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeSize = 24,
    insets = { left = -1, right = -1, top = -1, bottom = -1 },
}

local function CreateRequestPrompt(config)
    config.width = config.width or 300
    config.height = 185

    if not MEETING_DB.role or MEETING_DB.role == 0 then
        MEETING_DB.role = Meeting.GetClassRole(Meeting.playerClass)
    end

    config.onCustomFrame = function(parent, anchor)
        local frame = Meeting.GUI.CreateFrame({
            parent = parent,
            width = config.width - 20,
            height = 100,
            anchor = {
                point = "TOPLEFT",
                relative = anchor,
                relativePoint = "BOTTOMLEFT",
                x = 0,
                y = -10
            }
        })

        local roleEnable = Meeting.GetClassRole(Meeting.playerClass)

        local function createRole(role, anchor)
            local enable = bit.band(roleEnable, role) == role
            local ckecked = bit.band(MEETING_DB.role, role) == role

            local roleFrame = Meeting.GUI.CreateButton({
                parent = frame,
                width = 32,
                height = 40,
                anchor = anchor,
                disabled = not enable,
                click = function()
                    local ckeck = this.checkButton:GetChecked()
                    if bit.band(MEETING_DB.role, role) == role then
                        MEETING_DB.role = bit.bxor(MEETING_DB.role, role)
                    else
                        MEETING_DB.role = bit.bor(MEETING_DB.role, role)
                    end
                    this.checkButton:SetChecked(not ckeck)
                end
            })

            local tankTexture = roleFrame:CreateTexture()
            local textureName = "damage"
            if role == Meeting.Role.Tank then
                textureName = "tank"
            elseif role == Meeting.Role.Healer then
                textureName = "healer"
            end
            tankTexture:SetTexture("Interface\\AddOns\\Meeting\\assets\\" .. textureName .. ".blp")
            tankTexture:SetWidth(40)
            tankTexture:SetHeight(40)
            tankTexture:SetPoint("TOPLEFT", roleFrame, "TOPLEFT", 0, 0)
            if not enable then
                tankTexture:SetVertexColor(0.2, 0.2, 0.2, 1)
            else
                roleFrame.checkButton = Meeting.GUI.CreateCheck({
                    parent = roleFrame,
                    width = 20,
                    height = 20,
                    anchor = {
                        point = "BOTTOMRIGHT",
                        relative = roleFrame,
                        relativePoint = "BOTTOMRIGHT",
                        x = 0,
                        y = 0
                    },
                    checked = enable and ckecked,
                    click = function(checked)
                        if bit.band(MEETING_DB.role, role) == role then
                            MEETING_DB.role = bit.bxor(MEETING_DB.role, role)
                        else
                            MEETING_DB.role = bit.bor(MEETING_DB.role, role)
                        end
                    end
                })
            end
            return roleFrame
        end

        local tank = createRole(Meeting.Role.Tank, {
            point = "TOPLEFT",
            relative = frame,
            relativePoint = "TOPLEFT",
            x = 70,
            y = 0
        })

        local healer = createRole(Meeting.Role.Healer, {
            point = "TOPLEFT",
            relative = tank,
            relativePoint = "TOPRIGHT",
            x = 10,
            y = 0

        })

        local damage = createRole(Meeting.Role.Damage, {
            point = "TOPLEFT",
            relative = healer,
            relativePoint = "TOPRIGHT",
            x = 10,
            y = 0
        })

        local commentFrame = Meeting.GUI.CreateText({
            parent = frame,
            anchor = {
                point = "TOPLEFT",
                relative = tank,
                relativePoint = "BOTTOMLEFT",
                x = -70,
                y = -5
            },
            text = "备注",
        })

        local input = Meeting.GUI.CreateInput({
            parent = frame,
            width = config.width - 20,
            height = 20,
            anchor = {
                point = "TOPLEFT",
                relative = commentFrame,
                relativePoint = "BOTTOMLEFT",
                x = 0,
                y = -10
            },
            limit = 128,
            multiLine = false
        })
        Meeting.GUI.SetBackground(input, Meeting.GUI.Theme.Black, Meeting.GUI.Theme.White)

        config._confirm = function()
            local text = input:GetText()
            text = string.gsub(text, ":", "：")
            config.confirm(text, MEETING_DB.role)
        end

        return frame
    end

    return Meeting.GUI.CreateDialog(config)
end

local activityListFrame = Meeting.GUI.CreateListFrame({
    name = "MeetingActivityListFrame",
    parent = browserFrame,
    width = 746,
    height = 280,
    anchor = {
        point = "TOPLEFT",
        relative = activityListHeaderFrame,
        relativePoint = "BOTTOMLEFT",
        x = 0,
        y = 0
    },
    step = 28,
    display = 10,
    cell = function(f)
        f.OnHover = function(this, isHover)
            if isHover then
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT", 40)
                GameTooltip:SetText(this.name, 1, 1, 1, 1)
                local classColor = this.activity.classColor
                GameTooltip:AddLine(this.leader, classColor.r, classColor.g, classColor.b, 1)

                if this.level ~= nil and this.level > 0 then
                    local color = GetDifficultyColor(this.level)
                    GameTooltip:AddLine(
                        format('%s |cff%02x%02x%02x%s|r', LEVEL, color.r * 255, color.g * 255, color.b * 255,
                            this.level), 1, 1, 1)
                end

                if this.comment ~= "_" then
                    GameTooltip:AddLine(string.escapemarkup(this.comment), 0.75, 0.75, 0.75, 1)
                end

                local classMap = this.activity:GetClassMap()
                if classMap then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("-- 成员 --", 0.75, 0.75, 0.75, 1)
                    for k, v in pairs(classMap) do
                        local clsname = Meeting.GetClassLocaleName(k)
                        GameTooltip:AddLine(clsname .. " " .. v .. "个", 1, 1, 1, 1)
                    end
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("<双击>悄悄话", 1, 1, 1, 1)
                GameTooltip:SetWidth(220)
                GameTooltip:Show()
            else
                GameTooltip:Hide()
            end
        end
        f:SetScript("OnDoubleClick", function()
            if this.leader == Meeting.player then
                return
            end
            ChatFrame_OpenChat("/w " .. this.leader, SELECTED_DOCK_FRAME or DEFAULT_CHAT_FRAME)
        end)

        f.nameFrame = Meeting.GUI.CreateText({
            parent = f,
            text = "",
            fontSize = 14,
            height = 20,
            width = 148,
            anchor = {
                point = "TOPLEFT",
                relative = f,
                relativePoint = "TOPLEFT",
                x = 0,
                y = -6
            }
        })

        f.hcFrame = Meeting.GUI.CreateText({
            parent = f,
            text = "",
            fontSize = 14,
            height = 20,
            width = 32,
            anchor = {
                point = "TOPLEFT",
                relative = f.nameFrame,
                relativePoint = "TOPRIGHT",
                x = 0,
                y = 0
            }
        })

        f.membersFrame = Meeting.GUI.CreateText({
            parent = f,
            text = "",
            width = 56,
            fontSize = 14,
            height = 20,
            anchor = {
                point = "TOPLEFT",
                relative = f.hcFrame,
                relativePoint = "TOPRIGHT",
                x = 0,
                y = 0
            }
        })

        f.leaderFrame = Meeting.GUI.CreateText({
            parent = f,
            text = "",
            fontSize = 14,
            height = 20,
            width = 96,
            anchor = {
                point = "TOPLEFT",
                relative = f.membersFrame,
                relativePoint = "TOPRIGHT",
                x = 0,
                y = 0
            }
        })

        f.commentFrame = Meeting.GUI.CreateText({
            parent = f,
            text = "",
            fontSize = 14,
            height = 20,
            width = 352,
            anchor = {
                point = "TOPLEFT",
                relative = f.leaderFrame,
                relativePoint = "TOPRIGHT",
                x = 0,
                y = 0
            }
        })
        f.commentFrame:SetJustifyV("TOP")

        f.statusFrame = Meeting.GUI.CreateText({
            parent = f,
            text = "",
            fontSize = 14,
            height = 20,
            color = { r = 0, g = 1, b = 0 },
            anchor = {
                point = "TOPLEFT",
                relative = f.commentFrame,
                relativePoint = "TOPRIGHT",
                x = 0,
                y = 0
            }
        })

        f.requestButton = Meeting.GUI.CreateButton({
            parent = f,
            text = "申请",
            width = 54,
            height = 22,
            type = Meeting.GUI.BUTTON_TYPE.PRIMARY,
            anchor = {
                point = "TOPLEFT",
                relative = f.commentFrame,
                relativePoint = "TOPRIGHT",
                x = 4,
                y = 3
            },
            click = function()
                if f.isChat then
                    ChatFrame_OpenChat("/w " .. f.leader, SELECTED_DOCK_FRAME or DEFAULT_CHAT_FRAME)
                else
                    local frame = CreateRequestPrompt({
                        parent = Meeting.BrowserFrame,
                        anchor = {
                            point = "CENTER",
                            relative = Meeting.BrowserFrame,
                            relativePoint = "CENTER",
                            x = 0,
                            y = 0
                        },
                        title = "申请加入" .. f.name,
                        confirm = function(text, role)
                            Meeting.Message.Request(f.id, text, role)
                            local activity = Meeting:FindActivity(f.id)
                            activity.applicantStatus = Meeting.APPLICANT_STATUS.Invited
                            Meeting.BrowserFrame:UpdateActivity(activity)
                            f.requestButton:Disable()
                        end
                    })
                    frame:SetPoint("TOP", Meeting.BrowserFrame, "TOP", 0, -50)
                end
            end
        })
    end
})

local function ReloadCell(frame, activity)
	if not frame then return end
    local info = Meeting.GetActivityInfo(activity.code)
    local displayName = activity.raidChat and Meeting.RaidChat.Label(activity.raidChat, true) or info.name
    frame.nameFrame:SetText(displayName)
    frame.hcFrame:SetText(activity.isHC and "HC" or "")
    frame.leaderFrame:SetText(activity.unitname)
    local classColor = activity.classColor
    frame.leaderFrame:SetTextColor(classColor.r, classColor.g, classColor.b)
    local maxMambers = activity.targetMembers or Meeting.GetActivityMaxMembers(activity.code)
    local isChat = activity:IsChat()
    if isChat then
        frame.membersFrame:SetText("-")
    else
        frame.membersFrame:SetText((activity.members or 0) .. "/" .. maxMambers)
    end

    frame.commentFrame:SetText(activity.comment ~= "_" and string.escapemarkup(activity.comment) or "")

    if activity.unitname == Meeting.player or (Meeting.joinedActivity and Meeting.joinedActivity.unitname == activity.unitname) then
        frame.statusFrame:SetText("已加入")
        frame.statusFrame:SetTextColor(Meeting.GUI.Theme.Green.r, Meeting.GUI.Theme.Green.g,
            Meeting.GUI.Theme.Green.b)
        frame.statusFrame:Show()
        frame.requestButton:Hide()
    else
        if activity.applicantStatus == Meeting.APPLICANT_STATUS.Invited then
            frame.statusFrame:SetText("已申请")
            frame.statusFrame:SetTextColor(Meeting.GUI.Theme.Green.r, Meeting.GUI.Theme.Green.g,
                Meeting.GUI.Theme.Green.b)
            frame.statusFrame:Show()
            frame.requestButton:Hide()
        elseif activity.applicantStatus == Meeting.APPLICANT_STATUS.Declined then
            frame.statusFrame:SetText("已拒绝")
            frame.statusFrame:SetTextColor(Meeting.GUI.Theme.Red.r, Meeting.GUI.Theme.Red.g, Meeting.GUI.Theme.Red.b)
            frame.statusFrame:Show()
            frame.requestButton:Hide()
        elseif activity.applicantStatus == Meeting.APPLICANT_STATUS.Joined then
            frame.statusFrame:SetText("已加入")
            frame.statusFrame:SetTextColor(Meeting.GUI.Theme.Green.r, Meeting.GUI.Theme.Green.g,
                Meeting.GUI.Theme.Green.b)
            frame.statusFrame:Show()
            frame.requestButton:Hide()
        else
            frame.statusFrame:Hide()
            frame.requestButton:Show()
            if isChat then
                frame.requestButton:Enable()
                frame.requestButton:SetText("密语")
            elseif (activity.members or 0) >= maxMambers then
                frame.requestButton:Disable()
                frame.requestButton:SetText("满员")
            else
                frame.requestButton:Enable()
                frame.requestButton:SetText("申请")
            end
        end
    end

    frame.activity = activity
    frame.id = activity.unitname
    frame.name = activity.raidChat and Meeting.RaidChat.Label(activity.raidChat) or displayName
    frame.isChat = isChat
    frame.leader = activity.unitname
    frame.level = activity.level
    frame.comment = activity.comment
end

local resultText = Meeting.GUI.CreateText({ parent = browserFrame, text = "仅显示团本和世界首领", fontSize = 12,
    width = 746, height = 18, color = {r=0.65,g=0.72,b=0.8},
    anchor = {point="BOTTOMLEFT",relative=browserFrame,relativePoint="BOTTOMLEFT",x=18,y=0} })
local emptyText = Meeting.GUI.CreateText({ parent = browserFrame, text = "暂无符合条件的招募\n可切换活动筛选，或清空搜索", fontSize = 14,
    width = 500, height = 48, color = {r=0.65,g=0.72,b=0.8},
    anchor = {point="CENTER",relative=browserFrame,relativePoint="CENTER",x=0,y=-20} })
emptyText:SetJustifyH("CENTER")
emptyText:Hide()

local activities = {}

function Meeting.BrowserFrame:UpdateList(force, scroll)
    if not Meeting.MainFrame:IsShown() or not Meeting.BrowserFrame:IsShown() then
        return
    end
    if not scroll then
        if not force then
            if Meeting.isHover then
                Meeting.GUI.SetBackground(refreshButton, Meeting.GUI.Theme.Red)
                return
            end
        end
        Meeting.GUI.SetBackground(refreshButton, Meeting.GUI.Theme.Green)
        activities = {}
        
        -- 修改搜索逻辑，移除类别限制
        local function search(activity)
            -- 如果有多选，使用多选逻辑
            if next(Meeting.searchInfo.codes) then
                return Meeting.searchInfo.codes[activity.code] or Meeting.searchInfo.codes[activity.category] or false
            -- 如果有单个选择
            elseif Meeting.searchInfo.code ~= "" then
                return Meeting.searchInfo.code == activity.code
            -- 如果选择了类别但没有选择具体活动
            elseif Meeting.searchInfo.category ~= "" then
                return Meeting.searchInfo.category == activity.category
            -- 全部显示
            else
                return true
            end
        end
        
        -- 添加搜索文本过滤函数 by 武藤纯子酱 2025.9.24
        local function textSearch(activity)
            if Meeting.searchInfo.text == "" then
                return true  -- 没有搜索文本，显示所有
            end
            
            -- 在活动说明中搜索
            local commentMatch = activity.comment and 
                                string.find(string.lower(activity.comment), Meeting.searchInfo.text, 1, true)
            
            -- 在队长名字中搜索
            local leaderMatch = activity.unitname and 
                               string.find(string.lower(activity.unitname), Meeting.searchInfo.text, 1, true)
            
            -- 在活动名称中搜索
            local activityInfo = Meeting.GetActivityInfo(activity.code)
            local activityName = activity.raidChat and Meeting.RaidChat.Label(activity.raidChat) or (activityInfo and activityInfo.name)
            local activityNameMatch = activityName and
                                     string.find(string.lower(activityName), Meeting.searchInfo.text, 1, true)
            
            return commentMatch or leaderMatch or activityNameMatch
        end
        
        for _, activity in ipairs(Meeting.activities) do
			-- 添加屏蔽词检查
			local shouldShow = activity.raidChat ~= nil or Meeting.IsSupportedActivity(activity.code)
			
			-- 检查队长名字中的屏蔽词
			if Meeting.CheckBlockWords(activity.unitname, activity.unitname) then
				shouldShow = false
			end
			
			-- 检查活动说明中的屏蔽词
			if shouldShow and Meeting.CheckBlockWords(activity.unitname, activity.comment) then
				shouldShow = false
			end

            if shouldShow and textSearch(activity) then
                local matches = activity.raidChat
                    and Meeting.RaidChat.MatchesSearch(activity.raidChat, Meeting.searchInfo, activity.code)
                    or (not activity.raidChat and search(activity))
                if matches then table.insert(activities, activity) end
            end
        end
    end
    local count = table.getn(activities)
    resultText:SetText("显示 "..count.." 条招募  ·  双击密语，悬停查看完整说明")
    if count == 0 then emptyText:Show() else emptyText:Hide() end
    activityListFrame:Reload(count, function(frame, index)
        ReloadCell(frame, activities[index])
    end)
    
    -- 更新搜索结果显示 by 武藤纯子酱 2025.9.24
    -- 输入框持有焦点（用户正在输入/输入法合成中）时绝不回写，避免打断输入法合成
    if Meeting.searchInfo.text ~= "" and not searchInput:HasFocus() then
        searchInput:SetText(Meeting.searchInfo.text)
    end
end

activityListFrame.OnScroll = Meeting.BrowserFrame.UpdateList

function Meeting.BrowserFrame:UpdateActivity(activity)
    local index = -1
    for i, value in ipairs(activities) do
        if value.unitname == activity.unitname then
            index = i
            break
        end
    end
    if index == -1 then
        return
    end

    local offset = FauxScrollFrame_GetOffset(activityListFrame) + 1
    if index < offset or index > offset + table.getn(activityListFrame.pool) then
        return
    end

    local frame = activityListFrame.pool[index - offset + 1]
    ReloadCell(frame, activity)
end
