--[[
Cat - Potion 核心维护说明

这是一个 WoW 1.12（Interface 11200）独立插件，不调用 Cat、Cat2 或任何共享模块。
Core.lua 是唯一的数据与底层能力来源：物品清单、静态纹理、SavedVariables、背包缓存、
Buff/武器附魔缓存、物品使用，以及 /catpotion 与原生热键共用的一键补药入口。

重要约定：
1. addon.Categories 决定设置列表、小窗默认排列和补药优先级；windowOrder 只覆盖小窗显示顺序。
2. AddItem 的 buff 是玩家身上的效果名；只有同名 Buff 无法区分时才填写 buffIcon。
3. 缓存由 Window.lua 的游戏事件标记失效；有可见毒药条目时额外每秒刷新附魔次数。
4. 一键补药每次按键最多尝试一个已勾选物品；武器强化按配置的主/副手执行，毒药仍手动使用。
5. 旧客户端的 UseContainerItem 没有可靠成功返回值，“true”只表示使用请求已发出。
6. 不要仅因小型界面调整自动增加版本号；版本由维护者明确决定。
7. 每套配置独立保存 selected、macroExcluded、weaponSlots、windowOrder，以及窗口布局、缩放和警告阈值。
8. defaultProfileId 是默认配置的唯一身份依据；名称不是身份，默认配置禁止删除和改名。
9. /catpotion 与原生热键固定使用默认配置；带配置名命令才切换并使用指定配置。
10. 武器附魔缓存必须按槽位 16/17 分开；同一种强化可以同时存在于主手和副手。
]]

CatPotionAddon = CatPotionAddon or {}
local addon = CatPotionAddon

addon.Name = "Cat - Potion  药剂管理"
addon.Version = "1.1.6"
addon.Items = {}
addon.Categories = { "合剂", "独特药剂", "生存药剂", "混合药剂", "物理强化", "法系强化", "烹饪", "武器强化", "毒药", "功能药水", "恢复物品", "常用炸药", "工程道具" }

-- 两个分类共享主/副手选择、临时附魔缓存和涂抹流程。
-- 所有模块统一通过此入口判断，避免新增分类遗漏某条普通药剂路径。
function addon.IsWeaponCategory(category)
    return category == "武器强化" or category == "毒药"
end

BINDING_HEADER_CATPOTION = "Cat - Potion  药剂管理"

-- 静态纹理不依赖背包、物品缓存或 GetItemInfo，未持有物品也能稳定显示。
-- Turtle/旧客户端的物品信息缓存不可靠，不要改回运行时 GetItemInfo 取图标。
addon.ItemTextures = {
    titans = "Interface\\Icons\\INV_Potion_62",
    supremePower = "Interface\\Icons\\INV_Potion_41",
    distilledWisdom = "Interface\\Icons\\INV_Potion_120",
    zanzaSpeed = "Interface\\Icons\\INV_Potion_31",
    arthasGift = "Interface\\Icons\\INV_Potion_28",
    zanzaSpirit = "Interface\\Icons\\INV_Potion_30",
    fortitude = "Interface\\Icons\\INV_Potion_43",
    medivhWine = "Interface\\Icons\\INV_Drink_Waterskin_05",
    cocktail = "Interface\\Icons\\INV_Drink_12",
    trollBlood = "Interface\\Icons\\INV_Potion_80",
    stoneshield = "Interface\\Icons\\INV_Potion_66",
    greaterArcaneProtection = "Interface\\Icons\\INV_Potion_83",
    greaterShadowProtection = "Interface\\Icons\\INV_Potion_23",
    greaterNatureProtection = "Interface\\Icons\\INV_Potion_22",
    greaterFireProtection = "Interface\\Icons\\INV_Potion_24",
    greaterFrostProtection = "Interface\\Icons\\INV_Potion_20",
    mongoose = "Interface\\Icons\\INV_Potion_32",
    agility = "Interface\\Icons\\INV_Potion_93",
    encrusted = "Interface\\Icons\\INV_Misc_Dust_07",
    giants = "Interface\\Icons\\INV_Potion_61",
    soulEnergy = "Interface\\Icons\\INV_Misc_MonsterScales_11",
    firewater = "Interface\\Icons\\INV_Potion_92",
    herbalBrew = "Interface\\Icons\\INV_Drink_33",
    soulStrike = "Interface\\Icons\\INV_Misc_MonsterScales_07",
    hyenaStimulant = "Interface\\Icons\\INV_Stone_15",
    bruteForce = "Interface\\Icons\\INV_Potion_40",
    rapidGrowth = "Interface\\Icons\\inv_elixir_of_rapid_growth_1",
    demon = "Interface\\Icons\\INV_Potion_27",
    strengthScroll4 = "Interface\\Icons\\inv_scroll_13",
    agilityScroll4 = "Interface\\Icons\\inv_scroll_11",
    dreamEssence = "Interface\\Icons\\INV_Potion_113",
    arcanePower = "Interface\\Icons\\INV_Potion_25",
    arcaneElixir = "Interface\\Icons\\INV_Potion_30",
    dreamshire = "Interface\\Icons\\INV_Potion_114",
    cortexPotion = "Interface\\Icons\\INV_Potion_32",
    intellect = "Interface\\Icons\\INV_Potion_10",
    soulTrickery = "Interface\\Icons\\INV_Misc_MonsterScales_13",
    firepower = "Interface\\Icons\\INV_Potion_60",
    shadowPower = "Interface\\Icons\\INV_Potion_46",
    frostPower = "Interface\\Icons\\INV_Potion_13",
    greaterArcanePower = "Interface\\Icons\\INV_Potion_81",
    naturePower = "Interface\\Icons\\INV_Potion_22",
    felMana = "Interface\\Icons\\INV_Potion_45",
    medivhBlue = "Interface\\Icons\\INV_Drink_Waterskin_01",
    intellectScroll4 = "Interface\\Icons\\INV_Scroll_01",
    dreamMongoose = "Interface\\Icons\\INV_Blue_Gold_Elixir_2",
    arcaneGiants = "Interface\\Icons\\INV_Yellow_Purple_Elixir_2",
    dreamFirewater = "Interface\\Icons\\INV_Green_Pink_Elixir_1",
    desertDumplings = "Interface\\Icons\\INV_Misc_Food_64",
    nutritious = "Interface\\Icons\\inv_mushroom_14",
    bigFish = "Interface\\Icons\\INV_Misc_Food_47",
    grilledSquid = "Interface\\Icons\\INV_Misc_Fish_13",
    sweetBerries = "Interface\\Icons\\INV_Misc_Food_40",
    skewers = "Interface\\Icons\\INV_Misc_Food_68",
    terrabeMood = "Interface\\Icons\\INV_Misc_Food_73",
    terrabeFun = "Interface\\Icons\\INV_Drink_21",
    terrabeSurprise = "Interface\\Icons\\INV_Misc_Food_92",
    nightfinSoup = "Interface\\Icons\\INV_Drink_17",
    smokedPerch = "Interface\\Icons\\INV_Misc_Fish_03",
    herbSalad = "Interface\\Icons\\INV_Misc_Food_Salad",
    crispy = "Interface\\Icons\\INV_Mushroom_15",
    chimera = "Interface\\Icons\\INV_Misc_Food_65",
    seafood = "Interface\\Icons\\INV_Misc_Food_63",
    cookedFish = "Interface\\Icons\\INV_Misc_MonsterHead_03",
    dragonbreath = "Interface\\Icons\\INV_Drink_17",
    blessedSunfruit = "Interface\\Icons\\INV_Misc_Food_41",
    elementalStone = "Interface\\Icons\\INV_Stone_02",
    sacredStone = "Interface\\Icons\\INV_Stone_SharpeningStone_02",
    sacredOil = "Interface\\Icons\\INV_Potion_138",
    wizardOil = "Interface\\Icons\\INV_Potion_105",
    manaOil = "Interface\\Icons\\INV_Potion_100",
    instantPoison6 = "Interface\\Icons\\Ability_Poisons",
    dissolvePoison2 = "Interface\\Icons\\Spell_Nature_SlowPoison",
    deadlyPoison5 = "Interface\\Icons\\Ability_Rogue_DualWeild",
    deadlyPoison4 = "Interface\\Icons\\Ability_Rogue_DualWeild",
    corrosivePoison2 = "Interface\\Icons\\inv_corrosive_01",
    corrosivePoison = "Interface\\Icons\\inv_corrosive_01",
    mindNumbingPoison3 = "Interface\\Icons\\Spell_Nature_NullifyDisease",
    woundPoison = "Interface\\Icons\\Ability_PoisonSting",
    cripplingPoison = "Interface\\Icons\\INV_Potion_19"
}

-- 设置列表中的功能说明来自原自动药剂界面，仅复制文字数据，不依赖 Cat。
-- 说明为可选项；未配置说明的物品仅显示名称，不追加括号内容。
addon.ItemDetails = {
    titans = "1200生命",
    supremePower = "150法伤",
    distilledWisdom = "2000法力",
    zanzaSpeed = "20移速",
    arthasGift = "疾病",
    zanzaSpirit = "50耐力",
    fortitude = "120生命",
    medivhWine = "25耐力",
    cocktail = "25耐",
    trollBlood = "20回血",
    stoneshield = "450甲",
    mongoose = "25敏+2暴击",
    agility = "15敏",
    encrusted = "25敏捷",
    giants = "25力量",
    soulEnergy = "30力量",
    firewater = "35AP",
    herbalBrew = "35AP",
    soulStrike = "40AP",
    hyenaStimulant = "25力量",
    bruteForce = "18力+18耐",
    rapidGrowth = "30力量/2分钟",
    demon = "265恶魔AP",
    strengthScroll4 = "17力量",
    agilityScroll4 = "17敏捷",
    dreamEssence = "15法伤/治疗+2暴击",
    arcanePower = "35法伤",
    arcaneElixir = "20法伤",
    dreamshire = "35法伤",
    cortexPotion = "25智力",
    intellect = "25智力",
    soulTrickery = "30智力",
    firepower = "40火伤害",
    shadowPower = "40暗伤害",
    frostPower = "40冰伤害",
    greaterArcanePower = "40奥伤害",
    naturePower = "55自然伤害",
    felMana = "12回蓝",
    medivhBlue = "15智力",
    intellectScroll4 = "16智力",
    dreamMongoose = "25敏+15法伤+2暴",
    arcaneGiants = "25力+35法伤",
    dreamFirewater = "35AP+35法伤",
    desertDumplings = "20力量",
    nutritious = "20力量",
    bigFish = "20力量",
    grilledSquid = "10敏捷",
    sweetBerries = "10敏捷",
    skewers = "20敏捷",
    terrabeMood = "2急速",
    terrabeFun = "22法伤",
    terrabeSurprise = "45远程AP",
    nightfinSoup = "8回蓝",
    smokedPerch = "30精神",
    herbSalad = "24治疗",
    crispy = "25耐力",
    chimera = "30耐2闪",
    seafood = "150甲",
    cookedFish = "15法穿",
    dragonbreath = "喷火",
    blessedSunfruit = "10力量",
    elementalStone = "2暴击",
    sacredStone = "100亡灵AP",
    sacredOil = "60亡灵法伤",
    wizardOil = "36法伤+1暴",
    manaOil = "25治疗+12回蓝"
}

-- 桌面新版 Cat 自动药剂及 CatPotion 后续补充的提示关系。
-- 这里只描述“同时勾选时可能冲突”，
-- 不参与物品使用、补药顺序或选项互斥；设置界面只据此显示红色感叹号。
addon.ItemConflictPairs = {
    { "titans", "supremePower" },
    { "titans", "distilledWisdom" },
    { "supremePower", "distilledWisdom" },
    { "zanzaSpeed", "zanzaSpirit" },
    { "zanzaSpirit", "cocktail" },
    { "mongoose", "agility" },
    { "agilityScroll4", "mongoose" },
    { "agilityScroll4", "agility" },
    { "dreamMongoose", "mongoose" },
    { "dreamMongoose", "dreamEssence" },
    { "cocktail", "hyenaStimulant" },
    { "cocktail", "encrusted" },
    { "cocktail", "cortexPotion" },
    { "giants", "soulEnergy" },
    { "giants", "bruteForce" },
    { "soulEnergy", "bruteForce" },
    { "bruteForce", "rapidGrowth" },
    { "strengthScroll4", "bruteForce" },
    { "strengthScroll4", "giants" },
    { "strengthScroll4", "rapidGrowth" },
    { "arcaneGiants", "giants" },
    { "arcaneGiants", "greaterArcanePower" },
    { "firewater", "herbalBrew" },
    { "firewater", "soulStrike" },
    { "herbalBrew", "soulStrike" },
    { "hyenaStimulant", "encrusted" },
    { "hyenaStimulant", "cortexPotion" },
    { "encrusted", "cortexPotion" },
    { "cortexPotion", "soulTrickery" },
    { "intellect", "soulTrickery" }
}

-- 展开为双向索引，避免界面层分别维护冲突的两端。
addon.ItemConflicts = {}
local conflictIndex, conflictPair
for conflictIndex, conflictPair in ipairs(addon.ItemConflictPairs) do
    local firstKey = conflictPair[1]
    local secondKey = conflictPair[2]
    addon.ItemConflicts[firstKey] = addon.ItemConflicts[firstKey] or {}
    addon.ItemConflicts[secondKey] = addon.ItemConflicts[secondKey] or {}
    addon.ItemConflicts[firstKey][secondKey] = 1
    addon.ItemConflicts[secondKey][firstKey] = 1
end

local defaults = {
    version = 2,
    windowVisible = 1,
    locked = 0,
    minimized = 0,
    showMessages = 1,
    layout = "horizontal",
    layoutLimit = 2,
    scale = 0.8,
    warningMinutes = 4,
    windowPoint = "CENTER",
    windowRelativePoint = "CENTER",
    windowX = 0,
    windowY = 0,
    minimapAngle = 2.05
}

-- key 同时对应 ItemTextures、ItemDetails 和各配置中的 selected。
-- item 是背包中的完整物品名，label 是界面短名称，buffIcon 仅用于解决同名 Buff 冲突。
-- selfTarget 为 true 时，物品进入选择目标状态后会立即锁定对玩家自己施放。
local function AddItem(key, category, buff, item, label, buffIcon, selfTarget)
    table.insert(addon.Items, {
        key = key,
        category = category,
        buff = buff,
        item = item,
        label = label,
        buffIcon = buffIcon,
        selfTarget = selfTarget
    })
end

-- 合剂
AddItem("titans", "合剂", "泰坦合剂", "泰坦合剂", "泰坦合剂")
AddItem("supremePower", "合剂", "至高能量", "超级能量合剂", "超级能量合剂")
AddItem("distilledWisdom", "合剂", "萃取智慧", "精炼智慧合剂", "精炼智慧合剂")

-- 独特药剂
AddItem("zanzaSpeed", "独特药剂", "赞扎之速", "赞扎之速", "赞扎之速")
AddItem("arthasGift", "独特药剂", "阿尔萨斯的礼物", "阿尔萨斯的礼物", "阿尔萨斯礼物")

-- 生存药剂
AddItem("zanzaSpirit", "生存药剂", "赞扎之魂", "赞扎之魂", "赞扎之魂")
AddItem("fortitude", "生存药剂", "生命 II", "坚韧药剂", "坚韧药剂")
AddItem("medivhWine", "生存药剂", "麦迪文的葡萄酒", "麦迪文的葡萄酒", "麦迪文葡萄酒")
AddItem("cocktail", "生存药剂", "野猪之魂", "肺片鸡尾酒", "肺片鸡尾酒")
AddItem("trollBlood", "生存药剂", "回复", "特效巨魔之血药水", "特效巨魔之血药水")
AddItem("stoneshield", "生存药剂", "强效护甲", "超强防御药剂", "超强防御药剂")
-- 防护药水的 Buff 名称不同于物品名；映射与本地 XRS 中文防护药水监控一致。
AddItem("greaterArcaneProtection", "生存药剂", "奥术防护", "强效奥术防护药水", "强效奥术防护")
AddItem("greaterShadowProtection", "生存药剂", "防护暗影", "强效暗影防护药水", "强效暗影防护")
AddItem("greaterNatureProtection", "生存药剂", "防护自然", "强效自然防护药水", "强效自然防护")
AddItem("greaterFireProtection", "生存药剂", "防护火焰", "强效火焰防护药水", "强效火焰防护")
AddItem("greaterFrostProtection", "生存药剂", "防护冰霜", "强效冰霜防护药水", "强效冰霜防护")

-- 物理强化
AddItem("mongoose", "物理强化", "猫鼬药剂", "猫鼬药剂", "猫鼬药剂")
AddItem("agility", "物理强化", "敏捷", "敏捷药剂", "敏捷药剂", "Interface\\Icons\\INV_Potion_93")
AddItem("encrusted", "物理强化", "厚甲蝎之击", "厚甲蝎药粉", "厚甲蝎药粉")
AddItem("giants", "物理强化", "巨人药剂", "巨人药剂", "巨人药剂")
AddItem("soulEnergy", "物理强化", "魂能之力", "魂能之力", "魂能之力")
AddItem("hyenaStimulant", "物理强化", "远古之怒", "土狼兴奋剂", "土狼兴奋剂")
AddItem("herbalBrew", "物理强化", "黑根酒", "黑根酒", "黑根酒")
AddItem("soulStrike", "物理强化", "魂能之击", "魂能之击", "魂能之击")
AddItem("firewater", "物理强化", "冬泉火酒", "冬泉火酒", "冬泉火酒")
AddItem("bruteForce", "物理强化", "蛮力药剂", "蛮力药剂", "蛮力药剂")
AddItem("rapidGrowth", "物理强化", "急速生长药剂", "急速生长药剂", "急速生长药剂")
AddItem("demon", "物理强化", "屠魔药剂", "屠魔药剂", "屠魔药剂")
AddItem("strengthScroll4", "物理强化", "力量", "力量卷轴 IV", "力量卷轴 IV", nil, true)
AddItem("agilityScroll4", "物理强化", "敏捷", "敏捷卷轴 IV", "敏捷卷轴 IV", "Interface\\Icons\\Spell_Holy_BlessingOfAgility", true)

-- 法系强化
AddItem("dreamEssence", "法系强化", "梦境精华药剂", "梦境精华药剂", "梦境精华药剂")
AddItem("arcanePower", "法系强化", "强效奥法药剂", "强效奥法药剂", "强效奥法药剂")
AddItem("arcaneElixir", "法系强化", "奥法药剂", "奥法药剂", "奥法药剂")
AddItem("dreamshire", "法系强化", "梦通", "梦境酊剂", "梦境酊剂")
AddItem("cortexPotion", "法系强化", "坚定信念", "脑皮层混合饮料", "脑皮层饮料")
AddItem("intellect", "法系强化", "强效智力", "强效聪颖药剂", "强效聪颖药剂")
AddItem("soulTrickery", "法系强化", "魂能之诈", "魂能之诈", "魂能之诈")
AddItem("firepower", "法系强化", "强效火力", "强效火力药剂", "强效火力药剂")
AddItem("shadowPower", "法系强化", "暗影强化", "暗影之力药剂", "暗影之力药剂")
AddItem("frostPower", "法系强化", "强效冰霜之力", "强效冰霜之力药剂", "强效冰霜之力")
AddItem("greaterArcanePower", "法系强化", "强效奥术之力", "强效奥术之力药剂", "强效奥术之力")
AddItem("naturePower", "法系强化", "强效自然力量药剂", "强效自然之力药水", "强效自然之力")
AddItem("felMana", "法系强化", "法力回复", "魔血药水", "魔血药水", "Interface\\Icons\\INV_Potion_45")
AddItem("medivhBlue", "法系强化", "麦迪文的蓝标葡萄酒", "麦迪文的蓝标葡萄酒", "麦迪文蓝标酒")
AddItem("intellectScroll4", "法系强化", "智力", "智力卷轴 IV", "智力卷轴 IV", nil, true)

-- 混合药剂
AddItem("dreamMongoose", "混合药剂", "翡翠猫鼬药剂", "翡翠猫鼬药剂", "翡翠猫鼬药剂")
AddItem("arcaneGiants", "混合药剂", "奥法巨人药剂", "奥法巨人药剂", "奥法巨人药剂")
AddItem("dreamFirewater", "混合药剂", "梦境火酒药剂", "梦境火酒药剂", "梦境火酒药剂")

-- 烹饪
AddItem("desertDumplings", "烹饪", "进食充分", "沙漠肉丸子", "沙漠肉丸子")
AddItem("nutritious", "烹饪", "进食充分", "营养的魔法蘑菇", "营养魔法蘑菇")
AddItem("bigFish", "烹饪", "进食充分", "大鱼片", "大鱼片")
AddItem("grilledSquid", "烹饪", "敏捷提高", "烤鱿鱼", "烤鱿鱼")
AddItem("sweetBerries", "烹饪", "敏捷提高", "酸甜的山地浆果", "酸甜山地浆果")
AddItem("skewers", "烹饪", "进食充分", "鱿鱼鳗串", "鱿鱼鳗串")
AddItem("terrabeMood", "烹饪", "进食充分", "达农佐的泰拉比姆情调", "泰拉比姆情调")
AddItem("terrabeFun", "烹饪", "进食充分", "达农佐的泰拉比姆趣味", "泰拉比姆趣味")
AddItem("terrabeSurprise", "烹饪", "进食充分", "达农佐的泰拉比姆惊喜", "泰拉比姆惊喜")
AddItem("nightfinSoup", "烹饪", "法力回复", "夜鳞鱼汤", "夜鳞鱼汤", "Interface\\Icons\\Spell_Nature_ManaRegenTotem")
AddItem("smokedPerch", "烹饪", "进食充分", "烟熏鲈鱼", "烟熏鲈鱼")
AddItem("herbSalad", "烹饪", "提高治疗", "强能草药沙拉", "强能草药沙拉")
AddItem("crispy", "烹饪", "耐力提高", "香脆的魔法蘑菇", "香脆魔法蘑菇")
AddItem("chimera", "烹饪", "强化耐力", "迪尔格的超美味奇美拉肉片", "奇美拉肉片")
AddItem("seafood", "烹饪", "进食充分", "深海炖菜", "深海炖菜")
AddItem("cookedFish", "烹饪", "进食充分", "煮熟的光滑大鱼", "煮熟光滑大鱼")
AddItem("dragonbreath", "烹饪", "龙息红椒", "龙息红椒", "龙息红椒")
AddItem("blessedSunfruit", "烹饪", "神圣太阳果", "神圣太阳果", "神圣太阳果", "Interface\\Icons\\Spell_Holy_Devotion")

-- 武器强化（设置中分别选择主手/副手，小窗点击后自动落到对应装备槽位）
AddItem("elementalStone", "武器强化", nil, "元素磨刀石", "元素磨刀石")
AddItem("sacredStone", "武器强化", nil, "神圣磨刀石", "神圣磨刀石")
AddItem("sacredOil", "武器强化", nil, "神圣巫师之油", "神圣巫师之油")
AddItem("wizardOil", "武器强化", nil, "卓越巫师之油", "卓越巫师之油")
AddItem("manaOil", "武器强化", nil, "卓越法力之油", "卓越法力之油")

-- 毒药与武器强化共用 weaponSlots；毒药不进入普通 Buff 和补药宏路径。
AddItem("instantPoison6", "毒药", nil, "速效毒药 VI", "速效毒药 VI")
AddItem("dissolvePoison2", "毒药", nil, "溶解毒药 II", "溶解毒药 II")
AddItem("deadlyPoison5", "毒药", nil, "致命毒药 V", "致命毒药 V")
AddItem("deadlyPoison4", "毒药", nil, "致命毒药 IV", "致命毒药 IV")
AddItem("corrosivePoison2", "毒药", nil, "腐蚀毒药 II", "腐蚀毒药 II")
AddItem("corrosivePoison", "毒药", nil, "腐蚀毒药", "腐蚀毒药")
AddItem("mindNumbingPoison3", "毒药", nil, "麻痹毒药 III", "麻痹毒药 III")
AddItem("woundPoison", "毒药", nil, "致伤毒药", "致伤毒药")
AddItem("cripplingPoison", "毒药", nil, "致残毒药", "致残毒药")

-- 短效药水、恢复品与工程道具：数据来自本客户端 WDB/DBC（2026-10-06）。
-- 短效 Buff 默认仅显示，右键可启用宏；无 Buff 的恢复品、炸药和工程道具仅手动使用。
-- 按用户要求只收录背包直接使用的工程道具，不收录需装备的饰品、头盔和靴子。
local usableItems = {
    { key = "swiftness", category = "功能药水", item = "迅捷药水", label = "迅捷药水", buff = "速度", detail = "50%移速/15秒", texture = "Interface\\Icons\\INV_Potion_95", defaultMacroExcluded = true, macroWarningSeconds = 0, itemID = 2459, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "immolationOil", category = "功能药水", item = "献祭之油", label = "献祭之油", buff = "火焰之盾", detail = "周围火焰伤害/15秒", texture = "Interface\\Icons\\INV_Potion_11", defaultMacroExcluded = true, macroWarningSeconds = 0, itemID = 8956, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    { key = "limitedInvulnerability", category = "功能药水", item = "有限无敌药水", label = "有限无敌", buff = "无敌", detail = "短暂物理免疫", texture = "Interface\\Icons\\INV_Potion_121", defaultMacroExcluded = true, macroWarningSeconds = 0, itemID = 3387, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "quickness", category = "功能药水", item = "加速药水", label = "加速药水", buff = "速度药水", detail = "5%急速/30秒", texture = "Interface\\Icons\\INV_Potion_08", defaultMacroExcluded = true, macroWarningSeconds = 0, itemID = 61181, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "jujuFlurry", category = "功能药水", item = "魂能之速", label = "魂能之速", buff = "魂能之速", detail = "3%攻击/施法急速", texture = "Interface\\Icons\\INV_Misc_MonsterScales_17", defaultMacroExcluded = true, macroWarningSeconds = 0, itemID = 12450, cooldown = 60.0, cooldownCategory = 55, categoryCooldown = 10.0, gcdCategory = 0, gcd = 0.0, selfTarget = true },
    { key = "freeAction", category = "功能药水", item = "自由行动药剂", label = "自由行动", buff = "自由行动", detail = "免疫昏迷/移动限制", texture = "Interface\\Icons\\INV_Potion_04", defaultMacroExcluded = true, macroWarningSeconds = 0, itemID = 5634, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "livingAction", category = "功能药水", item = "活力行动药水", label = "活力行动", buff = "活力自由行动", detail = "解除并免疫控制", texture = "Interface\\Icons\\INV_Potion_07", defaultMacroExcluded = true, macroWarningSeconds = 0, itemID = 20008, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "mightyRage", category = "功能药水", item = "强效怒气药水", label = "强效怒气（强怒）", buff = "强效怒气", detail = "怒气+60力量/20秒", texture = "Interface\\Icons\\inv_potion_125", defaultMacroExcluded = true, macroWarningSeconds = 0, itemID = 13442, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "greatRage", category = "功能药水", item = "暴怒药水", label = "暴怒药水", detail = "补充怒气", texture = "Interface\\Icons\\INV_Potion_21", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 5633, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "ragePotion", category = "功能药水", item = "怒气药水", label = "怒气药水", detail = "补充怒气", texture = "Interface\\Icons\\INV_Potion_24", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 5631, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "greaterStoneshield", category = "功能药水", item = "强效石盾药水", label = "强效石盾", buff = "强效石盾", detail = "护甲提高/2分钟", texture = "Interface\\Icons\\INV_Potion_69", defaultMacroExcluded = true, macroWarningSeconds = 0, itemID = 13455, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "lesserStoneshield", category = "功能药水", item = "次级石盾药水", label = "次级石盾", buff = "石盾术", detail = "护甲提高", texture = "Interface\\Icons\\INV_Potion_67", defaultMacroExcluded = true, macroWarningSeconds = 0, itemID = 4623, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "restorative", category = "功能药水", item = "滋补药剂", label = "滋补药剂", buff = "恢复", detail = "定期驱散负面效果", texture = "Interface\\Icons\\INV_Potion_118", defaultMacroExcluded = true, macroWarningSeconds = 0, itemID = 9030, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 4, gcd = 0.0 },
    { key = "purification", category = "功能药水", item = "净化药水", label = "净化药水", detail = "解除诅咒/疾病/中毒", texture = "Interface\\Icons\\INV_Potion_116", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 13462, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "poisonResistance", category = "功能药水", item = "抗毒药水", label = "抗毒药水", detail = "解除中毒", texture = "Interface\\Icons\\INV_Potion_12", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 3386, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    { key = "invisibility", category = "功能药水", item = "隐形药水", label = "隐形药水", buff = "隐形术", detail = "隐形/18秒", texture = "Interface\\Icons\\INV_Potion_112", defaultMacroExcluded = true, macroWarningSeconds = 0, itemID = 9172, cooldown = 600.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "lesserInvisibility", category = "功能药水", item = "次级隐形药水", label = "次级隐形", buff = "次级隐形术", detail = "隐形/15秒", texture = "Interface\\Icons\\INV_Potion_18", defaultMacroExcluded = true, macroWarningSeconds = 0, itemID = 3823, cooldown = 600.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "magicResistance", category = "功能药水", item = "抗魔药水", label = "抗魔药水", buff = "抗性", detail = "提高全系魔法抗性", texture = "Interface\\Icons\\INV_Potion_16", defaultMacroExcluded = true, macroWarningSeconds = 0, itemID = 9036, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "swimSpeed", category = "功能药水", item = "速游药水", label = "速游药水", buff = "游泳速度", detail = "提高游泳速度", texture = "Interface\\Icons\\INV_Potion_13", defaultMacroExcluded = true, macroWarningSeconds = 0, itemID = 6372, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "greaterWaterBreathing", category = "功能药水", item = "强力水下呼吸药剂", label = "强力水下呼吸", buff = "强效水下呼吸", detail = "水下呼吸/1小时", texture = "Interface\\Icons\\INV_Potion_05", defaultMacroExcluded = true, macroWarningSeconds = 0, itemID = 18294, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    { key = "petrification", category = "功能药水", item = "化石合剂", label = "化石合剂", buff = "石化", detail = "无法行动/免疫伤害", texture = "Interface\\Icons\\INV_Potion_26", defaultMacroExcluded = true, macroWarningSeconds = 0, itemID = 13506, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 133, gcd = 1.5 },
    { key = "conjuredManaOrange", category = "恢复物品", item = "魔法橘子", label = "魔法橘子", detail = "坐下进食恢复生命/法力", texture = "Interface\\Icons\\INV_Misc_Food_41", defaultMacroExcluded = true, manualOnly = true, outOfCombatOnly = true, itemID = 83004, cooldown = 0, cooldownCategory = 11, categoryCooldown = 1, gcdCategory = 0, gcd = 0 },
    { key = "hourglassSand", category = "恢复物品", item = "沙漏", label = "沙漏", detail = "解除龙血之痛：青铜（含宠物）", texture = "Interface\\Icons\\INV_Misc_Dust_14", defaultMacroExcluded = true, manualOnly = true, itemID = 19183, cooldown = 0, cooldownCategory = 0, categoryCooldown = 0, gcdCategory = 0, gcd = 0 },
    { key = "majorHealing", category = "恢复物品", item = "特效治疗药水", label = "特效治疗（大红）", detail = "恢复生命值", texture = "Interface\\Icons\\INV_Potion_54", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 13446, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "majorMana", category = "恢复物品", item = "特效法力药水", label = "特效法力（大蓝）", detail = "恢复法力值", texture = "Interface\\Icons\\INV_Potion_76", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 13444, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "majorRejuvenation", category = "恢复物品", item = "特效活力药水", label = "特效活力", detail = "恢复生命/法力", texture = "Interface\\Icons\\INV_Potion_47", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 18253, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "superiorHealing", category = "恢复物品", item = "优质治疗药水", label = "优质治疗", detail = "恢复生命值", texture = "Interface\\Icons\\INV_Potion_53", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 3928, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "superiorMana", category = "恢复物品", item = "优质法力药水", label = "优质法力", detail = "恢复法力值", texture = "Interface\\Icons\\INV_Potion_74", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 13443, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "greaterMana", category = "恢复物品", item = "强效法力药水", label = "强效法力", detail = "恢复法力值", texture = "Interface\\Icons\\INV_Potion_73", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 6149, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "greaterDreamlessSleep", category = "恢复物品", item = "强效昏睡药水", label = "强效昏睡", detail = "睡眠中恢复生命/法力", texture = "Interface\\Icons\\INV_potion_109", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 20002, cooldown = 0.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 133, gcd = 1.5 },
    { key = "dreamlessSleep", category = "恢复物品", item = "昏睡药水", label = "昏睡药水", detail = "睡眠中恢复生命/法力", texture = "Interface\\Icons\\inv_potion_110", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 12190, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 1.5 },
    { key = "nordanaarTea", category = "恢复物品", item = "诺达纳尔草药茶", label = "诺达纳尔草药茶", detail = "恢复生命/法力", texture = "Interface\\Icons\\inv_drink_waterskin_03", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 61675, cooldown = 60.0, cooldownCategory = 1172, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "thistleTea", category = "恢复物品", item = "菊花茶", label = "菊花茶", detail = "恢复能量（盗贼）", texture = "Interface\\Icons\\INV_Drink_Milk_05", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 7676, cooldown = 300.0, cooldownCategory = 1153, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "demonicRune", category = "恢复物品", item = "恶魔符文", label = "恶魔符文", detail = "消耗生命恢复法力", texture = "Interface\\Icons\\INV_Misc_Rune_04", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 12662, cooldown = 0.0, cooldownCategory = 1172, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "darkRune", category = "恢复物品", item = "黑暗符文", label = "黑暗符文", detail = "消耗生命恢复法力", texture = "Interface\\Icons\\Spell_Shadow_SealOfKings", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 20520, cooldown = 0.0, cooldownCategory = 1172, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "majorHealthstone", category = "恢复物品", item = "特效治疗石", label = "特效治疗石", detail = "恢复生命值", texture = "Interface\\Icons\\INV_Stone_04", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 9421, cooldown = 0.0, cooldownCategory = 1153, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0, alternateIDs = { 19012, 19013 } },
    { key = "powerfulAntivenom", category = "恢复物品", item = "极效抗毒药剂", label = "极效抗毒药剂", detail = "解除中毒（可对友方）", texture = "Interface\\Icons\\antitoxin_03", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 19440, cooldown = 60.0, cooldownCategory = 150, categoryCooldown = 0.0, gcdCategory = 0, gcd = 0.0 },
    { key = "sapperCharge", category = "常用炸药", item = "地精工兵炸药", label = "地精工兵炸药", detail = "范围伤害/自身受伤", texture = "Interface\\Icons\\Spell_Fire_SelfDestruct", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 10646, cooldown = 300.0, cooldownCategory = 24, categoryCooldown = 60.0, gcdCategory = 0, gcd = 0.0 },
    { key = "thoriumGrenade", category = "常用炸药", item = "瑟银手榴弹", label = "瑟银手榴弹", detail = "范围伤害/昏迷", texture = "Interface\\Icons\\INV_Misc_Bomb_08", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 15993, cooldown = 0.0, cooldownCategory = 24, categoryCooldown = 60.0, gcdCategory = 0, gcd = 0.0 },
    { key = "ironGrenade", category = "常用炸药", item = "铁皮手雷", label = "铁皮手雷", detail = "范围伤害/昏迷", texture = "Interface\\Icons\\INV_Misc_Bomb_08", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 4390, cooldown = 0.0, cooldownCategory = 24, categoryCooldown = 60.0, gcdCategory = 0, gcd = 0.0 },
    { key = "denseDynamite", category = "常用炸药", item = "致密炸弹", label = "致密炸弹", detail = "范围火焰伤害", texture = "Interface\\Icons\\INV_Misc_Bomb_06", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 18641, cooldown = 0.0, cooldownCategory = 24, categoryCooldown = 60.0, gcdCategory = 0, gcd = 0.0 },
    { key = "solidDynamite", category = "常用炸药", item = "实心炸弹", label = "实心炸弹", detail = "范围火焰伤害", texture = "Interface\\Icons\\INV_Misc_Bomb_06", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 10507, cooldown = 0.0, cooldownCategory = 24, categoryCooldown = 60.0, gcdCategory = 0, gcd = 0.0 },
    { key = "mithrilFragBomb", category = "常用炸药", item = "秘银破片炸弹", label = "秘银破片炸弹", detail = "范围伤害/昏迷", texture = "Interface\\Icons\\INV_Misc_Bomb_02", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 10514, cooldown = 0.0, cooldownCategory = 24, categoryCooldown = 60.0, gcdCategory = 0, gcd = 0.0 },
    { key = "darkIronBomb", category = "常用炸药", item = "黑铁炸弹", label = "黑铁炸弹", detail = "范围伤害/昏迷", texture = "Interface\\Icons\\INV_Misc_Bomb_05", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 16005, cooldown = 0.0, cooldownCategory = 24, categoryCooldown = 60.0, gcdCategory = 0, gcd = 0.0 },
    { key = "bigOne", category = "常用炸药", item = "大炸弹", label = "大炸弹", detail = "大范围伤害/昏迷", texture = "Interface\\Icons\\INV_Misc_Bomb_04", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 10586, cooldown = 0.0, cooldownCategory = 24, categoryCooldown = 60.0, gcdCategory = 0, gcd = 0.0 },
    { key = "arcaneBomb", category = "常用炸药", item = "奥术炸弹", label = "奥术炸弹", detail = "吸收法力/伤害/沉默", texture = "Interface\\Icons\\Spell_Shadow_MindBomb", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 16040, cooldown = 0.0, cooldownCategory = 24, categoryCooldown = 60.0, gcdCategory = 0, gcd = 0.0 },
    { key = "heavyIronBomb", category = "常用炸药", item = "重磅铁制炸弹", label = "重磅铁制炸弹", detail = "范围伤害/昏迷", texture = "Interface\\Icons\\INV_Misc_Bomb_01", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 4394, cooldown = 0.0, cooldownCategory = 24, categoryCooldown = 60.0, gcdCategory = 0, gcd = 0.0 },
    { key = "ezThrowBomb", category = "常用炸药", item = "简易投掷炸弹 II", label = "简易投掷炸弹 II", detail = "无需工程学", texture = "Interface\\Icons\\INV_Misc_Bomb_03", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 18588, cooldown = 0.0, cooldownCategory = 24, categoryCooldown = 60.0, gcdCategory = 0, gcd = 0.0 },
    { key = "stratholmeWater", category = "常用炸药", item = "斯坦索姆圣水", label = "斯坦索姆圣水", detail = "对亡灵造成范围伤害", texture = "Interface\\Icons\\INV_Potion_75", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 13180, cooldown = 0.0, cooldownCategory = 24, categoryCooldown = 60.0, gcdCategory = 0, gcd = 0.0 },
    { key = "explosiveSheep", category = "工程道具", item = "自爆绵羊", label = "自爆绵羊", detail = "召唤爆炸绵羊", texture = "Interface\\Icons\\Spell_Nature_Polymorph", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 4384, cooldown = 0.0, cooldownCategory = 24, categoryCooldown = 60.0, gcdCategory = 0, gcd = 0.0 },
    { key = "goblinLandMine", category = "工程道具", item = "地精暗雷", label = "地精暗雷", detail = "放置爆炸地雷", texture = "Interface\\Icons\\INV_Shield_08", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 4395, cooldown = 0.0, cooldownCategory = 24, categoryCooldown = 60.0, gcdCategory = 0, gcd = 0.0 },
    { key = "targetDummy", category = "工程道具", item = "活动假人", label = "活动假人", detail = "吸引附近怪物", texture = "Interface\\Icons\\INV_Crate_06", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 4366, cooldown = 0.0, cooldownCategory = 1153, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "advancedDummy", category = "工程道具", item = "高级假人", label = "高级假人", detail = "吸引附近怪物", texture = "Interface\\Icons\\INV_Crate_05", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 4392, cooldown = 0.0, cooldownCategory = 1153, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "masterDummy", category = "工程道具", item = "高级活动假人", label = "高级活动假人", detail = "吸引附近怪物", texture = "Interface\\Icons\\INV_Crate_02", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 16023, cooldown = 0.0, cooldownCategory = 1153, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "discombobulator", category = "工程道具", item = "退化射线", label = "退化射线", detail = "削弱/减速敌人", texture = "Interface\\Icons\\INV_Misc_Spyglass_02", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 4388, cooldown = 0.0, cooldownCategory = 24, categoryCooldown = 60.0, gcdCategory = 0, gcd = 0.0 },
    { key = "alarmBot", category = "工程道具", item = "报警机器人", label = "报警机器人", detail = "侦测潜行/隐形", texture = "Interface\\Icons\\INV_Misc_EngGizmos_13", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 18645, cooldown = 600.0, cooldownCategory = 1153, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    { key = "repairBot", category = "工程道具", item = "战地修理机器人74A型", label = "修理机器人74A", detail = "展开修理机器人", texture = "Interface\\Icons\\INV_Egg_05", defaultMacroExcluded = true, manualOnly = true, macroWarningSeconds = 0, itemID = 18232, cooldown = 0.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 0, gcd = 0.0 },
    -- 主城虫洞：名称、图标与冷却来自本客户端 WDB/DBC；阵营限制包含高等精灵和地精。
    { key = "stormwindWormhole", category = "工程道具", item = "便携式虫洞制造机：暴风城", label = "虫洞：暴风城", detail = "联盟/工程学100/传送", texture = "Interface\\Icons\\INV_Gizmo_06", faction = "Alliance", defaultMacroExcluded = true, manualOnly = true, itemID = 51312, cooldown = 3600, cooldownCategory = 0, categoryCooldown = 0, gcdCategory = 133, gcd = 1.5 },
    { key = "orgrimmarWormhole", category = "工程道具", item = "便携式虫洞制造机：奥格瑞玛", label = "虫洞：奥格瑞玛", detail = "部落/工程学100/传送", texture = "Interface\\Icons\\INV_Gizmo_06", faction = "Horde", defaultMacroExcluded = true, manualOnly = true, itemID = 51313, cooldown = 3600, cooldownCategory = 0, categoryCooldown = 0, gcdCategory = 133, gcd = 1.5 },
}
local usableIndex, usableItem
for usableIndex, usableItem in ipairs(usableItems) do
    addon.ItemTextures[usableItem.key] = usableItem.texture
    addon.ItemDetails[usableItem.key] = usableItem.detail
    table.insert(addon.Items, usableItem)
end

-- 同时补齐原有药剂的冷却类别，使新旧药水/魂能/药剂的共享冷却一致。
local existingCooldowns = {
    titans = { itemID = 13510, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    supremePower = { itemID = 13512, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    distilledWisdom = { itemID = 13511, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    zanzaSpeed = { itemID = 20081, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    arthasGift = { itemID = 9088, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 133, gcd = 1.5 },
    zanzaSpirit = { itemID = 20079, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    fortitude = { itemID = 3825, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    cocktail = { itemID = 8411, cooldown = 0.0, cooldownCategory = 103, categoryCooldown = 60.0, gcdCategory = 133, gcd = 0.0 },
    trollBlood = { itemID = 20004, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    stoneshield = { itemID = 13445, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    greaterArcaneProtection = { itemID = 13461, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    greaterShadowProtection = { itemID = 13459, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    greaterNatureProtection = { itemID = 13458, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    greaterFireProtection = { itemID = 13457, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    greaterFrostProtection = { itemID = 13456, cooldown = 120.0, cooldownCategory = 4, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    mongoose = { itemID = 13452, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    agility = { itemID = 8949, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    encrusted = { itemID = 8412, cooldown = 0.0, cooldownCategory = 103, categoryCooldown = 60.0, gcdCategory = 133, gcd = 0.0 },
    giants = { itemID = 9206, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    soulEnergy = { itemID = 12451, cooldown = 60.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 133, gcd = 0.0 },
    hyenaStimulant = { itemID = 8410, cooldown = 0.0, cooldownCategory = 103, categoryCooldown = 60.0, gcdCategory = 133, gcd = 0.0 },
    herbalBrew = { itemID = 42014, cooldown = 0.0, cooldownCategory = 0, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    soulStrike = { itemID = 12460, cooldown = 60.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 133, gcd = 1.5 },
    firewater = { itemID = 12820, cooldown = 60.0, cooldownCategory = 0, categoryCooldown = 60.0, gcdCategory = 0, gcd = 0.0 },
    bruteForce = { itemID = 13453, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    rapidGrowth = { itemID = 56113, cooldown = 120.0, cooldownCategory = 0, categoryCooldown = 120.0, gcdCategory = 0, gcd = 0.0 },
    demon = { itemID = 9224, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 133, gcd = 1.5 },
    strengthScroll4 = { itemID = 10310, cooldown = 1.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 133, gcd = 0.0 },
    agilityScroll4 = { itemID = 10309, cooldown = 1.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 133, gcd = 0.0 },
    dreamEssence = { itemID = 61224, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    arcanePower = { itemID = 13454, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    arcaneElixir = { itemID = 9155, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    dreamshire = { itemID = 61423, cooldown = 60.0, cooldownCategory = 99, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    intellect = { itemID = 9179, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    soulTrickery = { itemID = 12458, cooldown = 60.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 133, gcd = 1.5 },
    firepower = { itemID = 21546, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    shadowPower = { itemID = 9264, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    frostPower = { itemID = 55046, cooldown = 0.0, cooldownCategory = 99, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    greaterArcanePower = { itemID = 55048, cooldown = 0.0, cooldownCategory = 99, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    naturePower = { itemID = 50237, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    felMana = { itemID = 20007, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    medivhBlue = { itemID = 61175, cooldown = 0.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 0, gcd = 0.0 },
    intellectScroll4 = { itemID = 10308, cooldown = 1.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 133, gcd = 0.0 },
    dreamMongoose = { itemID = 47410, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    arcaneGiants = { itemID = 47412, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    dreamFirewater = { itemID = 47414, cooldown = 0.0, cooldownCategory = 79, categoryCooldown = 3.0, gcdCategory = 0, gcd = 0.0 },
    desertDumplings = { itemID = 20452, cooldown = 0.0, cooldownCategory = 11, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    nutritious = { itemID = 51720, cooldown = 0.0, cooldownCategory = 0, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    bigFish = { itemID = 13934, cooldown = 0.0, cooldownCategory = 11, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    grilledSquid = { itemID = 13928, cooldown = 0.0, cooldownCategory = 11, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    sweetBerries = { itemID = 51711, cooldown = 0.0, cooldownCategory = 0, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    skewers = { itemID = 42163, cooldown = 0.0, cooldownCategory = 0, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    terrabeMood = { itemID = 60978, cooldown = 0.0, cooldownCategory = 11, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    terrabeFun = { itemID = 60977, cooldown = 0.0, cooldownCategory = 11, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    terrabeSurprise = { itemID = 60976, cooldown = 0.0, cooldownCategory = 11, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    nightfinSoup = { itemID = 13931, cooldown = 0.0, cooldownCategory = 11, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    smokedPerch = { itemID = 13929, cooldown = 0.0, cooldownCategory = 11, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    herbSalad = { itemID = 83309, cooldown = 0.0, cooldownCategory = 11, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    crispy = { itemID = 51717, cooldown = 0.0, cooldownCategory = 0, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    chimera = { itemID = 21023, cooldown = 0.0, cooldownCategory = 11, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    seafood = { itemID = 42164, cooldown = 0.0, cooldownCategory = 0, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    cookedFish = { itemID = 13927, cooldown = 0.0, cooldownCategory = 11, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    dragonbreath = { itemID = 12217, cooldown = 0.0, cooldownCategory = 11, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    blessedSunfruit = { itemID = 13810, cooldown = 0.0, cooldownCategory = 11, categoryCooldown = 1.0, gcdCategory = 0, gcd = 0.0 },
    elementalStone = { itemID = 18262, cooldown = 1.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 0, gcd = 0.0 },
    sacredStone = { itemID = 23122, cooldown = 1.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 0, gcd = 0.0 },
    sacredOil = { itemID = 23123, cooldown = 1.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 0, gcd = 0.0 },
    wizardOil = { itemID = 20749, cooldown = 1.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 0, gcd = 0.0 },
    manaOil = { itemID = 20748, cooldown = 1.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 0, gcd = 0.0 },
    instantPoison6 = { itemID = 8928, cooldown = 0.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 0, gcd = 0.0 },
    dissolvePoison2 = { itemID = 54010, cooldown = 0.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 0, gcd = 0.0 },
    deadlyPoison5 = { itemID = 20844, cooldown = 0.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 0, gcd = 0.0 },
    deadlyPoison4 = { itemID = 8985, cooldown = 0.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 0, gcd = 0.0 },
    corrosivePoison2 = { itemID = 47409, cooldown = 0.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 0, gcd = 0.0 },
    corrosivePoison = { itemID = 47408, cooldown = 0.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 0, gcd = 0.0 },
    mindNumbingPoison3 = { itemID = 9186, cooldown = 0.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 0, gcd = 0.0 },
    woundPoison = { itemID = 10918, cooldown = 0.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 0, gcd = 0.0 },
    cripplingPoison = { itemID = 3775, cooldown = 0.0, cooldownCategory = 0, categoryCooldown = 0.0, gcdCategory = 0, gcd = 0.0 },
}
addon.ItemsByName = {}
addon.ItemsByID = {}
local dataIndex, dataItem
for dataIndex, dataItem in ipairs(addon.Items) do
    local info = existingCooldowns[dataItem.key]
    if info then
        local field, value
        for field, value in pairs(info) do dataItem[field] = value end
    end
    addon.ItemsByName[dataItem.item] = dataItem
    if dataItem.itemID then addon.ItemsByID[dataItem.itemID] = dataItem end
    if dataItem.alternateIDs then
        local idIndex, itemID
        for idIndex, itemID in ipairs(dataItem.alternateIDs) do addon.ItemsByID[itemID] = dataItem end
    end
end

-- 用角色阵营判断种族所属，兼容龟服高等精灵/地精，不依赖种族名称的本地化。
-- 保留完整物品目录及 ID 索引；设置、小窗和使用入口统一过滤不适用条目。
function addon.IsItemAvailableForPlayer(item)
    if not item or not item.faction then return true end
    return type(UnitFactionGroup) == "function" and UnitFactionGroup("player") == item.faction
end

function addon.IsMacroExcluded(item, profile)
    if item.manualOnly then return true end
    local excluded = profile and profile.macroExcluded and profile.macroExcluded[item.key]
    if excluded == nil then return item.defaultMacroExcluded end
    return addon.ToBoolean(excluded)
end

-- 设置界面、药剂小窗和 /catpotion 共用这一顺序，避免三处排序不一致。
addon.SettingsOrderItems = {}
local orderCategoryIndex, orderCategory, orderItemIndex, orderItem
for orderCategoryIndex, orderCategory in ipairs(addon.Categories) do
    for orderItemIndex, orderItem in ipairs(addon.Items) do
        if orderItem.category == orderCategory then
            table.insert(addon.SettingsOrderItems, orderItem)
        end
    end
end

-- 小窗顺序独立于药剂目录/宏优先级；主手和副手各自拥有稳定的条目 ID。
local defaultWindowEntries, windowEntriesByKey = {}, {}
local entryIndex, entryItem
for entryIndex, entryItem in ipairs(addon.SettingsOrderItems) do
    local slots = addon.IsWeaponCategory(entryItem.category) and { 16, 17 } or { false }
    local slotIndex, slot
    for slotIndex, slot in ipairs(slots) do
        local entryKey = entryItem.key .. (slot and ":" .. slot or "")
        local entry = { key = entryKey, item = entryItem, weaponSlot = slot or nil }
        table.insert(defaultWindowEntries, entry)
        windowEntriesByKey[entryKey] = entry
    end
end

function addon.GetProfileWindowEntries(profile)
    local available, ordered, seen = {}, {}, {}
    local index, entry
    for index, entry in ipairs(defaultWindowEntries) do
        local enabled
        if entry.weaponSlot then
            local slots = profile.weaponSlots and profile.weaponSlots[entry.item.key]
            enabled = type(slots) == "table" and slots[entry.weaponSlot == 16 and "main" or "off"]
        else
            enabled = profile.selected and profile.selected[entry.item.key]
        end
        if addon.ToBoolean(enabled) and addon.IsItemAvailableForPlayer(entry.item) then
            available[entry.key] = entry
        end
    end
    local key
    for index, key in ipairs(type(profile.windowOrder) == "table" and profile.windowOrder or {}) do
        if type(key) == "string" and available[key] and not seen[key] then
            table.insert(ordered, available[key])
            seen[key] = true
        end
    end
    -- 新勾选且尚未自定义位置的条目排在末尾；没有自定义顺序时沿用原排列。
    for index, entry in ipairs(defaultWindowEntries) do
        if available[entry.key] and not seen[entry.key] then table.insert(ordered, entry) end
    end
    return ordered
end

function addon.SwapProfileWindowEntries(profileId, sourceKey, targetKey)
    local profile = addon.GetDatabase().profiles[profileId]
    if not profile or sourceKey == targetKey then return false end
    local visible = addon.GetProfileWindowEntries(profile)
    local sourceVisible, targetVisible
    local index, entry
    for index, entry in ipairs(visible) do
        if entry.key == sourceKey then sourceVisible = true end
        if entry.key == targetKey then targetVisible = true end
    end
    if not sourceVisible or not targetVisible then return false end
    local order, seen = {}, {}
    local key
    -- 保留已取消勾选条目的位置，重新勾选时恢复；丢弃未知或重复的存档条目。
    for index, key in ipairs(profile.windowOrder) do
        if type(key) == "string" and windowEntriesByKey[key] and not seen[key] then
            table.insert(order, key)
            seen[key] = true
        end
    end
    for index, entry in ipairs(visible) do
        if not seen[entry.key] then table.insert(order, entry.key); seen[entry.key] = true end
    end
    local sourceIndex, targetIndex
    for index, key in ipairs(order) do
        if key == sourceKey then sourceIndex = index end
        if key == targetKey then targetIndex = index end
    end
    order[sourceIndex], order[targetIndex] = order[targetIndex], order[sourceIndex]
    profile.windowOrder = order
    return true
end

function addon.ResetProfileWindowOrder(profileId)
    local profile = addon.GetDatabase().profiles[profileId]
    if not profile then return false end
    profile.windowOrder = {}
    return true
end

local auraTooltip = CreateFrame("GameTooltip", "CatPotionAuraTooltip", UIParent, "GameTooltipTemplate")
local weaponTooltip = CreateFrame("GameTooltip", "CatPotionWeaponTooltip", UIParent, "GameTooltipTemplate")

function addon.GetDatabase()
    if type(CatPotionDB) ~= "table" then
        CatPotionDB = {}
    end
    local key, value
    for key, value in pairs(defaults) do
        if CatPotionDB[key] == nil then
            CatPotionDB[key] = value
        end
    end
    -- 1.x 只有一份 selected；首次加载 2.x 时原样迁移为“默认配置”。
    if type(CatPotionDB.profiles) ~= "table" or type(CatPotionDB.profileOrder) ~= "table" then
        local migratedSelected = type(CatPotionDB.selected) == "table" and CatPotionDB.selected or {}
        CatPotionDB.profiles = {
            [1] = { id = 1, name = "默认配置", selected = migratedSelected, macroExcluded = {} }
        }
        CatPotionDB.profileOrder = { 1 }
        CatPotionDB.activeProfileId = 1
        CatPotionDB.defaultProfileId = 1
        CatPotionDB.nextProfileId = 2
    end
    if table.getn(CatPotionDB.profileOrder) == 0 then
        CatPotionDB.profiles[1] = { id = 1, name = "默认配置", selected = {}, macroExcluded = {} }
        CatPotionDB.profileOrder[1] = 1
        CatPotionDB.activeProfileId = 1
        CatPotionDB.defaultProfileId = 1
        CatPotionDB.nextProfileId = 2
    end
    if not CatPotionDB.profiles[CatPotionDB.defaultProfileId] then
        CatPotionDB.defaultProfileId = CatPotionDB.profiles[1] and 1 or CatPotionDB.profileOrder[1]
    end
    local profileIndex, profileId, profile
    for profileIndex, profileId in ipairs(CatPotionDB.profileOrder) do
        profile = CatPotionDB.profiles[profileId]
        if profile then
            -- 已有配置首次继承旧全局外观值，此后各配置独立保存。
            if profile.scale == nil then profile.scale = CatPotionDB.scale end
            if profile.layout == nil then profile.layout = CatPotionDB.layout end
            if profile.layoutLimit == nil then profile.layoutLimit = CatPotionDB.layoutLimit end
            if profile.minimized == nil then profile.minimized = 0 end
            if profile.locked == nil then profile.locked = CatPotionDB.locked end
            if profile.hideInCombat == nil then profile.hideInCombat = 0 end
            if profile.showMessages == nil then profile.showMessages = CatPotionDB.showMessages end
            if profile.warningMinutes == nil then profile.warningMinutes = CatPotionDB.warningMinutes end
            profile.warningMinutes = math.max(1, math.min(10, math.floor(tonumber(profile.warningMinutes) or 4)))
            profile.scale = math.max(0.5, math.min(1.5, tonumber(profile.scale) or 0.8))
            profile.layout = profile.layout == "vertical" and "vertical" or "horizontal"
            profile.layoutLimit = math.max(1, math.min(10, math.floor(tonumber(profile.layoutLimit) or 2)))
            if type(profile.selected) ~= "table" then profile.selected = {} end
            if type(profile.macroExcluded) ~= "table" then profile.macroExcluded = {} end
            if type(profile.weaponSlots) ~= "table" then profile.weaponSlots = {} end
            if type(profile.windowOrder) ~= "table" then profile.windowOrder = {} end
            -- 武器类物品若残留普通勾选，迁移时按主手处理，避免原选择直接消失。
            local migrateItemIndex, migrateItem
            for migrateItemIndex, migrateItem in ipairs(addon.Items) do
                if addon.IsWeaponCategory(migrateItem.category) and addon.ToBoolean(profile.selected[migrateItem.key]) then
                    if type(profile.weaponSlots[migrateItem.key]) ~= "table" then
                        profile.weaponSlots[migrateItem.key] = { main = 1 }
                    end
                    profile.selected[migrateItem.key] = nil
                end
            end
            if type(profile.name) ~= "string" or profile.name == "" then
                profile.name = "配置 " .. profileIndex
            end
        end
    end
    if not CatPotionDB.profiles[CatPotionDB.activeProfileId] then
        CatPotionDB.activeProfileId = CatPotionDB.profileOrder[1]
    end
    -- 从单小窗迁移时，仅原当前配置继承开关和位置，其他配置保持关闭。
    if not CatPotionDB.profileWindowsMigrated then
        local active = CatPotionDB.profiles[CatPotionDB.activeProfileId]
        if active.windowVisible == nil then active.windowVisible = CatPotionDB.windowVisible end
        active.windowPosition = active.windowPosition or CatPotionDB.windowPosition
        active.windowPoint = active.windowPoint or CatPotionDB.windowPoint
        active.windowRelativePoint = active.windowRelativePoint or CatPotionDB.windowRelativePoint
        active.windowX = active.windowX or CatPotionDB.windowX
        active.windowY = active.windowY or CatPotionDB.windowY
        CatPotionDB.profileWindowsMigrated = true
    end
    for profileId, profile in pairs(CatPotionDB.profiles) do
        if profile.windowVisible == nil then profile.windowVisible = 0 end
    end
    CatPotionDB.nextProfileId = math.floor(tonumber(CatPotionDB.nextProfileId) or 1)
    while CatPotionDB.profiles[CatPotionDB.nextProfileId] do
        CatPotionDB.nextProfileId = CatPotionDB.nextProfileId + 1
    end
    CatPotionDB.selected = nil
    CatPotionDB.version = 2
    -- 旧版本曾把物品售价误存为纹理，停用并清理这份缓存。
    CatPotionDB.itemTextures = nil
    if CatPotionDB.layout ~= "vertical" then
        CatPotionDB.layout = "horizontal"
    end
    CatPotionDB.layoutLimit = math.floor(tonumber(CatPotionDB.layoutLimit) or 2)
    if CatPotionDB.layoutLimit < 1 then CatPotionDB.layoutLimit = 1 end
    if CatPotionDB.layoutLimit > 10 then CatPotionDB.layoutLimit = 10 end
    return CatPotionDB
end

function addon.GetActiveProfile()
    local database = addon.GetDatabase()
    return database.profiles[database.activeProfileId]
end

function addon.GetDefaultProfile()
    local database = addon.GetDatabase()
    return database.profiles[database.defaultProfileId]
end

function addon.GetSelectedItems()
    local profile = addon.GetActiveProfile()
    return profile and profile.selected or {}
end

-- 与 selected 分离保存：被排除的普通药剂仍会显示在小窗中并允许手动点击，
-- 只有 /catpotion 与原生一键补药热键会跳过它们。
function addon.GetMacroExcludedItems()
    local profile = addon.GetActiveProfile()
    if not profile then return {} end
    if type(profile.macroExcluded) ~= "table" then profile.macroExcluded = {} end
    return profile.macroExcluded
end

function addon.GetWeaponSlotSelections()
    local profile = addon.GetActiveProfile()
    if not profile then return {} end
    if type(profile.weaponSlots) ~= "table" then profile.weaponSlots = {} end
    return profile.weaponSlots
end

function addon.IsDefaultProfile(profileId)
    local database = addon.GetDatabase()
    return profileId == database.defaultProfileId
end

function addon.SelectProfile(profileId)
    local database = addon.GetDatabase()
    if not database.profiles[profileId] then return false end
    database.activeProfileId = profileId
    return true
end

function addon.SelectProfileByName(profileName)
    local database = addon.GetDatabase()
    local index, profileId, profile
    for index, profileId in ipairs(database.profileOrder) do
        profile = database.profiles[profileId]
        if profile and profile.name == profileName then
            database.activeProfileId = profileId
            return true
        end
    end
    return false
end

function addon.CreateProfile(name)
    local database = addon.GetDatabase()
    local profileId = database.nextProfileId
    database.nextProfileId = profileId + 1
    database.profiles[profileId] = {
        id = profileId,
        name = name,
        scale = defaults.scale,
        layout = defaults.layout,
        layoutLimit = defaults.layoutLimit,
        locked = defaults.locked,
        minimized = defaults.minimized,
        hideInCombat = 0,
        showMessages = defaults.showMessages,
        warningMinutes = defaults.warningMinutes,
        windowVisible = 0,
        selected = {},
        macroExcluded = {},
        weaponSlots = {},
        windowOrder = {}
    }
    table.insert(database.profileOrder, profileId)
    database.activeProfileId = profileId
    return profileId
end

function addon.RenameProfile(profileId, name)
    local database = addon.GetDatabase()
    local profile = database.profiles[profileId]
    if not profile or profileId == database.defaultProfileId then return false end
    profile.name = name
    return true
end

function addon.DeleteProfile(profileId)
    local database = addon.GetDatabase()
    if profileId == database.defaultProfileId or table.getn(database.profileOrder) <= 1 or not database.profiles[profileId] then
        return false
    end
    local index
    for index = 1, table.getn(database.profileOrder) do
        if database.profileOrder[index] == profileId then
            table.remove(database.profileOrder, index)
            if index > table.getn(database.profileOrder) then index = table.getn(database.profileOrder) end
            database.profiles[profileId] = nil
            database.activeProfileId = database.profileOrder[index]
            if addon.RefreshPotionWindow then addon.RefreshPotionWindow() end
            return true
        end
    end
    return false
end

function addon.ResetDatabase()
    CatPotionDB = {}
    return addon.GetDatabase()
end

function addon.ToBoolean(value)
    return value == true or value == 1
end

-- 只有冲突双方都在当前配置中被勾选时才返回 true。
-- 此函数仅供提示界面使用，不会阻止或改变任何药剂选择。
function addon.HasSelectedItemConflict(itemKey, selected)
    if not addon.ToBoolean(selected and selected[itemKey]) then return false end
    local conflicts = addon.ItemConflicts[itemKey]
    if not conflicts then return false end
    local conflictKey
    for conflictKey in pairs(conflicts) do
        if addon.ToBoolean(selected[conflictKey]) then return true end
    end
    return false
end

function addon.ApplyFlatBackdrop(frame, red, green, blue, alpha)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame:SetBackdropColor(red, green, blue, alpha)
    frame:SetBackdropBorderColor(0.3, 0.4, 0.52, 0.9)
end

function addon.Print(message, errorMessage, profileId)
    local database = addon.GetDatabase()
    local profile = database.profiles[profileId or database.activeProfileId]
    if errorMessage or (profile and addon.ToBoolean(profile.showMessages)) then
        local color = errorMessage and "|cffff5555" or "|cff33aaff"
        DEFAULT_CHAT_FRAME:AddMessage(color .. "Cat - Potion：|r" .. tostring(message))
    end
end

local function GetLinkName(link)
    if not link then
        return nil
    end
    local startPosition, endPosition, name = string.find(link, "%[(.-)%]")
    return name
end

local function GetLinkItemID(link)
    if not link then return nil end
    local first, last, itemID = string.find(link, "item:(%d+)")
    return tonumber(itemID)
end

-- 冷却属于角色，所有配置/小窗共享。只从客户端冷却或实际消耗确认计时，
-- 不把 UseContainerItem 的请求当作成功；最后一件消耗后仍保留倒计时。
local itemCooldownEnds = {}
local categoryCooldownEnds = {}
local pendingItemUses = {}
local gcdProbeIndex
local gcdProbeNames = {
    ["火球术"] = 1, ["寒冰箭"] = 1, ["奥术智慧"] = 1,
    ["惩击"] = 1, ["真言术：韧"] = 1, ["恢复"] = 1,
    ["治疗波"] = 1, ["闪电箭"] = 1, ["愤怒"] = 1, ["回春术"] = 1,
    ["圣光术"] = 1, ["圣光闪现"] = 1, ["邪恶攻击"] = 1,
    ["战斗怒吼"] = 1, ["腐蚀术"] = 1, ["毒蛇钉刺"] = 1,
    ["Fireball"] = 1, ["Frostbolt"] = 1, ["Arcane Intellect"] = 1,
    ["Smite"] = 1, ["Power Word: Fortitude"] = 1, ["Renew"] = 1,
    ["Healing Wave"] = 1, ["Lightning Bolt"] = 1, ["Wrath"] = 1,
    ["Rejuvenation"] = 1, ["Holy Light"] = 1, ["Flash of Light"] = 1,
    ["Sinister Strike"] = 1, ["Battle Shout"] = 1, ["Corruption"] = 1, ["Serpent Sting"] = 1
}

function addon.MarkSpellCacheDirty()
    gcdProbeIndex = nil
end

local function IsSpellGlobalCooldown(startTime, duration)
    if type(GetSpellName) ~= "function" or type(GetSpellCooldown) ~= "function" then return false end
    local book = BOOKTYPE_SPELL or "spell"
    if gcdProbeIndex == nil then
        gcdProbeIndex = false
        local index
        for index = 1, 512 do
            local name = GetSpellName(index, book)
            if not name then break end
            if gcdProbeNames[name] then gcdProbeIndex = index; break end
        end
    end
    if not gcdProbeIndex then return false end
    local probeStart, probeDuration, enabled = GetSpellCooldown(gcdProbeIndex, book)
    return enabled and enabled ~= 0 and probeDuration and probeDuration > 0 and probeDuration <= 2
        and math.abs((probeStart or 0) - (startTime or 0)) < 0.01
        and math.abs(probeDuration - duration) < 0.01
end

local function StoreCooldown(item, startTime, duration)
    if not item or not duration or duration <= 0 then return end
    local expiration = startTime + duration
    if expiration <= GetTime() then return end
    itemCooldownEnds[item.key] = math.max(itemCooldownEnds[item.key] or 0, expiration)
    if item.cooldownCategory and item.cooldownCategory > 0 and (item.categoryCooldown or 0) > 0 then
        -- 工兵的自身 300 秒不能传播给其他炸药；类别只锁 60 秒。
        local categoryEnd = startTime + math.min(duration, item.categoryCooldown)
        categoryCooldownEnds[item.cooldownCategory] = math.max(categoryCooldownEnds[item.cooldownCategory] or 0, categoryEnd)
    end
end

-- 缓存保存“过期时间”而不是每帧重新扫描。Window.lua 在相关事件到来时调用 Mark*Dirty，
-- 真正的全量扫描会延迟合并执行，避免 BAG_UPDATE/PLAYER_AURAS_CHANGED 连续触发造成卡顿。
local bagItemCache = {}
local bagCacheReady = false
local auraNameCache = {}
local auraIconCache = {}
local auraCacheReady = false
local weaponEnchantCache = {}
local weaponEnchantCacheReady = false

local weaponEnchantMatchers = {
    -- 毒药名称先于磨刀石的属性兜底匹配，避免武器自带暴击属性误判。
    -- 与本地 Cat/EzPoison 一致按毒药类型识别，不依赖等级文字。
    -- 同类型收录多个等级时，先匹配带等级的名称。
    { item = "速效毒药 VI", patterns = { "速效毒药" } },
    { item = "溶解毒药 II", patterns = { "溶解毒药" } },
    -- 致命毒药同时收录 IV/V，必须按等级精确匹配，不能只匹配“致命毒药”。
    { item = "致命毒药 V", patterns = { "致命毒药%s*V" } },
    { item = "致命毒药 IV", patterns = { "致命毒药%s*IV" } },
    { item = "腐蚀毒药 II", patterns = { "腐蚀毒药%s*II" } },
    { item = "腐蚀毒药", patterns = { "腐蚀毒药" } },
    { item = "麻痹毒药 III", patterns = { "麻痹毒药" } },
    { item = "致伤毒药", patterns = { "致伤毒药" } },
    { item = "致残毒药", patterns = { "致残毒药" } },
    { item = "卓越巫师之油", patterns = { "卓越巫师之油" } },
    { item = "卓越法力之油", patterns = { "卓越法力之油" } },
    { item = "神圣巫师之油", patterns = { "神圣巫师之油" } },
    { item = "神圣磨刀石", patterns = { "神圣磨刀石", "100%s*攻击强度.-亡灵", "亡灵.-100%s*攻击强度" } },
    { item = "元素磨刀石", patterns = { "元素磨刀石", "致命一击.-2%%", "2%%.-致命一击" } }
}

function addon.MarkBagCacheDirty()
    bagCacheReady = false
end

function addon.RefreshBagCache()
    local refreshed = {}
    local bag, slot
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            local itemName = GetLinkName(link)
            if itemName then
                local itemData = addon.ItemsByID[GetLinkItemID(link)]
                if itemData then itemName = itemData.item end
                local texture, count = GetContainerItemInfo(bag, slot)
                if type(texture) ~= "string" or texture == "" then
                    texture = nil
                end
                local entry = refreshed[itemName]
                if not entry then
                    entry = {
                        bag = bag,
                        slot = slot,
                        count = 0,
                        texture = texture,
                        link = link
                    }
                    refreshed[itemName] = entry
                end
                if count then
                    if count < 0 then
                        entry.count = entry.count - count
                    else
                        entry.count = entry.count + count
                    end
                end
            end
        end
    end
    bagItemCache = refreshed
    bagCacheReady = true
    local key, request
    for key, request in pairs(pendingItemUses) do
        local entry = refreshed[request.item.item]
        local count = entry and entry.count or 0
        if GetTime() - request.time > 30 then
            pendingItemUses[key] = nil
        elseif count < request.count then
            StoreCooldown(request.item, GetTime(), math.max(request.item.cooldown or 0, request.item.categoryCooldown or 0))
            pendingItemUses[key] = nil
        end
    end
end

function addon.GetItemTexture(item)
    if not item then
        return nil
    end
    return addon.ItemTextures[item.key]
end

function addon.FindBagItem(itemName)
    if not bagCacheReady then
        addon.RefreshBagCache()
    end
    local entry = bagItemCache[itemName]
    if not entry then
        return nil, nil, 0, nil, nil
    end
    return entry.bag, entry.slot, entry.count, entry.texture, entry.link
end

function addon.GetCooldownInfo(itemName)
    local item = addon.ItemsByName[itemName]
    local bag, slot = addon.FindBagItem(itemName)
    local startTime, duration, enable
    if bag ~= nil and type(GetContainerItemCooldown) == "function" then
        startTime, duration, enable = GetContainerItemCooldown(bag, slot)
    end
    local remaining, kind = 0, "item"
    local unavailable = enable == 0 or enable == false
    if enable and enable ~= 0 and duration and duration > 0 then
        local nativeRemaining = math.max(0, (startTime or 0) + duration - GetTime())
        -- 短冷却不能一律丢弃：真实的 1 秒类别锁、3 秒药剂锁照常计算。
        -- 无 GCD 的药水若被技能 GCD 暂时覆盖，只忽略与物品数据不符的短锁。
        local unrelatedGCD = item and (item.gcd or 0) == 0 and duration <= 2
            and IsSpellGlobalCooldown(startTime, duration)
        if not unrelatedGCD then
            remaining = nativeRemaining
            if item and (item.gcd or 0) > 0 and duration <= 2 then
                kind = "gcd"
            elseif nativeRemaining > 0 then
                StoreCooldown(item, startTime or 0, duration)
                if item and (item.categoryCooldown or 0) > 0 and duration <= item.categoryCooldown + 0.01 then kind = "shared" end
            end
        end
    end
    if item then
        local ownRemaining = math.max(0, (itemCooldownEnds[item.key] or 0) - GetTime())
        local sharedRemaining = math.max(0, (categoryCooldownEnds[item.cooldownCategory] or 0) - GetTime())
        if ownRemaining > remaining then remaining, kind = ownRemaining, "item" end
        if sharedRemaining > remaining then remaining, kind = sharedRemaining, "shared" end
    end
    return remaining, kind, unavailable
end

function addon.GetCooldownRemaining(itemName)
    local remaining = addon.GetCooldownInfo(itemName)
    return remaining
end

function addon.CaptureItemCooldowns()
    local index, item
    for index, item in ipairs(addon.Items) do addon.GetCooldownInfo(item.item) end
end

function addon.ConfirmPendingItemUses()
    if next(pendingItemUses) then addon.RefreshBagCache() end
end

function addon.CancelPendingItemUses()
    pendingItemUses = {}
end

-- 返回 true 只代表已向客户端发出使用请求，并不代表服务器已经确认物品生效。
-- itemData 用于执行分类及物品限制（例如阻止战斗中进食）。
function addon.UseItem(itemName, itemData, weaponSlot, profileId)
    itemData = itemData or addon.ItemsByName[itemName]
    if not addon.IsItemAvailableForPlayer(itemData) then
        addon.Print("当前角色无法使用：" .. itemName, true)
        return false
    end
    local bag, slot, itemCount = addon.FindBagItem(itemName)
    if bag == nil then
        addon.Print("背包中没有：" .. itemName, true)
        return false
    end
    local texture, count, locked = GetContainerItemInfo(bag, slot)
    if locked == true or locked == 1 then
        addon.Print(itemName .. " 当前正在锁定，请稍后再试", true)
        return false
    end
    if itemData and (itemData.category == "烹饪" or itemData.outOfCombatOnly) and type(UnitAffectingCombat) == "function" and UnitAffectingCombat("player") then
        addon.Print("战斗中不能使用食物：" .. itemName, true)
        return false
    end
    if weaponSlot and not GetInventoryItemLink("player", weaponSlot) then
        addon.Print((weaponSlot == 16 and "主手" or "副手") .. "没有装备武器。", true)
        return false
    end
    local remaining = addon.GetCooldownRemaining(itemName)
    local unusedRemaining, unusedKind, unavailable = addon.GetCooldownInfo(itemName)
    if unavailable then
        addon.Print(itemName .. " 当前不可用", true)
        return false
    end
    if remaining > 0 then
        addon.Print(itemName .. " 尚有 " .. string.format("%.1f", remaining) .. " 秒冷却", true)
        return false
    end
    -- 卷轴和魂能类物品可以对友方目标使用。先把当前目标切换为自己，避免物品
    -- 在已有友方目标时直接施放给对方；使用完成后再恢复原目标。
    local forceSelfTarget = (itemData and itemData.selfTarget) or string.find(itemName, "魂能")
    local hadTarget, oldTargetGuid, targetWasPlayer
    if forceSelfTarget then
        hadTarget, oldTargetGuid = UnitExists("target")
        targetWasPlayer = type(UnitIsUnit) == "function" and UnitIsUnit("target", "player")
        TargetUnit("player")
    end

    if itemData then pendingItemUses[itemData.key] = { item = itemData, count = itemCount, time = GetTime() } end
    UseContainerItem(bag, slot)
    if weaponSlot then
        -- 与旧版客户端现有的武器上毒流程一致：使用物品后直接点击目标装备槽位。
        PickupInventoryItem(weaponSlot)
        if StaticPopup1 and StaticPopup1:IsVisible() and StaticPopup1Text and StaticPopup1Button1 then
            local popupText = StaticPopup1Text:GetText() or ""
            if string.find(popupText, "替换") then StaticPopup1Button1:Click() end
        end
        ClearCursor()
    elseif forceSelfTarget then
        -- 某些旧客户端仍会进入选择目标状态，再显式确认一次玩家自己。
        if type(SpellIsTargeting) == "function" and SpellIsTargeting() then
            SpellTargetUnit("player")
        end

        if not targetWasPlayer then
            if not hadTarget then
                ClearTarget()
            elseif oldTargetGuid then
                TargetUnit(oldTargetGuid)
            elseif type(TargetLastTarget) == "function" then
                TargetLastTarget()
            end
        end
    end
    -- 旧客户端的 UseContainerItem 没有可靠的成功返回值，只能确认已发出使用请求。
    -- Window.lua 在插件载入后提供统一的两阶段复扫；窗口隐藏时标脏缓存也能保证下次打开读取新状态。
    if addon.RequestPotionUseRefresh then
        addon.RequestPotionUseRefresh()
    else
        addon.MarkAuraCacheDirty()
        addon.MarkWeaponEnchantCacheDirty()
    end
    addon.Print("尝试使用：" .. itemName, false, profileId)
    return true
end

local function StoreAuraExpiration(cache, key, expiration)
    if not key then
        return
    end
    local previous = cache[key]
    if not previous or expiration > previous then
        cache[key] = expiration
    end
end

function addon.MarkAuraCacheDirty()
    auraCacheReady = false
end

function addon.RefreshAuraCache()
    local refreshedNames = {}
    local refreshedIcons = {}
    local currentTime = GetTime()
    local index
    auraTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    for index = 0, 31 do
        local texture = GetPlayerBuffTexture(index)
        if not texture then
            break
        end
        local remaining = GetPlayerBuffTimeLeft(index) or 0
        local expiration = currentTime + remaining
        StoreAuraExpiration(refreshedIcons, texture, expiration)
        auraTooltip:ClearLines()
        auraTooltip:SetPlayerBuff(index)
        local line = getglobal("CatPotionAuraTooltipTextLeft1")
        if line then
            StoreAuraExpiration(refreshedNames, line:GetText(), expiration)
        end
    end
    auraTooltip:Hide()
    auraNameCache = refreshedNames
    auraIconCache = refreshedIcons
    auraCacheReady = true
end

function addon.GetBuffTime(buffName, buffIcon)
    if not auraCacheReady then
        addon.RefreshAuraCache()
    end
    local expiration
    -- 指定 buffIcon 时刻意只按图标匹配；魔血药水与夜鳞鱼汤的 Buff 同名，需要这样区分。
    if buffIcon then
        expiration = auraIconCache[buffIcon]
    elseif buffName then
        expiration = auraNameCache[buffName]
    end
    if not expiration then
        return 0
    end
    local remaining = expiration - GetTime()
    if remaining < 0 then
        remaining = 0
    end
    return remaining
end

local function GetWeaponTooltipText(slot)
    local text = ""
    local lineIndex
    weaponTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    weaponTooltip:ClearLines()
    weaponTooltip:SetInventoryItem("player", slot)
    for lineIndex = 1, weaponTooltip:NumLines() do
        local left = getglobal("CatPotionWeaponTooltipTextLeft" .. lineIndex)
        local right = getglobal("CatPotionWeaponTooltipTextRight" .. lineIndex)
        local leftText = left and left:GetText()
        local rightText = right and right:GetText()
        if leftText then text = text .. "\n" .. leftText end
        if rightText then text = text .. "\n" .. rightText end
    end
    weaponTooltip:Hide()
    return text
end

local function IdentifyWeaponEnchant(tooltipText)
    local matcherIndex, matcher
    local patternIndex, pattern
    for matcherIndex, matcher in ipairs(weaponEnchantMatchers) do
        for patternIndex, pattern in ipairs(matcher.patterns) do
            if string.find(tooltipText, pattern) then
                return matcher.item
            end
        end
    end
    return nil
end

local function ReadWeaponEnchantCharges(tooltipText, apiCharges)
    -- 复用 CatLib 的 (%d+)次 识别方式，允许数字与“次”之间有空格。
    -- 提示文字优先；旧客户端 API 对部分毒药可能返回 0 或不提供次数。
    local startPosition, endPosition, value = string.find(tooltipText, "(%d+)%s*次")
    local charges = tonumber(value)
    if charges then return charges end
    charges = tonumber(apiCharges)
    if charges and charges > 0 then return math.floor(charges) end
    -- 无明确次数时返回 nil；不要将无次数的附魔显示成 0 层。
    return nil
end

local function StoreWeaponEnchant(slot, remainingMilliseconds, apiCharges, currentTime, refreshed)
    if not remainingMilliseconds or remainingMilliseconds <= 0 then
        return
    end
    local tooltipText = GetWeaponTooltipText(slot)
    local itemName = IdentifyWeaponEnchant(tooltipText)
    if not itemName then
        return
    end
    refreshed[slot] = {
        itemName = itemName,
        expiration = currentTime + remainingMilliseconds / 1000,
        charges = ReadWeaponEnchantCharges(tooltipText, apiCharges)
    }
end

function addon.MarkWeaponEnchantCacheDirty()
    weaponEnchantCacheReady = false
end

function addon.RefreshWeaponEnchantCache()
    local refreshed = {}
    local currentTime = GetTime()
    local hasMain, mainTime, mainCharges, hasOff, offTime, offCharges = GetWeaponEnchantInfo()
    if hasMain then
        StoreWeaponEnchant(16, mainTime, mainCharges, currentTime, refreshed)
    end
    if hasOff then
        StoreWeaponEnchant(17, offTime, offCharges, currentTime, refreshed)
    end
    weaponEnchantCache = refreshed
    weaponEnchantCacheReady = true
end

function addon.GetWeaponEnchantTime(itemName, slot)
    if not weaponEnchantCacheReady then
        addon.RefreshWeaponEnchantCache()
    end
    local entry = slot and weaponEnchantCache[slot]
    local expiration = entry and entry.itemName == itemName and entry.expiration or nil
    if not expiration then
        return 0
    end
    local remaining = expiration - GetTime()
    if remaining < 0 then
        remaining = 0
    end
    return remaining
end

-- 次数与倒计时一样必须同时匹配物品和槽位，避免同手勾选多个毒药时串值。
function addon.GetWeaponEnchantCharges(itemName, slot)
    if not weaponEnchantCacheReady then
        addon.RefreshWeaponEnchantCache()
    end
    local entry = slot and weaponEnchantCache[slot]
    if not entry or entry.itemName ~= itemName or entry.expiration <= GetTime() then
        return nil
    end
    return entry.charges
end

-- 一键补药宏/热键规则：
-- * 不带配置名的 /catpotion 与原生热键固定使用默认配置；指定配置名时使用对应配置。
-- * 每次硬件按键最多尝试一个物品，按 SettingsOrderItems 顺序寻找。
-- * macroExcluded 中标记的物品只供小窗监控和手动使用，不进入一键补药候选。
-- * 效果缺失或剩余时间小于 warningMinutes 时才补充。
-- * 施法、引导和“正在进食中”期间不触发，避免打断或重复消耗食物。
-- * 武器强化按配置中启用的主手、副手逐一补充；毒药仍由药剂小窗手动点击。
local lastMacroUseTime = -100

local function PlayerIsCastingOrChanneling()
    if type(UnitCastingInfo) == "function" and UnitCastingInfo("player") then
        return true
    end
    if type(UnitChannelInfo) == "function" and UnitChannelInfo("player") then
        return true
    end
    return false
end

function addon.PlayerIsEating()
    return addon.GetBuffTime("正在进食中") > 0 or addon.GetBuffTime("进食") > 0
end

function addon.UseNextSelectedPotion(profileId)
    local currentTime = GetTime()
    -- 只限制同一次按键的重复请求；GCD/共享冷却由物品实际状态决定。
    if currentTime - lastMacroUseTime < 0.2 then
        return false
    end
    if PlayerIsCastingOrChanneling() or addon.PlayerIsEating() then
        addon.Print("正在施法、引导或进食，暂不使用药剂。", false)
        return false
    end

    local database = addon.GetDatabase()
    local profile = profileId and database.profiles[profileId] or addon.GetActiveProfile()
    local warningSeconds = (tonumber(profile and profile.warningMinutes) or 4) * 60
    local selected = profile and profile.selected or {}
    local weaponSlots = profile and profile.weaponSlots or {}
    local selectedCount = 0
    local eligibleCount = 0
    local bagItemCount = 0
    local itemIndex, item

    -- 小窗隐藏时也读取最新附魔，避免同名强化续期后继续使用旧倒计时。
    addon.MarkWeaponEnchantCacheDirty()
    for itemIndex, item in ipairs(addon.SettingsOrderItems) do
        if item.category == "武器强化" then
            local slots = weaponSlots[item.key] or {}
            local weaponSlot
            for weaponSlot = 16, 17 do
                local enabled = weaponSlot == 16 and slots.main or nil
                if weaponSlot == 17 then enabled = slots.off end
                if addon.ToBoolean(enabled) then
                    selectedCount = selectedCount + 1
                    eligibleCount = eligibleCount + 1
                    local bag = addon.FindBagItem(item.item)
                    if bag ~= nil then
                        bagItemCount = bagItemCount + 1
                        if GetInventoryItemLink("player", weaponSlot)
                            and addon.GetWeaponEnchantTime(item.item, weaponSlot) <= warningSeconds
                            and addon.GetCooldownRemaining(item.item) <= 0 then
                            if addon.UseItem(item.item, item, weaponSlot, profileId) then
                                lastMacroUseTime = currentTime
                                return true
                            end
                        end
                    end
                end
            end
        elseif not addon.IsWeaponCategory(item.category) and addon.IsItemAvailableForPlayer(item) and addon.ToBoolean(selected[item.key]) then
            selectedCount = selectedCount + 1
            if not addon.IsMacroExcluded(item, profile) then
                eligibleCount = eligibleCount + 1
                local bag = addon.FindBagItem(item.item)
                if bag ~= nil then
                    bagItemCount = bagItemCount + 1
                    local effectTime = addon.GetBuffTime(item.buff, item.buffIcon)
                    local itemWarningSeconds = item.macroWarningSeconds or warningSeconds
                    if effectTime <= itemWarningSeconds and addon.GetCooldownRemaining(item.item) <= 0 then
                        if addon.UseItem(item.item, item, nil, profileId) then
                            lastMacroUseTime = currentTime
                            return true
                        end
                    end
                end
            end
        end
    end

    if selectedCount == 0 then
        addon.Print("请先在设置中勾选要使用的药剂。", true)
    elseif eligibleCount == 0 then
        addon.Print("已勾选药剂均设为仅显示，不参与一键补药。", false)
    elseif bagItemCount == 0 then
        addon.Print("背包中没有已勾选的可用药剂。", true)
    else
        addon.Print("已勾选药剂均已生效、冷却中或暂时不可用。", false)
    end
    return false
end

SLASH_CATPOTIONUSE1 = "/catpotion"
function CatPotionUseCommand(message)
    local profileName = tostring(message or "")
    profileName = string.gsub(profileName, "^%s+", "")
    profileName = string.gsub(profileName, "%s+$", "")
    if profileName ~= "" then
        if not addon.SelectProfileByName(profileName) then
            addon.Print("没有找到配置：" .. profileName, true)
            return false
        end
        if addon.RefreshSettings then addon.RefreshSettings() end
        if addon.RefreshPotionWindow then addon.RefreshPotionWindow() end
        return addon.UseNextSelectedPotion()
    end
    local database = addon.GetDatabase()
    return addon.UseNextSelectedPotion(database.defaultProfileId)
end
SlashCmdList["CATPOTIONUSE"] = CatPotionUseCommand

function addon.SecondsToText(seconds, compact)
    if not seconds or seconds <= 0 then
        return "未激活"
    end
    -- 剩余不足一秒仍处于冷却，避免画面提前显示 00:00。
    seconds = math.ceil(seconds)
    local hours = math.floor(seconds / 3600)
    local remaining = seconds - hours * 3600
    local minutes = math.floor(remaining / 60)
    local secs = math.floor(remaining - minutes * 60)
    if hours > 0 then
        if compact then return string.format("%02d:%02d", hours, minutes) end
        return string.format("%02d:%02d:%02d", hours, minutes, secs)
    end
    return string.format("%02d:%02d", minutes, secs)
end
