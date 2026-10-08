-- 确保即使AutoMarkerLocale未定义也能正常工作
local L = AutoMarkerLocale or setmetatable({}, {
    __index = function(t, k)
        -- 如果键不存在，直接返回键本身作为默认值
        return k
    end
})
local SKULL    = 8
local CROSS    = 7
local SQUARE   = 6
local MOON     = 5
local TRIANGLE = 4
local DIAMOND  = 3
local CIRCLE   = 2
local STAR     = 1
local UNMARKED = 0

defaultNpcsToMark = {}
orderedPacks = {}

--[[

一些 ID，例如 Anub 的小怪、Raz 的小怪、Faerlina 的小怪和 Buru 的小怪，是有趣且特殊的。
事实上，它们彼此之间是特别的，每个 Boss 在 ID 的一致性方面都有不同的行为。

当 Buru 的蛋在战斗中死亡时，ID 计数会多次增加。死亡后不久，会创建一个 ID 高一的生成器，当蛋再次生成时，它的 ID 将高于生成器的 ID。如果多个蛋同时死亡，这种 ID 的增加可能会被扩展并变得有些不可预测。
一个机制可以检测标记蛋的死亡顺序，并按照最终重生的顺序重新应用标记。

Anub'rekhan 的小怪在每次副本开始时总是新 ID，而并不一致。当战斗重置时，它们将再次是新的。
一个机制可以检测到他的两个小怪重新生成的情况。

Raz 的小怪在副本开始时有一个一致的标记，但每次战斗重置时，小怪都会一个一个以顺时针的顺序重新生成新的 ID。
一个机制可以检测到他的四个小怪重新生成的情况。

Skeram 在进行三路分裂时会生成克隆，但他自己的 ID 从未改变。
一个机制可以检测到他的三个小怪重新生成的情况，因为它们都共享相同的名称。

Arlokk 并没有确切的小怪可以标记，但她在战斗中会消失。
用于检测一个小怪重新生成的机制被用来重新标记她。

Faerlina 的小怪如果没有死亡，则在战斗重置时不会重新生成，也不会获得新的 ID，它们只是回到起始位置，
然而，死亡的小怪将获得新的 ID。
一个类似于 Buru 蛋的机制可以用来更新它们，跟踪标记死亡的顺序，假设它们在标记未释放时重新生成。
如果 它们的新 ID 之间有任何一致性，可以使用复合方法。
我们可以在房间中复活时进行排队，或在我们跑回她那里时检测小怪的 ID，并利用新 ID 较高的事实，
可以基于识别缺少标记的小怪重新标记，然后比较它们的死亡顺序与已排序的 ID。
或者，我们可以每次看到新的小怪时进行一次全面的重新标记，尽管标记不会保持一致。

--]]


-- Function to add entries while maintaining order
function addToDefaultNpcsToMark(instance, packName, npcs)
    if not defaultNpcsToMark[instance] then
        defaultNpcsToMark[instance] = {}
    end
    defaultNpcsToMark[instance][packName] = npcs
    table.insert(orderedPacks, {instance = instance, packName = packName})
end

addToDefaultNpcsToMark("Orgrimmar", "org_dummies", {
  ["0xF13000C55326FDD0"] = SKULL,
  ["0xF13000C55226FDCE"] = SQUARE,
  ["0xF13000C55426FE5A"] = CROSS,
})

--/////////////// Naxxramas 纳克萨玛斯 ///////////////

defaultNpcsToMark[L["Naxxramas"]] = {}

--/////////////// 蜘蛛区 ///////////////

addToDefaultNpcsToMark(L["Naxxramas"], "spider_entrance_patrol", {
  ["0xF130003E69269C39"] = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69269C38"] = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69269C37"] = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69269C36"] = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69269C35"] = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69269C34"] = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69269C33"] = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69269C32"] = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69269C05"] = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69269C0F"] = STAR, -- 染疫蜘蛛
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_entrance_right", {
  ["0xF130003E680158F6"]  = SKULL, -- 毒液捕猎者
  ["0xF130003E6601590E"]  = CROSS, -- 恐惧爬行者
  ["0xF130003E6601590F"]  = SQUARE, -- 恐惧爬行者
  ["0xF130003E670158F4"]  = MOON, -- 腐肉织网者
  ["0xF130003E670158F5"]  = TRIANGLE, -- 腐肉织网者
  ["0xF130003E670158F3"]  = DIAMOND, -- 腐肉织网者
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_entrance_left", {
  ["0xF130003E680158F7"]  = SKULL, -- 毒液捕猎者
  ["0xF130003E66015911"]  = CROSS, -- 恐惧爬行者
  ["0xF130003E66015910"]  = SQUARE, -- 恐惧爬行者
  ["0xF130003E670158F9"]  = MOON, -- 腐肉织网者
  ["0xF130003E670158FA"]  = TRIANGLE, -- 腐肉织网者
  ["0xF130003E670158F8"]  = DIAMOND, -- 腐肉织网者
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_anubrekhan_hallway", {
  ["0xF130003E68015917"]  = SKULL, -- 毒液捕猎者
  ["0xF130003E66015912"]  = CROSS, -- 恐惧爬行者
  ["0xF130003E66015913"]  = SQUARE, -- 恐惧爬行者
  ["0xF130003E67015914"]  = MOON, -- 腐肉织网者
  ["0xF130003E67015915"]  = TRIANGLE, -- 腐肉织网者
  ["0xF130003E67015916"]  = DIAMOND, -- 腐肉织网者
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_anubrekhan", {
  ["0xF130003E5401591A"]  = SKULL, -- 阿努布雷坎
  ["0xF1300040BD278C3F"]  = CROSS, -- 地穴卫士
  ["0xF1300040BD278C3E"]  = SQUARE, -- 地穴卫士
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_central_right", {
  ["0xF130003E6A0159DF"]  = SKULL, -- Crypt Reaver
  ["0xF130003E67269C2D"]  = CROSS, -- 腐肉织网者
  ["0xF130003E67269C2C"]  = SQUARE, -- 腐肉织网者
  ["0xF130003E67269C2B"]  = TRIANGLE, -- 腐肉织网者
  ["0xF130003E67269C2A"]  = DIAMOND, -- 腐肉织网者
  ["0xF130003E670159F3"]  = MOON, -- 腐肉织网者
  ["0xF130003E670159F4"]  = CIRCLE, -- 腐肉织网者
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_central_patrol", {
  ["0xF130003E69269C0B"]  = STAR, -- 染疫蜘蛛
  ["0xF130003E69269C0C"]  = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69269C13"]  = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69269C12"]  = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69269C11"]  = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69269C10"]  = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69269C0E"]  = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69269C0D"]  = UNMARKED, -- 染疫蜘蛛
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_necro_1", {
  ["0xF130004045015A20"]  = SKULL, -- 死灵捕猎者
  ["0xF130004045015A1F"]  = CROSS, -- 死灵捕猎者
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_necro_2", {
  ["0xF130004045269C25"]  = SKULL, -- 死灵捕猎者
  ["0xF130004045269C24"]  = CROSS, -- 死灵捕猎者
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_faerlina_patrol", {
  ["0xF130003E69049D6A"]  = STAR, -- 染疫蜘蛛
  ["0xF130003E69049D6B"]  = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69049D6C"]  = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69049D69"]  = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69049D68"]  = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69049D67"]  = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69049D66"]  = UNMARKED, -- 染疫蜘蛛
  ["0xF130003E69049D65"]  = UNMARKED, -- 染疫蜘蛛
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_faerlina_left_1", {
  ["0xF130003E6D269BFD"] = CROSS, -- 纳克萨玛斯侍僧
  ["0xF130003E6C269C02"] = CIRCLE,-- 纳克萨玛斯教徒
  ["0xF130003E6C269BFE"] = TRIANGLE,-- 纳克萨玛斯教徒
  ["0xF130003E6D269C01"] = MOON, -- 纳克萨玛斯侍僧
  ["0xF130003E6C269BFC"] = STAR,-- 纳克萨玛斯教徒
  ["0xF130003E6D269BFB"] = SQUARE, -- 纳克萨玛斯侍僧
  ["0xF130003E6C269C00"] = DIAMOND,-- 纳克萨玛斯教徒
  ["0xF130003E6D269BFF"] = SKULL, -- 纳克萨玛斯侍僧
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_faerlina_left_2", {
  ["0xF130003E6D269BFA"] = MOON, -- 纳克萨玛斯侍僧
  ["0xF130003E6C269BF5"] = CIRCLE, -- 纳克萨玛斯教徒
  ["0xF130003E6C269BF3"] = TRIANGLE,-- 纳克萨玛斯教徒
  ["0xF130003E6C269BF7"] = DIAMOND,-- 纳克萨玛斯教徒
  ["0xF130003E6D269BF8"] = SQUARE, -- 纳克萨玛斯侍僧
  ["0xF130003E6C269BF9"] = STAR,-- 纳克萨玛斯教徒
  ["0xF130003E6D269BF4"] = SKULL, -- 纳克萨玛斯侍僧
  ["0xF130003E6D269BF6"] = CROSS, -- 纳克萨玛斯侍僧
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_faerlina_left_3", {
  ["0xF130003E6C269BDA"] = STAR,-- 纳克萨玛斯教徒
  ["0xF130003E6D269BD9"] = SQUARE, -- 纳克萨玛斯侍僧
  ["0xF130003E6C269BD8"] = DIAMOND,-- 纳克萨玛斯教徒
  ["0xF130003E6D269BD7"] = SKULL, -- 纳克萨玛斯侍僧
  ["0xF130003E6C269BD6"] = CIRCLE,-- 纳克萨玛斯教徒
  ["0xF130003E6D269BD5"] = CROSS, -- 纳克萨玛斯侍僧
  ["0xF130003E6D269BD4"] = MOON, -- 纳克萨玛斯侍僧
  ["0xF130003E6C269BD3"] = TRIANGLE,-- 纳克萨玛斯教徒
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_faerlina_right_1", {
  ["0xF130003E6D269BE2"] = SQUARE, -- 纳克萨玛斯侍僧
  ["0xF130003E6C269BE1"] = DIAMOND,-- 纳克萨玛斯教徒
  ["0xF130003E6D269BE0"] = CROSS, -- 纳克萨玛斯侍僧
  ["0xF130003E6C269BDF"] = TRIANGLE,-- 纳克萨玛斯教徒
  ["0xF130003E6D269BDE"] = MOON, -- 纳克萨玛斯侍僧
  ["0xF130003E6C269BDD"] = CIRCLE,-- 纳克萨玛斯教徒
  ["0xF130003E6C269BDC"] = STAR,-- 纳克萨玛斯教徒
  ["0xF130003E6D269BDB"] = SKULL, -- 纳克萨玛斯侍僧
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_faerlina_right_2", {
  ["0xF130003E6C269BE3"] = CIRCLE,-- 纳克萨玛斯教徒
  ["0xF130003E6C269BE5"] = DIAMOND,-- 纳克萨玛斯教徒
  ["0xF130003E6C269BE7"] = STAR,-- 纳克萨玛斯教徒
  ["0xF130003E6C269BE9"] = TRIANGLE,-- 纳克萨玛斯教徒
  ["0xF130003E6D269BE8"] = CROSS, -- 纳克萨玛斯侍僧
  ["0xF130003E6D269BEA"] = SQUARE, -- 纳克萨玛斯侍僧
  ["0xF130003E6D269BE6"] = MOON, -- 纳克萨玛斯侍僧
  ["0xF130003E6D269BE4"] = SKULL, -- 纳克萨玛斯侍僧
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_faerlina_right_3", {
  ["0xF130003E6D269BED"] = SQUARE, -- 纳克萨玛斯侍僧
  ["0xF130003E6C269BF0"] = DIAMOND, -- 纳克萨玛斯教徒
  ["0xF130003E6D269BF1"] = MOON, -- 纳克萨玛斯侍僧
  ["0xF130003E6C269BF2"] = STAR, -- 纳克萨玛斯教徒
  ["0xF130003E6D269BEB"] = SKULL, -- 纳克萨玛斯侍僧
  ["0xF130003E6C269BEC"] = TRIANGLE, -- 纳克萨玛斯教徒
  ["0xF130003E6D269BEF"] = CROSS, -- 纳克萨玛斯侍僧
  ["0xF130003E6C269BEE"] = CIRCLE, -- 纳克萨玛斯教徒
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_faerlina", {
  ["0xF130003E510159B0"] = TRIANGLE, -- 黑女巫法琳娜
  ["0xF13000407927A7C4"] = CROSS, -- 纳克萨玛斯追随者
  ["0xF13000407927A7C5"] = SKULL, -- 纳克萨玛斯追随者
  ["0xF13000407A27A7C6"] = CIRCLE, -- 纳克萨玛斯膜拜者
  ["0xF13000407A27A7C7"] = SQUARE, -- 纳克萨玛斯膜拜者
  ["0xF13000407A27A7C8"] = MOON, -- 纳克萨玛斯膜拜者
  ["0xF13000407A27A7C9"] = STAR, -- 纳克萨玛斯膜拜者
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_final", {
  ["0xF130003E66269C1A"] = CROSS, -- 恐惧爬行者
  ["0xF130003E66269C18"] = TRIANGLE, -- 恐惧爬行者
  ["0xF130003E66015A2F"] = SQUARE, -- 恐惧爬行者
  ["0xF130003E66269C19"] = MOON, -- 恐惧爬行者
  ["0xF130003E6B01F3EE"] = SKULL, -- 墓穴恐惧蛛魔
})

addToDefaultNpcsToMark(L["Naxxramas"],"spider_ring_ghouls_1", {
  ["0xF13000403F269C03"] = SKULL,
  ["0xF13000403F269C04"] = SQUARE,
  ["0xF13000403F269C06"] = CROSS,
})

addToDefaultNpcsToMark(L["Naxxramas"],"spider_ring_ghouls_2", {
  ["0xF13000403F269BAE"] = SKULL,
  ["0xF13000403F269BAD"] = SQUARE,
  ["0xF13000403F269BAC"] = CROSS,
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_ring_pats", {
  -- addToDefaultNpcsToMark(L["Naxxramas"], "spider_ring_acolyte_1", {
    ["0xF130003FF0015AD7"] = CROSS, -- 墓地侍僧
    ["0xF130003FF0015AD8"] = SKULL, -- 墓地侍僧
  -- })
  -- ["spider_ring_spiders1"] = {
    ["0xF130004045269C07"] = CIRCLE, -- 死灵捕猎者
    ["0xF130004045269C08"] = UNMARKED, -- 死灵捕猎者
  -- },
  -- ["spider_ring_spiders2"] = {
    ["0xF130004045269C09"] = UNMARKED, -- 死灵捕猎者
    ["0xF130004045269C0A"] = STAR, -- 死灵捕猎者
  -- },
  -- ["garg1"] = {
    ["0xF13000403E269C44"] = UNMARKED, -- 疫病石像鬼
    ["0xF13000403E269C45"] = TRIANGLE, -- 疫病石像鬼
  -- },
  -- ["garg2"] = {
    ["0xF13000403E269C43"] = DIAMOND, -- 疫病石像鬼
    ["0xF13000403E015B18"] = UNMARKED, -- 疫病石像鬼
  -- },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_ring_acolyte_2", {
  ["0xF130003FF0015AD5"] = CROSS, -- 墓地侍僧
  ["0xF130003FF0015AD6"] = SKULL, -- 墓地侍僧
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_ring_acolyte_3", {
  ["0xF130003FF0015AD4"]  = SKULL, -- 墓地侍僧
  ["0xF130003FF0015AD3"]  = CROSS, -- 墓地侍僧
})

----/////////////// 军事区 ///////////////

addToDefaultNpcsToMark(L["Naxxramas"], "military_entrance", {
  ["0xF130003F1101594B"]  = SQUARE, -- 死亡骑士队长
  ["0xF130003F1101594C"]  = MOON, -- 死亡骑士队长
  ["0xF130003F1201594A"]  = CROSS, -- 死亡骑士
  ["0xF130003F1A015950"]  = CIRCLE, -- 复活的死亡骑士
  ["0xF130003F1A015951"]  = STAR, -- 复活的死亡骑士
  ["0xF130003F12015949"]  = SKULL, -- 死亡骑士
  ["0xF130003F1A015953"]  = TRIANGLE, -- 复活的死亡骑士
  ["0xF130003F1A015952"]  = DIAMOND, -- 复活的死亡骑士
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_entrance_patrol", {
  ["0xF130003F2401594D"]  = SKULL, -- 纳克萨玛斯之影
  ["0xF130003F2501594F"]  = CROSS, -- 死灵骑士
  ["0xF130003F2501594E"]  = SQUARE, -- 死灵骑士
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_static_1", {
  ["0xF130003F12015967"]  = SKULL, -- 死亡骑士
  ["0xF130003F1C015956"]  = CROSS, -- 黑暗战士
  ["0xF130003F1E015955"]  = SQUARE, -- 亡者战士
  ["0xF130003F11015954"]  = MOON, -- 死亡骑士队长
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_forge_captains", {
  ["0xF130003F11015968"]  = SKULL, -- 死亡骑士队长
  ["0xF130003F11015969"]  = CROSS, -- 死亡骑士队长
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_forge_shade_patrol", {
  ["0xF130003F24015957"]  = STAR, -- 纳克萨玛斯之影
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_forge_shades", {
  ["0xF130003F24015961"]  = SKULL, -- 纳克萨玛斯之影
  ["0xF130003F24015960"]  = CROSS, -- 纳克萨玛斯之影
  ["0xF130003F2501596A"]  = SQUARE, -- 死灵骑士
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_forge_constructs", {
  ["0xF130003F27015962"]  = SKULL, -- 白骨构造体
  ["0xF130003F27015963"]  = CROSS, -- 白骨构造体
  ["0xF130003F27015964"]  = SQUARE, -- 白骨构造体
  ["0xF130003F27015965"]  = MOON, -- 白骨构造体
  ["0xF130003F27015966"]  = TRIANGLE, -- 白骨构造体
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_forge_smiths", {
  ["0xF130003F4101595A"]  = SKULL, -- 骷髅铁匠
  ["0xF130003F41015958"]  = CROSS, -- 骷髅铁匠
  ["0xF130003F41015959"]  = SQUARE, -- 骷髅铁匠
  ["0xF130003F4101595B"]  = MOON, -- 骷髅铁匠
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_static_2", {
  ["0xF130003F1201595E"]  = SKULL, -- 死亡骑士
  ["0xF130003F1201595D"]  = CROSS, -- 死亡骑士
  ["0xF130003F1101595C"]  = SQUARE, -- 死亡骑士队长
  ["0xF130003F1101595F"]  = MOON, -- 死亡骑士队长
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_static_3", {
  ["0xF130003F1201596E"]  = SKULL, -- 死亡骑士
  ["0xF130003F1C01596B"]  = CROSS, -- 黑暗战士
  ["0xF130003F1D01596C"]  = SQUARE, -- 厄运战士
  ["0xF130003F1101596D"]  = MOON, -- 死亡骑士队长
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_upper_patrol", {
  ["0xF130003F12015978"]  = SKULL, -- 死亡骑士
  ["0xF130003F1E01597A"]  = CROSS, -- 亡者战士
  ["0xF130003F1E015979"]  = SQUARE, -- 亡者战士
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_static_4", {
  ["0xF130003F12015973"]  = SKULL, -- 死亡骑士
  ["0xF130003F12015972"]  = CROSS, -- 死亡骑士
  ["0xF130003F1101596F"]  = SQUARE, -- 死亡骑士队长
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_static_5", {
  ["0xF130003F12015975"]  = SKULL, -- 死亡骑士
  ["0xF130003F12015974"]  = CROSS, -- 死亡骑士
  ["0xF130003F11015970"]  = SQUARE, -- 死亡骑士队长
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_static_6", {
  ["0xF130003F12015977"]  = SKULL, -- 死亡骑士
  ["0xF130003F12015976"]  = CROSS, -- 死亡骑士
  ["0xF130003F11015971"]  = SQUARE, -- 死亡骑士队长
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_static_7", {
  ["0xF130003F1201597C"]  = SKULL, -- 死亡骑士
  ["0xF130003F1E01597B"]  = CROSS, -- 亡者战士
  ["0xF130003F1D01597E"]  = SQUARE, -- 厄运战士
  ["0xF130003F1101597D"]  = MOON, -- 死亡骑士队长
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_horse_duo", {
  ["0xF130003F23269C6E"]  = SKULL, -- 死亡骑兵
  ["0xF130003F23269C6D"]  = CROSS, -- 死亡骑兵
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_horse_1", {
  ["0xF130003F2301597F"]  = SKULL, -- 死亡骑兵
  ["0xF130003F1E015982"]  = CROSS, -- 亡者战士
  ["0xF130003F1E015981"]  = SQUARE, -- 亡者战士
  ["0xF130003F1E015989"]  = MOON, -- 亡者战士
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_horse_2", {
  ["0xF130003F23015980"]  = SKULL, -- 死亡骑兵
  ["0xF130003F1C015983"]  = CROSS, -- 黑暗战士
  ["0xF130003F1C015984"]  = SQUARE, -- 黑暗战士
  ["0xF130003F1D015985"]  = MOON, -- 厄运战士
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_horse_3", {
  ["0xF130003F23269C6C"]  = SKULL, -- 死亡骑兵
  ["0xF130003F1C015988"]  = CROSS, -- 黑暗战士
  ["0xF130003F1A015987"]  = SQUARE, -- 复活的死亡骑士
  ["0xF130003F1A015986"]  = MOON, -- 复活的死亡骑士
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_horse_trio", {
  ["0xF1300041DD082208"]  = SKULL, -- 死亡领主
  ["0xF130003F23015992"]  = CROSS, -- 死亡骑兵
  ["0xF130003F23015991"]  = SQUARE, -- 死亡骑兵
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_horse_4", {
  ["0xF130003F23015993"]  = SKULL, -- 死亡骑兵
  ["0xF130003F1C01598A"]  = CROSS, -- 黑暗战士
  ["0xF130003F1C01598B"]  = SQUARE, -- 黑暗战士
  ["0xF130003F1D01598C"]  = MOON, -- 厄运战士
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_razuvious", {
  ["0xF1300041A3278B80"]  = SQUARE, -- 死亡骑士学员, 左远
  ["0xF1300041A3278B7F"]  = MOON, -- 死亡骑士学员, 右远
  ["0xF1300041A3278B82"]  = SKULL, -- 死亡骑士学员, 左近
  ["0xF1300041A3278B81"]  = CROSS, -- 死亡骑士学员, 右近
  ["0xF130003EBD01598C"]  = TRIANGLE, -- 教官拉苏维奥斯
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_weps_1", {
  ["0xF130003F4201F334"]  = SKULL, -- 邪恶之斧
  ["0xF130003F4201F335"]  = CROSS, -- 邪恶之斧
  ["0xF130003F5801F350"]  = SQUARE, -- 邪恶之剑
  ["0xF130003F4201F336"]  = MOON, -- 邪恶之斧
  ["0xF130003F5801F34F"]  = TRIANGLE, -- 邪恶之剑
  ["0xF130003F4201F337"]  = DIAMOND, -- 邪恶之斧
  ["0xF130003F5701F34A"]  = CIRCLE, -- 邪恶法杖
  ["0xF130003F4201F333"]  = STAR, -- 邪恶之斧
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_weps_2", {  
  ["0xF130003F5701F34B"]  = SKULL, -- 邪恶法杖
  ["0xF130003F57269C68"]  = CROSS, -- 邪恶法杖
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_gothik_horses", {
  ["0xF130003F2301599A"]  = SKULL, -- 死亡骑兵
  ["0xF130003F23015999"]  = CROSS, -- 死亡骑兵
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_gothik_shade", {
  ["0xF130003F24015996"]  = SKULL, -- 纳克萨玛斯之影
  ["0xF130003F25015998"]  = CROSS, -- 死灵骑士
  ["0xF130003F25015997"]  = SQUARE, -- 死灵骑士
})

addToDefaultNpcsToMark(L["Naxxramas"], "gothick_ring_ghouls", {
  ["0xF13000403F015B30"] = SQUARE, -- 疫病食尸鬼
  ["0xF13000403F015B33"] = SKULL, -- 疫病食尸鬼
  ["0xF13000403F015B31"] = MOON, -- 疫病食尸鬼
  ["0xF13000403F015B32"] = CROSS, -- 疫病食尸鬼
})

addToDefaultNpcsToMark(L["Naxxramas"], "gothick_ring_horse", {
  ["0xF130004044015ADC"] = SKULL, -- 死灵骑士
  ["0xF130004044015ADD"] = CROSS, -- 死灵骑士
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_ring_acolyte_1", {
  ["0xF130003FF0015AD9"]  = SKULL, -- 墓地侍僧
  ["0xF130003FF0015ADA"]  = CROSS, -- 墓地侍僧
  ["0xF130004043015ADB"]  = DIAMOND, -- 死亡骑士 Vindicator
  ["0xF13000403E015B42"]  = TRIANGLE, -- 疫病石像鬼
  ["0xF13000403E269C6F"]  = UNMARKED, -- 疫病石像鬼
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_ring_acolyte_2", {
  ["0xF130003FF0015ADE"]  = SKULL, -- 墓地侍僧
  ["0xF130003FF0015ADF"]  = CROSS, -- 墓地侍僧
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_ring_ghouls1", {
  ["0xF13000403F015B39"] = SKULL,
  ["0xF13000403F015B3A"] = MOON,
  ["0xF13000403F015B3B"] = SQUARE,
  ["0xF13000403F015B3C"] = CROSS,
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_ring_acolyte_3", {
  ["0xF130003FF0015AE0"]  = SKULL, -- 墓地侍僧
  ["0xF130003FF0015AE1"]  = CROSS, -- 墓地侍僧
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_ring_four_horsemen", {
  ["0xF130003EBE015AB3"]  = SKULL, -- 大领主莫格莱尼
  ["0xF130003EC0015AB0"]  = CROSS, -- 库尔塔兹领主
  ["0xF130003EBF015AB2"]  = SQUARE, -- 瑟里耶克爵士
  ["0xF130003EC1015AB1"]  = MOON, -- 女公爵布劳缪克丝
})

----/////////////// 瘟疫区 ///////////////

addToDefaultNpcsToMark(L["Naxxramas"], "plague_1", {
  ["0xF130003F2801581F"] = CIRCLE, -- 岩肤石像鬼skin Gargoyle (patrol)
  ["0xF130003F74015811"] = SQUARE, -- 会传染的食尸鬼
  ["0xF130003F74015813"] = CROSS, -- 会传染的食尸鬼
  ["0xF130003F74015812"] = SKULL, -- 会传染的食尸鬼
  ["0xF130003F73015810"] = MOON, -- 瘟疫泥浆怪（绿）
  ["0xF130003F7301580F"] = STAR, -- 瘟疫泥浆怪（绿）
})

addToDefaultNpcsToMark(L["Naxxramas"], "plague_2", {
  ["0xF130003F73015817"] = MOON, -- 瘟疫泥浆怪（绿）
  ["0xF130003F73015816"] = STAR, -- 瘟疫泥浆怪
  ["0xF130003F74015814"] = SQUARE, -- 会传染的食尸鬼
  ["0xF130003F74015815"] = CROSS, -- 会传染的食尸鬼
  ["0xF130003F74015818"] = SKULL, -- 会传染的食尸鬼
})

addToDefaultNpcsToMark(L["Naxxramas"], "plague_gargs1_pat", {
  ["0xF130003F2801581E"] = STAR, -- pat
})

addToDefaultNpcsToMark(L["Naxxramas"], "plague_gargs1", {
  ["0xF130003F2801581C"] = SKULL, -- stone1_right
  ["0xF130003F2801581D"] = CROSS,
})

addToDefaultNpcsToMark(L["Naxxramas"], "plague_gargs2", {
  ["0xF130003F28015820"] = SKULL, -- stone2_right
  ["0xF130003F28015821"] = CROSS,
})

addToDefaultNpcsToMark(L["Naxxramas"], "plague_gargs3", {
  ["0xF130003F28015822"] = SKULL, -- stone3_right
  ["0xF130003F28015823"] = CROSS,
})

addToDefaultNpcsToMark(L["Naxxramas"], "plague_ring_ghouls1", {
  ["0xF13000403F015C0C"] = SKULL,
  ["0xF13000403F015C0A"] = CROSS,
  ["0xF13000403F015C0D"] = SQUARE,
  ["0xF13000403F015C0B"] = MOON,
})

addToDefaultNpcsToMark(L["Naxxramas"], "plague_ring_ghouls2", {
  ["0xF13000403F015C0F"] = SKULL,
  ["0xF13000403F015C10"] = CROSS,
  ["0xF13000403F015C11"] = SQUARE,
  ["0xF13000403F015C0E"] = MOON,
})
----/////////////// 构造区 ///////////////

addToDefaultNpcsToMark(L["Naxxramas"], "construct_entrance", {
  ["0xF130003E910158C7"]  = SKULL, -- 缝补傀儡
  ["0xF130003E910158C6"]  = CROSS, -- 缝补傀儡
  ["0xF130003E910158C5"]  = SQUARE, -- 缝补傀儡
  ["0xF130003E910158C8"]  = MOON, -- 缝补傀儡
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_entrance_patrol", {
  ["0xF130003E920158CD"]  = TRIANGLE, -- 胆汁呕吐者
  ["0xF130003E920158CE"]  = DIAMOND, -- 胆汁呕吐者
  ["0xF130003E9D015A90"]  = CIRCLE, -- 淤泥喷射者
  ["0xF130003E9D015A91"]  = STAR, -- 淤泥喷射者
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_central_left", {
  ["0xF130003E920158CF"]  = SKULL, -- 胆汁呕吐者
  ["0xF130003E910158CA"]  = CROSS, -- 缝补傀儡
  ["0xF130003E910158C9"]  = SQUARE, -- 缝补傀儡
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_central_right", {
  ["0xF130003E920158D0"]  = SKULL, -- 胆汁呕吐者
  ["0xF130003E910158CB"]  = CROSS, -- 缝补傀儡
  ["0xF130003E910158CC"]  = SQUARE, -- 缝补傀儡
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_central", {
  ["0xF130003E910158D8"]  = SKULL, -- 缝补傀儡
  ["0xF130003E910158D7"]  = CROSS, -- 缝补傀儡
  ["0xF130003E910158D6"]  = SQUARE, -- 缝补傀儡
  ["0xF130003E910158D9"]  = MOON, -- 缝补傀儡
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_patchwerk_patrol", {
  ["0xF130003E92015A93"]  = SKULL, -- 胆汁呕吐者
  ["0xF130003E92015A8E"]  = TRIANGLE, -- 胆汁呕吐者
  ["0xF130003E9D015A92"]  = CIRCLE, -- 淤泥喷射者
  ["0xF130003E92015A8F"]  = STAR, -- 胆汁呕吐者
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_scientist_1", {
  ["0xF130003E95269C46"] = SKULL, -- 畸形妖
  ["0xF130003E94269C4B"] = MOON, -- 疯狂的科学家
  ["0xF130003E94269C4C"] = SQUARE, -- 疯狂的科学家
  ["0xF130003E94269C4D"] = CROSS, -- 疯狂的科学家
  ["0xF130003E94269C4E"] = DIAMOND, -- 疯狂的科学家
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_scientist_2", {
  ["0xF130003E95269C4F"] = SKULL, -- 畸形妖
  ["0xF130003E94015AA1"] = MOON, -- 疯狂的科学家
  ["0xF130003E94015AA0"] = SQUARE, -- 疯狂的科学家
  ["0xF130003E94015A9F"] = CROSS, -- 疯狂的科学家
  ["0xF130003E94015A9E"] = DIAMOND, -- 疯狂的科学家
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_patchwerk", {
  ["0xF130003E91015A96"]  = SKULL, -- 缝补傀儡
  ["0xF130003E91015A94"]  = CROSS, -- 缝补傀儡
  ["0xF130003E91015A97"]  = SQUARE, -- 缝补傀儡
  ["0xF130003E91015A95"]  = MOON, -- 缝补傀儡
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_scientist_3", {
  ["0xF130003E95269C54"] = SKULL, -- 畸形妖
  ["0xF130003E94269C5C"] = MOON, -- 疯狂的科学家
  ["0xF130003E94269C5B"] = SQUARE, -- 疯狂的科学家
  ["0xF130003E94269C59"] = CROSS, -- 疯狂的科学家
  ["0xF130003E94269C5A"] = DIAMOND, -- 疯狂的科学家
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_scientist_4", {
  ["0xF130003E95269C5D"]  = SKULL, -- 畸形妖
  ["0xF130003E94269C61"]  = MOON, -- 疯狂的科学家
  ["0xF130003E94269C60"]  = SQUARE, -- 疯狂的科学家
  ["0xF130003E94269C5F"]  = CROSS, -- 疯狂的科学家
  ["0xF130003E94269C5E"]  = DIAMOND, -- 疯狂的科学家
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_scientist_5", {
  ["0xF130003E95269C66"] = SKULL, -- 畸形妖
  ["0xF130003E94015A85"] = MOON, -- 疯狂的科学家
  ["0xF130003E94015A86"] = SQUARE, -- 疯狂的科学家
  ["0xF130003E94015A87"] = CROSS, -- 疯狂的科学家
  ["0xF130003E94015A88"] = DIAMOND, -- 疯狂的科学家
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_grobb_entrance", {
  ["0xF130003E990158F2"]  = SKULL, -- 缝合喷吐者
  ["0xF130003E990158F1"]  = CROSS, -- 缝合喷吐者
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_grobb_left", {
  ["0xF130003E990158EC"]  = SKULL, -- 缝合喷吐者
  ["0xF130003E990158EB"]  = CROSS, -- 缝合喷吐者
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_grobb_far", {
  ["0xF130003E990158ED"]  = SKULL, -- 缝合喷吐者
  ["0xF130003E99269D08"]  = CROSS, -- 缝合喷吐者 -- is this changing weekly?
  ["0xF130003E990158EE"]  = SQUARE, -- 缝合喷吐者
})

--/////////////// AQ40 安其拉 ///////////////

defaultNpcsToMark[L["Ahn'Qiraj"]] = {}

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "entrance_1", {
  ["0xF130003BA0015613"]  = SKULL, -- 阿努比萨斯哨兵
  ["0xF130003BA0015610"]  = MOON, -- 阿努比萨斯哨兵
  ["0xF130003BA0015611"]  = SQUARE, -- 阿努比萨斯哨兵
  ["0xF130003BA0015612"]  = CROSS, -- 阿努比萨斯哨兵
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "entrance_2", {
  ["0xF130003BA001560C"]  = SKULL, -- 阿努比萨斯哨兵
  ["0xF130003BA001560D"]  = CROSS, -- 阿努比萨斯哨兵
  ["0xF130003BA001560F"]  = MOON, -- 阿努比萨斯哨兵
  ["0xF130003BA001560E"]  = SQUARE, -- 阿努比萨斯哨兵
})
addToDefaultNpcsToMark(L["Ahn'Qiraj"], "entrance_patrols", {
  ["0xF130003B9E130799"] = STAR, -- 黑曜石清除者
  ["0xF130003B9E01580A"] = TRIANGLE, -- 黑曜石清除者
  ["0xF130003B9E13079A"] = DIAMOND, -- 黑曜石清除者
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "skeram", {
  ["0xF130003B9F01580B"]  = SQUARE, -- 预言者斯克拉姆
  ["0xF130003B9F04A65A"]  = CROSS, -- Clone
  ["0xF130003B9F04A659"]  = SKULL, -- Clone
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "brainwasher_1", {
  ["0xF130003B8F01562D"] = SKULL, -- 其拉洗脑者
  ["0xF130003B8101562C"] = SQUARE, -- 维克尼斯守护者
  ["0xF130003B8101562B"] = CROSS, -- 维克尼斯守护者
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "warrior_1", {
  ["0xF130003B7E01567A"] = TRIANGLE, -- 维克尼战士
  ["0xF130003B7E015679"] = UNMARKED, -- 维克尼战士
  ["0xF130003B7E015678"] = UNMARKED, -- 维克尼战士
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "brainwasher_2", {
  ["0xF130003B81015630"]  = MOON, -- 维克尼斯守护者
  ["0xF130003B8101562F"]  = SQUARE, -- 维克尼斯守护者
  ["0xF130003B81015677"]  = CROSS, -- 维克尼斯守护者
  ["0xF130003B8F01562E"]  = SKULL, -- 其拉洗脑者
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "brainwasher_left", {
  ["0xF130003B8101563A"]  = SQUARE, -- 维克尼斯守护者
  ["0xF130003B8F015636"]  = CROSS, -- 其拉洗脑者
  ["0xF130003B81015639"]  = MOON, -- 维克尼斯守护者
  ["0xF130003B81015638"]  = TRIANGLE, -- 维克尼斯守护者
  ["0xF130003B8F015637"]  = SKULL, -- 其拉洗脑者
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "brainwasher_right", {
  ["0xF130003B8101563C"]  = MOON, -- 维克尼斯守护者
  ["0xF130003B8F015634"]  = SKULL, -- 其拉洗脑者
  ["0xF130003B8101563D"]  = TRIANGLE, -- 维克尼斯守护者
  ["0xF130003B8101563B"]  = SQUARE, -- 维克尼斯守护者
  ["0xF130003B8F015635"]  = CROSS, -- 其拉洗脑者
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "warrior_2", {
  ["0xF130003B7E049CA2"]  = STAR, -- 维克尼战士
  ["0xF130003B7E049CA4"]  = UNMARKED, -- 维克尼战士
  ["0xF130003B7E049CA3"]  = UNMARKED, -- 维克尼战士
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "guardian_1", {
  ["0xF130003B81015644"]  = SQUARE, -- 维克尼斯守护者
  ["0xF130003B81015645"]  = DIAMOND, -- 维克尼斯守护者
  ["0xF130003B8113079F"]  = CROSS, -- 维克尼斯守护者
  ["0xF130003B81015642"]  = SKULL, -- 维克尼斯守护者
  ["0xF130003B81015643"]  = MOON, -- 维克尼斯守护者
  ["0xF130003B81015641"]  = TRIANGLE, -- 维克尼斯守护者
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "guardian_2", {
  ["0xF130003B81015648"]  = CROSS, -- 维克尼斯守护者
  ["0xF130003B81015649"]  = TRIANGLE, -- 维克尼斯守护者
  ["0xF130003B81015647"]  = SQUARE, -- 维克尼斯守护者
  ["0xF130003B8101564A"]  = MOON, -- 维克尼斯守护者
  ["0xF130003B81015646"]  = DIAMOND, -- 维克尼斯守护者
  ["0xF130003B8101564B"]  = SKULL, -- 维克尼斯守护者
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "guardian_3", {
  ["0xF130003B8101564E"]  = SQUARE, -- 维克尼斯守护者
  ["0xF130003B8101564F"]  = SKULL, -- 维克尼斯守护者
  ["0xF130003B8101564C"]  = CROSS, -- 维克尼斯守护者
  ["0xF130003B81015650"]  = DIAMOND, -- 维克尼斯守护者
  ["0xF130003B8101564D"]  = TRIANGLE, -- 维克尼斯守护者
  ["0xF130003B81015651"]  = MOON, -- 维克尼斯守护者
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "guardian_4", {
  ["0xF130003B8101565B"]  = TRIANGLE, -- 维克尼斯守护者
  ["0xF130003B81015657"]  = CROSS, -- 维克尼斯守护者
  ["0xF130003B8101565A"]  = DIAMOND, -- 维克尼斯守护者
  ["0xF130003B81015658"]  = SQUARE, -- 维克尼斯守护者
  ["0xF130003B8101565C"]  = MOON, -- 维克尼斯守护者
  ["0xF130003B81015659"]  = SKULL, -- 维克尼斯守护者
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "sartura", {
  ["0xF130003E70015662"]  = CROSS, -- 沙尔图拉皇家卫士
  ["0xF130003E70015661"]  = SQUARE, -- 沙尔图拉皇家卫士
  ["0xF130003E70015663"]  = MOON, -- 沙尔图拉皇家卫士
  ["0xF130003C9C015660"]  = SKULL, -- 沙尔图拉
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "soldiers", {
  ["0xF130003B7D015762"]  = SKULL, -- 维克尼斯士兵
  ["0xF130003B7D01575D"]  = TRIANGLE, -- 维克尼斯士兵
  ["0xF130003B7D01575F"]  = SQUARE, -- 维克尼斯士兵
  ["0xF130003B7D015760"]  = CROSS, -- 维克尼斯士兵
  ["0xF130003B7D01575E"]  = MOON, -- 维克尼斯士兵
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "scorpions", {
  ["0xF130003B88015798"]  = SKULL, -- 维克尼斯爬行者
  ["0xF130003B88015799"]  = CROSS, -- 维克尼斯爬行者
  ["0xF130003B881307A3"]  = MOON, -- 维克尼斯爬行者
  ["0xF130003B881307A4"]  = SQUARE, -- 维克尼斯爬行者
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "scorpions2", {
  ["0xF130003B8801578E"]  = SKULL, -- 维克尼斯爬行者
  ["0xF130003B8801578F"]  = CROSS, -- 维克尼斯爬行者
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "lashers", {
  ["0xF130003B830157CD"]  = CIRCLE, -- 维克尼斯鞭笞者
  ["0xF130003B910157BF"]  = MOON, -- 其拉怒刺蜂
  ["0xF130003B910157C3"]  = CROSS, -- 其拉怒刺蜂
  ["0xF130003B910157C0"]  = UNMARKED, -- 维克尼斯黄蜂
  ["0xF130003B910157C1"]  = UNMARKED, -- 维克尼斯黄蜂
  ["0xF130003B910157C2"]  = SQUARE, -- 其拉怒刺蜂
  ["0xF130003B910157C8"]  = SKULL, -- 其拉怒刺蜂
  ["0xF130003B910157BC"]  = TRIANGLE, -- 其拉怒刺蜂
  ["0xF130003B830157B6"]  = DIAMOND, -- 维克尼斯鞭笞者
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "defenders", {
  ["0xF130003BAD0157CF"] = SKULL, -- 阿努比萨斯防御者
  ["0xF130003BAD0157D1"] = CROSS, -- 阿努比萨斯防御者
  ["0xF130003BAD0157D2"] = SQUARE, -- 阿努比萨斯防御者
  ["0xF130003BAD0157D0"] = MOON, -- 阿努比萨斯防御者
  ["0xF130003BAD0157D3"] = TRIANGLE, -- 阿努比萨斯防御者
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "champions", {
  ["0xF130003B940157E7"] = SQUARE, -- 其拉勇士
  ["0xF130003B940157E5"] = DIAMOND, -- 其拉勇士
  ["0xF130003B940157E6"] = CIRCLE, -- 其拉勇士
  ["0xF130003B940157F9"] = CROSS, -- 其拉勇士
  ["0xF130003B940157E4"] = MOON, -- 其拉勇士
  ["0xF130003B940157FA"] = TRIANGLE, -- 其拉勇士
  ["0xF130003B940157E3"] = SKULL, -- 其拉勇士
  ["0xF130003B940157DE"] = STAR, -- 其拉勇士
})

--/////////////// ZG 祖尔格拉布///////////////

defaultNpcsToMark[L["Zul'Gurub"]] = {}

--/////////////// Entrance to Jindo ///////////////

addToDefaultNpcsToMark(L["Zul'Gurub"], "entrance_snakes_left_1", {
  ["0xF130002C6C00BFC2"] = SKULL, -- 拉札什奎蛇
  ["0xF130002C6B00BFC3"] = CROSS, -- 拉扎什毒蛇
})
addToDefaultNpcsToMark(L["Zul'Gurub"], "entrance_priest_left", {
  ["0xF130002E3600BFDB"] = SKULL, -- 哈卡莱祭司
  ["0xF130002C5600BFDA"] = MOON, -- 古拉巴什掷斧者
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "jindo_entrance_patrols", {
  ["0xF1300039E911E65A"] = UNMARKED, -- Withered Mistress
  ["0xF130002E36016542"] = DIAMOND, -- 哈卡莱祭司
  ["0xF1300039E911E65D"] = STAR, -- Withered Mistress
  ["0xF130002C5800CAEC"] = SKULL, -- 古拉巴什狂暴者
  ["0xF1300039E911E65C"] = UNMARKED, -- Withered Mistress
  ["0xF1300039E911E65B"] = UNMARKED, -- Withered Mistress
  ["0xF130002C57016541"] = TRIANGLE, -- 古拉巴什猎头者
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "jindo_misress_1_patrol", {
  ["0xF1300039E911E657"] = STAR, -- Withered Mistress
  ["0xF1300039E900C0F6"] = UNMARKED, -- Withered Mistress
  ["0xF1300039E900C0F5"] = UNMARKED, -- Withered Mistress
  ["0xF1300039E911E658"] = UNMARKED, -- Withered Mistress
  ["0xF1300039E911E659"] = UNMARKED, -- Withered Mistress
  ["0xF130003A2200C0F7"] = UNMARKED, -- Atal'ai Mistress
  ["0xF1300039E911E656"] = UNMARKED, -- Withered Mistress
  ["0xF130003A2200C0F8"] = UNMARKED, -- Atal'ai Mistress
  ["0xF130003A2200C1A8"] = DIAMOND, -- Atal'ai Mistress
  ["0xF130003A2200C1A9"] = CIRCLE, -- Atal'ai Mistress
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "jindo_mistress_2", {
  ["0xF130003A2300C0DB"] = MOON, -- Voodoo Slave
  ["0xF1300039E900C0D5"] = UNMARKED, -- Withered Mistress
  ["0xF1300039E900C0D6"] = UNMARKED, -- Withered Mistress
  ["0xF130003A2300C0DA"] = SKULL, -- Voodoo Slave
  ["0xF130003A2200C0D8"] = UNMARKED, -- Atal'ai Mistress
  ["0xF130003A2200C0D9"] = UNMARKED, -- Atal'ai Mistress
  ["0xF130003A2300C0DC"] = SQUARE, -- Voodoo Slave
  ["0xF1300039E900C0D3"] = UNMARKED, -- Withered Mistress
  ["0xF130003A2200C0D7"] = UNMARKED, -- Atal'ai Mistress
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "jindo_boss_pack", {
  ["0xF1300039E900C1A5"] = UNMARKED, -- Withered Mistress
  ["0xF1300039E900C0FA"] = UNMARKED, -- Withered Mistress
  ["0xF130003A2200C1A7"] = UNMARKED, -- Atal'ai Mistress
  ["0xF130002C7400C1F7"] = SKULL, -- Jin'do the Hexxer
  ["0xF1300039E900C0FB"] = UNMARKED, -- Withered Mistress
  ["0xF130003A2200C1A8"] = DIAMOND, -- Atal'ai Mistress
  ["0xF130003A2200C1A9"] = CIRCLE, -- Atal'ai Mistress
  ["0xF1300039E900C10D"] = UNMARKED, -- Withered Mistress
  ["0xF130003A2300C1F2"] = SQUARE, -- Voodoo Slave
  ["0xF130003A2200C1A6"] = UNMARKED, -- Atal'ai Mistress
  ["0xF130003A2300C1C9"] = MOON, -- Voodoo Slave
})

--/////////////// Marli(Bat) ///////////////

addToDefaultNpcsToMark(L["Zul'Gurub"], "hill_bottom_priest", {
  ["0xF130002C6B00BFC9"] = UNMARKED, -- 拉扎什毒蛇
  ["0xF130002C6C00BFC8"] = UNMARKED, -- 拉札什奎蛇
  ["0xF130002E3600C25A"] = SKULL, -- 哈卡莱祭司
  ["0xF130002C5800C261"] = STAR, -- 古拉巴什狂暴者
  ["0xF130002C5600C259"] = CROSS, -- 古拉巴什掷斧者
})

bat1= {}
bat1["bat_one_rider_1"] = {
  ["0xF13000399E00BFFB"] = STAR, -- 古拉巴什蝙蝠骑士
  ["0xF130002C6800BFF7"] = UNMARKED, -- 觅血蝙蝠
  ["0xF130002C6800BFF9"] = UNMARKED, -- 觅血蝙蝠
  ["0xF130002C6800BFF8"] = UNMARKED, -- 觅血蝙蝠
  ["0xF130002C6800BFFA"] = UNMARKED, -- 觅血蝙蝠
}
bat1["bat_one_rider_2"] = {
  ["0xF130002C6800C024"] = UNMARKED, -- 觅血蝙蝠
  ["0xF130002C6800C023"] = UNMARKED, -- 觅血蝙蝠
  ["0xF130002C6800BFFF"] = UNMARKED, -- 觅血蝙蝠
  ["0xF130002C6800C001"] = UNMARKED, -- 觅血蝙蝠
  ["0xF13000399E00C025"] = TRIANGLE, -- 古拉巴什蝙蝠骑士
}
bat1["bat_two_rider_1"] = {
  ["0xF130002C6800C004"] = UNMARKED, -- 觅血蝙蝠
  ["0xF130002C6800C009"] = UNMARKED, -- 觅血蝙蝠
  ["0xF13000399E00C003"] = CIRCLE, -- 古拉巴什蝙蝠骑士
  ["0xF130002C6800C007"] = UNMARKED, -- 觅血蝙蝠
  ["0xF130002C6800BFFE"] = UNMARKED, -- 觅血蝙蝠
  ["0xF13000399E00C002"] = DIAMOND, -- 古拉巴什蝙蝠骑士
}
bat1["bat_headhunter_1"] = {
  ["0xF130002E3700BFF0"] = SQUARE, -- 哈卡莱巫医
  ["0xF130002C5700BFEE"] = CROSS, -- 古拉巴什猎头者
  ["0xF130002C5700BFEF"] = SKULL, -- 古拉巴什猎头者
}

local cbat = {}
for _,pack in pairs(bat1) do
  for guid,mark in pairs(pack) do
    cbat[guid] = mark
  end
end
addToDefaultNpcsToMark(L["Zul'Gurub"], "consolidated_bat_1", cbat)

bat2 = {}
bat2["bat_two_rider_rtv"] = {
  ["0xF130002C6800BFF2"] = UNMARKED, -- 觅血蝙蝠
  ["0xF130002C6800BFF3"] = UNMARKED, -- 觅血蝙蝠
  ["0xF13000399E00BFF5"] = MOON, -- 古拉巴什蝙蝠骑士
  ["0xF13000399E00BFF6"] = SQUARE, -- 古拉巴什蝙蝠骑士
  ["0xF130002C6800BFF1"] = UNMARKED, -- 觅血蝙蝠
}
bat2["bat_two_rider_2"] = {
  ["0xF130002C6800BFE8"] = UNMARKED, -- 觅血蝙蝠
  ["0xF130002C6800BFE7"] = UNMARKED, -- 觅血蝙蝠
  ["0xF130002C6800BFE3"] = UNMARKED, -- 觅血蝙蝠
  ["0xF130002C6800BFE5"] = UNMARKED, -- 觅血蝙蝠
  ["0xF130002C6800BFE4"] = UNMARKED, -- 觅血蝙蝠
  ["0xF13000399E00BFEA"] = CIRCLE, -- 古拉巴什蝙蝠骑士
  ["0xF13000399E00BFE9"] = DIAMOND, -- 古拉巴什蝙蝠骑士
}
bat2["bat_two_rider_3"] = {
  ["0xF130002C6800BFF4"] = UNMARKED, -- 觅血蝙蝠
  ["0xF130002C6800C022"] = UNMARKED, -- 觅血蝙蝠
  ["0xF13000399E00C021"] = STAR, -- 古拉巴什蝙蝠骑士
  ["0xF130002C6800C006"] = UNMARKED, -- 觅血蝙蝠
  ["0xF13000399E00C00F"] = TRIANGLE, -- 古拉巴什蝙蝠骑士
  ["0xF130002C6800C005"] = UNMARKED, -- 觅血蝙蝠
}
bat2["bat_headhunter_2"] = {
  ["0xF130002C5700BFED"] = SKULL, -- 古拉巴什猎头者
  ["0xF130002E3700BFEB"] = CROSS, -- 哈卡莱巫医
  ["0xF130002E3700BFEC"] = SQUARE, -- 哈卡莱巫医
}

local cbat = {}
for _,pack in pairs(bat2) do
  for guid,mark in pairs(pack) do
    cbat[guid] = mark
  end
end
addToDefaultNpcsToMark(L["Zul'Gurub"], "consolidated_bat_2", cbat)


--/////////////// Venoxis ///////////////

addToDefaultNpcsToMark(L["Zul'Gurub"], "venoxis_two_axethrower", {
  ["0xF130002C5600BFD1"] = MOON, -- 古拉巴什掷斧者
  ["0xF130002C5600BFD0"] = SKULL, -- 古拉巴什掷斧者
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "venoxis_priest_pat", {
  ["0xF130002C6C00C8FB"] = UNMARKED, -- 拉札什奎蛇
  ["0xF130002E3600C258"] = SKULL, -- 哈卡莱祭司
  ["0xF130002C6B00C8FC"] = UNMARKED, -- 拉扎什毒蛇
  ["0xF130002C5600C257"] = MOON, -- 古拉巴什掷斧者
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "venoxis_room", {
  ["0xF130002C5600C248"] = MOON, -- 古拉巴什掷斧者
  ["0xF130002C6C00BFCB"] = UNMARKED, -- 拉札什奎蛇
  ["0xF130002C6C00BFD3"] = UNMARKED, -- 拉札什奎蛇
  ["0xF130002E3600C249"] = SKULL, -- 哈卡莱祭司
  ["0xF130002C6C00BFCC"] = UNMARKED, -- 拉札什奎蛇
  ["0xF130002C6B00BFD7"] = UNMARKED, -- 拉扎什毒蛇
  ["0xF130002C6B00BFD9"] = UNMARKED, -- 拉扎什毒蛇
  ["0xF130002C6C00BFD2"] = UNMARKED, -- 拉札什奎蛇
  ["0xF130002C6C00BFD6"] = UNMARKED, -- 拉札什奎蛇
  ["0xF130002C6B00BFCD"] = UNMARKED, -- 拉扎什毒蛇
  ["0xF130002C7B00C24A"] = UNMARKED, -- 沙怒部族演讲者
  ["0xF130002C6B00BFD8"] = UNMARKED, -- 拉扎什毒蛇
  ["0xF130002C6C00BFCA"] = UNMARKED, -- 拉札什奎蛇
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "venoxis_exit_snake_1", {
  ["0xF130002C6B00C250"] = UNMARKED, -- 拉扎什毒蛇
  ["0xF130002C6B00C251"] = UNMARKED, -- 拉扎什毒蛇
  ["0xF130002C6C00C252"] = SKULL, -- 拉札什奎蛇
  ["0xF130002C6B00C24F"] = UNMARKED, -- 拉扎什毒蛇
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "venoxis_exit_snake_2", {
  ["0xF130002C6C00BFC7"] = SKULL, -- 拉札什奎蛇
  ["0xF130002C6B00BFC6"] = UNMARKED, -- 拉扎什毒蛇
  ["0xF130002C6B00BFC5"] = UNMARKED, -- 拉扎什毒蛇
  ["0xF130002C6B00BFC4"] = UNMARKED, -- 拉扎什毒蛇
})

--/////////////// Mandokir //////////////

addToDefaultNpcsToMark(L["Zul'Gurub"], "zanza_tower_zerks", {
  ["0xF130002C5800CAFA"] = TRIANGLE, -- 古拉巴什狂暴者
  ["0xF130002C5800CAEB"] = DIAMOND, -- 古拉巴什狂暴者
  ["0xF130002C58016565"] = CIRCLE, -- 古拉巴什狂暴者
  ["0xF130002C5800C222"] = STAR, -- 古拉巴什狂暴者
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "mandokir_entrance_and_zerk", {
  ["0xF130002E3600C278"] = SKULL, -- 哈卡莱祭司
  ["0xF130002C5900C280"] = UNMARKED, -- 古拉巴什饮血者
  ["0xF130002C5900C27F"] = SQUARE, -- 古拉巴什饮血者
  ["0xF130002C5900C271"] = UNMARKED, -- 古拉巴什饮血者
  ["0xF130002E3600C279"] = CROSS, -- 哈卡莱祭司
  ["0xF130002C5900C270"] = MOON, -- 古拉巴什饮血者
  ["0xF130002C5800C229"] = STAR, -- 古拉巴什狂暴者
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "mandokir_room", {
  ["0xF130002E3600C287"] = SKULL, -- 哈卡莱祭司
  ["0xF130002C5900C285"] = MOON, -- 古拉巴什饮血者
  ["0xF130002C5C00C282"] = STAR, -- 古拉巴什勇士
  ["0xF130002C5C00C283"] = UNMARKED, -- 古拉巴什勇士
  ["0xF130002C5C00C281"] = UNMARKED, -- 古拉巴什勇士
  ["0xF130002C5C00CB5B"] = UNMARKED, -- 古拉巴什勇士
  ["0xF130002C5C00C284"] = UNMARKED, -- 古拉巴什勇士
  ["0xF130002C5C00CB88"] = UNMARKED, -- 古拉巴什勇士

  -- to mark room easier
  ["0xF1300039E500C974"] = UNMARKED, -- 拉札什迅猛龙
  ["0xF1300039E500CB00"] = UNMARKED, -- 拉札什迅猛龙
  ["0xF1300039E500C972"] = UNMARKED, -- 拉札什迅猛龙
  ["0xF1300039E500C973"] = UNMARKED, -- 拉札什迅猛龙
  ["0xF1300039E500CAFF"] = UNMARKED, -- 拉札什迅猛龙
  ["0xF1300039E500CB01"] = UNMARKED, -- 拉札什迅猛龙
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "zanaz_witchdoctor_rtv", {
  ["0xF130002C6100CAF2"] = UNMARKED, -- 祖利安猛虎
  ["0xF130002E37016557"] = SKULL, -- 哈卡莱巫医
  ["0xF130002C6100CAF1"] = UNMARKED, -- 祖利安猛虎
  ["0xF130002C56016556"] = MOON, -- 古拉巴什掷斧者
})

--/////////////// Madness /////////////

addToDefaultNpcsToMark(L["Zul'Gurub"], "madness1", {
  ["0xF130003B0700BFA4"] = DIAMOND, -- 疯狂仆从
  ["0xF130003B0700BFA3"] = SKULL, -- 疯狂仆从
  ["0xF130003B0700BFA5"] = CROSS, -- 疯狂仆从
  ["0xF130000B6200BF8D"] = UNMARKED, -- Snake
  ["0xF130003B0700BFA0"] = CIRCLE, -- 疯狂仆从
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "madness2", {
  ["0xF130003B0700BF9F"] = DIAMOND, -- 疯狂仆从
  ["0xF130003B0700BFA1"] = CROSS, -- 疯狂仆从
  ["0xF130003B0700BF9D"] = SKULL, -- 疯狂仆从
  ["0xF130003B0700BF9E"] = TRIANGLE, -- 疯狂仆从
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "madness3", {
  ["0xF130003B0700BFAA"] = CROSS, -- 疯狂仆从
  ["0xF130003B0700BFA9"] = DIAMOND, -- 疯狂仆从
  ["0xF130003B0700BFAB"] = TRIANGLE, -- 疯狂仆从
  ["0xF130002C4C00BF9B"] = SKULL, -- 哈卡莱鲜血祭司
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "madness4", {
  ["0xF130002C4C00BF9C"] = SKULL, -- 哈卡莱鲜血祭司
  ["0xF130003B0700BFA8"] = DIAMOND, -- 疯狂仆从
  ["0xF130003B0700BFA6"] = TRIANGLE, -- 疯狂仆从
  ["0xF130003B0700BFA7"] = CROSS, -- 疯狂仆从
})

--/////////////// Thekal //////////////

addToDefaultNpcsToMark(L["Zul'Gurub"], "thekal_pack", {
  ["0xF13000390700C09E"] = DIAMOND, -- 高阶祭司塞卡尔
  ["0xF130002C5300C0A2"] = SQUARE, -- 狂热者洛卡恩
  ["0xF130002C5400C0A1"] = TRIANGLE, -- 狂热者札斯

  -- to mark thekal easier
  ["0xF130002C6100C08D"] = UNMARKED, -- 祖利安猛虎
  ["0xF130002C6100C08A"] = UNMARKED, -- 祖利安猛虎
  ["0xF130002C6100C089"] = UNMARKED, -- 祖利安猛虎
  ["0xF130002C6100C08E"] = UNMARKED, -- 祖利安猛虎
  ["0xF130002C6100C08C"] = UNMARKED, -- 祖利安猛虎
  ["0xF130002C6100C08B"] = UNMARKED, -- 祖利安猛虎
  ["0xF130002C6000C09A"] = UNMARKED, -- 祖利安幼虎
  ["0xF130002C6000C098"] = UNMARKED, -- 祖利安幼虎
  ["0xF130002C6000C97C"] = UNMARKED, -- 祖利安幼虎
  ["0xF130002C6000C97D"] = UNMARKED, -- 祖利安幼虎
  ["0xF130002C6000C288"] = UNMARKED, -- 祖利安幼虎
  ["0xF130002C6000C292"] = UNMARKED, -- 祖利安幼虎
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "gaz_fish", {
  ["0xF130002C6E00C242"] = TRIANGLE, -- 眼镜王蛇
  ["0xF130002C6E00BFAD"] = CIRCLE, -- 眼镜王蛇
  ["0xF130002C6E00C8F4"] = DIAMOND, -- 眼镜王蛇
  ["0xF130002C6E00C23E"] = STAR, -- 眼镜王蛇
  ["0xF130002C6E00BFAF"] = CROSS, -- 眼镜王蛇

  -- to mark fish easier
  ["0xF130003AC300C22C"] = UNMARKED, -- 祖利安鳄鱼
  ["0xF130003AC300C22D"] = UNMARKED, -- 祖利安鳄鱼
  ["0xF130003AC300C22B"] = SKULL, -- 祖利安鳄鱼
  ["0xF130003AC300C22A"] = UNMARKED, -- 祖利安鳄鱼

})

addToDefaultNpcsToMark(L["Zul'Gurub"], "thekal_zerk_panther", {
  ["0xF130002C5801652B"] = STAR, -- 古拉巴什狂暴者
  ["0xF130002C6500C0A6"] = UNMARKED, -- 祖利安雌猎虎
  ["0xF130002C6500C0A7"] = UNMARKED, -- 祖利安雌猎虎
  ["0xF130002C6500C0A8"] = CIRCLE, -- 祖利安雌猎虎
})

--/////////////// Arlok ///////////////

addToDefaultNpcsToMark(L["Zul'Gurub"], "arlok_1", {
  ["0xF130002C4B00C899"] = UNMARKED, -- 哈卡莱暗影猎手
  ["0xF130002C4B00C8A4"] = SKULL, -- 哈卡莱暗影猎手
  ["0xF130002C4B00C89A"] = CROSS, -- 哈卡莱暗影猎手
  ["0xF130002C4B00C8A3"] = UNMARKED, -- 哈卡莱暗影猎手
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "arlok_2", {
  ["0xF130002C6500C0C2"] = UNMARKED, -- 祖利安雌猎虎
  ["0xF130002C6500C0C1"] = UNMARKED, -- 祖利安雌猎虎
  ["0xF130002C5900C98B"] = MOON, -- 古拉巴什饮血者
  ["0xF130002C5900C98A"] = SQUARE, -- 古拉巴什饮血者
  ["0xF130002C6500C0C0"] = UNMARKED, -- 祖利安雌猎虎
  ["0xF130002C6500C0BF"] = SKULL, -- 祖利安雌猎虎
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "arlok_3", {
  ["0xF130002C6500C0BD"] = UNMARKED, -- 祖利安雌猎虎
  ["0xF130002C6500C0BE"] = SKULL, -- 祖利安雌猎虎
  ["0xF130002C4B00C0B1"] = TRIANGLE, -- 哈卡莱暗影猎手
  ["0xF130002C6500C0BB"] = UNMARKED, -- 祖利安雌猎虎
  ["0xF130002C6500C0BC"] = UNMARKED, -- 祖利安雌猎虎
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "arlok_4", {
  ["0xF130002C6500C8B7"] = UNMARKED, -- 祖利安雌猎虎
  ["0xF130002C6500C8B5"] = SKULL, -- 祖利安雌猎虎
  ["0xF130002C6500C8AF"] = UNMARKED, -- 祖利安雌猎虎
  ["0xF130002C4B00C8A5"] = DIAMOND, -- 哈卡莱暗影猎手
  ["0xF130002C6500C8B6"] = UNMARKED, -- 祖利安雌猎虎
  ["0xF130002C4B00C8A6"] = TRIANGLE, -- 哈卡莱暗影猎手
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "arlokk", {
  ["0xF1300038B3276EF0"] = CIRCLE,
})

--/////////////// Hakkar ///////////////

addToDefaultNpcsToMark(L["Zul'Gurub"], "hakkar_bottom", {
  ["0xF130003AC300C231"] = CROSS, -- 祖利安鳄鱼
  ["0xF130002C5800C8C3"] = STAR, -- 古拉巴什狂暴者
  ["0xF130002C5800C8C4"] = SKULL, -- 古拉巴什狂暴者
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "hakkar_sons", {
  ["0xF130002C5D00BF8A"] = DIAMOND, -- 哈卡之子
  ["0xF130002C5D00BF89"] = CIRCLE, -- 哈卡之子
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "hakkar_soulflayer_1", {
  ["0xF130002C5F00C8E0"] = MOON, -- 灵魂掠夺者
  ["0xF130002C5D00C8E2"] = SKULL, -- 哈卡之子
  ["0xF130002C5D00C8E1"] = CROSS, -- 哈卡之子
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "hakkar_soulflayer_2", {
  ["0xF130002C5D00C8E4"] = CROSS, -- 哈卡之子
  ["0xF130002C5D00C8E5"] = SKULL, -- 哈卡之子
  ["0xF130002C5F00C8E3"] = MOON, -- 灵魂掠夺者
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "hakkar_large_1", {
  ["0xF130002C5F00C8D7"] = MOON, -- 灵魂掠夺者
  ["0xF130002C5800C204"] = UNMARKED, -- 古拉巴什狂暴者
  ["0xF130002E3600C8D6"] = SKULL, -- 哈卡莱祭司
  ["0xF130002C5C00C8D8"] = UNMARKED, -- 古拉巴什勇士
  ["0xF130002E3600C8D9"] = CROSS, -- 哈卡莱祭司
  ["0xF130002C5F11E679"] = SQUARE, -- 灵魂掠夺者
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "hakkar_large_2", {
  ["0xF130002C5F11F381"] = SQUARE, -- 灵魂掠夺者
  ["0xF130002E3611F383"] = SKULL, -- 哈卡莱祭司
  ["0xF130002E3611F384"] = CROSS, -- 哈卡莱祭司
  ["0xF130002C5F11F380"] = MOON, -- 灵魂掠夺者
  ["0xF130002C4C11F37E"] = UNMARKED, -- 哈卡莱鲜血祭司
  ["0xF130002C5C11F382"] = UNMARKED, -- 古拉巴什勇士
})

--/////////////// ES 翡翠 ///////////////

local errenius = "0xF13000ED4B2739FA"
local errenius_mark = CIRCLE

addToDefaultNpcsToMark(L["Emerald Sanctum"], "entrance", {
  ["0xF13000ED482739F2"] = SQUARE, -- 圣所巨龙
  ["0xF13000ED4A273A45"] = MOON, -- 圣所麟龙人
  ["0xF13000ED4A273A43"] = TRIANGLE, -- 圣所麟龙人

  -- dreamer_pack_left_1
  ["0xF13000ED462739E2"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462739E3"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462739E4"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462739E5"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462739E6"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462739E7"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462739E8"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462739E9"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462739EB"] = UNMARKED, -- 圣所梦游者

  -- wyrmkin_pack_right_1
  ["0xF13000ED462739F1"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462739F0"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462739EF"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462739EE"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED472739ED"] = SKULL, -- 圣所龙人
  ["0xF13000ED472739EA"] = CROSS, -- 圣所龙人
})

addToDefaultNpcsToMark(L["Emerald Sanctum"], "wyrmkin_pack_right_2", {
  ["0xF13000ED492739F3"] = SKULL, -- 圣所龙族
  ["0xF13000ED492739F4"] = CROSS, -- 圣所龙族
  ["0xF13000ED472739F5"] = SQUARE, -- 圣所龙人
  ["0xF13000ED462739F6"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462739F7"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462739F8"] = UNMARKED, -- 圣所梦游者
})

addToDefaultNpcsToMark(L["Emerald Sanctum"], "dreamer_pack_left_2", {
  ["0xF13000ED49273A17"] = SKULL, -- 圣所龙族
  ["0xF13000ED46273A16"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A15"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A14"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A12"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A10"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A0F"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A0D"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A0C"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A0B"] = UNMARKED, -- 圣所梦游者

  [errenius] = errenius_mark, -- increase chance of spotting him early
})

addToDefaultNpcsToMark(L["Emerald Sanctum"], "wyrmkin_pack_left_1", {
  ["0xF13000ED47273A1C"] = SQUARE, -- 圣所龙人
  ["0xF13000ED4A273A1A"] = MOON, -- 圣所麟龙人
  ["0xF13000ED49273A18"] = CROSS, -- 圣所龙族
  ["0xF13000EF1C275495"] = SKULL, -- Sanctum Supressor
  ["0xF13000ED47273A1E"] = STAR, -- 圣所龙人

  [errenius] = errenius_mark, -- increase chance of spotting him early
})

addToDefaultNpcsToMark(L["Emerald Sanctum"], "wyrmkin_pack_left_2", {
  ["0xF13000ED46273A26"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A1F"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED49273A25"] = SKULL, -- 圣所龙族
  ["0xF13000ED49273A24"] = STAR, -- 圣所龙族
  ["0xF13000ED46273A20"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A27"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED48273A19"] = CROSS, -- 圣所巨龙
  [errenius] = errenius_mark, -- increase chance of spotting him early
})

addToDefaultNpcsToMark(L["Emerald Sanctum"], "dreamer_pack_right_1", {
  ["0xF13000ED462754A3"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462754A4"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462754A5"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462754A6"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462754A7"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462754A8"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462754A9"] = UNMARKED, -- 圣所梦游者

  [errenius] = errenius_mark, -- increase chance of spotting him early
})

addToDefaultNpcsToMark(L["Emerald Sanctum"], "wyrmkin_pack_left_3", {
  ["0xF13000ED46273A4B"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A4C"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A54"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A56"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A57"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A58"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A59"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED4A273A48"] = STAR, -- 圣所麟龙人
  ["0xF13000ED4A273A49"] = SKULL, -- 圣所麟龙人
  ["0xF13000ED49273A47"] = CROSS, -- 圣所龙族
  ["0xF13000ED47273A1C"] = SQUARE, -- 圣所龙人

  [errenius] = errenius_mark, -- increase chance of spotting him early
})

addToDefaultNpcsToMark(L["Emerald Sanctum"], "dreamer_pack_end", {
  ["0xF13000ED47273A46"] = CROSS, -- 圣所龙人
  ["0xF13000ED46273A28"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A29"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A2A"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A2B"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A2C"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A2D"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A2E"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A2F"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED46273A31"] = UNMARKED, -- 圣所梦游者
  ["0xF13000EF1C275497"] = SKULL, -- Sanctum Supressor

  [errenius] = errenius_mark, -- increase chance of spotting him early
})

addToDefaultNpcsToMark(L["Emerald Sanctum"], "wyrmkin_pack_right_3", {
  ["0xF13000ED462754A2"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED4627549E"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462754A0"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462754A1"] = UNMARKED, -- 圣所梦游者
  ["0xF13000ED462754A2"] = UNMARKED, -- 圣所梦游者
  ["0xF13000EF1C275499"] = SKULL, -- Sanctum Supressor
  ["0xF13000ED4727549C"] = STAR, -- 圣所龙人
  ["0xF13000ED4A27549D"] = CROSS, -- 圣所麟龙人
  ["0xF13000ED4A27549B"] = SQUARE, -- 圣所麟龙人
})

addToDefaultNpcsToMark(L["Emerald Sanctum"], "solnius", {
  ["0xF13000ED4C2739E1"] = UNMARKED, -- Solnius
})

--/////////////// MC ///////////////

addToDefaultNpcsToMark(L["Molten Core"], "giants1", {
  ["0xF130002D8A00DD81"] = CROSS, -- 熔核巨人
  ["0xF130002D8A00DD80"] = SKULL, -- 熔核巨人
})

addToDefaultNpcsToMark(L["Molten Core"], "pats1", {
  ["0xF130002D9900DE21"] = MOON, -- 上古熔火恶犬
  ["0xF130002F4500DE0C"] = TRIANGLE, -- 熔岩奔腾者
  ["0xF130002F4500DE07"] = CIRCLE, -- 熔岩奔腾者
  ["0xF130002D9900DE15"] = STAR, -- 上古熔火恶犬
  ["0xF130002D9900DE13"] = CROSS, -- 上古熔火恶犬
  ["0xF130002D9900DE14"] = SQUARE, -- 上古熔火恶犬
  ["0xF130002D9900DE16"] = DIAMOND, -- 上古熔火恶犬
})

addToDefaultNpcsToMark(L["Molten Core"], "giants2", {
  ["0xF130002D8A00DD8C"] = CROSS, -- 熔核巨人
  ["0xF130002D8A00DD8D"] = SKULL, -- 熔核巨人
})

addToDefaultNpcsToMark(L["Molten Core"], "鲁西弗隆", {
  ["0xF130002F5700DD1F"] = CROSS, -- 火妖护卫
  ["0xF130002F5600DD1D"] = SKULL, -- 鲁西弗隆
  ["0xF130002F5700DD1E"] = SQUARE, -- 火妖护卫
})

addToDefaultNpcsToMark(L["Molten Core"], "imp_surgers", {
  ["0xF130002F4500DE0A"] = DIAMOND, -- 熔岩奔腾者
  ["0xF130002F4500DE0B"] = TRIANGLE, -- 熔岩奔腾者
  ["0xF130002F4500DE08"] = SKULL, -- 熔岩奔腾者
  ["0xF130002F4500DE09"] = CROSS, -- 熔岩奔腾者
})

addToDefaultNpcsToMark(L["Molten Core"], "giants3", {
  ["0xF130002D8A00DD83"] = CROSS, -- 熔核巨人
  ["0xF130002D8A00DD82"] = SKULL, -- 熔核巨人
})

addToDefaultNpcsToMark(L["Molten Core"], "giants4", {
  ["0xF130002D8A00DD86"] = CROSS, -- 熔核巨人
  ["0xF130002D8B00DD87"] = SKULL, -- 熔核摧毁者
})

addToDefaultNpcsToMark(L["Molten Core"], "pats2", {
  ["0xF130002D9900DE1E"] = CIRCLE, -- 上古熔火恶犬
  ["0xF130002D9900DE1A"] = TRIANGLE, -- 上古熔火恶犬
  ["0xF130002D9900DE20"] = DIAMOND, -- 上古熔火恶犬
  ["0xF130002D9900DE17"] = CROSS, -- 上古熔火恶犬
  ["0xF130002F4500DE11"] = STAR, -- 熔岩奔腾者
  ["0xF130002D9900DE19"] = SKULL, -- 上古熔火恶犬
  ["0xF130002F4500DE10"] = MOON, -- 熔岩奔腾者
  ["0xF130002D9900DE18"] = SQUARE, -- 上古熔火恶犬
})

addToDefaultNpcsToMark(L["Molten Core"], "giants5", {
  ["0xF130002D8B00DD7D"] = CROSS, -- 熔核摧毁者
  ["0xF130002D8B00DD7C"] = SKULL, -- 熔核摧毁者
})

addToDefaultNpcsToMark(L["Molten Core"], "garr", {
  ["0xF130002F4300DD28"] = STAR, -- 火誓者
  ["0xF130002F4300DD2E"] = CIRCLE, -- 火誓者
  ["0xF130002F4300DD2C"] = SQUARE, -- 火誓者
  ["0xF130002F4300DD34"] = DIAMOND, -- 火誓者
  ["0xF130002F4300DD2B"] = SKULL, -- 火誓者
  ["0xF130002F4300DD32"] = CROSS, -- 火誓者
  ["0xF130002F4300DD33"] = MOON, -- 火誓者
  ["0xF130002F4300DD22"] = TRIANGLE, -- 火誓者
})

addToDefaultNpcsToMark(L["Molten Core"], "baron_pack_1", {
  ["0xF130002D93016498"] = CROSS, -- 烈焰守卫
  ["0xF130002F2C016497"] = CIRCLE, -- 熔岩元素
  ["0xF130002D92016496"] = SKULL, -- 火焰行者
  ["0xF130002F2C016499"] = DIAMOND, -- 熔岩元素
})

addToDefaultNpcsToMark(L["Molten Core"], "baron_pack_2", {
  ["0xF130002F2C016480"] = CIRCLE, -- 熔岩元素
  ["0xF130002F2C01647E"] = DIAMOND, -- 熔岩元素
  ["0xF130002D9301647F"] = CROSS, -- 烈焰守卫
  ["0xF130002D9201647D"] = SKULL, -- 火焰行者
  ["0xF130002F1800DD4F"] = STAR, -- 迦顿男爵
})

addToDefaultNpcsToMark(L["Molten Core"], "baron_pack_3", {
  ["0xF130002D9301649C"] = CROSS, -- 烈焰守卫
  ["0xF130002D9201649A"] = SKULL, -- 火焰行者
  ["0xF130002F4401649B"] = CIRCLE, -- 熔岩掠夺者
  ["0xF130002FE800DD20"] = STAR, -- Shazzrah
})

addToDefaultNpcsToMark(L["Molten Core"], "baron_pack_4", {
  ["0xF130002D9200DD92"] = SKULL, -- 火焰行者
  ["0xF130002F4400DD93"] = CIRCLE, -- 熔岩掠夺者
  ["0xF130002D9300DD94"] = CROSS, -- 烈焰守卫
})

addToDefaultNpcsToMark(L["Molten Core"], "baron_pack_5", {
  ["0xF130002F2C00DDD9"] = CIRCLE, -- 熔岩元素
  ["0xF130002D9300DDDA"] = CROSS, -- 烈焰守卫
  ["0xF130002D9200DDD8"] = SKULL, -- 火焰行者
  ["0xF130002F2C00DDDB"] = DIAMOND, -- 熔岩元素
})

addToDefaultNpcsToMark(L["Molten Core"], "sulfuron", {
  ["0xF130002D8E00DD69"] = MOON, -- 火妖祭司
  ["0xF130002D8E00DD66"] = SQUARE, -- 火妖祭司
  ["0xF130002D8E00DD67"] = CROSS, -- 火妖祭司
  ["0xF130002F4200DD65"] = TRIANGLE, -- 萨弗隆先驱者
  ["0xF130002D8E00DD6A"] = SKULL, -- 火妖祭司
})

addToDefaultNpcsToMark(L["Molten Core"], "golemag_shadowforge_pack", {
  ["0xF130002D9300DDC7"] = SKULL, -- 烈焰守卫
  ["0xF130002F2C00DDAF"] = DIAMOND, -- 熔岩元素
  ["0xF130002F2C00DDC8"] = CIRCLE, -- 熔岩元素
  ["0xF130002D9200DDAE"] = CROSS, -- 火焰行者
})

addToDefaultNpcsToMark(L["Molten Core"], "twin_golems", {
  ["0xF13000FDFC278C2C"] = CROSS, -- 巴萨尔萨
  ["0xF13000FDFD278C2D"] = SKULL, -- 斯摩达利斯
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_left_1", {
  ["0xF13000CBB7278CD2"] = DIAMOND, -- 暗炉圣职者
  ["0xF13000CBB6278CD3"] = SQUARE, -- 暗炉卫士
  ["0xF13000CBB8278CD4"] = CROSS, -- 暗炉织焰者
  ["0xF13000CBB8278CD5"] = SKULL, -- 暗炉织焰者
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_left_2", {
  ["0xF13000CBB6278CDD"] = CROSS, -- 暗炉卫士
  ["0xF13000CBB6278CDE"] = SKULL, -- 暗炉卫士
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_left_3", {
  ["0xF13000CBB8278CDA"] = CROSS, -- 暗炉织焰者
  ["0xF13000CBB8278CDB"] = SKULL, -- 暗炉织焰者
  ["0xF13000CBB8278CDC"] = SQUARE, -- 暗炉织焰者
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_left_4", {
  ["0xF13000CBB7278CDF"] = SKULL, -- 暗炉圣职者
  ["0xF13000CBB6278CE0"] = CROSS, -- 暗炉卫士
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_left_5", {
  ["0xF13000CBB8278CC4"] = SKULL, -- 暗炉织焰者
  ["0xF13000CBB6278CC1"] = SQUARE, -- 暗炉卫士
  ["0xF13000CBB8278CC3"] = CROSS, -- 暗炉织焰者
  ["0xF13000CBB6278CC2"] = MOON, -- 暗炉卫士
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_right_1", {
  ["0xF13000CBB6278CB8"] = SQUARE, -- 暗炉卫士
  ["0xF13000CBB8278CB7"] = SKULL, -- 暗炉织焰者
  ["0xF13000CBB6278CB9"] = CROSS, -- 暗炉卫士
  ["0xF13000CBB6278CB3"] = DIAMOND, -- 暗炉卫士
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_right_2", {
  ["0xF13000CBB6278CC6"] = SKULL, -- 暗炉卫士
  ["0xF13000CBB6278CC5"] = CROSS, -- 暗炉卫士
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_right_3", {
  ["0xF13000CBB7278CE3"] = SKULL, -- 暗炉圣职者
  ["0xF13000CBB7278CE2"] = SQUARE, -- 暗炉圣职者
  ["0xF13000CBB7278CE1"] = CROSS, -- 暗炉圣职者
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_right_4", {
  ["0xF13000CBB6278CCB"] = CROSS, -- 暗炉卫士
  ["0xF13000CBB6278CCC"] = SKULL, -- 暗炉卫士
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_right_5", {
  ["0xF13000CBB6278CC0"] = MOON, -- 暗炉卫士
  ["0xF13000CBB6278CBF"] = SQUARE, -- 暗炉卫士
  ["0xF13000CBB7278CBD"] = CROSS, -- 暗炉圣职者
  ["0xF13000CBB7278CBE"] = SKULL, -- 暗炉圣职者
})

addToDefaultNpcsToMark(L["Molten Core"], "domo", {
  ["0xF130002D90278D51"] = DIAMOND, -- elite
  ["0xF130002D90278D52"] = STAR, -- elite
  ["0xF130002D90278D53"] = CIRCLE, -- elite
  ["0xF130002D90278D54"] = TRIANGLE, -- elite
  ["0xF130002D8F278D55"] = SKULL, -- healer
  ["0xF130002D8F278D56"] = SQUARE, -- healer
  ["0xF130002D8F278D57"] = MOON, -- healer
  ["0xF130002D8F278D58"] = CROSS, -- healer
  ["0xF130002EF2278D50"] = UNMARKED, -- domo
})

--/////////////// AQ20 ///////////////

addToDefaultNpcsToMark(L["Ruins of Ahn'Qiraj"], "entrance", {
  ["0xF130003BEF11FB53"] = TRIANGLE, -- Qiraji Swarmguard
  ["0xF130003BDC0155E6"] = CIRCLE, -- Qiraji Gladiator
  ["0xF130003BDC11FAC8"] = SKULL, -- Qiraji Gladiator
})

addToDefaultNpcsToMark(L["Ruins of Ahn'Qiraj"], "entrance_pats", {
  ["0xF130003BDF0155DA"] = STAR, -- Hive'Zara Stinger
  ["0xF130003BDD11FAD8"] = UNMARKED, -- 佐拉黄蜂
  ["0xF130003BDD11FAD7"] = UNMARKED, -- 佐拉黄蜂
  ["0xF130003BDD11FADF"] = UNMARKED, -- 佐拉黄蜂
  ["0xF130003BDD11FAD6"] = UNMARKED, -- 佐拉黄蜂
  ["0xF130003BDD11FAD5"] = UNMARKED, -- 佐拉黄蜂
  ["0xF130003BEF11FB4D"] = CIRCLE, -- Qiraji Swarmguard
  ["0xF130003BDD11FADB"] = UNMARKED, -- 佐拉黄蜂
  ["0xF130003BDD11FADA"] = UNMARKED, -- 佐拉黄蜂
  ["0xF130003BDD11FADE"] = UNMARKED, -- 佐拉黄蜂
  ["0xF130003BDD11FAD4"] = UNMARKED, -- 佐拉黄蜂
  ["0xF130003BDF0155DB"] = SQUARE, -- Hive'Zara Stinger
  ["0xF130003BEF11FAE1"] = DIAMOND, -- Qiraji Swarmguard
  ["0xF130003BDF11FAE0"] = SKULL, -- Hive'Zara Stinger
  ["0xF130003BDD11FAD3"] = UNMARKED, -- 佐拉黄蜂
  ["0xF130003BEF11FAE2"] = TRIANGLE, -- Qiraji Swarmguard
  ["0xF130003BDF11FADD"] = MOON, -- Hive'Zara Stinger
  ["0xF130003BDF11FB4E"] = CROSS, -- Hive'Zara Stinger
})

addToDefaultNpcsToMark(L["Ruins of Ahn'Qiraj"], "entrance_pats_2", {
  ["0xF130003BDD11FAF3"] = UNMARKED, -- 佐拉黄蜂
  ["0xF130003BDD11FAF7"] = UNMARKED, -- 佐拉黄蜂
  ["0xF130003BDD11FAEF"] = UNMARKED, -- 佐拉黄蜂
  ["0xF130003BDF11FAF5"] = SQUARE, -- Hive'Zara Stinger
  ["0xF130003BDD11FAFA"] = UNMARKED, -- 佐拉黄蜂
  ["0xF130003BDD11FAF4"] = UNMARKED, -- 佐拉黄蜂
  ["0xF130003BDF11FAF0"] = DIAMOND, -- Hive'Zara Stinger
  ["0xF130003BDF11FAF2"] = MOON, -- Hive'Zara Stinger
  ["0xF130003BDF11FAF8"] = CROSS, -- Hive'Zara Stinger
  ["0xF130003BF40162B5"] = TRIANGLE, -- Kurinnaxx
  ["0xF130003BDD11FAF6"] = UNMARKED, -- 佐拉黄蜂
  ["0xF130003BDD11FAF1"] = UNMARKED, -- 佐拉黄蜂
  ["0xF130003BDD11FAF9"] = UNMARKED, -- 佐拉黄蜂
  ["0xF130003BDC11FACA"] = CIRCLE, -- Qiraji Gladiator
  ["0xF130003BDC11FAC9"] = SKULL, -- Qiraji Gladiator
  ["0xF130003BDD11FB50"] = UNMARKED, -- 佐拉黄蜂
  ["0xF130003BDF11FB4F"] = STAR, -- Hive'Zara Stinger
  ["0xF130003BDD11FB52"] = UNMARKED, -- 佐拉黄蜂
})

addToDefaultNpcsToMark(L["Ruins of Ahn'Qiraj"], "general_rajaxx", {
  ["0xF130003C1B11FB5A"] = UNMARKED, -- Qiraji Warrior
  ["0xF130003BF011FB71"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003C1B11FB57"] = UNMARKED, -- Qiraji Warrior
  ["0xF130003BF011FB5C"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003BF011FB72"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003C1C11FC00"] = CIRCLE, -- Major Pakkon
  ["0xF130003C1B11FB6D"] = UNMARKED, -- Qiraji Warrior
  ["0xF130003BF011FB89"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003C1911FBFF"] = DIAMOND, -- Colonel Zerran
  ["0xF130003C1B11FB84"] = UNMARKED, -- Qiraji Warrior
  ["0xF130003C1B11FB7D"] = UNMARKED, -- Qiraji Warrior
  ["0xF130003BF011FB6F"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003BF011FB78"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003BF011FB66"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003BF011FB79"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003C1B11FB7F"] = UNMARKED, -- Qiraji Warrior
  ["0xF130003C1B11FB6B"] = UNMARKED, -- Qiraji Warrior
  ["0xF130003C1D11FBFD"] = CROSS, -- Captain Drenn
  ["0xF130003BF011FB80"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003BF011FB64"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003C1B11FB59"] = UNMARKED, -- Qiraji Warrior
  ["0xF130003C1B11FB5F"] = UNMARKED, -- Qiraji Warrior
  ["0xF130003BF011FB77"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003C1B11FB60"] = UNMARKED, -- Qiraji Warrior
  ["0xF130003BF011FB68"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003BF011FB62"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003C1F11FB5D"] = SKULL, -- Captain Qeez
  ["0xF130003C2011FB5E"] = SQUARE, -- Captain Tuubid
  ["0xF130003BF011FB76"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003BF011FB81"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003BF011FB5B"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003C1B11FB61"] = UNMARKED, -- Qiraji Warrior
  ["0xF130003C1B11FB58"] = UNMARKED, -- Qiraji Warrior
  ["0xF130003BF011FB63"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003C1B11FB69"] = UNMARKED, -- Qiraji Warrior
  ["0xF130003C1B11FB6A"] = UNMARKED, -- Qiraji Warrior
  ["0xF130003BF011FB67"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003C1E11FC01"] = MOON, -- Captain Xurrem
  ["0xF130003C1B11FB85"] = UNMARKED, -- Qiraji Warrior
  ["0xF130003BED0162F7"] = UNMARKED, -- General Rajaxx
  ["0xF130003BF011FB82"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003C1A11FBFE"] = TRIANGLE, -- Major Yeggeth
  ["0xF130003BF011FB87"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003BF011FB70"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003C1B11FB86"] = UNMARKED, -- Qiraji Warrior
  ["0xF130003C1B11FB7E"] = UNMARKED, -- Qiraji Warrior
  ["0xF130003BF011FB6E"] = UNMARKED, -- Swarmguard Needler
  ["0xF130003C1B11FB7A"] = UNMARKED, -- Qiraji Warrior
  ["0xF130003C1B11FB88"] = UNMARKED, -- Qiraji Warrior
})

addToDefaultNpcsToMark(L["Ruins of Ahn'Qiraj"], "buru_path", {
  ["0xF130003BE7014F7D"] = STAR, -- Flesh Hunter
  ["0xF130003BDC11FACC"] = CIRCLE, -- Qiraji Gladiator
  ["0xF130003BDC11FACD"] = SKULL, -- Qiraji Gladiator
  ["0xF130003BDB11FB96"] = TRIANGLE, -- Hive'Zara Sandstalker
})

addToDefaultNpcsToMark(L["Ruins of Ahn'Qiraj"], "buru_slimes", {
  ["0xF130003BE711FE02"] = CROSS, -- Flesh Hunter
  ["0xF130003BE711FB9F"] = SKULL, -- Flesh Hunter
})

addToDefaultNpcsToMark(L["Ruins of Ahn'Qiraj"], "buru_eggs", {
  ["0xF130003C9A276DE0"] = CIRCLE, -- egg
  ["0xF130003C9A276DE1"] = DIAMOND, -- egg
  ["0xF130003C9A276DE2"] = TRIANGLE, -- egg
  ["0xF130003C9A276DE3"] = MOON, -- egg
  ["0xF130003C9A276DE4"] = SQUARE, -- egg
  ["0xF130003C9A276DE5"] = STAR, -- egg
  ["0xF130003C0A0162F9"] = UNMARKED, -- Buru the Gorger
})

addToDefaultNpcsToMark(L["Ruins of Ahn'Qiraj"], "resevoir", {
  ["0xF130003BE711FC27"] = SQUARE, -- Flesh Hunter
  ["0xF130003BEA11FC12"] = DIAMOND, -- Obsidian Destroyer
  ["0xF130003BEA0153E5"] = MOON, -- Obsidian Destroyer
  ["0xF130003BDC11FACE"] = SKULL, -- Qiraji Gladiator
  ["0xF130003BEA11FC39"] = TRIANGLE, -- Obsidian Destroyer
  ["0xF130003BDC11FACF"] = CIRCLE, -- Qiraji Gladiator
  ["0xF130003BE711FC2B"] = STAR, -- Flesh Hunter
})

addToDefaultNpcsToMark(L["Ruins of Ahn'Qiraj"], "ossirian_room", {
  ["0xF130003BFB11FBDC"] = CROSS, -- Anubisath Guardian
  ["0xF130003BFB11FBDD"] = SKULL, -- Anubisath Guardian
  ["0xF130003BFB0155C3"] = SQUARE, -- Anubisath Guardian
  ["0xF130003BFB11FBE0"] = TRIANGLE, -- Anubisath Guardian
  ["0xF130003BFB11FBDF"] = STAR, -- Anubisath Guardian
  ["0xF130003BFB11FBDB"] = DIAMOND, -- Anubisath Guardian
  ["0xF130003BFB11FBDE"] = CIRCLE, -- Anubisath Guardian
  ["0xF130003BFB11FBE1"] = MOON, -- Anubisath Guardian
})

--/////////////// BWL ///////////////

addToDefaultNpcsToMark(L["Blackwing Lair"], "bwl_razor", {
  ["0xF1300030930149A4"] = STAR, -- 狂野的拉佐格尔
  ["0xF13000310D0149A5"] = SKULL, -- 黑翼控制者
  ["0xF1300038780149A7"] = UNMARKED, -- 黑翼卫士
  ["0xF1300038780149A6"] = UNMARKED, -- 黑翼卫士
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "vael", {
  ["0xF1300032DC014A20"] = STAR, -- 堕落的瓦拉斯塔兹
  ["0xF1300036AC104CD6"] = CROSS, -- 黑翼技师
  ["0xF1300036AC104CD5"] = SQUARE, -- 黑翼技师
  ["0xF1300036AC104CD4"] = MOON, -- 黑翼技师
  ["0xF1300036AC104DD3"] = TRIANGLE, -- 黑翼技师
  ["0xF1300036AC104DD2"] = DIAMOND, -- 黑翼技师
  ["0xF1300036AC104DD1"] = CIRCLE, -- 黑翼技师
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "wyrm1", {
  ["0xF1300030B1014A2E"] = DIAMOND, -- 死爪老龙人
  ["0xF1300030B3014A27"] = STAR, -- 死爪龙人队长
  ["0xF1300030B0014A2C"] = SQUARE, -- 死爪狂乱者
  ["0xF1300030AF014A33"] = SKULL, -- 死爪火鳞龙人
  ["0xF1300030AF014A34"] = CROSS, -- 死爪火鳞龙人
  ["0xF1300030B1014A2D"] = CIRCLE, -- 死爪老龙人
  ["0xF1300030B0014A2B"] = MOON, -- 死爪狂乱者
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "wyrm2", {
  ["0xF1300030B0014A29"] = SKULL, -- 死爪狂乱者
  ["0xF1300030B3014A28"] = STAR, -- 死爪龙人队长
  ["0xF1300030B1014A30"] = CIRCLE, -- 死爪老龙人
  ["0xF1300030B1014A2F"] = DIAMOND, -- 死爪老龙人
  ["0xF1300030B0014A2A"] = CROSS, -- 死爪狂乱者
  ["0xF1300030AF014A31"] = SQUARE, -- 死爪火鳞龙人
  ["0xF1300030AF014A32"] = MOON, -- 死爪火鳞龙人
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "supress1", {
  ["0xF1300030AA104BD1"] = CROSS, -- 黑翼工头
  ["0xF1300030AA104BD0"] = SQUARE, -- 黑翼工头
  ["0xF1300030AA104BCF"] = SKULL, -- 黑翼工头
  ["0xF1300030B40BA218"] = TRIANGLE, -- 死爪孵化者
  ["0xF1300030B40BA216"] = DIAMOND, -- 死爪孵化者
  ["0xF1300030B40BA08B"] = STAR, -- 死爪孵化者
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "supress1_2", {
  ["0xF1300030AA104BD5"] = CROSS, -- 黑翼工头
  ["0xF1300030AA104BD4"] = SQUARE, -- 黑翼工头
  ["0xF1300030AA104BD3"] = SKULL, -- 黑翼工头
  ["0xF1300030B40BA43A"] = TRIANGLE, -- 死爪孵化者
  ["0xF1300030B40BA3BF"] = DIAMOND, -- 死爪孵化者
  ["0xF1300030B40BA395"] = STAR, -- 死爪孵化者
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "supress2", {
  ["0xF1300030AA104BD8"] = CROSS, -- 黑翼工头
  ["0xF1300030AA104BD7"] = SQUARE, -- 黑翼工头
  ["0xF1300030AA104BD6"] = SKULL, -- 黑翼工头
  ["0xF1300030B40BA441"] = TRIANGLE, -- 死爪孵化者
  ["0xF1300030B40BA43F"] = DIAMOND, -- 死爪孵化者
  ["0xF1300030B40BA43D"] = STAR, -- 死爪孵化者
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "supress2_2", {
  ["0xF1300030AA104BDB"] = CROSS, -- 黑翼工头
  ["0xF1300030AA104BDA"] = SQUARE, -- 黑翼工头
  ["0xF1300030AA104BD9"] = SKULL, -- 黑翼工头
  ["0xF1300030B40BA632"] = TRIANGLE, -- 死爪孵化者
  ["0xF1300030B40BA630"] = DIAMOND, -- 死爪孵化者
  ["0xF1300030B40BA62E"] = STAR, -- 死爪孵化者
  ["0xF130002EF10149A3"] = CIRCLE, -- Broodlord Lashlayer
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "lab1", {
  ["0xF1300036AC11F796"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014A3C"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC11F797"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014A37"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014A3B"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014A38"] = UNMARKED, -- 黑翼技师
  ["0xF1300030AB014A3E"] = CROSS, -- 黑翼术士
  ["0xF1300030AB014A3D"] = SKULL, -- 黑翼术士
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "lab2", {
  ["0xF1300036AC11F79B"] = UNMARKED, -- 黑翼技师
  ["0xF1300030A9014A44"] = MOON, -- 黑翼缚法者
  ["0xF1300030AD014A4D"] = SQUARE, -- 黑翼监工
  ["0xF1300036AC11F79A"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014A46"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014A4A"] = UNMARKED, -- 黑翼技师
  ["0xF1300030AB014A42"] = SKULL, -- 黑翼术士
  ["0xF1300036AC014A47"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014A48"] = UNMARKED, -- 黑翼技师
  ["0xF1300030AB014A49"] = CROSS, -- 黑翼术士
  ["0xF1300036AC014A4B"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014A43"] = UNMARKED, -- 黑翼技师
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "lab3", {
  ["0xF1300036AC014A53"] = UNMARKED, -- 黑翼技师
  ["0xF1300030AB014A51"] = CROSS, -- 黑翼术士
  ["0xF1300036AC014A57"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014A55"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014A5A"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC11F79D"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014A58"] = UNMARKED, -- 黑翼技师
  ["0xF1300030AD014A4E"] = SQUARE, -- 黑翼监工
  ["0xF1300030AB014A50"] = SKULL, -- 黑翼术士
  ["0xF1300036AC014A56"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014A54"] = UNMARKED, -- 黑翼技师
  ["0xF1300030A911F78B"] = MOON, -- 黑翼缚法者
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "wyrmguard1", {
  ["0xF1300030AD014A6F"] = SQUARE, -- 黑翼监工
  ["0xF1300030AC014A70"] = SKULL, -- 死爪龙人护卫
  ["0xF1300030AD014A6D"] = MOON, -- 黑翼监工
  ["0xF1300030AD014A6E"] = CROSS, -- 黑翼监工
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "lab4", {
  ["0xF1300030A911F78C"] = MOON, -- 黑翼缚法者
  ["0xF1300036AC014A7E"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014A87"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014A90"] = UNMARKED, -- 黑翼技师
  ["0xF1300030AB014A76"] = SKULL, -- 黑翼术士
  ["0xF1300036AC014A8B"] = UNMARKED, -- 黑翼技师
  ["0xF1300030AD014A91"] = SQUARE, -- 黑翼监工
  ["0xF1300030AD014B68"] = CIRCLE, -- 黑翼监工
  ["0xF1300036AC014A7D"] = UNMARKED, -- 黑翼技师
  ["0xF1300030AD11F78F"] = TRIANGLE, -- 黑翼监工
  ["0xF1300030AB014A77"] = CROSS, -- 黑翼术士
  ["0xF1300036AC014A86"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC11F798"] = UNMARKED, -- 黑翼技师
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "lab5", {
  ["0xF1300036AC014B1A"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014AAE"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC11F791"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014AD1"] = UNMARKED, -- 黑翼技师
  ["0xF1300030AB014AAD"] = SKULL, -- 黑翼术士
  ["0xF1300030AD014B68"] = SQUARE, -- 黑翼监工
  ["0xF1300036AC014AD0"] = UNMARKED, -- 黑翼技师
  ["0xF1300030A911F78D"] = MOON, -- 黑翼缚法者
  ["0xF1300036AC014AD3"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014B1B"] = UNMARKED, -- 黑翼技师
  ["0xF1300030AB014AAC"] = CROSS, -- 黑翼术士
  ["0xF1300036AC014B19"] = UNMARKED, -- 黑翼技师
})


addToDefaultNpcsToMark(L["Blackwing Lair"], "lab6", {
  ["0xF1300030A9014EFE"] = MOON, -- 黑翼缚法者
  ["0xF1300036AC11F794"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014F07"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014F06"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014F00"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014F0C"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014F0D"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014F04"] = UNMARKED, -- 黑翼技师
  ["0xF1300030A9014F08"] = STAR, -- 黑翼缚法者
  ["0xF1300030AD11F78F"] = SQUARE, -- 黑翼监工
  ["0xF1300036AC11F795"] = UNMARKED, -- 黑翼技师
  ["0xF1300030AB014EFD"] = SKULL, -- 黑翼术士
  ["0xF1300030AB014F0F"] = CROSS, -- 黑翼术士
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "lab7", {
  ["0xF1300036AC014E77"] = UNMARKED, -- 黑翼技师
  ["0xF1300030AB014E61"] = CROSS, -- 黑翼术士
  ["0xF1300030A9014E6D"] = STAR, -- 黑翼缚法者
  ["0xF1300036AC11F792"] = UNMARKED, -- 黑翼技师
  ["0xF1300030A9014E75"] = MOON, -- 黑翼缚法者
  ["0xF1300036AC014E79"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014E69"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014E74"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014E6C"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014E6B"] = UNMARKED, -- 黑翼技师
  ["0xF1300036AC014E70"] = UNMARKED, -- 黑翼技师
  ["0xF1300030AB014E4D"] = SKULL, -- 黑翼术士
  ["0xF1300030AD11F78E"] = SQUARE, -- 黑翼监工
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "wyrmguard2", {
  ["0xF1300030AC014A9B"] = SKULL, -- 死爪龙人护卫
  ["0xF1300030AC014A9A"] = CROSS, -- 死爪龙人护卫
  ["0xF1300030AC014A94"] = SQUARE, -- 死爪龙人护卫
  ["0xF130003841014A93"] = MOON, -- 大元素师克里希克
  ["0xF130002ECD014F17"] = DIAMOND, -- 弗莱格尔
  ["0xF130003909014F14"] = TRIANGLE, -- 埃博诺克
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "wyrmguard3", {
  ["0xF1300030AC014A9F"] = SQUARE, -- 死爪龙人护卫
  ["0xF1300030AC014AAA"] = SKULL, -- 死爪龙人护卫
  ["0xF1300030AC014AA8"] = CROSS, -- 死爪龙人护卫
})


--/////////////// KARA10 ///////////////

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara1", {
  ["0xF13000EF0A2747D1"] = UNMARKED, -- 影刺怒牙
  ["0xF13000EF082747D2"] = CROSS, -- 影刺暗法师
  ["0xF13000EF0A2747D0"] = UNMARKED, -- 影刺怒牙
  ["0xF13000EF092747CF"] = UNMARKED, -- 影刺伏击者
  ["0xF13000EF082747D3"] = SKULL, -- 影刺暗法师
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara2", {
  ["0xF13000EF082747C1"] = SKULL, -- 影刺暗法师
  ["0xF13000EF082747C9"] = CROSS, -- 影刺暗法师
  ["0xF13000EF092747C7"] = UNMARKED, -- 影刺伏击者
  ["0xF130003A212755AA"] = UNMARKED, -- 蜘蛛
  ["0xF13000EF0A2747C4"] = UNMARKED, -- 影刺怒牙
  ["0xF13000EF0A2747C6"] = UNMARKED, -- 影刺怒牙
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara3", {
  ["0xF13000EF0A2747AD"] = UNMARKED, -- 影刺怒牙
  ["0xF13000EF0A2747AE"] = UNMARKED, -- 影刺怒牙
  ["0xF13000EF072747AA"] = STAR, -- 影刺前锋
  ["0xF13000EF082747B3"] = SKULL, -- 影刺暗法师
  ["0xF13000EF0A2747AF"] = UNMARKED, -- 影刺怒牙
  ["0xF130000FEB2755A4"] = UNMARKED, -- Rat
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara4", {
  ["0xF13000EF082747A9"] = CROSS, -- 影刺暗法师
  ["0xF13000EF0A2747A8"] = UNMARKED, -- 影刺怒牙
  ["0xF13000EF092747AB"] = UNMARKED, -- 影刺伏击者
  ["0xF13000EF072747AA"] = STAR, -- 影刺前锋
  ["0xF13000EF082747AC"] = SKULL, -- 影刺暗法师
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "rider", {
  ["0xF13000EF1B274792"] = CROSS, -- 影刺暴食者
  ["0xF13000EF1427470C"] = TRIANGLE, -- 黑暗骑士勇士
  ["0xF13000EF13277329"] = UNMARKED,
  ["0xF13000EF1327732A"] = UNMARKED,
  ["0xF13000EF12274794"] = DIAMOND, -- 闹鬼铁匠
  ["0xF13000EF1B274795"] = SQUARE, -- 影刺暴食者
  ["0xF13000EF1B2747A2"] = SKULL, -- 影刺暴食者
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara5", {
  ["0xF13000EF152756BF"] = SKULL, -- 幻影仆从
  ["0xF13000EF102756C0"] = UNMARKED, -- 幻影守卫
  ["0xF13000EF102747BD"] = UNMARKED, -- 幻影守卫
  ["0xF13000EF102747BE"] = UNMARKED, -- 幻影守卫
  ["0xF13000EF152756BE"] = CROSS, -- 幻影仆从
  ["0xF13000EF072747D4"] = TRIANGLE, -- 影刺前锋
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara6", {
  ["0xF13000EF082747EB"] = CROSS, -- 影刺暗法师
  ["0xF13000EF0A2747AE"] = UNMARKED, -- 影刺怒牙
  ["0xF13000EF0A2747AF"] = UNMARKED, -- 影刺怒牙
  ["0xF13000EF0A2747AD"] = UNMARKED, -- 影刺怒牙
  ["0xF13000EF082747E7"] = SKULL, -- 影刺暗法师
  ["0xF13000EF0A2747E8"] = UNMARKED, -- 影刺怒牙
  ["0xF13000EF0A2747E9"] = UNMARKED, -- 影刺怒牙
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara7", {
  ["0xF13000EF0A2747DD"] = UNMARKED, -- 影刺怒牙
  ["0xF13000EF082747DE"] = SKULL, -- 影刺暗法师
  ["0xF13000EF082747DC"] = CROSS, -- 影刺暗法师
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara8", {
  ["0xF13000EF082747DA"] = CROSS, -- 影刺暗法师
  ["0xF13000EF0A2747DB"] = UNMARKED, -- 影刺怒牙
  ["0xF13000EF082747D9"] = SKULL, -- 影刺暗法师
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "imps1", {
  ["0xF13000EF0C274822"] = UNMARKED, -- 劣魔原猎者
  ["0xF13000EF102747F0"] = SQUARE, -- 幻影守卫
  ["0xF13000EF182747F4"] = TRIANGLE, -- 掠网毒牙蛛
  ["0xF13000EF102747F1"] = UNMARKED, -- 幻影守卫
  ["0xF13000EF102747E5"] = UNMARKED, -- 幻影守卫
  ["0xF13000EF0B274824"] = SKULL, -- 劣魔影织者
  ["0xF13000EF102747E4"] = CROSS, -- 幻影守卫
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "imps2", {
  ["0xF13000EF0C274808"] = UNMARKED, -- 劣魔原猎者
  ["0xF13000EF0B274802"] = MOON, -- 劣魔影织者
  ["0xF13000EF0B274801"] = SQUARE, -- 劣魔影织者
  ["0xF13000EF0B274803"] = CROSS, -- 劣魔影织者
  ["0xF13000EF0B274806"] = SKULL, -- 劣魔影织者
  ["0xF13000EF0D274809"] = UNMARKED, -- 劣魔魔导师
  ["0xF13000EF0D274804"] = UNMARKED, -- 劣魔魔导师
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "imps3", {
  ["0xF13000EF0D27480F"] = UNMARKED, -- 劣魔魔导师
  ["0xF13000EF0C274812"] = UNMARKED, -- 劣魔原猎者
  ["0xF13000EF0B27480D"] = CROSS, -- 劣魔影织者
  ["0xF13000EF0B274811"] = SKULL, -- 劣魔影织者
  ["0xF13000EF0D27480E"] = UNMARKED, -- 劣魔魔导师
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "imps4", {
  ["0xF13000EF0B27481B"] = SQUARE, -- 劣魔影织者
  ["0xF13000EF0B27481C"] = SKULL, -- 劣魔影织者
  ["0xF13000EF0B274819"] = CROSS, -- 劣魔影织者
  ["0xF13000EF0C274815"] = UNMARKED, -- 劣魔原猎者
  ["0xF130003A212755AD"] = UNMARKED, -- 蜘蛛
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "imps5", {
  ["0xF13000EF0C2747F9"] = UNMARKED, -- 劣魔原猎者
  ["0xF13000EF0B2747F7"] = SKULL, -- 劣魔影织者
  ["0xF13000EF0D2747FB"] = UNMARKED, -- 劣魔魔导师
  ["0xF130000FEB2755AE"] = UNMARKED, -- Rat
  ["0xF13000EF0C274800"] = UNMARKED, -- 劣魔原猎者
  ["0xF13000EF0C2747F8"] = UNMARKED, -- 劣魔原猎者
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "imps6", {
  ["0xF13000EF0D27481F"] = UNMARKED, -- 劣魔魔导师
  ["0xF13000EF0C274823"] = UNMARKED, -- 劣魔原猎者
  ["0xF13000EF0D274814"] = UNMARKED, -- 劣魔魔导师
  ["0xF13000EF0D27481A"] = TRIANGLE, -- 劣魔魔导师
  ["0xF13000EF0C27481D"] = UNMARKED, -- 劣魔原猎者
  ["0xF13000EF0D274817"] = UNMARKED, -- 劣魔魔导师
  ["0xF13000EF0D274818"] = UNMARKED, -- 劣魔魔导师
  ["0xF13000EF0B274820"] = SKULL, -- 劣魔影织者
  ["0xF13000EF0C27481E"] = UNMARKED, -- 劣魔原猎者
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "imps7", {
  ["0xF13000EF0C2747FD"] = UNMARKED, -- 劣魔原猎者
  ["0xF13000EF0B2747FA"] = SKULL, -- 劣魔影织者
  ["0xF13000EF0D2747FE"] = UNMARKED, -- 劣魔魔导师
  ["0xF13000EF0B2747FC"] = CROSS, -- 劣魔影织者
  ["0xF13000EF0C2747FF"] = UNMARKED, -- 劣魔原猎者
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "spiderpats", {
  ["0xF130003A212755BA"] = UNMARKED, -- 蜘蛛
  ["0xF13000EF16274778"] = UNMARKED, -- 掠网爬行者
  ["0xF13000EF1927477B"] = UNMARKED, -- 掠网跳跃者
  ["0xF13000EF16274776"] = UNMARKED, -- 掠网爬行者
  ["0xF13000EF152756C3"] = CROSS, -- 幻影仆从
  ["0xF13000EF1627477E"] = UNMARKED, -- 掠网爬行者
  ["0xF13000EF16274772"] = UNMARKED, -- 掠网爬行者
  ["0xF13000EF182747F4"] = TRIANGLE, -- 掠网毒牙蛛
  ["0xF13000EF19274775"] = UNMARKED, -- 掠网跳跃者
  ["0xF13000EF1827477A"] = SKULL, -- 掠网毒牙蛛
  ["0xF13000EF1827475C"] = SQUARE, -- 掠网毒牙蛛
  ["0xF13000EF18274753"] = CIRCLE, -- 掠网毒牙蛛
  ["0xF13000EF19274774"] = UNMARKED, -- 掠网跳跃者
  ["0xF13000EF16274777"] = UNMARKED, -- 掠网爬行者
  ["0xF130003A212755B3"] = UNMARKED, -- 蜘蛛
  ["0xF13000EF1627477F"] = UNMARKED, -- 掠网爬行者
  ["0xF13000EF19274773"] = UNMARKED, -- 掠网跳跃者
  ["0xF130003A212755B2"] = UNMARKED, -- 蜘蛛
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "moroes1", {
  ["0xF13000EF072747D5"] = SKULL, -- 影刺前锋
  ["0xF13000EF0A2747D7"] = UNMARKED, -- 影刺怒牙
  ["0xF13000EF082747EF"] = CROSS, -- 影刺暗法师
  ["0xF13000EF0F2756DE"] = CIRCLE, -- 碎笼骨法师
  ["0xF13000EF0A2747D6"] = UNMARKED, -- 影刺怒牙
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "moroes2", {
  ["0xF13000EF0F2756DD"] = CROSS, -- 碎笼骨法师
  ["0xF13000EF0F2756E3"] = DIAMOND, -- 碎笼骨法师
  ["0xF13000EF0F2756E4"] = TRIANGLE, -- 碎笼骨法师
  ["0xF13000EF0F2756DE"] = CIRCLE, -- 碎笼骨法师
  ["0xF13000EF0F2756DC"] = SKULL, -- 碎笼骨法师
  })

addToDefaultNpcsToMark(L["Tower of Karazhan"], "moroes3", {
  ["0xF13000EF0E274841"] = UNMARKED, -- 碎笼矛兵
  ["0xF13000EF0E27483D"] = UNMARKED, -- 碎笼矛兵
  ["0xF13000EF1027484C"] = CROSS, -- 幻影守卫
  ["0xF13000EF0E274842"] = UNMARKED, -- 碎笼矛兵
  ["0xF13000EF0E27483E"] = UNMARKED, -- 碎笼矛兵
  ["0xF13000EF10274840"] = UNMARKED, -- 幻影守卫
  ["0xF13000EF0827483C"] = SKULL, -- 影刺暗法师
  ["0xF13000EF0F27482A"] = CIRCLE, -- 碎笼骨法师
  ["0xF13000EF0E27483F"] = STAR, -- 碎笼矛兵
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "moroes4", {
  ["0xF13000EF15274838"] = TRIANGLE, -- 幻影仆从
  ["0xF13000EF19274828"] = UNMARKED, -- 掠网跳跃者
  ["0xF13000EF15274839"] = SKULL, -- 幻影仆从
  ["0xF13000EF1027483A"] = UNMARKED, -- 幻影守卫
  ["0xF13000EF16274826"] = UNMARKED, -- 掠网爬行者
  ["0xF13000EF15274832"] = DIAMOND, -- 幻影仆从
  ["0xF13000EF15274837"] = CROSS, -- 幻影仆从
  ["0xF13000EF16274827"] = UNMARKED, -- 掠网爬行者
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "moroes5", {
  ["0xF13000EF15274845"] = SKULL, -- 幻影仆从
  ["0xF13000EF10274849"] = UNMARKED, -- 幻影守卫
  ["0xF13000EF15274847"] = CROSS, -- 幻影仆从
  ["0xF13000EF15274832"] = DIAMOND, -- 幻影仆从
})

--/////////////// Kara40 ///////////////


addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_patrols", {
  ["0xF13000F1F0276B43"] = 8, -- 影爪暗行者
  ["0xF13000F1F0276B48"] = 6, -- 影爪暗行者
  ["0xF13000F1F0276B4A"] = 7, -- 影爪暗行者
  ["0xF13000F1F1276B46"] = 5, -- 影爪狼人
  ["0xF13000F1EC276B44"] = 4, -- 吸血暗翼
  ["0xF13000F1F2276B2C"] = 3, -- 影爪狂暴者
  ["0xF13000F1ED276B19"] = 2, -- 大型暗翼
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_1", {
  ["0xF13000F1EE276B1F"] = SKULL, -- 幽灵工人
  ["0xF13000F1EE276B20"] = SQUARE, -- 幽灵工人
  ["0xF13000F1EE276B21"] = CROSS, -- 幽灵工人
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_2", {
  ["0xF13000F1EE276B25"] = SKULL, -- 幽灵工人
  ["0xF13000F1F1276B24"] = CROSS, -- 影爪狼人
  ["0xF13000F1F1276B23"] = SQUARE, -- 影爪狼人
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_worgen_1", {
  ["0xF13000F1F1276B29"] = TRIANGLE, -- 影爪狼人
  ["0xF13000F1F1276B2B"] = SQUARE, -- 影爪狼人
  ["0xF13000F1F1276B27"] = MOON, -- 影爪狼人
  ["0xF13000F1F0276B28"] = SKULL, -- 影爪暗行者
  ["0xF13000F1F2276B26"] = CROSS, -- 影爪狂暴者
  ["0xF13000F1F1276B57"] = DIAMOND, -- 影爪狼人
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_worgen_2", {
  ["0xF13000F1F0276B33"] = 8, -- 影爪暗行者
  ["0xF13000F1EC276B2D"] = 5, -- 吸血暗翼
  ["0xF13000F1ED276B2E"] = 4, -- 大型暗翼
  ["0xF13000F1EF276B36"] = 7, -- 暮牙爬行者
  ["0xF13000F1F2276B31"] = 6, -- 影爪狂暴者
  ["0xF13000F1ED276B2F"] = 3, -- 大型暗翼
  ["0xF13000F1F1276B30"] = 2, -- 影爪狼人
  ["0xF13000F1F1276B32"] = 1, -- 影爪狼人
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_worker", {
  ["0xF13000F1EE276B34"] = SKULL, -- 幽灵工人
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_outer", {
  ["0xF13000F1ED276B39"] = SQUARE, -- 大型暗翼
  ["0xF13000F1EE276B37"] = SKULL, -- 幽灵工人
  ["0xF13000F1EE276B38"] = CROSS, -- 幽灵工人
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_outer_2", {
  ["0xF13000F1EE276B3B"] = SKULL, -- 幽灵工人
  ["0xF13000F1F1276B3A"] = CROSS, -- 影爪狼人
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_outer_3", {
  ["0xF13000F1F2276B41"] = SQUARE, -- 影爪狂暴者
  ["0xF13000F1F2276B42"] = CROSS, -- 影爪狂暴者
  ["0xF13000F1F1276B3D"] = TRIANGLE, -- 影爪狼人
  ["0xF13000F1F1276B3E"] = MOON, -- 影爪狼人
  ["0xF13000F1F0276B40"] = SKULL, -- 影爪暗行者
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_inner_2", {

})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_gnarlmoon", {
  ["0xF13000F1F2276B51"] = TRIANGLE, -- 影爪狂暴者
  ["0xF13000F1F0276B4F"] = CROSS, -- 影爪暗行者
  ["0xF13000F1F1276B54"] = DIAMOND, -- 影爪狼人
  ["0xF13000F1F2276B52"] = MOON, -- 影爪狂暴者
  ["0xF13000F1F0276B53"] = SKULL, -- 影爪暗行者
  ["0xF13000F1F1276B55"] = CIRCLE, -- 影爪狼人
  ["0xF13000F1F0276B50"] = SQUARE, -- 影爪暗行者
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_upper_demon_3", {
  ["0xF13000F48C278713"] = DIAMOND, -- 荒芜的入侵者
  ["0xF13000F48C278714"] = SKULL, -- 荒芜的入侵者
  ["0xF13000F48D278715"] = CROSS, -- 荒芜的毁灭者
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_inner_1", {

})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "gnarlmoon_owls", {
  ["0xF13000EA5E278C14"] = STAR,     -- blue owl 1, fake id
  ["0xF13000EA5E278C15"] = CIRCLE,   -- blue owl 2, fake id
  ["0xF13000EA5D278C16"] = DIAMOND,  -- red owl 1, fake id
  ["0xF13000EA5D278C17"] = TRIANGLE, -- red owl 2, fake id
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_1", {
  ["0xF13000F1F8276B9C"] = CROSS, -- 魔鳞织法者
  ["0xF13000F1F7276B9E"] = SKULL, -- 魔鳞抑法者
  ["0xF13000F1F6276B9B"] = SQUARE, -- 魔鳞护龙者
  ["0xF13000EA54276B8A"] = UNMARKED, -- 魔鳞幼龙 ??wrong id??
  ["0xF13000F1F8276B9F"] = DIAMOND, -- 魔鳞织法者
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_patrols", {
  ["0xF13000F1F7276B70"] = DIAMOND, -- 魔鳞抑法者
  ["0xF13000F1F6276B8C"] = STAR, -- 魔鳞护龙者 ??wrong id??
  ["0xF13000F1F7276BA0"] = TRIANGLE, -- 魔鳞抑法者
  ["0xF13000F1F9276B5F"] = CIRCLE, -- 魔鳞监工
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_2", {
  ["0xF13000EA54276B98"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000EA54276B9A"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000F1F8276B97"] = SKULL, -- 魔鳞织法者
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_3", {
  ["0xF13000EA54276B66"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000F1F8276B61"] = CROSS, -- 魔鳞织法者
  ["0xF13000EA54276B63"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000EA54276B65"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000F1F8276B62"] = SKULL, -- 魔鳞织法者
  ["0xF13000F1F6276B60"] = SQUARE, -- 魔鳞护龙者
  ["0xF13000EA54276B64"] = UNMARKED, -- 魔鳞幼龙
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_4", {
  ["0xF13000EA54276B8E"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000F1F4276B71"] = SKULL, -- 魔鳞巨龙
  ["0xF13000EA54276B94"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000EA54276B91"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000EA54276B92"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000EA54276B96"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000EA54276B8F"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000EA54276B93"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000EA54276B8D"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000EA54276B95"] = UNMARKED, -- 魔鳞幼龙
})

-- skippable
addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_5", {
  ["0xF13000F1F8276B80"] = CROSS,
  ["0xF13000F1F8276B81"] = SQUARE,
  ["0xF13000F1F8276B82"] = SKULL,
})

-- skippable
addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_6", {
  ["0xF13000EA54276B79"] = UNMARKED,
  ["0xF13000EA54276B7B"] = UNMARKED,
  ["0xF13000F1F8276B73"] = SQUARE,
  ["0xF13000F1F6276B72"] = MOON,
  ["0xF13000EA54276B76"] = UNMARKED,
  ["0xF13000F1F7276B75"] = SKULL,
  ["0xF13000F1F7276B74"] = CROSS,
  ["0xF13000EA54276B7F"] = UNMARKED,
  ["0xF13000EA54276B7C"] = UNMARKED,
  ["0xF13000EA54276B7D"] = UNMARKED,
  ["0xF13000EA54276B7E"] = UNMARKED,
  ["0xF13000EA54276B77"] = UNMARKED,
  ["0xF13000EA54276B78"] = UNMARKED,
  ["0xF13000EA54276B7A"] = UNMARKED,
})

-- skippable
addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_7", {
  ["0xF13000EA54276BA8"] = UNMARKED,
  ["0xF13000F1F7276BA4"] = SKULL,
  ["0xF13000F1F7276BA3"] = CROSS,
  ["0xF13000EA54276BA7"] = UNMARKED,
  ["0xF13000EA54276BA6"] = UNMARKED,
  ["0xF13000EA54276BAB"] = UNMARKED,
  ["0xF13000F1F8276BA2"] = SQUARE,
  ["0xF13000EA54276BA9"] = UNMARKED,
  ["0xF13000F1F6276BA1"] = TRIANGLE,
  ["0xF13000F1F6276BA5"] = MOON,
  ["0xF13000EA54276BAC"] = UNMARKED,
  ["0xF13000EA54276BAA"] = UNMARKED,
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_8", {
  ["0xF13000F1F7276BAF"] = 7, -- 魔鳞抑法者
  ["0xF13000F1F8276BB0"] = 6, -- 魔鳞织法者
  ["0xF13000F1F6276BB1"] = 5, -- 魔鳞护龙者
  ["0xF13000F1F6276BB2"] = 4, -- 魔鳞护龙者
  ["0xF13000F1F4276BAE"] = 8, -- 魔鳞巨龙
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "incantagos_seekers", {
  ["0xF13000EA55278B84"] = SQUARE, -- 魔鳞魔网搜寻者
  ["0xF13000EA55278B83"] = CROSS, -- 魔鳞魔网搜寻者
  ["0xF13000EA55278B82"] = MOON, -- 魔鳞魔网搜寻者
  ["0xF13000EA55278B81"] = SKULL, -- 魔鳞魔网搜寻者
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_upper_1", {
  ["0xF13000F1F8276BC0"] = SQUARE, -- 魔鳞织法者
  ["0xF13000F1F72783E5"] = SKULL, -- 魔鳞抑法者
  ["0xF13000F1F62783E9"] = MOON, -- 魔鳞护龙者
  ["0xF13000F1F62783E7"] = TRIANGLE, -- 魔鳞护龙者
  ["0xF13000EA54276BBE"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000EA54276BBF"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000EA54276BBB"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000EA54276BBC"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000F1F82783E8"] = CROSS, -- 魔鳞织法者
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_upper_patrols", {
  ["0xF13000F1F6276BC1"] = DIAMOND, -- 魔鳞护龙者
  ["0xF13000F1FE276BD6"] = CIRCLE, -- 异常的法力
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_upper_2", {
  ["0xF13000F1F7276BC2"] = CROSS, -- 魔鳞抑法者
  ["0xF13000EA54276BC9"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000EA54276BC5"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000EA54276BCA"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000EA54276BC7"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000EA54276BC8"] = UNMARKED, -- 魔鳞幼龙
  ["0xF13000F1F7276BC3"] = SKULL, -- 魔鳞抑法者
  ["0xF13000F1FC2783E4"] = SQUARE, -- 不稳定的奥术元素
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_upper_3", {
  ["0xF13000F1FC276BCE"] = STAR, -- 不稳定的奥术元素
  ["0xF13000F1F7276BCB"] = SKULL, -- 魔鳞抑法者
  ["0xF13000F1FB276BCC"] = MOON, -- 溢出的法力
  ["0xF13000F1FB276BCF"] = SQUARE, -- 溢出的法力
  ["0xF13000F1FB276BCD"] = CROSS, -- 溢出的法力
  ["0xF13000F1FC2783E3"] = DIAMOND, -- 不稳定的奥术元素
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_anomalus", {
  ["0xF13000F1FD276BDA"] = SKULL, -- 破碎的奥术元素
  ["0xF13000F1FB276BD8"] = CROSS, -- 溢出的法力
  ["0xF13000F1FB276BDB"] = SQUARE, -- 溢出的法力
  ["0xF13000F1FB2783E2"] = MOON, -- 溢出的法力
  ["0xF13000F1FC276BDC"] = DIAMOND, -- 不稳定的奥术元素
  ["0xF13000F1FC276BD9"] = TRIANGLE, -- 不稳定的奥术元素
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_observatory_1", {
  ["0xF13000F1FB276BE1"] = MOON, -- 溢出的法力
  ["0xF13000F1FB276BDD"] = CROSS, -- 溢出的法力
  ["0xF13000F1FE276BE0"] = DIAMOND, -- 异常的法力
  ["0xF13000F1FB276BDF"] = SQUARE, -- 溢出的法力
  ["0xF13000F1FC276BDE"] = TRIANGLE, -- 不稳定的奥术元素
  ["0xF13000F1FD2783E1"] = SKULL, -- 破碎的奥术元素
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_observatory_patrols", {
  ["0xF13000F1FB276D3D"] = MOON, -- 溢出的法力
  ["0xF13000F203276D40"] = SKULL, -- 徘徊的工匠
  ["0xF13000F1FB276D3F"] = SQUARE, -- 溢出的法力
  ["0xF13000F1F7276D3C"] = TRIANGLE, -- 魔鳞抑法者
  ["0xF13000F205276D3E"] = CROSS, -- 徘徊的魔法师
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_observatory_2", {
  ["0xF13000F204276D36"] = 7, -- 徘徊的占星家
  ["0xF13000F203276D37"] = 8, -- 徘徊的工匠
  ["0xF13000F202276D35"] = 6, -- 徘徊的魔术师
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_observatory_left", {
  ["0xF13000F202276D38"] = CROSS, -- 徘徊的魔术师
  ["0xF13000F205276D39"] = MOON, -- 徘徊的魔法师
  ["0xF13000F202276D3A"] = SQUARE, -- 徘徊的魔术师
  ["0xF13000F204276D3B"] = SKULL, -- 徘徊的占星家
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_observatory_3", {
  ["0xF13000F1FE276D4D"] = SKULL, -- 异常的法力
  ["0xF13000F201276D61"] = SQUARE, -- 卡拉赞守护魔像
  ["0xF13000F201276D60"] = CROSS, -- 卡拉赞守护魔像
  ["0xF13000F1FD2783DF"] = 5, -- 破碎的奥术元素
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_observatory_6", {
  ["0xF13000F200276D68"] = SKULL, -- 摇摇欲坠的保护者
  ["0xF13000F203276D52"] = SQUARE, -- 徘徊的工匠 
  ["0xF13000F201276D66"] = MOON, -- 卡拉赞守护魔像
  ["0xF13000F201276D67"] = TRIANGLE, -- 卡拉赞守护魔像
  ["0xF13000F202276D51"] = CROSS, -- 徘徊的魔术师
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_echo_pre_1", {
  ["0xF13000F203276D2F"] = 8, -- 徘徊的工匠
  ["0xF13000F205276D33"] = 4, -- 徘徊的魔法师
  ["0xF13000F204276D32"] = 7, -- 徘徊的占星家
  ["0xF13000F202276D31"] = 5, -- 徘徊的魔术师
  ["0xF13000F202276D30"] = 6, -- 徘徊的魔术师
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_echo_pre_2_1", {
  ["0xF13000F200276D62"] = SKULL, -- 摇摇欲坠的保护者
  ["0xF13000F202276D2E"] = CROSS, -- 徘徊的魔术师
  ["0xF13000F1FE2783E6"] = SQUARE, -- 异常的法力
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_echo_pre_2_2", {
  ["0xF13000F200276D63"] = 5, -- 摇摇欲坠的保护者
  ["0xF13000F204276D2B"] = 7, -- 徘徊的占星家
  ["0xF13000F205276D2C"] = 6, -- 徘徊的魔法师
  ["0xF13000F203276D2D"] = 8, -- 徘徊的工匠
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_chess_1", {
  ["0xF13000F1FB276D47"] = MOON, -- 溢出的法力
  ["0xF13000F200276D64"] = SKULL, -- 摇摇欲坠的保护者
  ["0xF13000F201276D65"] = TRIANGLE, -- 卡拉赞守护魔像
  ["0xF13000F204276D4A"] = SQUARE, -- 徘徊的占星家
  ["0xF13000F202276D49"] = CROSS, -- 徘徊的魔术师
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_chess_2", {
  ["0xF13000F1FD2783E0"] = SQUARE, -- 破碎的奥术元素
  ["0xF13000F204276D4A"] = CROSS, -- 徘徊的占星家
  ["0xF13000F202276D49"] = SKULL, -- 徘徊的魔术师
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_chess_3", {
  ["0xF13000F201276D66"] = TRIANGLE, -- 卡拉赞守护魔像
  ["0xF13000F203276D52"] = CROSS, -- 徘徊的工匠
  ["0xF13000F201276D67"] = MOON, -- 卡拉赞守护魔像
  ["0xF13000F202276D51"] = SKULL, -- 徘徊的魔术师
  ["0xF13000F200276D68"] = SQUARE, -- 摇摇欲坠的保护者
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_chess", {
  ["0xF13000EA42276C07"] = CIRCLE, -- 战车
  ["0xF13000BF75278779"] = SKULL, -- 干枯的主教
  ["0xF13000EA40276C08"] = TRIANGLE, -- 骑士
  ["0xF13000EA43276C06"] = DIAMOND, -- 主教
  ["0xF13000BF74278778"] = SQUARE, -- 损坏的战车
  ["0xF13000BF76278777"] = CROSS, -- 失控的骑士
  ["0xF13000EA3F276C05"] = STAR, -- 国王
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_foyer_1", {
  ["0xF13000F203276D54"] = 8, -- 徘徊的工匠
  ["0xF13000F205276D55"] = 5, -- 徘徊的魔法师
  ["0xF13000F202276D53"] = 6, -- 徘徊的魔术师
  ["0xF13000F204276D56"] = 7, -- 徘徊的占星家
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_foyer_2", {
  ["0xF13000F202276D57"] = 6, -- 徘徊的魔术师
  ["0xF13000F205276D5A"] = 5, -- 徘徊的魔法师
  ["0xF13000F203276D5B"] = 8, -- 徘徊的工匠
  ["0xF13000F204276D58"] = 7, -- 徘徊的占星家
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_foyer_3", {
  ["0xF13000F48F278747"] = CROSS, -- 被遗忘的回响
  ["0xF13000F48F278746"] = SKULL, -- 被遗忘的回响
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_roof", {
  ["0xF13000F48F278741"] = SKULL, -- 被遗忘的回响
  ["0xF13000F48F27873F"] = SQUARE, -- 被遗忘的回响
  ["0xF13000F48F278740"] = CROSS, -- 被遗忘的回响
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_upper_demon_1", {
  ["0xF13000F48D278726"] = 7, -- 荒芜的毁灭者
  ["0xF13000F48C278725"] = 6, -- 荒芜的入侵者
  ["0xF13000F48C278724"] = 8, -- 荒芜的入侵者
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_upper_demon_2", {
  ["0xF13000F48C278713"] = 6, -- Desolate 荒芜的入侵者
  ["0xF13000F48C278714"] = 8, -- Desolate 荒芜的入侵者
  ["0xF13000F48D278715"] = 7, -- Desolate 荒芜的毁灭者
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_upper_demon_3", {
  ["0xF13000F48C278710"] = 6, -- Desolate 荒芜的入侵者
  ["0xF13000F48C278711"] = 8, -- Desolate 荒芜的入侵者
  ["0xF13000F48D278712"] = 7, -- Desolate 荒芜的毁灭者
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_upper_demon_4", {
  ["0xF13000F48C27870F"] = 6, -- 荒芜的入侵者
  ["0xF13000F48D27870D"] = 5, -- 荒芜的毁灭者
  ["0xF13000F48E27870B"] = 8, -- 伊玛高尔，荒芜的先驱
  ["0xF13000F48D27870C"] = 7, -- 荒芜的毁灭者
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "darkbinders1", {
  ["0xF13000F243276CCD"] = SKULL, -- 战争使者监军
  ["0xF13000F245276CE7"] = CROSS, -- 德莱尼黑暗缚灵者
  ["0xF13000F245276CE6"] = SQUARE, -- 德莱尼黑暗缚灵者
  ["0xF13000F244276C76"] = MOON, -- souleater
})
addToDefaultNpcsToMark(L["The Rock of Desolation"], "village_1", {
  ["0xF13000F243276CCC"] = SKULL, -- 战争使者监军
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "village_2", {
  ["0xF13000F240276CCB"] = SKULL, -- 末日守卫歼灭者
  ["0xF13000F242276CC9"] = CROSS, -- 黑焰小鬼
  ["0xF13000F242276CC8"] = SQUARE, -- 黑焰小鬼
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "village_3", {
  ["0xF13000F245276CD7"] = SKULL, -- 德莱尼黑暗缚灵者
  ["0xF13000F245276CE2"] = CROSS, -- 德莱尼黑暗缚灵者
  ["0xF13000F246276CDF"] = UNMARKED, -- 德莱尼信徒
  ["0xF13000F246276CE1"] = UNMARKED, -- 德莱尼信徒
  ["0xF13000F246276CE0"] = UNMARKED, -- 德莱尼信徒
  ["0xF13000F246276CDE"] = UNMARKED, -- 德莱尼信徒
  ["0xF13000F245276CD6"] = SQUARE, -- 德莱尼黑暗缚灵者
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "infernal_2", {
  ["0xF13000F241276D0A"] = SKULL, -- 地狱火毁灭者
  ["0xF13000F242276D0C"] = UNMARKED, -- 黑焰小鬼
  ["0xF13000F242276D0D"] = UNMARKED, -- 黑焰小鬼
  ["0xF13000F242276D0B"] = UNMARKED, -- 黑焰小鬼
  ["0xF13000F242276D0E"] = UNMARKED, -- 黑焰小鬼
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "sanv_1", {
  ["0xF13000F245276CDA"] = SKULL, -- 德莱尼黑暗缚灵者
  ["0xF13000F244276CD9"] = CROSS, -- 被流放的食魂者
  ["0xF13000F244276CD8"] = SQUARE, -- 被流放的食魂者
  ["0xF13000F246276CDD"] = UNMARKED, -- 德莱尼信徒
  ["0xF13000F246276CDB"] = UNMARKED, -- 德莱尼信徒
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "sanv_2", {
  ["0xF13000F245276C92"] = SKULL, -- 德莱尼黑暗缚灵者
  ["0xF13000F244276C94"] = CROSS, -- 被流放的食魂者
  ["0xF13000F246276C85"] = UNMARKED, -- 德莱尼信徒
  ["0xF13000F246276C7D"] = UNMARKED, -- 德莱尼信徒
  ["0xF13000F246276C80"] = UNMARKED, -- 德莱尼信徒
  ["0xF13000F246276C81"] = UNMARKED, -- 德莱尼信徒
  ["0xF13000F246276C7F"] = UNMARKED, -- 德莱尼信徒
  ["0xF13000F246276C82"] = UNMARKED, -- 德莱尼信徒
  ["0xF13000F246276C83"] = UNMARKED, -- 德莱尼信徒
})
addToDefaultNpcsToMark(L["The Rock of Desolation"], "sanv_3", {
  ["0xF13000F245276C8E"] = SKULL, -- 德莱尼黑暗缚灵者
  ["0xF13000F245276C8F"] = CROSS, -- 德莱尼黑暗缚灵者
  ["0xF13000F244276C8D"] = SQUARE, -- 被流放的食魂者
  ["0xF13000F246276C7E"] = UNMARKED, -- 德莱尼信徒
  ["0xF13000F246276C91"] = UNMARKED, -- 德莱尼信徒
  ["0xF13000F246276C90"] = UNMARKED, -- 德莱尼信徒
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "sanv_4", {
  ["0xF13000F245276C87"] = SKULL, -- 德莱尼黑暗缚灵者
  ["0xF13000F245276C86"] = CROSS, -- 德莱尼黑暗缚灵者
  ["0xF13000F244276C88"] = SQUARE, -- 被流放的食魂者
  ["0xF13000F246276C84"] = UNMARKED, -- 德莱尼信徒
  ["0xF13000F246276C8C"] = UNMARKED, -- 德莱尼信徒
  ["0xF13000F246276C8B"] = UNMARKED, -- 德莱尼信徒
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "sanv_5", {
  ["0xF13000EA4C05DA46"] = SKULL, -- 德莱尼朝圣者
  ["0xF13000EA4C05DA45"] = CROSS, -- 德莱尼朝圣者
  ["0xF13000EA4D05DA44"] = SQUARE, -- 桑夫·塔斯达尔
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "pre_rupturan_1", {
  ["0xF13000F241276CBE"] = SKULL, -- Infernal 荒芜的毁灭者
  ["0xF13000F242276CC7"] = UNMARKED, -- 黑焰小鬼
  ["0xF13000F242276CC4"] = UNMARKED, -- 黑焰小鬼
  ["0xF13000F242276CC6"] = UNMARKED, -- 黑焰小鬼
  ["0xF13000F242276CC3"] = UNMARKED, -- 黑焰小鬼
  ["0xF13000F242276CC5"] = UNMARKED, -- 黑焰小鬼
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "rupturan_exile", {
  ["0xF13000EA38073D39"] = SKULL, -- 摇摇欲坠的流放者
  ["0xF13000EA38073D38"] = CROSS, -- 摇摇欲坠的流放者
  ["0xF13000EA38073D37"] = SQUARE, -- 摇摇欲坠的流放者
  ["0xF13000EA38073D36"] = MOON, -- 摇摇欲坠的流放者
  ["0xF13000EA39073D35"] = UNMARKED,-- 破碎者鲁普图兰
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "rupturan_fragments", {
  ["0xF13000EA35279A2F"] = SKULL, -- 鲁普图兰的碎块, fake id
  ["0xF13000EA35279A30"] = CROSS, -- 鲁普图兰的碎块, fake id
  ["0xF13000EA35279A31"] = SQUARE, -- 鲁普图兰的碎块, fake id
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "outland_patrols", {
  ["0xF13000F240276CB1"] = 3, -- 末日守卫歼灭者
  ["0xF13000F241276D09"] = 2, -- 地狱火毁灭者
  ["0xF13000F245276CAA"] = 4, -- 德莱尼黑暗缚灵者
  ["0xF13000F241276D0A"] = 5,-- 地狱火毁灭者
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "pre_kruul_3", {
  ["0xF13000F245276CA7"] = 5, -- 德莱尼黑暗缚灵者
  ["0xF13000F244276CB8"] = 7, -- 被流放的食魂者
  ["0xF13000F246276CA8"] = 8, -- 德莱尼信徒
  ["0xF13000F244276CA9"] = 6, -- 被流放的食魂者
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "pre_kruul_4", {
  ["0xF13000F240276CB6"] = 8, -- 末日守卫歼灭者
  ["0xF13000F244276CB4"] = 7, -- 被流放的食魂者
  ["0xF13000F245276CB3"] = 6, -- 德莱尼黑暗缚灵者
})


addToDefaultNpcsToMark(L["The Rock of Desolation"], "pre_kruul_1", {
  ["0xF13000F240276D11"] = CROSS, -- 末日守卫歼灭者
  ["0xF13000F240276D10"] = SQUARE, -- 末日守卫歼灭者
  ["0xF13000F243276D0F"] = SKULL, -- 战争使者监军
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "pre_kruul_2", {
  ["0xF13000F23F276D12"] = SKULL, -- 恐惧魔王末日搜寻者
  ["0xF13000F23F276D17"] = CROSS, -- 恐惧魔王末日搜寻者
  ["0xF13000F23F276D14"] = SQUARE, -- 恐惧魔王末日搜寻者
  ["0xF13000F23F276D13"] = MOON, -- 恐惧魔王末日搜寻者
  ["0xF13000F23F276D15"] = TRIANGLE, -- 恐惧魔王末日搜寻者
  ["0xF13000F23F276D16"] = DIAMOND, -- 恐惧魔王末日搜寻者
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "mephistroth", {
  ["0xF130016C98271234"] = CROSS, -- 狱火末日卫士, fake id
  ["0xF130016C98271235"] = SKULL, -- 狱火末日卫士, fake id
})

--/////////////// Stratholme ///////////////

addToDefaultNpcsToMark(L["Stratholme"], "live_pats", {
  ["0xF1300028AB11E66A"] = STAR, -- 纳克萨玛斯之眼
  ["0xF1300028AB11E66B"] = TRIANGLE, -- 纳克萨玛斯之眼
  ["0xF1300028AE00D2C1"] = SQUARE, -- 缝补憎恶
  ["0xF1300028AE00D2C2"] = CIRCLE, -- 缝补憎恶
  ["0xF1300028AE00D2B7"] = DIAMOND, -- 缝补憎恶
})

addToDefaultNpcsToMark(L["Stratholme"], "dead_pats", {
  ["0xF1300028A800D22E"] = SKULL, -- 石翼石像鬼
  ["0xF1300028A800D22B"] = CROSS, -- 石翼石像鬼
  ["0xF1300028A800D229"] = SQUARE, -- 石翼尖啸者
  ["0xF1300028A800D227"] = MOON, -- 石翼石像鬼
  ["0xF1300028A800D225"] = TRIANGLE, -- 石翼尖啸者
  ["0xF1300028A800D223"] = DIAMOND, -- 石翼尖啸者
  ["0xF1300028A800D221"] = CIRCLE, -- 石翼尖啸者
  -- ["0xF130002A3900D22F"] = STAR,-- Stonespine -- need the mark for eye
  ["0xF1300028AB11E66C"] = STAR, -- 纳克萨玛斯之眼
})

--/////////////// Timbermaw Hold ///////////////

addToDefaultNpcsToMark(L["Timbermaw Hold"], "entrance_1", {
  ["0xF13000F59C279368"] = CROSS, -- 枯喉守卫
  ["0xF13000F59B279367"] = SQUARE, -- 枯喉追踪者
  ["0xF13000F598279366"] = DIAMOND, -- 枯喉探路者
  ["0xF13000F599279370"] = SKULL, -- 枯喉图腾师
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "entrance_2", {
  ["0xF13000F59627936B"] = SKULL, -- 枯喉污染者
  ["0xF13000F59727936E"] = CROSS, -- 枯喉萨满祭司
  ["0xF13000F599279735"] = SQUARE, -- 枯喉图腾师
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "entrance_3", {
  ["0xF13000F596279739"] = SKULL, -- 枯喉污染者
  ["0xF13000F597279737"] = SQUARE, -- 枯喉萨满祭司
  ["0xF13000F596279738"] = CROSS, -- 枯喉污染者
  ["0xF13000F59927936F"] = MOON, -- 枯喉图腾师 -- random loner
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_lower_1", {
  ["0xF13000F59C279D57"] = CROSS, -- 枯喉守卫
  ["0xF13000F596279D58"] = SKULL, -- 枯喉污染者
  ["0xF13000F598279D59"] = SQUARE, -- 枯喉探路者
  ["0xF13000F598279D5A"] = MOON, -- 枯喉探路者
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_lower_loose", {
  ["0xF13000F596279D61"] = SKULL, -- 枯喉污染者
  ["0xF13000F59F279D60"] = CROSS, -- 落潭的腐根
  ["0xF13000F5A5279D5C"] = DIAMOND, -- 乌索尔之子
  ["0xF13000F59E279D5E"] = CIRCLE, -- 被污染的胶团
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_lower_2", {
  ["0xF13000F59F279D62"] = SKULL, -- 落潭的腐根
  ["0xF13000F59F279D63"] = CROSS, -- 落潭的腐根
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_ramp_1", {
  ["0xF13000F59D279D6B"] = CROSS, -- 枯喉巨熊怪
  ["0xF13000F596279D6C"] = SKULL, -- 枯喉污染者
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_ramp_2", {
  ["0xF13000F59F279D7E"] = SKULL, -- 落潭的腐根
  ["0xF13000F5A2279D81"] = CROSS, -- 腐心萨特
  ["0xF13000F5A1279D7F"] = SQUARE, -- 腐心欺诈者
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_ramp_3", {
  ["0xF13000F5A3279D86"] = SKULL, -- 腐心诡术师
  ["0xF13000F5A2279D87"] = CROSS, -- 腐心萨特
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "satyr_1", {
  ["0xF13000F5A2279D82"] = SKULL, -- 腐心萨特
  ["0xF13000F5A2279D83"] = CROSS, -- 腐心萨特
  ["0xF13000F5A1279D84"] = SQUARE, -- 腐心欺诈者
  ["0xF13000F5A1279D85"] = MOON, -- 腐心欺诈者
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "satyr_2", {
  ["0xF13000F5A4279D89"] = SKULL, -- 腐心唤魔者
  ["0xF13000F5A2279D8A"] = CROSS, -- 腐心萨特
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "satyr_3", {
  ["0xF13000F5A2279D8B"] = SKULL, -- 腐心萨特
  ["0xF13000F5A3279D91"] = CROSS, -- 腐心诡术师
  ["0xF13000F5A2279D90"] = SQUARE, -- 腐心萨特
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "satyr_4", {
  ["0xF13000F5A3279D8F"] = SKULL, -- 腐心诡术师
  ["0xF13000F5A4279D8D"] = CROSS, -- 腐心唤魔者
  ["0xF13000F5A2279D8C"] = SQUARE, -- 腐心萨特
  ["0xF13000F5A1279D8E"] = MOON, -- 腐心欺诈者
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "satyr_5", {
  ["0xF13000F5A1279D9A"] = SKULL, -- 腐心欺诈者
  ["0xF13000F5A2279D99"] = CROSS, -- 腐心萨特
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "satyr_6", {
  ["0xF13000F5A1279D96"] = SKULL, -- 腐心欺诈者
  ["0xF13000F5A4279D97"] = CROSS, -- 腐心唤魔者
  ["0xF13000F5A4279D98"] = SQUARE, -- 腐心唤魔者
  ["0xF13000F5A2279D95"] = MOON, -- 腐心萨特
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "karrsh_2", {
  ["0xF13000F5D627973C"] = UNMARKED, -- 哨兵卡什
  ["0xF13000F59627973E"] = SKULL, -- 枯喉污染者
  ["0xF13000F59327973F"] = CROSS, -- 暴怒的枯喉熊怪
  ["0xF13000F593279740"] = MOON, -- 暴怒的枯喉熊怪
  ["0xF13000F593279741"] = SQUARE, -- 暴怒的枯喉熊怪
})

-- TODO: karrsh_1 has identical GUIDs/marks as left_upper_1 - need to resolve this over time
addToDefaultNpcsToMark(L["Timbermaw Hold"], "left_upper_1", {
  ["0xF13000F59C279D4F"] = SKULL, -- 枯喉守卫
  ["0xF13000F599279D51"] = CROSS, -- 枯喉图腾师
  ["0xF13000F59B279D50"] = SQUARE, -- 枯喉追踪者
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "karrsh_1", {
  ["0xF13000F59C279D4F"] = CROSS, -- 枯喉守卫
  ["0xF13000F599279D51"] = SKULL, -- 枯喉图腾师
  ["0xF13000F59B279D50"] = SQUARE, -- 枯喉追踪者
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "left_upper_2", {
  ["0xF13000F593279D55"] = SKULL, -- 暴怒的枯喉熊怪
  ["0xF13000F593279D54"] = CROSS, -- 暴怒的枯喉熊怪
  ["0xF13000F5A5279D52"] = DIAMOND, -- 乌索尔之子
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "left_upper_3", {
  ["0xF13000F593279725"] = SKULL, -- 暴怒的枯喉熊怪
  ["0xF13000F593279722"] = CROSS, -- 暴怒的枯喉熊怪
  ["0xF13000F593279723"] = SQUARE, -- 暴怒的枯喉熊怪
  ["0xF13000F593279724"] = MOON, -- 暴怒的枯喉熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "left_upper_4", {
  ["0xF13000F59727971C"] = SQUARE, -- 枯喉萨满祭司
  ["0xF13000F59927971D"] = CROSS, -- 枯喉图腾师
  ["0xF13000F59627971E"] = SKULL, -- 枯喉污染者
  ["0xF13000F59327971F"] = UNMARKED, -- 暴怒的枯喉熊怪
  ["0xF13000F593279720"] = UNMARKED, -- 暴怒的枯喉熊怪
  ["0xF13000F593279721"] = UNMARKED, -- 暴怒的枯喉熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "left_upper_6", {
  ["0xF13000F59927971B"] = SKULL, -- 枯喉图腾师
  ["0xF13000F59327971A"] = CROSS, -- 暴怒的枯喉熊怪
  ["0xF13000F593279719"] = SQUARE, -- 暴怒的枯喉熊怪
  ["0xF13000F593279718"] = MOON, -- 暴怒的枯喉熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "left_upper_7", {
  ["0xF13000F596279717"] = SKULL, -- 枯喉污染者
  ["0xF13000F593279716"] = CROSS, -- 暴怒的枯喉熊怪
  ["0xF13000F593279715"] = SQUARE, -- 暴怒的枯喉熊怪
  ["0xF13000F593279713"] = UNMARKED, -- 暴怒的枯喉熊怪
  ["0xF13000F593279714"] = UNMARKED, -- 暴怒的枯喉熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "stump_1", {
  ["0xF13000F599279710"] = SKULL, -- 枯喉图腾师
  ["0xF13000F593279711"] = CROSS, -- 暴怒的枯喉熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "stump_2", {
  ["0xF13000F59D27970B"] = CROSS, -- 枯喉巨熊怪
  ["0xF13000F59927970C"] = SKULL, -- 枯喉图腾师
  ["0xF13000F59C27970F"] = SQUARE, -- 枯喉守卫
  ["0xF13000F59827970D"] = MOON, -- 枯喉探路者
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_1", {
  ["0xF13000F5972796CF"] = SKULL, -- 枯喉萨满祭司
  ["0xF13000F5932796CD"] = CROSS, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796CC"] = SQUARE, -- 暴怒的枯喉熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "village_1", {
  ["0xF13000F5962796C9"] = SKULL, -- 枯喉污染者
  ["0xF13000F5932796D1"] = CROSS, -- 暴怒的枯喉熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "pre_kronn", {
  ["0xF13000F59C2796C2"] = SQUARE, -- 枯喉守卫
  ["0xF13000F59B2796C3"] = MOON, -- 枯喉追踪者
  ["0xF13000F5962796C5"] = SKULL, -- 枯喉污染者
  ["0xF13000F5992796C4"] = CROSS, -- 枯喉图腾师
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_2", {
  ["0xF13000F5992796F1"] = SKULL, -- 枯喉图腾师
  ["0xF13000F5932796F5"] = CROSS, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796F2"] = SQUARE, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796F3"] = UNMARKED, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796F4"] = UNMARKED, -- 暴怒的枯喉熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_3", {
  ["0xF13000F59C2796D4"] = SKULL, -- 枯喉守卫
  ["0xF13000F59B2796D5"] = CROSS, -- 枯喉追踪者
  ["0xF13000F5982796D3"] = SQUARE, -- 枯喉探路者
  ["0xF13000F5932796D6"] = MOON, -- 暴怒的枯喉熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_2b", {
  ["0xF13000F59B2796F9"] = SKULL, -- 枯喉追踪者
  ["0xF13000F5932796FA"] = CROSS, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796FB"] = SQUARE, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796FC"] = UNMARKED, -- 暴怒的枯喉熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_4", {
  ["0xF13000F5932796DB"] = SKULL, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796D7"] = CROSS, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796D8"] = SQUARE, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796DA"] = UNMARKED, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796D9"] = UNMARKED, -- 暴怒的枯喉熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_5", {
  ["0xF13000F59C2796DE"] = SKULL, -- 枯喉守卫
  ["0xF13000F5972796DD"] = CROSS, -- 枯喉萨满祭司
  ["0xF13000F59B2796DF"] = SQUARE, -- 枯喉追踪者
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_7", {
  ["0xF13000F59D2796E1"] = SQUARE, -- 枯喉巨熊怪
  ["0xF13000F5972796E0"] = CROSS, -- 枯喉萨满祭司
  ["0xF13000F5962796E2"] = SKULL, -- 枯喉污染者
  ["0xF13000F5932796E3"] = UNMARKED, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796E4"] = UNMARKED, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796E5"] = UNMARKED, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796E6"] = UNMARKED, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796E7"] = UNMARKED, -- 暴怒的枯喉熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_6", {
  ["0xF13000F59D2796E8"] = SQUARE, -- 枯喉巨熊怪
  ["0xF13000F5992796EA"] = CROSS, -- 枯喉图腾师
  ["0xF13000F5962796E9"] = SKULL, -- 枯喉污染者
  ["0xF13000F5932796EE"] = UNMARKED, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796EB"] = UNMARKED, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796ED"] = UNMARKED, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796EC"] = UNMARKED, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796EF"] = UNMARKED, -- 暴怒的枯喉熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_illuminators", {
  ["0xF13000F5DD2796C0"] = SKULL, -- 大酋长帕萨斯
  ["0xF13000F5DE2797AD"] = SQUARE, -- 枯喉照明者
  ["0xF13000F5DE2797AE"] = MOON, -- 枯喉照明者
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_shadowkeepers", {
  ["0xF13000F5DF27ADA2"] = SKULL, -- 枯喉暗影守卫
  ["0xF13000F5DF27ADA3"] = CROSS, -- 枯喉暗影守卫
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_2c", {
  ["0xF13000F5982796F7"] = SKULL, -- 枯喉探路者
  ["0xF13000F5932796F8"] = CROSS, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796F6"] = SQUARE, -- 暴怒的枯喉熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_2d", {
  ["0xF13000F5962796FF"] = SKULL, -- 枯喉污染者
  ["0xF13000F5932796FE"] = CROSS, -- 暴怒的枯喉熊怪
  ["0xF13000F5932796FD"] = SQUARE, -- 暴怒的枯喉熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_2e", {
  ["0xF13000F59B279700"] = SKULL, -- 枯喉追踪者
  ["0xF13000F593279701"] = CROSS, -- 暴怒的枯喉熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_2f", {
  ["0xF13000F593279703"] = SKULL, -- 暴怒的枯喉熊怪
  ["0xF13000F593279702"] = CROSS, -- 暴怒的枯喉熊怪
  ["0xF13000F593279704"] = SQUARE, -- 暴怒的枯喉熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "corruption_1", {
  ["0xF13000F59F279A35"] = SKULL, -- 落潭的腐根
  ["0xF13000F59C279A34"] = CROSS, -- 枯喉守卫
  ["0xF13000F598279A33"] = SQUARE, -- 枯喉探路者
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "center_upper_2", {
  ["0xF13000F59327972A"] = SKULL, -- 暴怒的枯喉熊怪
  ["0xF13000F59327972C"] = CROSS, -- 暴怒的枯喉熊怪
  ["0xF13000F59327972B"] = SQUARE, -- 暴怒的枯喉熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "center_loose", {
  ["0xF13000F59D279730"] = DIAMOND, -- 枯喉巨熊怪
  ["0xF13000F59B27972F"] = CIRCLE, -- 枯喉追踪者
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "center_upper_1", {
  ["0xF13000F597279728"] = CROSS, -- 枯喉萨满祭司
  ["0xF13000F599279729"] = SKULL, -- 枯喉图腾师
  ["0xF13000F598279726"] = SQUARE, -- 枯喉探路者
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "left_upper_5", {
  ["0xF13000F596279731"] = SKULL, -- 枯喉污染者
  ["0xF13000F593279733"] = CROSS, -- 暴怒的枯喉熊怪
  ["0xF13000F593279732"] = SQUARE, -- 暴怒的枯喉熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "rotgrowl", {
  ["0xF13000F5D927A7C6"] = STAR, -- 腐嚎
  ["0xF13000F5D8279798"] = CROSS, -- 科迪亚克
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "corruption_2", {
  ["0xF13000F59F27975E"] = SKULL, -- 落潭的腐根
  ["0xF13000F59F27975F"] = CROSS, -- 落潭的腐根
  ["0xF13000F59E27975D"] = SQUARE, -- 被污染的胶团
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "corruption_3", {
  ["0xF13000F596279757"] = SKULL, -- 枯喉污染者
  ["0xF13000F59E279759"] = CROSS, -- 被污染的胶团
  ["0xF13000F599279758"] = SQUARE, -- 枯喉图腾师
})

-- addToDefaultNpcsToMark(L["Timbermaw Hold"], "globules_1", {
--   ["0xF13000085D27AAFC"] = SKULL, -- Corrupted Globule
--   ["0xF13000085D27AAFB"] = CROSS, -- Corrupted Globule
--   ["0xF13000085D27AAFA"] = SQUARE, -- Corrupted Globule
--   ["0xF13000085D27AAFD"] = MOON, -- Corrupted Globule
-- })

-- addToDefaultNpcsToMark(L["Timbermaw Hold"], "globules_2", {
--   ["0xF13000085D27AB04"] = SKULL, -- Corrupted Globule
--   ["0xF13000085D27AB03"] = CROSS, -- Corrupted Globule
--   ["0xF13000085D27AB02"] = SQUARE, -- Corrupted Globule
--   ["0xF13000085D27AB01"] = MOON, -- Corrupted Globule
-- })

-- addToDefaultNpcsToMark(L["Timbermaw Hold"], "globules_3", {
--   ["0xF13000085D27AB10"] = SKULL, -- Corrupted Globule
--   ["0xF13000085D27AB0F"] = CROSS, -- Corrupted Globule
--   ["0xF13000085D27AB0E"] = SQUARE, -- Corrupted Globule
--   ["0xF13000085D27AB0D"] = MOON, -- Corrupted Globule
-- })

-- addToDefaultNpcsToMark(L["Timbermaw Hold"], "globules_4", {
--   ["0xF13000085D27AB18"] = SKULL, -- Corrupted Globule
--   ["0xF13000085D27AB17"] = CROSS, -- Corrupted Globule
--   ["0xF13000085D27AB16"] = SQUARE, -- Corrupted Globule
--   ["0xF13000085D27AB15"] = MOON, -- Corrupted Globule
-- })

-- addToDefaultNpcsToMark(L["Timbermaw Hold"], "globules_5", {
--   ["0xF13000085D27AB1B"] = SKULL, -- Corrupted Globule
--   ["0xF13000085D27AB1E"] = CROSS, -- Corrupted Globule
--   ["0xF13000085D27AB1D"] = SQUARE, -- Corrupted Globule
--   ["0xF13000085D27AB1C"] = MOON, -- Corrupted Globule
-- })

-- addToDefaultNpcsToMark(L["Timbermaw Hold"], "globules_6", {
--   ["0xF13000085D27AB23"] = SKULL, -- Corrupted Globule
--   ["0xF13000085D27AB22"] = CROSS, -- Corrupted Globule
--   ["0xF13000085D27AB21"] = SQUARE, -- Corrupted Globule
--   ["0xF13000085D27AB20"] = MOON, -- Corrupted Globule
-- })

addToDefaultNpcsToMark(L["Timbermaw Hold"], "corruption_4", {
  ["0xF13000F59627975C"] = SKULL, -- 枯喉污染者
  ["0xF13000F59F27975B"] = CROSS, -- 落潭的腐根
  ["0xF13000F59F27975A"] = SQUARE, -- 落潭的腐根
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "twisted_rumblers", {
  ["0xF13000F5A0279A28"] = SKULL, -- 扭曲的滚石
  ["0xF13000F5A0279A29"] = CROSS, -- 扭曲的滚石
  ["0xF13000F5A0279A2A"] = SQUARE, -- 扭曲的滚石
  --   ["0xF13000F5A0279A2B"] = MOON, -- 扭曲的滚石
  --   ["0xF13000F5A0279A2C"] = TRIANGLE, -- 扭曲的滚石
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "corruption_5", {
  ["0xF13000F596279A31"] = SKULL, -- 枯喉污染者
  ["0xF13000F59F279A2F"] = CROSS, -- 落潭的腐根
})

-- here for posterity but no real reason to mark these
addToDefaultNpcsToMark(L["Timbermaw Hold"], "kronn", {
  ["0xF13000F5962796C7"] = SKULL, -- 枯喉污染者
  ["0xF13000F59B2796C6"] = CROSS, -- 枯喉追踪者
  ["0xF13000F5982796C8"] = SQUARE, -- 枯喉探路者
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_lower_3", {
  ["0xF13000F59C279D64"] = CROSS, -- 枯喉守卫
  ["0xF13000F599279D66"] = SKULL, -- 枯喉图腾师
  ["0xF13000F598279D65"] = SQUARE, -- 枯喉探路者
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_hut_1", {
  ["0xF13000F5A4279DA9"] = SKULL, -- 腐心唤魔者
  ["0xF13000F5A4279DAA"] = CROSS, -- 腐心唤魔者
  ["0xF13000F59D279DAC"] = MOON, -- 枯喉巨熊怪
  ["0xF13000F599279DAB"] = SQUARE, -- 枯喉图腾师
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_patrol", {
  ["0xF13000F5A1279DA7"] = DIAMOND, -- 腐心欺诈者
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_ramp_4", {
  ["0xF13000F5A4279DA6"] = CROSS, -- 腐心唤魔者
  ["0xF13000F5A2279DA5"] = SQUARE, -- 腐心萨特
  ["0xF13000F59D279DA3"] = MOON, -- 枯喉巨熊怪
  ["0xF13000F596279DA4"] = SKULL, -- 枯喉污染者
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_ramp_5", {
  ["0xF13000F5A5279D9F"] = SKULL, -- 乌索尔之子
  ["0xF13000F5A5279D9D"] = CROSS, -- 乌索尔之子
  ["0xF13000F5A5279D9E"] = SQUARE, -- 乌索尔之子
  ["0xF13000F5A5279DA0"] = MOON, -- 乌索尔之子
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "inner_1", {
  ["0xF13000F59D279DA2"] = SKULL, -- 枯喉巨熊怪
  ["0xF13000F59D279DA1"] = CROSS, -- 枯喉巨熊怪
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "ursol_corrupters", {
  ["0xF13000F5E3279B8E"] = UNMARKED, -- Ursol
  ["0xF13000732827A7C5"] = SKULL, -- Withermaw Corrupter
  ["0xF13000732827A7C6"] = CROSS, -- Withermaw Corrupter
})

--/////////////// Onyxia's Lair ///////////////

addToDefaultNpcsToMark(L["Onyxia's Lair"], "trash_1", {
  ["0xF13000BF782792E7"] = SKULL, -- 奥妮克希亚煽动者
  ["0xF13000BF782792E4"] = CROSS, -- 奥妮克希亚煽动者
})

-- brood commnader is here

addToDefaultNpcsToMark(L["Onyxia's Lair"], "trash_2", {
  ["0xF13000BF782792EC"] = SKULL, -- 奥妮克希亚煽动者
  ["0xF13000BF792792EB"] = CROSS, -- 奥妮克希亚火嗣
  ["0xF13000BF792792EA"] = SQUARE, -- 奥妮克希亚火嗣
})

addToDefaultNpcsToMark(L["Onyxia's Lair"], "trash_3", {
  ["0xF130002F6100CB55"] = SKULL, -- 奥妮克希亚守卫
  ["0xF13000BF782792E8"] = CROSS, -- 奥妮克希亚煽动者
  ["0xF13000BF782792E9"] = SQUARE, -- 奥妮克希亚煽动者
})

addToDefaultNpcsToMark(L["Onyxia's Lair"], "trash_4", {
  ["0xF130002F6100CB50"] = SKULL, -- 奥妮克希亚守卫
  ["0xF13000BF792792F3"] = CROSS, -- 奥妮克希亚火嗣
})

addToDefaultNpcsToMark(L["Onyxia's Lair"], "trash_5", {
  ["0xF130002F612792F2"] = SKULL, -- 奥妮克希亚守卫
  ["0xF13000BF782792F1"] = CROSS, -- 奥妮克希亚煽动者
  ["0xF13000BF782792F0"] = SQUARE, -- 奥妮克希亚煽动者
  ["0xF13000BF792792ED"] = MOON, -- 奥妮克希亚火嗣
})

-- ony path
addToDefaultNpcsToMark(L["Onyxia's Lair"], "trash_left", {
  ["0xF13000BF792792E5"] = CROSS,-- Onyxian Flamespawn
  ["0xF13000BF782792E6"] = SKULL, -- Onyxian Inciter
})



--/////////////// 黑上 ///////////////

addToDefaultNpcsToMark(L["Blackrock Spire"], "room_left_1", {
  ["0xF130002659009D3C"] = 7,
  ["0xF130002659009D42"] = 4,
  ["0xF13000265A009D3B"] = 8,
  ["0xF13000265B009D3D"] = 6,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "room_left_2", {
  ["0xF13000265A009D47"] = 8,
  ["0xF130002659009D49"] = 7,
  ["0xF13000265B009D46"] = 6,
  ["0xF130002659009D48"] = 4,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "room_left_3", {
  ["0xF13000265B009D55"] = 3,
  ["0xF13000265A009E07"] = 8,
  ["0xF130002659009E08"] = 7,
  ["0xF13000265B009D50"] = 6,
  ["0xF13000265B009E09"] = 4,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "room_right_1", {
  ["0xF130002659009D40"] = 4,
  ["0xF130002659009D41"] = 6,
  ["0xF13000265A009D44"] = 7,
  ["0xF13000265A009D43"] = 8,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "room_right_2", {
  ["0xF13000265A009D4B"] = 8,
  ["0xF13000265B00B309"] = 4,
  ["0xF130002659009D4A"] = 7,
  ["0xF13000265B009D4C"] = 6,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "room_right_3", {
  ["0xF13000265B009D3E"] = 6,
  ["0xF130002659009D45"] = 7,
  ["0xF13000265B00B30A"] = 4,
  ["0xF13000265A009D3F"] = 8,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "room_right_4", {
  ["0xF130002659009D4F"] = 4,
  ["0xF13000265A009D4E"] = 8,
  ["0xF13000265A00B308"] = 7,
  ["0xF130002659009D4D"] = 6,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "room_stairwell", {
  ["0xF130002659009E35"] = 7,
  ["0xF13000265B009E32"] = 6,
  ["0xF13000265A009E34"] = 8,
  ["0xF13000265B009E33"] = 4,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "rookery_ramp", {
  ["0xF130002388009E16"] = 6,
  ["0xF130002388009E24"] = 8,
  ["0xF130002388009E12"] = 7,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "rookery_walkway", {
  ["0xF130002763009E0B"] = 8,
  ["0xF130002388009E14"] = 4,
  ["0xF130002388009E15"] = 7,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "forge_stairs1", {
  ["0xF13000265B009E28"] = 6,
  ["0xF13000284D009E29"] = 8,
  ["0xF13000265B009E2E"] = 7,
  ["0xF13000265B009E2D"] = 4,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "forge_stairs2", {
  ["0xF130002763009E13"] = 8,
  ["0xF13000238800B307"] = 4,
  ["0xF130002388009E0E"] = 6,
  ["0xF130002763009E21"] = 7,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "anvilcrack", {
  ["0xF130002A9300B305"] = 8,
  ["0xF13000265B009E2B"] = 7,
  ["0xF13000265B009E2C"] = 4,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "forge_pathers", {
  ["0xF130002388009E16"] = 6,
  ["0xF130002659009E0D"] = 3,
  ["0xF13000265B009E0A"] = 1,
  ["0xF13000265900B306"] = 5,
  ["0xF130002388009E0C"] = 2,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "forge_corner", {
  ["0xF13000265A009E43"] = 8,
  ["0xF130002659009E3C"] = 7,
  ["0xF13000265B009E3D"] = 4,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "forge_far_mid", {
  ["0xF13000265B009E3A"] = 4,
  ["0xF13000265B009E3B"] = 7,
  ["0xF13000284D009E3E"] = 8,
  ["0xF13000265B009E39"] = 6,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "forge_near_mid", {
  ["0xF13000265B009E2A"] = 4,
  ["0xF13000265B009E27"] = 6,
  ["0xF13000284D009E17"] = 8,
  ["0xF13000265B009E22"] = 7,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "forge_far_stairs2", {
  ["0xF13000265B009E42"] = 6,
  ["0xF13000265B009E46"] = 4,
  ["0xF13000284D009E44"] = 8,
  ["0xF13000265B009E45"] = 7,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "forge_stair_up_left", {
  ["0xF130002763009E99"] = 8,
  ["0xF130002388009E9A"] = 7,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "forge_stair_up_right", {
  ["0xF130002763009E9B"] = 8,
  ["0xF13000238800A168"] = 7,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "forge_jump", {
  ["0xF13000238800A333"] = 7,
  ["0xF13000276300A334"] = 8,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "arena_lobby", {
  ["0xF13000265900B300"] = 7,
  ["0xF13000238800B301"] = 3,
  ["0xF13000265B00A393"] = 6,
  ["0xF13000265B00B2FF"] = 4,
  ["0xF13000265A00A394"] = 8,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "beast_pathers", {
  ["0xF13000284F104CE4"] = 2,
  ["0xF13000284F104CE0"] = 1,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "upstairs", {
  ["0xF13000284E00A649"] = 8,
  ["0xF13000284E00A4AC"] = 7,
  ["0xF13000287E00A647"] = 3,
  ["0xF13000288400A4B2"] = 4,
  ["0xF13000284D00A648"] = 6,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "beast_lobby_near_right", {
  ["0xF13000287E00A4B1"] = 7,
  ["0xF13000284E00A4CB"] = 8,
  ["0xF13000284D00A64B"] = 4,
  ["0xF13000284D00A64C"] = 6,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "beast_lobby_far_left", {
  ["0xF13000284E106356"] = 8,
  ["0xF13000288400A6A7"] = 7,
  ["0xF130002884106359"] = 4,
  ["0xF13000284D104CDE"] = 5,
  ["0xF13000284F104CDD"] = 3,
  ["0xF13000288300A6A8"] = 6,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "beast_lobby_center", {
  ["0xF13000284D00A4AE"] = 6,
  ["0xF13000284D00A68F"] = 7,
  ["0xF13000284D00A4AF"] = 4,
  ["0xF13000288400A4AD"] = 8,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "beast_lobby_far_right", {
  ["0xF13000287E00A69B"] = 4,
  ["0xF13000284E00A68E"] = 7,
  ["0xF13000284E00A6A6"] = 8,
  ["0xF13000287E00A69C"] = 6,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "beast_lobby_near_left", {
  ["0xF13000284E106358"] = 8,
  ["0xF13000284D106357"] = 4,
  ["0xF13000287E10635A"] = 7,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "drak_bridge2", {
  ["0xF13000284F104CE9"] = 4,
  ["0xF13000284E104CE7"] = 8,
  ["0xF13000284F106350"] = 6,
  ["0xF13000284D104CE3"] = 7,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "drak_corner1", {
  ["0xF130002884106360"] = 8,
  ["0xF13000288310635E"] = 7,
  ["0xF13000284F106361"] = 6,
  ["0xF13000284F10635F"] = 3,
  ["0xF13000284D10635C"] = 4,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "drak_pathers", {
  ["0xF13000284F104CEA"] = 6,
  ["0xF130002883104CE1"] = 4,
  ["0xF13000284E104CE5"] = 8,
  ["0xF13000287E104CEC"] = 7,
  ["0xF13000284F104CED"] = 3,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "drak_room1", {
  ["0xF13000284E106354"] = 7,
  ["0xF13000284F106351"] = 3,
  ["0xF130002883106353"] = 6,
  ["0xF13000284E106352"] = 4,
  ["0xF130002884106355"] = 8,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "drak", {
  ["0xF130002A3E016360"] = 8,
  ["0xF130002A3E27173D"] = 7,
  ["0xF13000287B009CD9"] = 3,
})

addToDefaultNpcsToMark(L["Blackrock Spire"], "drak_bridge1", {
  ["0xF13000284F104CDF"] = 4,
  ["0xF13000287E104CE8"] = 7,
  ["0xF13000287E104CEB"] = 8,
  ["0xF13000284F104CE2"] = 6,
})

-- /////////////////////////////////////////////////////////////////////////////
-- 从 AutoMarker 最爱版移植的自定义组(2026-08-22)
-- /////////////////////////////////////////////////////////////////////////////

addToDefaultNpcsToMark(L["Tower of Karazhan"], "荒芜王座_423", {
  ["0xF130016C9A278BFE"] = SKULL, --地狱之怒碎�?
  ["0xF130016C9A278BF9"] = CROSS, --地狱之怒碎�?
  ["0xF130016C9A278BFD"] = SQUARE, --地狱之怒碎�?
  ["0xF130016C9A278BFC"] = MOON, --地狱之怒碎�?
  ["0xF130016C9A278BFA"] = TRIANGLE, --地狱之怒碎�?
  ["0xF130016C9A278BFB"] = DIAMOND, --地狱之怒碎�?
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "荒芜巨岩_3", {
  ["0xF13000EA35278D9B"] = SKULL,    -- 鲁普图兰的碎�?
  ["0xF13000EA35278D9A"] = CROSS,    -- 鲁普图兰的碎�?
  ["0xF13000EA35278D99"] = SQUARE,   -- 鲁普图兰的碎�?
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "荒芜巨岩_4", {
  ["0xF13000F243276CB0"] = SKULL,    -- 战争使者监�?
  ["0xF13000F246276CAF"] = CROSS,    -- 德莱尼信�?
  ["0xF13000F245276CAD"] = SQUARE,   -- 德莱尼黑暗缚灵�?
  ["0xF13000F245276CAC"] = MOON,     -- 德莱尼黑暗缚灵�?
  ["0xF13000F244276CAE"] = TRIANGLE, -- 被流放的食魂�?
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "荒芜王座_2", {
  ["0xF13000EA562797AF"] = SKULL, --虛空地狱火
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "兽栏_1", {
  ["0xF13000EF0E27472E"] = SKULL,    -- 碎笼矛兵
  ["0xF13000EF10274727"] = CROSS,    -- 幻影守卫
  ["0xF13000EF12274728"] = SQUARE,   -- 闹鬼铁匠
  ["0xF13000EF0E27472D"] = MOON,     -- 碎笼矛兵
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "兽栏_2", {
  ["0xF13000EF0E27472C"] = SKULL,    -- 碎笼矛兵
  ["0xF13000EF0E27472B"] = CROSS,    -- 碎笼矛兵
  ["0xF13000EF1027472A"] = SQUARE,   -- 幻影守卫
  ["0xF13000EF10274729"] = MOON,     -- 幻影守卫
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "兽栏_3", {
  ["0xF13000EF13278B79"] = CROSS,    -- 黑暗骑士学徒
  ["0xF13000EF13278B7A"] = SQUARE,   -- 黑暗骑士学徒
  ["0xF13000EF13278B78"] = SQUARE,   -- 黑暗骑士学徒（组内序号重复，按规则分配相同标记）
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "兽栏_4", {
  ["0xF13000EF1027471C"] = SKULL,    -- 幻影守卫
  ["0xF13000EF122746FE"] = CROSS,    -- 闹鬼铁匠
  ["0xF13000EF122746FF"] = SQUARE,   -- 闹鬼铁匠
  ["0xF13000EF12274785"] = MOON,     -- 闹鬼铁匠
  ["0xF13000EF12274702"] = TRIANGLE, -- 闹鬼铁匠
  ["0xF13000EF12274786"] = DIAMOND,  -- 闹鬼铁匠
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "兽栏_5", {
  ["0xF13000EF0F274715"] = SKULL,    -- 碎笼骨法�?
  ["0xF13000EF0E274716"] = CROSS,    -- 碎笼矛兵
  ["0xF13000EF0E274718"] = SQUARE,   -- 碎笼矛兵
  ["0xF13000EF0E27471A"] = MOON,     -- 碎笼矛兵
})

addToDefaultNpcsToMark(L["Molten Core"], "玛格曼达洞穴_1", {
  ["0xF130002D9700DD3A"] = SKULL,    -- 熔火恶犬
  ["0xF130002D9700DD3D"] = CROSS,    -- 熔火恶犬
  ["0xF130002D9700DD3C"] = SQUARE,   -- 熔火恶犬
  ["0xF130002D9700DD3B"] = MOON,     -- 熔火恶犬
  ["0xF130002D9700DD3E"] = TRIANGLE, -- 熔火恶犬
})

addToDefaultNpcsToMark(L["Molten Core"], "玛格曼达洞穴_2", {
  ["0xF130002D9700DD37"] = SKULL,    -- 熔火恶犬
  ["0xF130002D9700DD39"] = CROSS,    -- 熔火恶犬
  ["0xF130002D9700DD35"] = SQUARE,   -- 熔火恶犬
  ["0xF130002D9700DD36"] = MOON,     -- 熔火恶犬
  ["0xF130002D9700DD38"] = TRIANGLE, -- 熔火恶犬
})

addToDefaultNpcsToMark(L["Molten Core"], "玛格曼达洞穴_3", {
  ["0xF130002D9700DD41"] = SKULL,    -- 熔火恶犬
  ["0xF130002D9700DD40"] = CROSS,    -- 熔火恶犬
  ["0xF130002D9700DD3F"] = SQUARE,   -- 熔火恶犬
  ["0xF130002D9700DD42"] = MOON,     -- 熔火恶犬
  ["0xF130002D9700DD43"] = TRIANGLE, -- 熔火恶犬
})

addToDefaultNpcsToMark(L["Molten Core"], "玛格曼达洞穴_4", {
  ["0xF130002D9700DD4B"] = SKULL,    -- 熔火恶犬
  ["0xF130002D9700DD4E"] = CROSS,    -- 熔火恶犬
  ["0xF130002D9700DD4D"] = SQUARE,   -- 熔火恶犬
  ["0xF130002D9700DD4A"] = MOON,     -- 熔火恶犬
  ["0xF130002D9700DD4C"] = TRIANGLE, -- 熔火恶犬
})

addToDefaultNpcsToMark(L["Molten Core"], "玛格曼达洞穴_5", {
  ["0xF130002D9700DD48"] = SKULL,    -- 熔火恶犬
  ["0xF130002D9700DD44"] = CROSS,    -- 熔火恶犬
  ["0xF130002D9700DD49"] = SQUARE,   -- 熔火恶犬
  ["0xF130002D9700DD46"] = MOON,     -- 熔火恶犬
  ["0xF130002D9700DD47"] = TRIANGLE, -- 熔火恶犬
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "karazhan_bestiary3", {
  ["0xF13000F1F0276B4D"] = SKULL,    -- 影爪暗行者（怪物展览馆）
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "karazhan_guardian_library3", {
  ["0xF13000EA55278B79"] = SKULL,    -- 魔鳞魔网搜寻者（守护者的图书馆）
  ["0xF13000EA55278B7B"] = CROSS,    -- 魔鳞魔网搜寻者（守护者的图书馆）
  ["0xF13000EA55278B7C"] = SQUARE,   -- 魔鳞魔网搜寻者（守护者的图书馆）
  ["0xF13000EA55278B7A"] = MOON,     -- 魔鳞魔网搜寻者（守护者的图书馆）
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "karazhan_ballroom2", {
  ["0xF13000EF102756C3"] = SKULL,    -- 幻影守卫（舞厅）
  ["0xF13000EF152756C1"] = CROSS,    -- 幻影仆从（舞厅）
  ["0xF13000EF152756C2"] = SQUARE,   -- 幻影仆从（舞厅）
  ["0xF13000EF072747D6"] = MOON,     -- 影刺前锋（舞厅）
  ["0xF13000EF072747D7"] = DIAMOND,  -- 影刺前锋（舞厅）
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "karazhan_ballroom3", {
  ["0xF13000EF102756C6"] = SKULL,    -- 幻影守卫（舞厅）
  ["0xF13000EF152756C4"] = CROSS,    -- 幻影仆从（舞厅）
  ["0xF13000EF152756C5"] = SQUARE,   -- 幻影仆从（舞厅）
  ["0xF13000EF072747DA"] = MOON,     -- 影刺前锋（舞厅）
  ["0xF13000EF072747D8"] = TRIANGLE, -- 影刺前锋（舞厅）
  ["0xF13000EF072747D9"] = DIAMOND,  -- 影刺前锋（舞厅）
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "karazhan_ballroom4", {
  ["0xF13000EF102756C9"] = SKULL,    -- 幻影守卫（舞厅）
  ["0xF13000EF152756C7"] = CROSS,    -- 幻影仆从（舞厅）
  ["0xF13000EF152756C8"] = SQUARE,   -- 幻影仆从（舞厅）
  ["0xF13000EF072747DD"] = MOON,     -- 影刺前锋（舞厅）
  ["0xF13000EF072747DB"] = TRIANGLE, -- 影刺前锋（舞厅）
  ["0xF13000EF072747DC"] = DIAMOND,  -- 影刺前锋（舞厅）
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "karazhan_ballroom5", {
  ["0xF13000EF102756CC"] = SKULL,    -- 幻影守卫（舞厅）
  ["0xF13000EF152756CA"] = CROSS,    -- 幻影仆从（舞厅）
  ["0xF13000EF152756CB"] = SQUARE,   -- 幻影仆从（舞厅）
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "karazhan_ballroom6", {
  ["0xF13000EF102756CF"] = SKULL,    -- 幻影守卫（舞厅）
  ["0xF13000EF152756CD"] = CROSS,    -- 幻影仆从（舞厅）
  ["0xF13000EF152756CE"] = SQUARE,   -- 幻影仆从（舞厅）
  ["0xF13000EF072747E2"] = MOON,     -- 影刺前锋（舞厅）
  ["0xF13000EF072747E0"] = TRIANGLE, -- 影刺前锋（舞厅）
  ["0xF13000EF072747E1"] = DIAMOND,  -- 影刺前锋（舞厅）
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "karazhan_ballroom7", {
  ["0xF13000EF102756D2"] = SKULL,    -- 幻影守卫（舞厅）
  ["0xF13000EF152756D0"] = CROSS,    -- 幻影仆从（舞厅）
  ["0xF13000EF152756D1"] = SQUARE,   -- 幻影仆从（舞厅）
  ["0xF13000EF072747E5"] = MOON,     -- 影刺前锋（舞厅）
  ["0xF13000EF072747E3"] = TRIANGLE, -- 影刺前锋（舞厅）
  ["0xF13000EF072747E4"] = DIAMOND,  -- 影刺前锋（舞厅）
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "karazhan_ballroom8", {
  ["0xF13000EF102756D5"] = SKULL,    -- 幻影守卫（舞厅）
  ["0xF13000EF152756D3"] = CROSS,    -- 幻影仆从（舞厅）
  ["0xF13000EF152756D4"] = SQUARE,   -- 幻影仆从（舞厅）
  ["0xF13000EF072747E8"] = MOON,     -- 影刺前锋（舞厅）
  ["0xF13000EF072747E6"] = TRIANGLE, -- 影刺前锋（舞厅）
  ["0xF13000EF072747E7"] = DIAMOND,  -- 影刺前锋（舞厅）
})

