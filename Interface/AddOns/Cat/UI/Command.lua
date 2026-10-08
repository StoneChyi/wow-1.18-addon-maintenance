-- 指令相关

BINDING_HEADER_CAT_PLUGINNAME = MPLanguage.UI_BindingHeader


-- 注册猫德输出指令
function MPCatCommand(msg)
    if MPPlayerClass ~= "DRUID" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPDruidCatConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPDruidCatConfig = num
		end
	end

	MPCat()
end
function MPCatShredCommand(msg)
    if MPPlayerClass ~= "DRUID" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPDruidCatConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPDruidCatConfig = num
		end
	end

	MPCat(2)
end
function MPBearCommand(msg)
    if MPPlayerClass ~= "DRUID" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPDruidBearConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPDruidBearConfig = num
		end
	end

	MPBear()
end
function MPCooCommand(msg)
    if MPPlayerClass ~= "DRUID" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPDruidCooConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPDruidCooConfig = num
		end
	end

	MPCoo()
end
function MPDHealCommand(msg)
    if MPPlayerClass ~= "DRUID" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPDruidHealConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPDruidHealConfig = num
		end
	end

	MPDruidAutoHealth()
end






function MPWarriorArmsCommand(msg)
    if MPPlayerClass ~= "WARRIOR" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPWarrorArmsConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPWarrorArmsConfig = num
		end
	end

	MPArmsDPS()
end

function MPWarriorFuryCommand(msg)
    if MPPlayerClass ~= "WARRIOR" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPWarriorFuryConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPWarriorFuryConfig = num
		end
	end

	MPFuryDPS()
end

function MPWarriorEvilCommand(msg)
    if MPPlayerClass ~= "WARRIOR" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPWarriorEvilConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPWarriorEvilConfig = num
		end
	end

	MPEvilDPS()
end


function MPWarriorTankCommand(msg)
    if MPPlayerClass ~= "WARRIOR" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPWarriorTankConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPWarriorTankConfig = num
		end
	end

	MPWarriorTank()
end




function MPPaladinHealCommand(msg)
    if MPPlayerClass ~= "PALADIN" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPPaladinHealConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPPaladinHealConfig = num
		end
	end

	MPPaladinAutoHealth()
end
function MPPaladinMeleeHealCommand(msg)
    if MPPlayerClass ~= "PALADIN" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPPaladinMeleeHealConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPPaladinMeleeHealConfig = num
		end
	end

	MPPaladinAutoMeleeHealth()
end
function MPPaladinDPSSpellCommand(msg)
    if MPPlayerClass ~= "PALADIN" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPPaladinCJConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPPaladinCJConfig = num
		end
	end

	MPPaladinCJSpell()
end
function MPPaladinTankCommand(msg)
    if MPPlayerClass ~= "PALADIN" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPPaladinTankConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPPaladinTankConfig = num
		end
	end

	MPPallyTank()
end








function MPRogueDPSCommand(msg)
    if MPPlayerClass ~= "ROGUE" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPRogueConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPRogueConfig = num
		end
	end

	MPRogueDPS()
end

function MPRogueEnvenomCommand(msg)
    if MPPlayerClass ~= "ROGUE" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPRogueEnvenomConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPRogueEnvenomConfig = num
		end
	end

	MPRogueEnvenomDPS()
end

function MPRogueCombatCommand(msg)
    if MPPlayerClass ~= "ROGUE" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPRogueCombatConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPRogueCombatConfig = num
		end
	end

	MPRogueCombatDPS()
end

function MPRoguePJZCommand(msg)
    if MPPlayerClass ~= "ROGUE" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPRogueArmorConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPRogueArmorConfig = num
		end
	end

	MPRoguePJZ()
end




function MPShamanHealCommand(msg)
    if MPPlayerClass ~= "SHAMAN" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPShamanHealConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPShamanHealConfig = num
		end
	end

	MPShamanAutoHealth()
end
function MPShamanEnhanceCommand(msg)
    if MPPlayerClass ~= "SHAMAN" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPShamanEnhanceConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPShamanEnhanceConfig = num
		end
	end

	MPShamanAutoEnhance()
end
function MPShamanElementalCommand(msg)
    if MPPlayerClass ~= "SHAMAN" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPShamanElementalConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPShamanElementalConfig = num
		end
	end

	MPShamanAutoElemental()
end





function MPWarlockSDCommand(msg)
    if MPPlayerClass ~= "WARLOCK" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPWarlockSDConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPWarlockSDConfig = num
		end
	end

	MPWarlockSD()
end
function MPWarlockFDCommand(msg)
    if MPPlayerClass ~= "WARLOCK" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPWarlockFDConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPWarlockFDConfig = num
		end
	end

	MPWarlockFD()
end
function MPWarlockAffCommand(msg)
    if MPPlayerClass ~= "WARLOCK" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPWarlockAffConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPWarlockAffConfig = num
		end
	end

	MPWarlockAff()
end
function MPWarlockDemoCommand(msg)
    if MPPlayerClass ~= "WARLOCK" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPWalockDemoConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPWalockDemoConfig = num
		end
	end

	MPWarlockDemo()
end





function MPMageArcaneCommand(msg)
    if MPPlayerClass ~= "MAGE" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPMageArcaneConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPMageArcaneConfig = num
		end
	end

	MPMageArcaneAuto()
end
function MPMageFireCommand(msg)
    if MPPlayerClass ~= "MAGE" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPMageFireConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPMageFireConfig = num
		end
	end

	MPMageFireAuto()
end
function MPMageFrostCommand(msg)
    if MPPlayerClass ~= "MAGE" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPMageFrostConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPMageFrostConfig = num
		end
	end

	MPMageFrostAuto()
end





function MPHolyPriestCommand(msg)
    if MPPlayerClass ~= "PRIEST" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPPriestHealConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPPriestHealConfig = num
		end
	end

	MPPriestAutoHealth()
end
function MPShadowPriestCommand(msg)
    if MPPlayerClass ~= "PRIEST" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPPriestShadowConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPPriestShadowConfig = num
		end
	end

	MPPriestShadow()
end
function MPDisciplinePriestCommand(msg)
    if MPPlayerClass ~= "PRIEST" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPPriestDConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPPriestDConfig = num
		end
	end

	MPPriestDiscipline()
end





function MPHunterShotCommand(msg)
    if MPPlayerClass ~= "HUNTER" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPHunterShotConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPHunterShotConfig = num
		end
	end

	MPHunterShotDPS()
end
function MPHunterBeastCommand(msg)
    if MPPlayerClass ~= "HUNTER" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPHunterBeastConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPHunterBeastConfig = num
		end
	end

	MPHunterBeastDPS()
end
function MPHunterMeleeCommand(msg)
    if MPPlayerClass ~= "HUNTER" then
		DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ClassError)
		return
	end

	MPHunterMeleeConfig = 1
	local num = MPToNumber(MPMatch(msg or "", "(%d+)"))
	if num then
		if num>0 and num<4 then
			MPHunterMeleeConfig = num
		end
	end

	MPHunterMeleeDPS()
end





function MPINTCastCommand(arg1)
	if not arg1 or string.len(arg1)<1 then
		MPINTCast()
	else
		MPINTCast(arg1)
	end
end

function MPINTCastListCommand(arg1)
	MPINTCastList()
end

function MPMDotCommand(arg1)
	MPMuiltlineDot()
end

function MPPowerCommand(arg1)
	MPCatPower()
end

function MPAutoLootCommand(arg1)
	MPAutoLoot()
end

function MPCatUICommand()

    MPCatSettingsCloseAll()
    CatUISettingsCatMenu:Show()

end




SlashCmdList['CAT1'] = MPCatCommand
SLASH_CAT11 = '/catdps'
SlashCmdList['CAT2'] = MPCatShredCommand
SLASH_CAT21 = '/catshred'
SlashCmdList['BEAR'] = MPBearCommand
SLASH_BEAR1 = '/beardps'
SlashCmdList['COO'] = MPCooCommand
SLASH_COO1 = '/coodps'
SlashCmdList['DHEAL'] = MPDHealCommand
SLASH_DHEAL1 = '/dheal'


SlashCmdList['WARRIORARMS'] = MPWarriorArmsCommand
SLASH_WARRIORARMS1 = '/arms'
SlashCmdList['WARRIORFURY'] = MPWarriorFuryCommand
SLASH_WARRIORFURY1 = '/fury'
SlashCmdList['WARRIOREVIL'] = MPWarriorEvilCommand
SLASH_WARRIOREVIL1 = '/evil'
SlashCmdList['WARRIORTANK'] = MPWarriorTankCommand
SLASH_WARRIORTANK1 = '/wtank'


SlashCmdList['PALADINHEAL'] = MPPaladinHealCommand
SLASH_PALADINHEAL1 = '/pheal'
SlashCmdList['PALADINMELEEHEAL'] = MPPaladinMeleeHealCommand
SLASH_PALADINMELEEHEAL1 = '/mpheal'
SlashCmdList['PALADINDPS'] = MPPaladinDPSSpellCommand
SLASH_PALADINDPS1 = '/pdps'
SlashCmdList['PALADINTANK'] = MPPaladinTankCommand
SLASH_PALADINTANK1 = '/ptank'


SlashCmdList['ROGUEDPS'] = MPRogueDPSCommand
SLASH_ROGUEDPS1 = '/rdps'
SlashCmdList['ROGUEENVENOM'] = MPRogueEnvenomCommand
SLASH_ROGUEENVENOM1 = '/dsdps'
SlashCmdList['ROGUECOMBAT'] = MPRogueCombatCommand
SLASH_ROGUECOMBAT1 = '/zddps'
SlashCmdList['ROGUEPJZ'] = MPRoguePJZCommand
SLASH_ROGUEPJZ1 = '/pjz'


SlashCmdList['SHAMANHEAL'] = MPShamanHealCommand
SLASH_SHAMANHEAL1 = '/sheal'
SlashCmdList['SHAMANENHANCE'] = MPShamanEnhanceCommand
SLASH_SHAMANENHANCE1 = '/swdps'
SlashCmdList['SHAMANELEMENTAL'] = MPShamanElementalCommand
SLASH_SHAMANELEMENTAL1 = '/sedps'


SlashCmdList['WARLOCKSD'] = MPWarlockSDCommand
SLASH_WARLOCKSD1 = '/ahdps'
SlashCmdList['WARLOCKFD'] = MPWarlockFDCommand
SLASH_WARLOCKFD1 = '/fhdps'
SlashCmdList['WARLOCKAFF'] = MPWarlockAffCommand
SLASH_WARLOCKAFF1 = '/tkdps'
SlashCmdList['WARLOCKDEMO'] = MPWarlockDemoCommand
SLASH_WARLOCKDEMO1 = '/dedps'


SlashCmdList['MAGEARCANE'] = MPMageArcaneCommand
SLASH_MAGEARCANE1 = '/madps'
SlashCmdList['MAGEFIRE'] = MPMageFireCommand
SLASH_MAGEFIRE1 = '/mhdps'
SlashCmdList['MAGEFROST'] = MPMageFrostCommand
SLASH_MAGEFROST1 = '/mfdps'


SlashCmdList['HOLYPRIEST'] = MPHolyPriestCommand
SLASH_HOLYPRIEST1 = '/mheal'
SlashCmdList['SHADOWPRIEST'] = MPShadowPriestCommand
SLASH_SHADOWPRIEST1 = '/amdps'
SlashCmdList['DISCIPLINEPRIEST'] = MPDisciplinePriestCommand
SLASH_DISCIPLINEPRIEST1 = '/jldps'


SlashCmdList['HUNTERSHOT'] = MPHunterShotCommand
SLASH_HUNTERSHOT1 = '/sjdps'
SlashCmdList['HUNTERBEAST'] = MPHunterBeastCommand
SLASH_HUNTERBEAST1 = '/hbdps'
SlashCmdList['HUNTERMELEE'] = MPHunterMeleeCommand
SLASH_HUNTERMELEE1 = '/hmdps'



SlashCmdList['INTCAST'] = MPINTCastCommand
SLASH_INTCAST1 = '/INTCast'

SlashCmdList['INTCASTLIST'] = MPINTCastListCommand
SLASH_INTCASTLIST1 = '/INTCastList'

SlashCmdList['MDOT'] = MPMDotCommand
SLASH_MDOT1 = '/mdot'

SlashCmdList['CATPOWER'] = MPPowerCommand
SLASH_CATPOWER1 = '/catp'
SLASH_CATPOWER2 = '/catpower'

SlashCmdList['AUTOLOOT'] = MPAutoLootCommand
SLASH_AUTOLOOT1 = '/catpick'

SlashCmdList['CATUI'] = MPCatUICommand
SLASH_CATUI1 = '/catui'
SLASH_CATUI2 = '/cat'
