Tmog = {}

local axes, axes2H, bows, guns, maces, maces2H, polearms, swords, swords2H, staves, fists, miscellaneous, daggers, thrown, crossbows, wands, fishingPole = GetAuctionItemSubClasses(1)
local miscellaneous, cloth, leather, mail, plate, shields, librams, idols, totems = GetAuctionItemSubClasses(2)
local weapon, armor, container, consumable, tradeGoods, projectile, quiver, recipe, reagent, miscellaneous =  GetAuctionItemClasses(1)

Tmog.L = {
	["Cloth"] = cloth,
	["Leather"] = leather,
	["Mail"] = mail,
	["Plate"] = plate,
	["Miscellaneous"] = miscellaneous,
	["Daggers"] = daggers,
	["One-Handed Axes"] = axes,
	["One-Handed Swords"] = swords,
	["One-Handed Maces"] = maces,
	["Fist Weapons"] = fists,
	["Polearms"] = polearms,
	["Staves"] = staves,
	["Two-Handed Axes"] = axes2H,
	["Two-Handed Swords"] = swords2H,
	["Two-Handed Maces"] = maces2H,
	["Shields"] = shields,
	["Bows"] = bows,
	["Guns"] = guns,
	["Crossbows"] = crossbows,
	["Wands"] = wands,
	["Weapon"] = weapon,
	["Armor"] = armor,
	["Fishing Pole"] = fishingPole,
	----------------------------
	["Collected"] = true,
	["Not collected"] = true,
	["Unique appearance"] = true,
	["Non-unique appearance"] = true,
	["Unknown appearance"] = true,
	["Shares appearance with"] = true,
	["Outfits"] = true,
	["New outfit"] = true,
	["Create an outfit from currently selected items."] = true,
	["Enter outfit name:"] = true,
	["Outfit with this name already exists."] = true,
	["Outfit name not valid."] = true,
	["Delete outfit?"] = true,
	["Invalid outfit code."] = true,
	["Enter outfit code:"] = true,
	["toggle dressing room"] = true,
	["reset minimap button position"] = true,
	["lock/unlock minimap button"] = true,
	["print debug messages in chat"] = true,
	["attempt to repair this character's cache (can fix minor bugs)"] = true,
	["minimap button unlocked"] = true,
	["minimap button locked"] = true,
	["debug is on"] = true,
	["debug is off"] = true,
	["Cache repair started."] = true,
	["bad item %d, requesting info from server, try #%d"] = true,
	["Cache repair finished: bad items deleted: %d, item names restored: %d, missing shared items added: %d"] = true,
	["Share outfit"] = true,
	["Import outfit"] = true,
	["Select outfit"] = true,
	["Save outfit"] = true,
	["Delete outfit"] = true,
	["Select type"] = true,
	["Only usable"] = true,
	["Check this to only show items that you can equip. Can be inaccurate for quest rewards."] = true,
	["Check this to ignore level requirements while \"Only usable\" filter is active. Can be inaccurate for quest rewards."] = true,
	["Ignore level"] = true,
	["Hide UI"] = true,
	["Show UI"] = true,
	["Clear"] = true,
	["Undress"] = true,
	["Reset Position"] = true,
	["Revert"] = true,
	["Full Screen"] = true,
	["Share"] = true,
	["Import"] = true,
	["Copy this code:"] = true,
	["Left-click to toggle dressing room\nHold Left-click and drag to move this button"] = true,
	["Loading"] = true,
	["Outfits: %s"] = true,
	["Database links:"] = true,
	["reset this character's collection"] = true,
	["cllection has been reset"] = true,
}

if GetLocale() == "zhCN" then
	Tmog.L["Collected"] = "已有幻化"
	Tmog.L["Not collected"] = "未收集幻化"
	Tmog.L["Unique appearance"] = "独特外观"
	Tmog.L["Non-unique appearance"] = "非独特外观"
	Tmog.L["Unknown appearance"] = "未知的外观"
	Tmog.L["Shares appearance with"] = "共享外观"
	Tmog.L["Outfits"] = "配装"
	Tmog.L["New outfit"] = "新配装"
	Tmog.L["Create an outfit from currently selected items."] = "用当前选定的物品创建一套配装。"
	Tmog.L["Enter outfit name:"] = "输入配装名称:"
	Tmog.L["Outfit with this name already exists."] = "已存在同名配装。"
	Tmog.L["Outfit name not valid."] = "配装名称无效。"
	Tmog.L["Delete outfit?"] = "删除配装？"
	Tmog.L["Invalid outfit code."] = "无效的配装代码。"
	Tmog.L["Enter outfit code:"] = "在此输入配装代码:"
	Tmog.L["toggle dressing room"] = "切换幻化界面"
	Tmog.L["reset minimap button position"] = "重置小地图按钮位置"
	Tmog.L["lock/unlock minimap button"] = "锁定/解锁小地图按钮"
	Tmog.L["print debug messages in chat"] = "在聊天中显示调试信息"
	Tmog.L["attempt to repair this character's cache (can fix minor bugs)"] = "尝试修复角色缓存(可解决小问题)"
	Tmog.L["minimap button unlocked"] = "小地图按钮已解锁"
	Tmog.L["minimap button locked"] = "小地图按钮已锁定"
	Tmog.L["debug is on"] = "调试模式已开启"
	Tmog.L["debug is off"] = "调试模式已关闭"
	Tmog.L["Cache repair started."] = "缓存修复已开始。"
	Tmog.L["bad item %d, requesting info from server, try #%d"] = "无效对象 %d，正在向服务器请求信息，尝试第 #%d次"
	Tmog.L["Cache repair finished: bad items deleted: %d, item names restored: %d, missing shared items added: %d"] = "缓存修复已完成：已删除物品：%d，已恢复物品名称：%d，已添加相似物品：%d"
	Tmog.L["Share outfit"] = "分享配装"
	Tmog.L["Import outfit"] = "导入配装"
	Tmog.L["Select outfit"] = "选择一个配装"
	Tmog.L["Save outfit"] = "保存配装"
	Tmog.L["Delete outfit"] = "删除配装"
	Tmog.L["Select type"] = "选择类型"
	Tmog.L["Only usable"] = "仅可用"
	Tmog.L["Ignore level"] = "忽略等级"
	Tmog.L["Check this to only show items that you can equip. Can be inaccurate for quest rewards."] = "选中此项只会显示可以装备的物品。对于任务奖励可能不准确。"
	Tmog.L["Check this to ignore level requirements while \"Only usable\" filter is active. Can be inaccurate for quest rewards."] = "选中此选项将在 \“仅可用\”过滤器激活时忽略等级要求。对于任务奖励来说可能不准确。"
	Tmog.L["Hide UI"] = "隐藏"
	Tmog.L["Show UI"] = "显示"
	Tmog.L["Clear"] = "清除"
	Tmog.L["Undress"] = "脱光"
	Tmog.L["Reset Position"] = "重置位置"
	Tmog.L["Revert"] = "还原"
	Tmog.L["Full Screen"] = "全屏显示"
	Tmog.L["Share"] = "分享"
	Tmog.L["Import"] = "导入"
	Tmog.L["Copy this code:"] = "复制此代码:"
	Tmog.L["Left-click to toggle dressing room\nHold Left-click and drag to move this button"] = "左键点击打开试衣间\n按住左键拖动可移动此按钮。"
	Tmog.L["Loading"] = "加载中"
	Tmog.L["Outfits: %s"] = "配装：%s"
	Tmog.L["Database links:"] = "数据库链接："
	Tmog.L["reset this character's collection"] = "重置此角色的收藏"
	Tmog.L["cllection has been reset"] = "收藏已重置"
elseif GetLocale() == "ruRU" then
	Tmog.L["Collected"] = "В коллекции"
	Tmog.L["Not collected"] = "Не в коллекции"
	Tmog.L["Unique appearance"] = "Уникальный внешний вид"
	Tmog.L["Non-unique appearance"] = "Не уникальный внешний вид"
	Tmog.L["Unknown appearance"] = "Неизвестный внешний вид"
	Tmog.L["Shares appearance with"] = "Общий внешний вид с"
	Tmog.L["Outfits"] = "Наряды"
	Tmog.L["New outfit"] = "Новый наряд"
	Tmog.L["Create an outfit from currently selected items."] = "Создать наряд из выбранных предметов."
	Tmog.L["Enter outfit name:"] = "Введите название наряда:"
	Tmog.L["Outfit with this name already exists."] = "Наряд с таким названием уже существует."
	Tmog.L["Outfit name not valid."] = "Некорректное название."
	Tmog.L["Delete outfit?"] = "Удалить наряд?"
	Tmog.L["Invalid outfit code."] = "Некорректный код."
	Tmog.L["Enter outfit code:"] = "Введите код наряда:"
	Tmog.L["toggle dressing room"] = "открыть примерочную."
	Tmog.L["reset minimap button position"] = "восстановить позицию мини-кнопки."
	Tmog.L["lock/unlock minimap button"] = "зафиксировать/разблокировать мини-кнопкую"
	Tmog.L["print debug messages in chat"] = "вывод отладочных сообщений в чат."
	Tmog.L["attempt to repair this character's cache (can fix minor bugs)"] = "попытка исправить кэш данного персонажа (может помочь в случае незначительных ошибок)"
	Tmog.L["minimap button unlocked"] = "мини-кнопка разблокирована"
	Tmog.L["minimap button locked"] = "мини-кнопка зафиксирована"
	Tmog.L["debug is on"] = "отладка включена"
	Tmog.L["debug is off"] = "отладка выключена"
	Tmog.L["Cache repair started."] = "Починка кэша начата."
	Tmog.L["bad item %d, requesting info from server, try #%d"] = "некорректный предмет %d, запрос с сервера номер %d"
	Tmog.L["Cache repair finished: bad items deleted: %d, item names restored: %d, missing shared items added: %d"] = "Починка кэша завершена: удалено предметов: %d, названий предметов восстановлено: %d, похожих предметов добавлено: %d"
	Tmog.L["Share outfit"] = "Экспортировать наряд"
	Tmog.L["Import outfit"] = "Импортировать наряд"
	Tmog.L["Select outfit"] = "Выбрать наряд"
	Tmog.L["Save outfit"] = "Сохранить наряд"
	Tmog.L["Delete outfit"] = "Удалить наряд"
	Tmog.L["Select type"] = "Выбрать тип"
	Tmog.L["Only usable"] = "Подходящее"
	Tmog.L["Ignore level"] = "Игнор. уровень"
	Tmog.L["Check this to only show items that you can equip. Can be inaccurate for quest rewards."] = "Кликните чтобы показать только те предметы, которые вы можете надеть. Награды за задания могут отображаться некорректно."
	Tmog.L["Check this to ignore level requirements while \"Only usable\" filter is active. Can be inaccurate for quest rewards."] = "Кликните чтобы не учитывать требуемый уровень предметов, когда \"Подходящее\" фильтр активен. Награды за задания могут отображаться некорректно."
	Tmog.L["Hide UI"] = "СкрытьUI"
	Tmog.L["Show UI"] = "Показ.UI"
	Tmog.L["Clear"] = "Очистить"
	Tmog.L["Undress"] = "Раздеть"
	Tmog.L["Reset Position"] = "Сброс позиции"
	Tmog.L["Revert"] = "Сброс"
	Tmog.L["Full Screen"] = "Во весь экран"
	Tmog.L["Share"] = "Экспорт"
	Tmog.L["Import"] = "Импорт"
	Tmog.L["Copy this code:"] = "Скопируйте код:"
	Tmog.L["Left-click to toggle dressing room\nHold Left-click and drag to move this button"] = "ЛКМ чтобы открыть или закрыть примерочную\nУдерживайте ЛКМ и тащите чтобы перемесить эту кнопку."
	Tmog.L["Loading"] = "Загрузка"

elseif GetLocale() == "esES" then

elseif GetLocale() == "ptBR" then


elseif GetLocale() == "deDE" then

end

for k, v in pairs(Tmog.L) do
	if v == true then
		Tmog.L[k] = k
	end
end