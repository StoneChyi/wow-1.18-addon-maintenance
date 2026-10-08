-- options.lua
local L = AceLibrary("AceLocale-2.2"):new("NotGrid")

-----------------------------
-- 默认配置选项
-----------------------------
local DefaultOptions = {
    ["minimapAngle"] = 180,                     -- 小地图按钮角度
    ["version"] = 2.1,                          -- 版本号（跟随提交编号）
    ["versionchecking"] = true,                 -- 版本检查

    ["unitwidth"] = 45,                         -- 框架宽度
    ["unitheight"] = 30,                        -- 框架高度
    ["unitborder"] = 2,                         -- 边框厚度
    ["space_left_and_right"] = 2,               -- 左右间距
    ["space_top_and_bottom"] = 2,               -- 上下间距
    ["unitbgcolor"] = {0,0,0,0.4},              -- 背景颜色
    ["unitbordercolor"] = {0,0,0,0.8},          -- 边框颜色
    ["unithealthorientation"] = 2,              -- 血条方向 (1=垂直,2=水平)
    ["unithealthbartexture"] = 3,               -- 血条纹理编号
    ["unithealthbarcolor"] = {39/255,186/255,42/255,1},   -- 血条颜色
    ["unithealthbarbgcolor"] = {0,0,0,0.1},     -- 血条背景色
    ["unithealthbarbgtexture"] = "Interface\\Buttons\\WHITE8X8",   -- 血条背景纹理
    ["unitfont"] = STANDARD_TEXT_FONT,          -- 字体
    ["unitnamehealthtextcolor"] = {1,1,1,1},    -- 姓名/血量文字颜色
    ["unitnamehealthtextsize"] = 13.5,          -- 姓名/血量文字大小
    ["unithealcommbarcolor"] = {32/255,112/255,11/255,1},   -- 预估治疗条颜色
    ["unithealcommtextcolor"] = {39/255,186/255,42/255,1},  -- 预估治疗文字颜色
    ["unithealcommtextsize"] = 10,              -- 预估治疗文字大小
    ["unithealcommtextoffx"] = 0,               -- 预估治疗文字X偏移
    ["unithealcommtextoffy"] = -10,             -- 预估治疗文字Y偏移
    ["unittrackingiconsize"] = 6,               -- 追踪图标大小
    ["unittrackingiconborder"] = 1,             -- 追踪图标边框（已弃用）
    ["unittrackingiconbordercolor"] = {0,0,0,1},-- 追踪图标边框颜色（已弃用）

    ["showpowerbar"] = true,                    -- 显示能量/怒气/蓝条
    ["powersize"] = 5,                          -- 能量条大小
    ["powerposition"] = 2,                      -- 能量条位置 (1=上,2=下,3=左,4=右)
    ["colorpowerbarbgbytype"] = false,          -- 按类型着色能量条背景
    ["unitpowerbarbgcolor"] = {0,0,0,0.1},     -- 能量条背景色

    ["showTrackingAsColors"] = false,           -- 追踪图标显示为纯色块
    -- 八个方位的自定义监控图标 (buff/debuff名称或类型)
    ["trackingicon1"] = {"回春术","愈合","恢复",},
    ["trackingicon1invert"] = false,
    ["trackingicon1color"] = {0.37,0.83,0.38},
    ["trackingicon2"] = {"",},
    ["trackingicon2invert"] = false,
    ["trackingicon2color"] = {0.20,0.60,1.00},
    ["trackingicon3"] = {L["Magic"],},
    ["trackingicon3invert"] = false,
    ["trackingicon3color"] = {0.20,0.60,1.00},
    ["trackingicon4"] = {L["Poison"],},
    ["trackingicon4invert"] = false,
    ["trackingicon4color"] = {0.00,0.60,0},
    ["trackingicon5"] = {L["Curse"],},
    ["trackingicon5invert"] = false,
    ["trackingicon5color"] = {0.60,0.00,1.00},
    ["trackingicon6"] = {L["Disease"],},
    ["trackingicon6invert"] = false,
    ["trackingicon6color"] = {0.60,0.40,0},
    ["trackingicon7"] = {"致死打击","重伤","暗影迷雾","死木诅咒","血性狂暴","致伤毒药","虚弱妖术",},
    ["trackingicon7invert"] = false,
    ["trackingicon7color"] = {0.80,0,0},
    ["trackingicon8"] = {"",},
    ["trackingicon8invert"] = false,
    ["trackingicon8color"] = {0.20,0.60,1.00},

    ["showOnlyDispellableDebuffs"] = false,     -- 只显示可驱散的Debuff

    ["trackaggro"] = true,                      -- 仇恨警告
    ["aggrowarningcolor"] = {150/255,10/255,10/255,0.8},   -- 仇恨警告颜色
    ["trackmana"] = true,                       -- 低蓝量警告
    ["manawarningcolor"] = {42/255,69/255,117/255,0.8},    -- 低蓝量警告颜色

    ["tracktarget"] = true,                     -- 高亮当前目标
    ["targetcolor"] = {1,1,1,0.8},              -- 目标高亮颜色

    ["containerpoint"] = "TOPLEFT",             -- 容器锚点
    ["containeroffx"] = 40,                     -- 容器X偏移
    ["containeroffy"] = -400,                   -- 容器Y偏移

    ["unitnamehealthoffx"] = 0,                 -- 姓名X偏移
    ["unitnamehealthoffy"] = 0,                 -- 姓名Y偏移

    ["healththreshhold"] = 1,                   -- 血量阈值（低于此百分比显示数值）
    ["manathreshhold"] = 20,                    -- 低蓝量警告阈值（%）
    ["namelength"] = 6,                         -- 姓名显示长度

    ["ooralpha"] = 0.5,                         -- 超出范围透明度

    ["useproximity"] = true,                    -- 使用距离检测（已废弃，保留）
    ["proximityrate"] = 1,                      -- 距离检测间隔（秒）
    ["proximityleeway"] = 4,                    -- 距离检测宽容时间（秒）

    ["colorunitnamehealthbyclass"] = true,      -- 姓名按职业着色
    ["colorunithealthbarbyclass"] = true,       -- 血条按职业着色
    ["colorunithealthbarbgbyclass"] = true,     -- 血条背景按职业着色
    ["usetbcshamancolor"] = true,               -- 使用TBC萨满颜色
    ["usepetcolor"] = true,                     -- 使用自定义宠物颜色
    ["petcolor"] = {1,0.74,0},                  -- 宠物颜色

    ["smartcenter"] = false,                    -- 智能居中
    ["showhealcommtext"] = true,                -- 显示预估治疗文字
    ["showhealcommbar"] = true,                 -- 显示预估治疗条
    ["usemapdistances"] = true,                 -- 使用地图距离检测

    ["ShowPartyIndex"] = true,                  -- 显示小队编号
    ["showwhilesolo"] = false,                  -- 单人时显示框架
    ["showinparty"] = true,                     -- 队伍中显示框架
    ["showpartyinraid"] = false,                -- 团队中显示小队
    ["showpets"] = false,                       -- 显示宠物
    ["showblizzframesInParty"] = false,         -- 队伍中显示暴雪小队框架
    ["showblizzframesInRaid"] = false,          -- 团队中显示暴雪小队框架

    ["growthdirection"] = 1,                    -- 生长方向 (1~9)
    -- 1: 小组从左到右，组内从上到下
    -- 2: 小组从右到左，组内从上到下
    -- 3: 小组从上到下，组内从左到右
    -- 4: 小组从下到上，组内从左到右
    -- 5: 单列向下
    -- 6: 单列向上
    -- 7: 单行向右
    -- 8: 单行向左
    -- 9: 自定义(两排布局)

    ["cliquehook"] = false,                     -- Clique 钩子（默认关闭避免困惑）
    ["configmode"] = false,                     -- 配置模式
    ["disablemouseoverincombat"] = false,       -- 战斗中禁用鼠标提示

    ["borderartwork"] = false,                  -- 边框艺术效果

    ["draggable"] = true,                       -- 可拖动
    ["showmenuhint"] = true,                    -- 显示滚动提示
    ["requireSight"] = false,                   -- 需要视线检测
    ["showdungeonrole"] = false,                -- 显示职责图标
    ["manualroles"] = {},                       -- 手动设置的职责（按姓名保存）
    ["dungeonrolesize"] = 14,                   -- 职责图标大小
    ["dungeonroleoffx"] = -2,                   -- 职责图标X偏移
    ["dungeonroleoffy"] = -2,                   -- 职责图标Y偏移
}

------------------------------
-- 重置为默认设置并重载界面
------------------------------
function NotGrid:ResetDefaultOptions()
    NotGridOptions = {}
    NotGridOptions = DefaultOptions
    ReloadUI()
end

--------------------------------------------
-- 初始化时确保所有选项都存在（补全缺失项）
--------------------------------------------
function NotGrid:SetDefaultOptions()
    for key,value in DefaultOptions do
        if not NotGridOptions[key] and not (not NotGridOptions[key] and type(NotGridOptions[key]) == "boolean") then
            NotGridOptions[key] = value
        end
    end
    -- 版本迁移处理：将旧的字符串配置转为新的数组配置
    if NotGridOptions.version < 1.112 and type(NotGridOptions.trackingicon1) ~= "table" then
        for i=1,8 do
            NotGridOptions["trackingicon"..i] = DefaultOptions["trackingicon"..i]
        end
    end
    -- 版本 < 1.106 时统一容器锚点
    if NotGridOptions.version < 1.106 and NotGridOptions.containerpoint ~= "CENTER" then
        NotGridOptions.containerpoint = DefaultOptions.containerpoint
        NotGridOptions.containeroffx = DefaultOptions.containeroffx
        NotGridOptions.containeroffy = DefaultOptions.containeroffy
    end
    -- 版本 < 1.104 时将字符串方向转为数字
    if NotGridOptions.version < 1.104 and type(NotGridOptions.unithealthorientation) ~= "number" then
        NotGridOptions.unithealthorientation = DefaultOptions.unithealthorientation
    end
    NotGridOptions.version = DefaultOptions.version -- 更新版本号

    -- 加载并过滤手动设置的职责（只保留当前队伍中的成员）
    if self.o.manualroles then
        local stillInTeam = {}
        local currNames = {}
        for i=1,GetNumRaidMembers() do
            local n = GetRaidRosterInfo(i)
            if n then currNames[n]=true end
        end
        for i=1,GetNumPartyMembers() do
            currNames[UnitName("party"..i)]=true
        end
        currNames[UnitName("player")]=true

        for name,role in pairs(self.o.manualroles) do
            if currNames[name] then
                stillInTeam[name]=role
            end
        end
        self.o.manualroles = stillInTeam
        self.ManualRoles    = stillInTeam
    end
end

--------------------
-- 斜杠命令处理
--------------------
SLASH_NOTGRID1 = "/notgrid"
SLASH_NOTGRID2 =  "/ng"
function SlashCmdList.NOTGRID(msg, editbox)
    if msg == "reset" then
        -- 重置所有选项并重载
        for key,value in DefaultOptions do
            NotGridOptions[key] = value
        end
        ReloadUI()
    elseif msg == "grid" then
        -- 快速应用 Grid 风格血条纹理
        NotGrid.o.unithealthbartexture = "Interface\\AddOns\\NotGrid\\media\\GridGradient"
        NotGrid.o.unithealthbarbgtexture = "Interface\\AddOns\\NotGrid\\media\\GridGradient"
        NotGrid.o.unithealthbarcolor = {0,0,0,0.65}
        NotGrid.o.unithealthbarbgcolor = {0,0,0,1}
        NotGrid.o.colorunithealthbarbyclass = false
        NotGrid.o.colorunithealthbarbgbyclass = true
        ReloadUI()
    else
        -- 默认打开设置菜单
        NotGridOptionsMenu:Show()
    end
end