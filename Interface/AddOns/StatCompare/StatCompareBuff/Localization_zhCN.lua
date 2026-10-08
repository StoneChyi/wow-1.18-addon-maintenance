--[[

	File containing localized strings
	for Simplified Chinese and English versions, defaults to English

]]
function SC_BuffLocalization_zhCN()

	STATCOMPARE_BUFF_PATTERNS = {
		-- 德鲁伊的野性印记
		{ pattern = "护甲提高285点，所有属性提高12点，所有抗性提高20点。",
			effect = {"ARMOR", "STR", "AGI", "STA", "INT", "SPI", "ARCANERES", "FIRERES", "FROSTRES", "NATURERES", "SHADOWRES"},
			value = {285, 12, 12, 12, 12, 12, 20, 20, 20, 20, 20}},
		-- 猎人
		{ pattern = "远程攻击强度提高(%d+)点。", effect = "RANGEDATTACKPOWER"},
		{ pattern = "攻击强度提高(%d+)点。", effect = {"ATTACKPOWER", "RANGEDATTACKPOWER"}},
		{ pattern = "躲闪几率提高(%d+)%%。", effect = "DODGE"},
		{ pattern = "自然抗性提高(%d+)点。", effect = "NATURERES"},
		-- 法师
		{ pattern = "智力提高(%d+)点。", effect = "INT"},
		{ pattern = "使护甲提高(%d+)点，冰霜抗性提高(%d+)点，并可令攻击者减速。", effect = {"ARMOR", "FROSTRES"}},
		{ pattern = "对所有魔法的抗性提高%d+点，在任意情况下都保持(%d+)%%的法力值回复速度。",effect = "CASTING_MANA_REG"},
		{ pattern = "法力值回复速度提高(%d+)%%。", effect = "CASTING_MANA_REG"},
		{ pattern = "施法速度提高(%d+)%%，但损失法力值", effect = "HASTE"},
		-- 术士
		{ pattern = "护甲值提高(%d+)点，暗影抗性提高(%d+)点，每5秒回复(%d+)点生命值。", effect = {"ARMOR", "SHADOWRES", "HEALTHREG"}},
		-- 牧师
		{ pattern = "精神提高(%d+)点。", effect = "SPI"},
		{ pattern = "耐力提高(%d+)点。", effect = "STA"},
		{ pattern = "力量提高(%d+)点。", effect = "STR"},
		{ pattern = "每5秒恢复(%d+)点法力值。", effect = "MANAREG"},
		{ pattern = "每5秒回复(%d+)点法力值。", effect = "MANAREG"},
		{ pattern = "防御值提高(%d+)点。", effect = "ARMOR"},
		-- 圣骑士
		{ pattern = "护甲值提高(%d+)点。", effect = "ARMOR"},
		{ pattern = "所有属性提高10%%。", king = 1},
		{ pattern = "近战攻击强度提高(%d+)点。", effect = "ATTACKPOWER"},
		{ pattern = "格挡几率提高(%d+)%%", effect = "TOBLOCK"},
		-- 猫釉
		{pattern = "使敏捷提高(%d+)点，致命一击几率提高(%d+)%%。", effect = {"AGI", "CRIT"}},
		-- 赞达拉之魂
		--{ pattern = "移动速度提高10%%，所有属性提高(%d+)%%，持续2小时。"},
		-- 东泉火酒
		{ pattern = "近战攻击强度提高(%d+)点，体型增大。", effect = "ATTACKPOWER"},
		{ pattern = "火焰抗性提高(%d+)点。", effect = "FIRERES"},
		{ pattern = "生命值上限提高(%d+)点。", effect = "HEALTH"},
		{ pattern = "暗影抗性提高(%d+)点，可能令攻击者感染疾病。", effect = "SHADOWRES"},
		{ pattern = "敏捷提高(%d+)点。", effect = "AGI"},
		
		{ pattern = "使法术的致命一击几率提高(%d+)%%，近战和远程攻击的致命一击几率提高(%d+)%%，攻击强度提高(%d+)点。持续120分钟。",effect = {"SPELLCRIT","CRIT","ATTACKPOWER"},value = {10,5,140}},
		{ pattern = "魔法伤害和治疗效果提高(%d+)点。", effect = {"DMG","HEAL"}},
		{ pattern = "法术伤害提高最多(%d+)点。\n治疗效果提高最多(%d+)点。", effect = {"DMG","HEAL"}},
		--急速
		{ pattern = "急速提高(%d+)%%。", effect = "HASTE"},
		{ pattern = "攻击速度提高(%d+)%%。", effect = "HASTE"},
		{ pattern = "近战攻击速度增加(%d+)%%。", effect = "HASTE"},
		{ pattern = "远程攻击速度增加(%d+)%%。", effect = "HASTE"},
		{ pattern = "远程攻击速度提高(%d+)%%。", effect = "HASTE"},
		{ pattern = "施法速度提高(%d+)%%。", effect = "HASTE"},
		{ pattern = "攻击速度和施法速度提高(%d+)%%。", effect = "HASTE"},
		{ pattern = "攻击速度和施法速度提高(%d+)%%，受到治疗减少75%。", effect = "HASTE"},
		{ pattern = "攻击和施法速度提高(%d+)%%。", effect = "HASTE"},
		--翡翠祝福
		{ pattern = "移动速度增加10%%。法术命中率增加(%d)%%。战斗中的法力回复增加(%d)%%。", effect = {"SPELLTOHIT","CASTING_MANA_REG"}},
		--破甲
		{ pattern = "忽略目标的(%d+)点护甲值。", effect = "ARMORPENETRATION"},
		{ pattern = "当前目标的护甲值降低(%d+)点。", effect = "ARMORPENETRATION"},
		{ pattern = "提高法术所造成的伤害，最多(%d+)点。目标的魔法抗性降低(%d+)点。", effect = {"DMG", "SPELLPENETRATION"}},
		--橙杖光环
		{ pattern = "你的攻击和施法速度提高(%d+)%%。", effect = "HASTE"},
		{ pattern = "法术造成致命一击的几率提高(%d+)%%。", effect = "SPELLCRIT"},
		{ pattern = "使法术和魔法效果造成的伤害和治疗效果提高最多(%d+)点。", effect = {"DMG","HEAL"}},
		{ pattern = "法术和魔法效果所造成的治疗效果提高最多(%d+)点。", effect = "HEAL"},
		--蘑菇花
		{ pattern = "法术致命一击几率提高(%d+)%%。", effect = "SPELLCRIT"},
		--药剂
		{ pattern = "法术和技能造成的自然伤害最多增加(%d+)。", effect = "NATUREDMG"},
		{ pattern = "法术和技能造成的魔法伤害最多增加(%d+)。", effect = "DMG"},
		--陆行鸟守护
		{ pattern = "距离陆行鸟50码范围内的小队成员在战斗中将获得(%d+)%%的法力值回复和20%%的生命值回复。该效果持续到主动取消。", effect = "CASTING_MANA_REG"},
		--1.18.0新药剂
		{ pattern = "冰霜法术伤害提高最多(%d+)点。", effect = "FROSTDMG"},
		{ pattern = "奥术法术伤害提高最多(%d+)点。", effect = "ARCANEDMG"},
		{ pattern = "法术伤害和治疗效果提高(%d+)点，\r\n敏捷提高25点，\r\n物理和法术致命一击几率提高(%d+)%%", effect = {"DMG","SPELLCRIT"}},
		{ pattern = "法术伤害提高(%d+)点，\r\n近战攻击强度提高35点。", effect = "DMG"},
		{ pattern = "法术伤害提高(%d+)点，\r\n力量提高25点。", effect = "DMG"},
		--1.18.1
		{ pattern = "法术伤害提高(%d+)，", effect = "DMG"},
		{ pattern = "法术伤害和治疗效果提高(%d+)点，攻击强度提高", effect = {"DMG","HEAL"}},
		{ pattern = "施法时保持(%d+)%%的法力值回复速度，施法速度提高(%d+)%%。", effect = {"CASTING_MANA_REG","HASTE"}},
		{ pattern = "法术命中几率提高(%d)%%", effect = "SPELLTOHIT"},

	};

end