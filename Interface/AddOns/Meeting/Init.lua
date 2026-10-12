BINDING_HEADER_CS_MEETING_HEADER = "集合石"
BINDING_NAME_CS_MEETING_NAME = "显示/隐藏"

MEETING_DB = {}

local _, class = UnitClass("player")

Meeting = {
    VERSION = {
        MAJOR = 1,
        MINOR = 1,
        PATCH = 9,
    },

    player = UnitName("player"),

    playerClass = class,

    APPLICANT_STATUS = { None = 1, Invited = 2, Declined = 3, Joined = 4 },

    createInfo = {},

    searchInfo = {},

    activities = {},

    playerIsHC = false,

    channel = "LFT",

    isAFK = false,

    members = {},

    blockWords = {}, -- 添加屏蔽词引用 by 武藤纯子酱 2025.12.30
}

local classNameMap = {
    [1] = "WARLOCK",
    [2] = "HUNTER",
    [3] = "PRIEST",
    [4] = "PALADIN",
    [5] = "MAGE",
    [6] = "ROGUE",
    [7] = "DRUID",
    [8] = "SHAMAN",
    [9] = "WARRIOR",
}

local classNumberMap = {
    ["WARLOCK"] = 1,
    ["HUNTER"] = 2,
    ["PRIEST"] = 3,
    ["PALADIN"] = 4,
    ["MAGE"] = 5,
    ["ROGUE"] = 6,
    ["DRUID"] = 7,
    ["SHAMAN"] = 8,
    ["WARRIOR"] = 9,
}

local classChineseNameMap = {
    [1] = "术士",
    [2] = "猎人",
    [3] = "牧师",
    [4] = "圣骑士",
    [5] = "法师",
    [6] = "盗贼",
    [7] = "德鲁伊",
    [8] = "萨满",
    [9] = "战士",
}

function Meeting.NumberToClass(n)
    return classNameMap[n]
end

function Meeting.ClassToNumber(class)
    return classNumberMap[class]
end

function Meeting.GetClassRGBColor(class, unitname)
    local rgb = RAID_CLASS_COLORS[class]
    if not class or not rgb then
        if SCCN_storage then
            local cache = SCCN_storage[unitname]
            if cache then
                return Meeting.GetClassRGBColor(Meeting.NumberToClass(cache.c))
            end
        end
        rgb = RAID_CLASS_COLORS[nil]
    end
    if not rgb then
        rgb = { r = 0.6, g = 0.6, b = 0.6 }
    end
    return rgb
end

Meeting.Categories = {
    {
        key = "DUNGENO",
        name = "地下城",
        members = 5,
        children = {
            {
                key = "RFC",
                name = "怒焰裂谷",
                minLevel = 13,
                match = { "怒焰", "ny" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "FH",
                name = "霜鬃谷",
                minLevel = 13,
                match = { "霜鬃", "szg" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "WC",
                name = "哀嚎洞穴",
                minLevel = 17,
                match = { "哀嚎", "ah" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "DM",
                name = "死亡矿井",
                minLevel = 17,
                match = { "死矿", "sw" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "SFK",
                name = "影牙城堡",
                minLevel = 22,
                match = { "影牙" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "STOCKS",
                name = "暴风城：监狱",
                minLevel = 22,
                match = { "监狱" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "BFD",
                name = "黑暗深渊",
                minLevel = 23,
                match = { "深渊" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "DR",
                name = "龙喉居所",
                minLevel = 27,
                match = { "龙喉","格瑞姆巴托" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },	
            {
                key = "WINDCAN",
                name = "风角峡谷",
                minLevel = 27,
                match = { "风角","峡谷","牛头本" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },				
            {
                key = "SMGY",
                name = "血色修道院墓地",
                minLevel = 27,
                match = { "血色" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "SMLIB",
                name = "血色修道院图书馆",
                minLevel = 28,
                match = { "血色" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "GNOMER",
                name = "诺莫瑞根",
                minLevel = 29,
				match = { "矮子本" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "RFK",
                name = "剃刀沼泽",
                minLevel = 29,
                match = { "剃刀" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "TCG",
                name = "新月林地",
                minLevel = 32,
                match = { "新月" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "SMARMORY",
                name = "血色修道院军械库",
                minLevel = 32,
                match = { "血色" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "STORM",
                name = "风暴废墟",
                minLevel = 35,
                match = { "风暴","风暴废墟","风暴之临","风暴城堡","巴洛" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },				
            {
                key = "SMCATH",
                name = "血色修道院大教堂",
                minLevel = 35,
                match = { "血色","教堂" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "RFD",
                name = "剃刀高地",
                minLevel = 36,
                match = { "剃刀" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "ULDA",
                name = "奥达曼",
                minLevel = 40,
                match = { "奥达曼" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "GILNEAS",
                name = "吉尔尼斯城",
                minLevel = 42,
				match = { "吉尔尼斯", "狼人" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "ZF",
                name = "祖尔法拉克",
                minLevel = 44,
                match = { "祖尔", "zul" },
				nomatch = { "祖尔格拉布" }  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "MARA",
                name = "玛拉顿",
                minLevel = 45,
                match = { "玛拉顿", "mld", "紫门", "橙门" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "ST",
                name = "阿塔哈卡神庙",
                minLevel = 50,
                match = { "神庙" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "HFQ",
                name = "仇恨熔炉采石场",
                minLevel = 50,
                match = { "采石场" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "BRD",
                name = "黑石深渊",
                minLevel = 52,
				match = { "黑石深渊" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "UBRS",
                name = "黑石塔上层",
                minLevel = 55,
                members = 10,
                match = { "黑上" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "LBRS",
                name = "黑石塔下层",
                minLevel = 55,
                match = { "黑下" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22

            },
            {
                key = "DME",
                name = "厄运之槌：东",
                minLevel = 55,
                match = { "厄运东" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "DMN",
                name = "厄运之槌：北",
                minLevel = 57,
                match = { "厄运北" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "DMW",
                name = "厄运之槌：西",
                minLevel = 57,
                match = { "厄运西" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "SCHOLO",
                name = "通灵学院",
                minLevel = 58,
                members = 10,
                match = { "通灵", "tl" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "STRAT",
                name = "斯坦索姆",
                minLevel = 58,
                members = 10,
                match = { "斯坦索姆", "stsm" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "KC",
                name = "卡拉赞墓穴",
                minLevel = 58,
                match = { "卡拉赞墓穴", "klz", "墓穴" },
				nomatch = {"卡上", "卡下", "40人卡拉赞", "40人klz", "40klz", "klz40", "klz上层", "上层klz", "上层卡拉赞", "卡拉赞上层", "卡拉赞之塔", "k40"}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "COTBM",
                name = "时光之穴：黑色沼泽",
                minLevel = 60,
                match = { "时光", "沼泽" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "SWV",
                name = "暴风城地牢",
                minLevel = 60,
				match = { "大监狱", "地牢" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
        }
    },
    {
        key = "RAID",
        name = "团队副本",
        members = 40,
        children = {
            {
                key = "MC",
                name = "熔火之心",
                minLevel = 60,
            },
            {
                key = "ONY",
                name = "奥妮克希亚的巢穴",
                minLevel = 60,
            },
            {
                key = "BWL",
                name = "黑翼之巢",
                minLevel = 60,
            },
            {
                key = "AQ40",
                name = "安其拉神殿",
                minLevel = 60,
            },
            {
                key = "NAXX",
                name = "纳克萨玛斯",
                minLevel = 60,
            },
            {
                key = "ZUG",
                name = "祖尔格拉布",
                minLevel = 60,
                members = 20,
            },
            {
                key = "AQ20",
                name = "安其拉废墟",
                minLevel = 60,
                members = 20,
            },
            {
                key = "TH",
                name = "木喉要塞",
                minLevel = 60,
                members = 20,
            },
            {
                key = "LKH",
                name = "卡拉赞下层",
                minLevel = 60,
                members = 10,
            },
            {
                key = "ES",
                name = "翡翠圣殿",
                minLevel = 60,
            },
			{
				key = "TOK",              -- 唯一标识符（需唯一）
				name = "卡拉赞之塔",        -- 显示名称
				minLevel = 60,              -- 最低等级要求（根据实际设定调整）
			}		
        }
    },
    {
        key = "QUEST",
        name = "任务",
        members = 5,
        children = {
            {
                key = "PartyQuest",
                name = "小队任务",
                members = 5,
				match = { "任务" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "RaidQuest",
                name = "团队任务",
                members = 40,
				match = { "任务" },		
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
			{
				key = "QuestLink",  -- 新增任务链接追踪
				name = "任务链接",
				members = 5,
				match = { "quest:" },  -- 匹配任务链接特征
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
			},			
        }
    },
    {
        key = "BOSS",
        name = "世界首领",
        members = 40,
        children = {
            {
                key = "Azuregos",
                name = "艾索雷葛斯",
                members = 40,
				match = { "蓝龙", "艾萨拉", "世界BOSS" },		
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "Emeriss",
                name = "艾莫莉丝",
                members = 40,
				match = { "绿龙", "菲拉斯", "辛特兰", "暮色森林", "灰谷", "世界BOSS" },	
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "Lethon",
                name = "雷索",
                members = 40,
				match = { "绿龙", "菲拉斯", "辛特兰", "暮色森林", "灰谷", "世界BOSS" },		
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "Taerar",
                name = "泰拉尔",
                members = 40,
				match = { "绿龙", "菲拉斯", "辛特兰", "暮色森林", "灰谷", "世界BOSS" },	
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "Ysondre",
                name = "伊森德雷",
                members = 40,
				match = { "绿龙", "菲拉斯", "辛特兰", "暮色森林", "灰谷", "世界BOSS" },	
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "Kazzak",
                name = "卡扎克",
                members = 40,
				match = { "卡扎克", "诅咒之地", "世界BOSS" },			
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },	
            {
                key = "Nerubian",
                name = "蛛魔监工",
                members = 40,
				match = { "蛛魔监工", "东瘟疫", "世界BOSS" },	
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },	
            {
                key = "DarkReaver",
                name = "卡拉赞黑暗掠夺者",
                members = 40,
				match = { "黑暗掠夺者", "逆风小径", "世界BOSS" },	
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "Ostarius",
                name = "奥兹塔里亚斯",
                members = 40,
				match = { "奥兹塔里亚斯", "奥丹姆", "塔纳利斯", "世界BOSS" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "Concavius",
                name = "空卡维斯",
                members = 40,
				match = { "空卡维斯", "虚空之子", "凄凉之地", "世界BOSS" },	
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "Cow",
                name = "奶牛王",
                members = 40,
				match = { "奶牛", "艾尔文森林", "世界BOSS" },	
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "Cla'ckora",
                name = "克拉科拉",
                members = 40,
				match = { "克拉科拉", "鱼人", "艾萨拉", "世界BOSS" },	
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },			
        }
    },
    {
        key = "PVP",
        name = "PvP",
        children = {
            {
                key = "AV",
                name = "奥特兰克山谷",
                minLevel = 51,
                members = 40,
				match = { "奥特兰克", "奥山", "大战场" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "WSG",
                name = "战歌峡谷",
                minLevel = 10,
                members = 10,
				match = { "战歌", "小战场" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "AB",
                name = "阿拉希盆地",
                minLevel = 20,
                members = 15,
				match = { "阿拉希", "ALX" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "BR",
                name = "血环竞技场",
                minLevel = 11,
                members = 3,
				match = { "血环", "竞技场" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
            {
                key = "PVP",
                name = "野外PvP",
                minLevel = 1,
                members = 40,
				match = { "PVP" },
				nomatch = {}  -- 新增排除关键词 by 武藤纯子酱 2025.9.22
            },
        }
    },
    {
        key = "OTHER",
        name = "其它",
        members = 40,
        children = {
            {
                key = "OTHER",
                name = "其它",
                minLevel = 1,
            },
        }
    },
    {
        key = "CHAT",
        name = "频道",
        members = 40,
        hide = true,
        children = {
            {
                key = "WORLD",
                name = "世界频道",
                minLevel = 1,
            },
            {
                key = "CHINA",
                name = "中文频道",
                minLevel = 1,
            },
            {
                key = "HARDCORE",
                name = "硬核频道",
                minLevel = 1,
            },
        }
    }
}

local activityCategoryMap = {}

for _, value in ipairs(Meeting.Categories) do
    for _, child in ipairs(value.children) do
        activityCategoryMap[child.key] = { key = value.key, members = value.members }
    end
end

function Meeting.GetActivityCategory(code)
    -- 未知 code（旧版客户端/畸形报文）兜底到 OTHER，避免调用方 .key 索引 nil 崩溃
    return activityCategoryMap[code] or activityCategoryMap["OTHER"]
end

function Meeting.GetActivityMaxMembers(code)
    local info = Meeting.GetActivityInfo(code)
    if info and info.members then
        return info.members
    end

    local category = Meeting.GetActivityCategory(code)
    if category then
        return category.members
    end

    return 40
end

local activityInfoMap = {}

function Meeting.GetActivityInfo(code)
    if activityInfoMap[code] then
        return activityInfoMap[code]
    end
    for _, value in pairs(Meeting.Categories) do
        for _, value in pairs(value.children) do
            if value.key == code then
                activityInfoMap[code] = value
                return value
            end
        end
    end
    local other = Meeting.GetActivityInfo("OTHER")
    activityInfoMap[code] = other
    return other
end

function Meeting.GetPlayerScore()
    if ItemSocre and ItemSocre.ScanUnit then
        local score = ItemSocre:ScanUnit("player")
        if score and score > 0 then
            return score
        end
    end
    return 0
end

local Role = {
    Tank = bit.lshift(1, 1),
    Healer = bit.lshift(1, 2),
    Damage = bit.lshift(1, 3)
}
Meeting.Role = Role

local classRoleMap = {
    ["WARLOCK"] = Role.Damage,
    ["HUNTER"] = Role.Damage,
    ["PRIEST"] = bit.bor(Role.Healer, Role.Damage),
    ["PALADIN"] = bit.bor(Role.Tank, Role.Healer, Role.Damage),
    ["MAGE"] = Role.Damage,
    ["ROGUE"] = Role.Damage,
    ["DRUID"] = bit.bor(Role.Tank, Role.Healer, Role.Damage),
    ["SHAMAN"] = bit.bor(Role.Healer, Role.Damage),
    ["WARRIOR"] = bit.bor(Role.Tank, Role.Damage),
}

function Meeting.GetClassRole(class)
    return classRoleMap[class]
end

local fortyone = { "0",
    "1", "2", "3", "4", "5",
    "6", "7", "8", "9", "a",
    "b", "c", "d", "e", "f",
    "g", "h", "i", "j", "k",
    "l", "m", "n", "o", "p",
    "q", "r", "s", "t", "u",
    "v", "w", "x", "y", "z",
    "A", "B", "C", "D", "E" }
local fortyoneIndexes = {}
for index, value in ipairs(fortyone) do
    fortyoneIndexes[value] = index - 1
end

function Meeting.EncodeGroupClass()
    local raid = false
    local arr = {}
    for _, value in ipairs(classNameMap) do
        if value == Meeting.playerClass then
            arr[value] = 1
        else
            arr[value] = 0
        end
    end

	for i = 1, GetNumRaidMembers() do
		raid = true
		local _, class = UnitClass("raid" .. i)
		if class then
			arr[class] = (arr[class] or 0) + 1
		end
	end

	if not raid then
		for i = 1, GetNumPartyMembers() do
			local _, class = UnitClass("party" .. i)
			if class then
				arr[class] = (arr[class] or 0) + 1
			end
		end
	end

    local result = ""
    for _, v in ipairs(classNameMap) do
        local num = arr[v]
        result = result .. fortyone[num + 1]
    end
    return result
end

function Meeting.DecodeGroupClass(str)
    if not str then
        return
    end
    local arr = {}
    for i = 1, string.len(str) do
        local c = string.sub(str, i, i)
        local num = fortyoneIndexes[c]
        if num ~= nil and num > 0 then
            arr[i] = num
        end
    end
    return arr
end

local colorCache = {}

function Meeting.GetClassLocaleName(i)
    if colorCache[i] then
        return colorCache[i]
    end
    local color = Meeting.GetClassRGBColor(Meeting.NumberToClass(i))
    local str = string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, classChineseNameMap
        [i])
    colorCache[i] = str
    return str
end

-- 添加初始化 by 武藤纯子酱 2025.9.22
Meeting.searchInfo.codes = {}  -- 初始化多选状态