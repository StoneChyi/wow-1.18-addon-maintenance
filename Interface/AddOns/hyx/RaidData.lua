-- Original hyx raid reference data; original authorship retained.
XinRaidManualDB = {
    ["祖尔格拉布"] = {
        { 
            name = "毒液喷射", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "拉札什奎蛇", 
            effect = "每2秒受到一次自然伤害",
            note = "无" 
        },
        { 
            name = "雷霆一击", icon = "Interface\\Icons\\Spell_Nature_ThunderClap", type = "Magic",
            caster = "古拉巴什狂暴者", 
            effect = "攻击间隔延长33%、移动速度降低61%",
            note = "无" 
        },
        { 
            -- 合并了 (3) 和 (9)
            name = "感染撕咬", icon = "Interface\\Icons\\Spell_Shadow_CallofBone", type = "Disease",
            caster = "古拉巴什蝙蝠骑士、拉札什迅猛龙", 
            effect = "[古拉巴什蝙蝠骑士]每10秒受到一次自然伤害、在受到物理攻击时承受更多伤害\n\n[拉札什迅猛龙]每10秒受到250点自然伤害、受到物理攻击时承受的伤害值提高100点",
            note = "无" 
        },
        { 
            name = "妖术", icon = "Interface\\Icons\\Spell_Shaman_Hex", type = "Magic",
            caster = "哈卡莱巫医、妖术师金度", 
            effect = "被变形",
            note = "无" 
        },
        { 
            name = "音爆", icon = "Interface\\Icons\\Spell_Nature_WispSplode", type = "Magic",
            caster = "高阶女祭司耶克里克", 
            effect = "不能施法",
            note = "无" 
        },
        { 
            -- 合并了 (6) 和 (12)
            name = "暗言术：痛", icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain", type = "Magic",
            caster = "高阶女祭司耶克里克、高阶女祭司娅尔罗", 
            effect = "[高阶女祭司耶克里克]每3秒受到422到478点暗影伤害\n\n[高阶女祭司娅尔罗]每3秒704到796点暗影伤害",
            note = "无" 
        },
        { 
            name = "中毒", icon = "Interface\\Icons\\Spell_Nature_NullifyDisease", type = "Poison",
            caster = "拉扎什眼镜蛇", 
            effect = "每3秒受到一次自然伤害",
            note = "无" 
        },
        { 
            name = "宁神毒药", icon = "Interface\\Icons\\Ability_Creature_Poison_03", type = "Poison",
            caster = "拉扎什毒蛇", 
            effect = "攻击间隔延长150%、移动速度降低70%、每秒吸取10点怒气值、越来越困……",
            note = "8秒持续时间结束时获得无法驱散、持续时间为10秒的<睡眠>效果(无法移动、操作)" 
        },
        { 
            name = "沉默", icon = "Interface\\Icons\\Spell_Holy_Silence", type = "Magic",
            caster = "高阶祭司塞卡尔", 
            effect = "不能施法",
            note = "无" 
        },
        { 
            name = "翼龙钉刺", icon = "Interface\\Icons\\INV_Spear_02", type = "Poison",
            caster = "哈卡莱暗影猎手", 
            effect = "沉睡",
            note = "无" 
        },
        { 
            name = "酸性毒液", icon = "Interface\\Icons\\Spell_Nature_Acid_01", type = "Poison",
            caster = "哈卡之子", 
            effect = "每3秒造成100点伤害",
            note = "无" 
        },
        { 
            name = "吸取生命", icon = "Interface\\Icons\\Spell_Shadow_LifeDrain02", type = "Magic",
            caster = "哈卡莱鲜血祭司", 
            effect = "在5秒内从敌人身上吸取总计1500点生命值，并将其转移给施法者",
            note = "无" 
        },
        { 
            name = "恐惧术", icon = "Interface\\Icons\\Spell_Shadow_Possession", type = "Magic",
            caster = "灵魂掠夺者", 
            effect = "因恐惧而逃跑",
            note = "无" 
        }
    },
    
    ["卡拉赞下层大厅"] = {
        {
            name = "幻影尖叫", icon = "Interface\\Icons\\Spell_Shadow_PsychicScream", type = "Magic",
            caster = "幻影仆从", 
            effect = "无法施展法术",
            note = "无" 
        },
        {
            name = "腐蚀箭", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "掠网毒牙蛛", 
            effect = "每3秒造成一次自然伤害",
            note = "无" 
        },
        {
            name = "巢毒齐射", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "掠网毒牙蛛、巢穴女王阿拉克萨娜", 
            effect = "每3秒造成自然伤害",
            note = "无" 
        },
        {
            name = "水蛭叮咬", icon = "Interface\\Icons\\Ability_PoisonSting", type = "Poison",
            caster = "掠网爬行者", 
            effect = "治疗效果降低25%",
            note = "无" 
        },
        {
            name = "暗牙毒液", icon = "Interface\\Icons\\Spell_Nature_SlowPoison", type = "Poison",
            caster = "掠网暗牙蛛", 
            effect = "移动速度降低10%、攻击和施法速度降低15%",
            note = "无" 
        },
        {
            name = "冰霜震击", icon = "Interface\\Icons\\Spell_Frost_FrostShock", type = "Magic",
            caster = "劣魔原猎者", 
            effect = "移动速度降低",
            note = "无" 
        },
        {
            name = "吸取法力", icon = "Interface\\Icons\\Spell_Shadow_SiphonMana", type = "Magic",
            caster = "劣魔影织者", 
            effect = "在5秒内吸取总计1540点法力值",
            note = "无" 
        },
        {
            name = "烟雾弹", icon = "Interface\\Icons\\Ability_Vanish", type = "Magic",
            caster = "莫罗斯", 
            effect = "无法施展法术",
            note = "无" 
        }
    },    
    
    ["安其拉废墟"] = {
        {
            name = "扎拉虫巢催化", icon = "Interface\\Icons\\Ability_Creature_Poison_02", type = "Poison",
            caster = "佐拉黄蜂", 
            effect = "移动速度降低50%、每2秒146点伤害、被扎拉钉刺攻击时承受更多伤害",
            note = "无" 
        },
        {
            name = "雷霆一击", icon = "Interface\\Icons\\Spell_Nature_ThunderClap", type = "Magic",
            caster = "其拉战士", 
            effect = "攻击间隔延长33%、移动速度降低60%",
            note = "无" 
        }
    },
    
    ["奥妮克希亚的巢穴"] = {
        {
            name = "烈焰鞭笞", icon = "Interface\\Icons\\Spell_Fire_Fireball", type = "Magic",
            caster = "奥妮克希亚守卫", 
            effect = "火焰抗性降低70点",
            note = "无" 
        },
        {
            name = "烈焰打击", icon = "Interface\\Icons\\Spell_Fire_Fireball", type = "Magic",
            caster = "奥妮克希亚火嗣", 
            effect = "受到火焰攻击时多承受1000点伤害",
            note = "无" 
        },
        {
            name = "爆裂印记", icon = "Interface\\Icons\\Spell_Fire_SelfDestruct", type = "Magic",
            caster = "奥妮克希亚煽动者", 
            effect = "当被击中时对自己和盟友造成657到843点火焰伤害",
            note = "无" 
        }
    },
    
    ["熔火之心"] = {
        {
            name = "灵魂燃烧", icon = "Interface\\Icons\\Spell_Fire_SoulBurn", type = "Magic",
            caster = "火焰之王", 
            effect = "在16秒内受到4000点火焰伤害、物理伤害能力降低50%、沉默",
            note = "无" 
        },
        {
            name = "枯萎热浪", icon = "Interface\\Icons\\Spell_Fire_Fire", type = "Magic",
            caster = "上古熔火恶犬", 
            effect = "生命值上限降低35%",
            note = "无" 
        },
        {
            name = "灼烧之焰", icon = "Interface\\Icons\\Spell_Fire_Volcano", type = "Magic",
            caster = "上古熔火恶犬", 
            effect = "火焰抗性降低200点",
            note = "无" 
        },
        {
            name = "上古恐慌", icon = "Interface\\Icons\\Spell_Shadow_CurseOfTounges", type = "Magic",
            caster = "上古熔火恶犬", 
            effect = "施法速度降低50%、攻击间隔延长100%",
            note = "无" 
        },
        {
            name = "上古绝望", icon = "Interface\\Icons\\Spell_Shadow_MindSteal", type = "Magic",
            caster = "上古熔火恶犬", 
            effect = "困惑",
            note = "无" 
        },
        {
            name = "末日降临", icon = "Interface\\Icons\\Spell_Shadow_NightOfTheDead", type = "Magic",
            caster = "鲁西弗隆", 
            effect = "10秒后受到2000点暗影伤害",
            note = "无" 
        },
        {
            name = "统御意志", icon = "Interface\\Icons\\Spell_Shadow_ShadowWordDominate", type = "Magic",
            caster = "鲁西弗隆", 
            effect = "被魅惑",
            note = "无法被驱散" 
        },
        {
            name = "恐慌", icon = "Interface\\Icons\\Spell_Shadow_DeathScream", type = "Magic",
            caster = "玛格曼达", 
            effect = "因恐惧而逃跑",
            note = "无" 
        },
        {
            name = "野火", icon = "Interface\\Icons\\Spell_Fire_SealOfFire", type = "Magic",
            caster = "暗炉织焰者", 
            effect = "每3秒450点火焰伤害",
            note = "造成伤害时有概率扩散到10码内附近的1名队友" 
        },
        {
            name = "暗言术：痛", icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain", type = "Magic",
            caster = "暗炉圣职者、火妖祭司", 
            effect = "[暗炉圣职者]每3秒250点暗影伤害\n\n[火妖祭司]每3秒受到一次暗影伤害",
            note = "无" 
        },
        {
            name = "献祭", icon = "Interface\\Icons\\Spell_Fire_Immolation", type = "Magic",
            caster = "火誓者、火妖祭司", 
            effect = "每3秒380到420点火焰伤害",
            note = "无" 
        },
        {
            name = "熔岩镣铐", icon = "Interface\\Icons\\Spell_Nature_EarthBind", type = "Magic",
            caster = "加尔", 
            effect = "移动速度降低60%",
            note = "无" 
        },
        {
            name = "点燃法力", icon = "Interface\\Icons\\Spell_Fire_Incinerate", type = "Magic",
            caster = "迦顿男爵", 
            effect = "每3秒燃烧400点法力值",
            note = "无" 
        },
        {
            name = "煽动烈焰", icon = "Interface\\Icons\\Spell_Fire_FlameBlades", type = "Magic",
            caster = "火焰行者", 
            effect = "火焰抗性降低50点",
            note = "无" 
        },
    },
    
    ["黑翼之巢"] = {
        {
            name = "减速术", icon = "Interface\\Icons\\Spell_Nature_Slow", type = "Magic",
            caster = "黑翼控制者", 
            effect = "使敌人的攻击间隔延长54%、移动速度降低60%",
            note = "无" 
        },
        {
            name = "毒药瓶", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "黑翼技师", 
            effect = "每3秒造成180点自然伤害",
            note = "无" 
        },
        {
            name = "爆裂印记", icon = "Interface\\Icons\\Spell_Fire_SelfDestruct", type = "Magic",
            caster = "死爪龙人队长", 
            effect = "在被击中时对自己和盟友造成657到843点伤害",
            note = "无" 
        },
        {
            name = "强效变形术", icon = "Interface\\Icons\\Spell_Nature_Brilliance", type = "Magic",
            caster = "黑翼缚法者", 
            effect = "不能攻击或施法、生命值回复速度提高",
            note = "无" 
        },
        {
            name = "雷霆一击", icon = "Interface\\Icons\\Spell_Nature_ThunderClap", type = "Magic",
            caster = "暴怒的恶魔守卫", 
            effect = "攻击间隔延长33%、移动速度降低60%",
            note = "无" 
        },
        {
            name = "龙血之痛：红", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01", type = "Disease",
            caster = "克洛玛古斯", 
            effect = "每3秒造成50点伤害、死亡后为克洛玛古斯恢复生命值",
            note = "无" 
        },
        {
            name = "龙血之痛：蓝", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Blue", type = "Magic",
            caster = "克洛玛古斯", 
            effect = "每1秒燃烧50点法力值、施法速度降低50%、移动速度降低30%",
            note = "无" 
        },
        {
            name = "龙血之痛：绿", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Green", type = "Poison",
            caster = "克洛玛古斯", 
            effect = "每5秒造成250点伤害、治疗效果降低50%",
            note = "无" 
        },
        {
            name = "恐惧术", icon = "Interface\\Icons\\Spell_Shadow_Possession", type = "Magic",
            caster = "维克多·奈法里奥斯领主", 
            effect = "因恐惧而逃跑",
            note = "无" 
        },
        {
            name = "沉默", icon = "Interface\\Icons\\Spell_Holy_Silence", type = "Magic",
            caster = "维克多·奈法里奥斯领主", 
            effect = "不能施法",
            note = "无" 
        }
    },

    ["翡翠圣殿"] = {
        {
            name = "梦境", icon = "Interface\\Icons\\Spell_Nature_Sleep", type = "Magic",
            caster = "圣所梦游者", 
            effect = "睡着了",
            note = "无" 
        },
        {
            name = "毒箭之雨", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "圣所巨龙、埃伦纽斯", 
            effect = "每2秒受到一次自然伤害",
            note = "无" 
        },
        {
            name = "龙族毒液", icon = "Interface\\Icons\\Ability_Creature_Poison_03", type = "Poison",
            caster = "圣所龙族", 
            effect = "攻击间隔增加25%、移动速度降低30%",
            note = "无" 
        },
        {
            name = "翡翠镇压", icon = "Interface\\Icons\\Spell_Nature_MagicImmunity", type = "Magic",
            caster = "圣所压制者", 
            effect = "12秒内损失5856到5868点法力值",
            note = "无" 
        },
        {
            name = "埃伦纽斯的哀嚎", icon = "Interface\\Icons\\Spell_Shadow_ShadeTrueSight", type = "Magic",
            caster = "埃伦纽斯", 
            effect = "睡眠",
            note = "无" 
        }, 
        {
            name = "腐蚀箭", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "索尔纽斯", 
            effect = "每3秒造成一次自然伤害",
            note = "无" 
        },     
        {
            name = "翡翠松懈", icon = "Interface\\Icons\\Spell_Nature_Purge", type = "Magic",
            caster = "索尔纽斯", 
            effect = "容易受到自然力量的影响、自然法术造成的伤害最多增加200",
            note = "无" 
        },
        {
            name = "翡翠腐烂", icon = "Interface\\Icons\\Spell_Nature_NatureTouchDecay", type = "Disease",
            caster = "索尔纽斯", 
            effect = "攻击间隔增加80%、施法速度降低80%",
            note = "驱散后获得不可驱散、持续时间为2分钟的<翡翠腐烂>效果(攻击间隔增加50%、施法速度降低50%)" 
        },
        {
            name = "圣心腐朽", icon = "Interface\\Icons\\Spell_Shadow_MindRot", type = "Disease",
            caster = "索尔纽斯", 
            effect = "每2秒损失135点法力值",
            note = "驱散后获得不可驱散、持续时间为30秒的<梦热>效果(施法速度降低75%)" 
        },
        {
            name = "梦热", icon = "Interface\\Icons\\Ability_Creature_Disease_03", type = "Poison",
            caster = "索尔纽斯", 
            effect = "攻击速度降低60%",
            note = "驱散后获得不可驱散、持续时间为10秒<狂热的梦>效果(睡着了)" 
        }
    },

    ["安其拉神殿"] = {
        {
            name = "毒箭之雨", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "维希度斯", 
            effect = "每2秒受到413到587点自然伤害",
            note = "无" 
        },
        {
            name = "致残毒药", icon = "Interface\\Icons\\Ability_PoisonSting", type = "Poison",
            caster = "维克尼斯爬行者", 
            effect = "移动速度降低50%",
            note = "无" 
        },
        {
            name = "麻痹毒药", icon = "Interface\\Icons\\Spell_Nature_NullifyDisease", type = "Poison",
            caster = "维克尼斯爬行者", 
            effect = "施法速度降低50%",
            note = "无" 
        },
        {
            name = "毒云之箭", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "维克尼斯爬行者", 
            effect = "每1秒造成500点自然伤害",
            note = "无" 
        },
        {
            name = "维克尼斯催化", icon = "Interface\\Icons\\Ability_Creature_Poison_02", type = "Poison",
            caster = "维克尼斯黄蜂", 
            effect = "移动速度降低50%、每2秒286点伤害、被维克尼钉刺攻击时承受更多伤害",
            note = "无" 
        },
        {
            name = "翼龙钉刺", icon = "Interface\\Icons\\INV_Spear_02", type = "Poison",
            caster = "哈霍兰公主", 
            effect = "沉睡",
            note = "被驱散后被驱散者受到大量自然伤害" 
        }
    },

    ["木喉要塞"] = {
        {
            name = "毒蛇钉刺", icon = "Interface\\Icons\\Ability_Hunter_Quickshot", type = "Poison",
            caster = "枯喉追踪者", 
            effect = "每3秒111点自然伤害",
            note = "无" 
        },
        {
            name = "毒根之毒", icon = "Interface\\Icons\\INV_Misc_Herb_16", type = "Poison",
            caster = "枯喉探路者", 
            effect = "受到伤害提高200%",
            note = "无" 
        },
        {
            name = "腐蚀之种", icon = "Interface\\Icons\\ability_warlock_shadowflame", type = "Magic",
            caster = "哨兵卡什", 
            effect = "造成伤害提高100%",
            note = "移除(8秒消失后或被驱散)时对附近的友军造成伤害，伤害的大小取决于期间玩家造成的伤害" 
        },
        {
            name = "腐蚀毒药", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "被污染的胶团", 
            effect = "每5秒受到657到843点自然伤害、护甲值降低5000点",
            note = "无" 
        },
        {
            name = "桀骜之炎", icon = "Interface\\Icons\\Spell_Fire_Immolation", type = "Magic",
            caster = "腐嚎", 
            effect = "每1秒200点火焰伤害",
            note = "腐嚎的火焰箭根据人数均摊伤害，被命中的目标获得<桀骜之炎>效果" 
        },
        {
            name = "麻痹之毒", icon = "Interface\\Icons\\Ability_PoisonSting", type = "Poison",
            caster = "落潭的腐根", 
            effect = "昏迷、持续8秒",
            note = "无" 
        },
        {
            name = "恶液烂芽", icon = "Interface\\Icons\\Spell_Shadow_CallofBone", type = "Disease",
            caster = "落潭的腐根", 
            effect = "移动速度降低15%、受到伤害提高100%",
            note = "无" 
        },
        {
            name = "黑脓疮", icon = "Interface\\Icons\\Spell_Shadow_CreepingPlague", type = "Disease",
            caster = "落潭的腐根", 
            effect = "皮肤上布满黑色肿胀的疖子、并滋生霉菌",
            note = "10秒持续时间结束时受到18500点伤害" 
        },
        {
            name = "恶心污泥", icon = "Interface\\Icons\\Ability_Creature_Poison_06", type = "Poison",
            caster = "腐化的脂滴", 
            effect = "每1秒造成50点自然伤害",
            note = "该效果会叠加层数" 
        },
        {
            name = "毒藤", icon = "Interface\\Icons\\Spell_Nature_StrangleVines", type = "Disease",
            caster = "落潭", 
            effect = "受到物理伤害提高500、且每3秒造成1000点自然伤害",
            note = "无" 
        },
        {
            name = "清醒梦魇", icon = "Interface\\Icons\\Spell_Nature_Sleep", type = "Magic",
            caster = "大德鲁伊科罗恩", 
            effect = "无法进行任何行动、周期性地受到500点暗影伤害",
            note = "被驱散时在梦境中生成1个萨维亚幻象" 
        },
        {
            name = "狂热梦境", icon = "Interface\\Icons\\Spell_Shadow_PlagueCloud", type = "Disease",
            caster = "萨维亚幻象", 
            effect = "造成的伤害降低50%、每6秒受到1000点伤害",
            note = "被驱散时会扩散到附近目标" 
        },
        {
            name = "黑暗虹吸", icon = "Interface\\Icons\\Spell_Shadow_AbominationExplosion", type = "Magic",
            caster = "大酋长帕萨斯", 
            effect = "效果结束后从目标身上吸取3000点生命值",
            note = "被驱散时伤害由驱散者和被驱散者均摊、各受到1500点暗影伤害" 
        },
        {
            name = "石化", icon = "Interface\\Icons\\Ability_Druid_Cower", type = "Magic",
            caster = "枯喉巨熊怪", 
            effect = "攻击速度降低50%、移动速度降低50%",
            note = "无" 
        },
        {
            name = "腐心虹吸", icon = "Interface\\Icons\\Spell_Shadow_Haunting", type = "Magic",
            caster = "腐心诡术师", 
            effect = "每1秒损失600点生命值和1200点法力值",
            note = "无" 
        },
        {
            name = "腐蚀术", icon = "Interface\\Icons\\Spell_Shadow_AbominationExplosion", type = "Magic",
            caster = "塞雷纳克斯·腐心", 
            effect = "每3秒600到800点暗影伤害",
            note = "BOSS会给当前目标施加<萨特污秽>效果(提高受到的暗影伤害)" 
        }
    },


    ["纳克萨玛斯"] = {
        {
            name = "雷霆一击", icon = "Interface\\Icons\\Spell_Nature_ThunderClap", type = "Magic",
            caster = "骷髅铁匠", 
            effect = "攻击间隔延长100%、移动速度降低60%",
            note = "无" 
        },
        {
            name = "冰霜新星", icon = "Interface\\Icons\\Spell_Frost_FrostNova", type = "Magic",
            caster = "邪恶法杖、死灵骑士、死灵骑士卫兵", 
            effect = "[邪恶法杖/死灵骑士]不能移动\n\n[死灵骑士卫兵]被定身",
            note = "无" 
        },
        {
            name = "变形术", icon = "Interface\\Icons\\Spell_Nature_Polymorph", type = "Magic",
            caster = "邪恶法杖", 
            effect = "不能攻击或施法、生命值回复速度提高",
            note = "无" 
        },
        {
            name = "吸取生命", icon = "Interface\\Icons\\Spell_Shadow_LifeDrain02", type = "Magic",
            caster = "鬼灵骑兵", 
            effect = "在5秒吸收总计4000点生命值",
            note = "无" 
        },
        {
            name = "恐惧", icon = "Interface\\Icons\\Spell_Shadow_Possession", type = "Magic",
            caster = "鬼灵训练师", 
            effect = "因恐惧而逃跑",
            note = "无" 
        },
        {
            name = "寒冷之锥", icon = "Interface\\Icons\\Spell_Frost_Glacier", type = "Magic",
            caster = "死灵骑士卫兵", 
            effect = "移动速度降低",
            note = "无" 
        },
        {
            name = "残废术", icon = "Interface\\Icons\\Spell_Shadow_Cripple", type = "Magic",
            caster = "瘟疫使者诺斯", 
            effect = "攻击间隔延长100%、移动速度降低50%、力量降低50%",
            note = "无" 
        },
        {
            name = "腐烂撕咬", icon = "Interface\\Icons\\Ability_Creature_Disease_03", type = "Disease",
            caster = "疫病蝙蝠", 
            effect = "受到攻击时承受的伤害提高120点",
            note = "无" 
        },
        {
            name = "衰弱瘟疫", icon = "Interface\\Icons\\Ability_Creature_Disease_03", type = "Disease",
            caster = "肮脏的希尔盖", 
            effect = "生命值上限降低50%、每3秒造成500点自然伤害",
            note = "无" 
        },
        {
            name = "毒性光环", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "洛欧塞布", 
            effect = "每6秒受到196点自然伤害",
            note = "驱散后会获得<堕落心灵>效果(无法治疗，持续1分钟)" 
        },
        {
            name = "毒性充能", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "死灵捕猎者", 
            effect = "每3秒造成2500点自然伤害",
            note = "无" 
        },
        {
            name = "毒箭之雨", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "黑女巫法琳娜", 
            effect = "每2秒造成417到483点自然伤害",
            note = "无" 
        },
        {
            name = "死灵之毒", icon = "Interface\\Icons\\Ability_Creature_Poison_03", type = "Poison",
            caster = "迈克斯纳", 
            effect = "治疗效果降低90%",
            note = "无" 
        },
        {
            name = "软泥之箭", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "缝合喷吐者", 
            effect = "每5秒造成一次自然伤害",
            note = "无" 
        },
        {
            name = "变异注射", icon = "Interface\\Icons\\Spell_Shadow_CallofBone", type = "Disease",
            caster = "格罗布鲁斯", 
            effect = "你被注射了变异毒素",
            note = "移除(10秒持续时间结束或被驱散)时在原地留下一个逐渐扩散的毒圈" 
        },
        {
            name = "群体寒冰箭", icon = "Interface\\Icons\\Spell_Frost_FrostBolt02", type = "Magic",
            caster = "克尔苏加德", 
            effect = "移动速度降低",
            note = "无" 
        }
    },

    ["卡拉赞之塔"] = {
        {
            name = "幻影尖叫", icon = "Interface\\Icons\\Spell_Shadow_PsychicScream", type = "Magic",
            caster = "幽灵工人", 
            effect = "无法施展法术",
            note = "无" 
        },
        {
            name = "吸血毒药", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "暮牙爬行者", 
            effect = "在15秒造成7500点伤害、在15秒内损失7500点法力值",
            note = "无" 
        },
        {
            name = "侵蚀毒药", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "暮牙爬行者", 
            effect = "在4秒后造成13000伤害",
            note = "无" 
        },
        {
            name = "魔鳞冰箭", icon = "Interface\\Icons\\Spell_Nature_Slow", type = "Magic",
            caster = "魔鳞织法者、魔鳞幼龙、魔鳞魔网搜寻者", 
            effect = "攻击间隔增加50%、移动速度降低50%、施法速度降低50%",
            note = "无" 
        },
        {
            name = "法力箭", icon = "Interface\\Icons\\Spell_Shadow_SiphonMana", type = "Magic",
            caster = "魔鳞织法者、魔鳞幼龙", 
            effect = "抗性降低、受到法术伤害提高",
            note = "无" 
        },
        {
            name = "寒霜气息", icon = "Interface\\Icons\\Spell_Frost_FrostShock", type = "Magic",
            caster = "魔鳞巨龙", 
            effect = "被冻结",
            note = "无" 
        },
        {
            name = "巨龙怒吼", icon = "Interface\\Icons\\Ability_Devour", type = "Magic",
            caster = "魔鳞巨龙", 
            effect = "因恐惧而逃跑",
            note = "无" 
        },
        {
            name = "祈求沉默", icon = "Interface\\Icons\\Spell_Holy_Silence", type = "Magic",
            caster = "魔鳞抑法者", 
            effect = "沉默",
            note = "无" 
        },
        {
            name = "因塔苟斯的凝视", icon = "Interface\\Icons\\Spell_Shadow_Possession", type = "Magic",
            caster = "魔网观察者因塔苟斯", 
            effect = "恐惧",
            note = "无" 
        },
        {
            name = "不稳定的法力", icon = "Interface\\Icons\\Spell_Shadow_Teleport", type = "Magic",
            caster = "魔鳞抑法者", 
            effect = "每1秒抽取600点法力值并造成599点伤害",
            note = "被驱散时被驱散者及其小队受到8000点伤害" 
        },
        {
            name = "奥术压力", icon = "Interface\\Icons\\Spell_Frost_IceShock", type = "Magic",
            caster = "溢出的法力", 
            effect = "移动速度降低80%、攻击速度降低80%",
            note = "无" 
        },
        {
            name = "魔力积聚", icon = "Interface\\Icons\\Spell_Nature_Lightning", type = "Magic",
            caster = "破碎的奥术元素", 
            effect = "奥术能量正在积聚...",
            note = "7秒持续时间结束时所在小队受到大量伤害" 
        },
        {
            name = "奥术监牢", icon = "Interface\\Icons\\INV_Misc_Gem_Amethyst_02", type = "Magic",
            caster = "阿诺玛鲁斯", 
            effect = "昏迷，每秒造成1200点伤害并消耗500法力值，持续10秒",
            note = "无" 
        },
        {
            name = "奥术超载", icon = "Interface\\Icons\\Spell_Nature_WispSplode", type = "Magic",
            caster = "阿诺玛鲁斯", 
            effect = "治疗效果提高100%、造成伤害提高100%、移动速度提高100%、造成的威胁值降低100%",
            note = "无法被驱散，15秒持续时间结束时对周围的目标造成伤害、并获得不可驱散且持续时间为45秒的<奥术抑制>效果(受到奥术伤害降低90%、受到物理伤害提高900%)" 
        },
        {
            name = "挥之不去的变羊术", icon = "Interface\\Icons\\Spell_Nature_Polymorph", type = "Magic",
            caster = "徘徊的魔法师", 
            effect = "变成绵羊、在30秒内造成15000伤害",
            note = "无" 
        },
        {
            name = "烈焰笼罩", icon = "Interface\\Icons\\Spell_Fire_Immolation", type = "Magic",
            caster = "徘徊的魔术师", 
            effect = "沉默，移动时对周围的目标造成7000点火焰伤害",
            note = "无" 
        },
        {
            name = "冰霜新星", icon = "Interface\\Icons\\Spell_Frost_FrostNova", type = "Magic",
            caster = "麦迪文的回响", 
            effect = "被冻结在原地",
            note = "无" 
        },
        {
            name = "奥术集中", icon = "Interface\\Icons\\Spell_Holy_FlashHeal", type = "Magic",
            caster = "麦迪文的回响", 
            effect = "受到的魔法伤害增加40%",
            note = "无" 
        },
        {
            name = "麦迪文的灾祸", icon = "Interface\\Icons\\Spell_Nature_Drowsy", type = "Magic",
            caster = "麦迪文的回响", 
            effect = "一股深深的恐惧充斥着你的内心……",
            note = "被驱散时驱散者受到1540点暗影伤害并生成1个徘徊的末日、5层时对周围的目标造成大量暗影伤害" 
        },
        {
            name = "恐惧", icon = "Interface\\Icons\\Spell_Shadow_Possession", type = "Magic",
            caster = "干枯的主教", 
            effect = "因恐惧而逃跑",
            note = "无" 
        },
        {
            name = "幽冥放逐", icon = "Interface\\Icons\\Spell_Shadow_Cripple", type = "Magic",
            caster = "桑夫·塔斯达尔", 
            effect = "无法移动",
            note = "无法被驱散" 
        },
        {
            name = "裂隙纠缠", icon = "Interface\\Icons\\spell_nature_astralrecalgroup", type = "Magic",
            caster = "桑夫·塔斯达尔", 
            effect = "受到所有伤害增加200%、造成暗影伤害增加100%",
            note = "无" 
        },
        {
            name = "相位转换", icon = "Interface\\Icons\\Spell_Shadow_AbominationExplosion", type = "Magic",
            caster = "桑夫·塔斯达尔", 
            effect = "每1秒造成240点暗影伤害、可以看到德莱尼虚无行者",
            note = "无" 
        },
        {
            name = "燃烧血肉", icon = "Interface\\Icons\\Spell_Fire_Immolation", type = "Magic",
            caster = "鲁普图兰的碎块", 
            effect = "每2秒造成2200点火焰伤害",
            note = "无" 
        },
        {
            name = "火焰之雨", icon = "Interface\\Icons\\spell_Holy_SearingLight", type = "Magic",
            caster = "末日守卫歼灭者", 
            effect = "每1秒对你附近10码内的所有玩家造成1400点伤害",
            note = "无" 
        },
        {
            name = "恐惧魔王的嚎叫", icon = "Interface\\Icons\\spell_shadow_deathcoil", type = "Magic",
            caster = "墨菲斯托斯", 
            effect = "惊恐地逃跑",
            note = "无" 
        },
        {
            name = "吸血鬼光环", icon = "Interface\\Icons\\SPELL_SHADOW_VAMPIRICAURA", type = "Magic",
            caster = "墨菲斯托斯", 
            effect = "每1秒消耗300点生命值",
            note = "无法被驱散，此效果为首领的光环效果，可被萨满驱散\n[感谢|cffF58CBA逐日光辉|r提供机制解读]" 
        },
        {
            name = "腐臭虫群", icon = "Interface\\Icons\\Spell_Shadow_Contagion", type = "Disease",
            caster = "墨菲斯托斯", 
            effect = "治疗效果降低25%、每1秒造成350点自然伤害",
            note = "无" 
        },
        {
            name = "沉睡麻痹", icon = "Interface\\Icons\\spell_holy_prayerofshadowprotection", type = "Magic",
            caster = "墨菲斯托斯", 
            effect = "噩梦正在袭来",
            note = "无法移动并且场地中央生成1颗眼球缓慢靠近，被驱散或眼球碰到玩家时眼球周围的目标受到5000点暗影伤害" 
        }
    },

}

-- ==========================================
-- 分割线与下拉菜单调整
-- ==========================================
