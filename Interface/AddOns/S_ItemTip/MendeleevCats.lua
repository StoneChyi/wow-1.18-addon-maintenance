MendeleevLocals.infosets = {
	{
		name		= MendeleevLocals.CatNames.Gather,
		setindex = "gatherskill",
		--color = {0.0, 0.75, 0.8},
		colour = "|cff8470FF",
		header = MendeleevLocals.Category.Gather,
		sets = {
			gatherskillfishing    = MendeleevLocals.Gather.Fish,
			gatherskilldisenchant = MendeleevLocals.Gather.Disen,
			gatherskillherbalism  = MendeleevLocals.Gather.Herb,
			gatherskillmining     = MendeleevLocals.Gather.Mine,
			gatherskillskinning   = MendeleevLocals.Gather.Skin,
		}
	},
	{
		name = MendeleevLocals.CatNames.Mine,
		setindex = "minedgem",
		--color = {0.75, 0.75, 0.75},
		colour = "|cffB0C4DE",
		header = MendeleevLocals.Category.Mine,
		sets = {
			minedgemcopper      = MendeleevLocals.Mine.Copper,
			minedgemtin         = MendeleevLocals.Mine.Tin,
			minedgemsilver      = MendeleevLocals.Mine.Silver,
			minedgemiron        = MendeleevLocals.Mine.Iron,
			minedgemgold        = MendeleevLocals.Mine.Gold,
			minedgemmithril     = MendeleevLocals.Mine.Mithril,
			minedgemtruesilver  = MendeleevLocals.Mine.TSilver,
			minedgemthorium     = MendeleevLocals.Mine.Thorium,
			minedgemzgthorium   = MendeleevLocals.Mine.ZGThorium,
			minedgemrichthorium = MendeleevLocals.Mine.RThorium,
			minedgemdarkiron    = MendeleevLocals.Mine.DIron,
		}
	},
	{
		name = MendeleevLocals.CatNames.Trade,
		setindex = "tradeskill",
		--color = {1.0, 0.82, 0.0},
		colour = "|cffF5DEB3",
		header = MendeleevLocals.Category.Used,
		sets = {
			tradeskillalchemy        = MendeleevLocals.Used.Alch,
			tradeskillblacksmithing  = MendeleevLocals.Used.Smth,
			tradeskillcooking        = MendeleevLocals.Used.Cook,
			tradeskillenchanting     = MendeleevLocals.Used.Enchan,
			tradeskillengineering    = MendeleevLocals.Used.Eng,
			tradeskillfirstaid       = MendeleevLocals.Used.Aid,
			tradeskillleatherworking = MendeleevLocals.Used.Leather,
			tradeskilltailoring      = MendeleevLocals.Used.Tailor,
		}
	},
	{
		name = MendeleevLocals.CatNames.Class,
		setindex = "reagent",
		colour = "|cffff00ff",
		--color = {1.0, 0.0, 1.0},
		header = MendeleevLocals.Category.Classes,
		sets = {
			reagentpaladin = MendeleevLocals.Classes.Pal,
			reagentdruid   = MendeleevLocals.Classes.Dru,
			reagentmage    = MendeleevLocals.Classes.Mag,
			reagentpriest  = MendeleevLocals.Classes.Pri,
			reagentrogue   = MendeleevLocals.Classes.Rog,
			reagentshaman  = MendeleevLocals.Classes.Sha,
			reagentwarlock = MendeleevLocals.Classes.Warl,
		}
	},
	{
		name = MendeleevLocals.CatNames.ZGE,
		setindex = "zulgurubenchants",
		--color = { },
		colour = "|cffDC143C",
		header = MendeleevLocals.Category.ZGE,
		sets = {
			zulgurubdruidenchant   = MendeleevLocals.Classes.Dru,
			zulgurubhunterenchant  = MendeleevLocals.Classes.Hun,
			zulgurubmageenchant    = MendeleevLocals.Classes.Mag,
			zulgurubpaladinenchant = MendeleevLocals.Classes.Pal,
			zulgurubpriestenchant  = MendeleevLocals.Classes.Pri,
			zulgurubrogueenchant   = MendeleevLocals.Classes.Rog,
			zulgurubshamanenchant  = MendeleevLocals.Classes.Sha,
			zulgurubwarlockenchant = MendeleevLocals.Classes.Warl,
			zulgurubwarriorenchant = MendeleevLocals.Classes.Warr,
		}
	},
	{
		name = MendeleevLocals.CatNames.Food,
		setindex = "foodclass",
		--color = {0.2, 0.6, 0.8},
		colour = "|cff87CEFA",
		header = MendeleevLocals.Category.Foodtype,
		sets = {
			foodclassbread  	= MendeleevLocals.Foodtype.Bread,
			foodclassfish   	= MendeleevLocals.Foodtype.Fish,
			foodclassmeat   	= MendeleevLocals.Foodtype.Meat,
			foodclasscheese 	= MendeleevLocals.Foodtype.Cheese,
			foodclassfruit  	= MendeleevLocals.Foodtype.Fruit,
			foodclassfungus 	= MendeleevLocals.Foodtype.Fungus,
			foodclassmisc   	= MendeleevLocals.Foodtype.Misc,
		}
	},
	{
		name = MendeleevLocals.CatNames.Booze,
		setindex = "booze",
		--color = {1,1,1},
		colour = "|cffB0C4DE",
		header = " ",
		useval = function (v) return string.format("酒精度: %.1f%% ", v/10) end,
		sets = {
			booze  = "",
		}
	},
	{
		name = MendeleevLocals.CatNames.Faire,
		setindex = "faire",
		--color = {1,0.2,1},
		colour = "|cffFFFF00",
		header = MendeleevLocals.Category.Faire,
		useval = function (v) return string.format(" (%d 票)", v) end,
		sets = {
			faireengin   	= MendeleevLocals.Used.Eng,
			fairegreys   	= MendeleevLocals.Faire.Junk,
			faireleather 	= MendeleevLocals.Faire.Leather,
			fairesmithy  	= MendeleevLocals.Used.Smth,
		}
	},
}

MendeleevLocals.custominfosets = {"crafting"}