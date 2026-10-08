local _G = getglobal
local tinsert = table.insert
local tremove = table.remove
local UN = UnitName
local strform = string.format
local flr = floor
local strgfind = string.gfind
local strfind = string.find
local GT = GetTime
local tnbr = tonumber

local SELECTEDICON = "Interface\\Icons\\Ability_Warrior_BattleShout"
local icopath = "Interface\\Icons\\"
local locpath = "Interface\\AddOns\\ModifiedPowerAuras\\Auras\\"

local icons = {
	["warrior"] = {
		[icopath.."Ability_Warrior_BattleShout"] = true,
		[icopath.."Ability_Warrior_DefensiveStance"] = true,
		[icopath.."Ability_Warrior_Disarm"] = true,
		[icopath.."Ability_Warrior_OffensiveStance"] = true,
		[icopath.."Ability_Warrior_PunishingBlow"] = true,
		[icopath.."Ability_Warrior_SavageBlow"] = true,
		[icopath.."Ability_Warrior_Sunder"] = true,
		[icopath.."Ability_Warrior_ShieldWall"] = true,
		[icopath.."Ability_Warrior_WarCry"] = true,
		[icopath.."Ability_Racial_Avatar"] = true,
		[icopath.."Ability_Racial_BloodRage"] = true,
		[icopath.."Spell_Nature_AncestralGuardian"] = true,
		[icopath.."Spell_Nature_ThunderClap"] = true,
		[icopath.."Ability_Gouge"] = true,
		[icopath.."Ability_ShockWave"] = true,
		[icopath.."Ability_CriticalStrike"] = true,
		[icopath.."Ability_Warrior_Challange"] = true,
		[icopath.."Ability_GolemThunderClap"] = true,
		[icopath.."Spell_Nature_Reincarnation"] = true,
		[icopath.."Ability_Defend"] = true,
		[icopath.."Ability_Rogue_SliceDice"] = true,
		[icopath.."spell_holy_ashestoashes"] = true,
		[icopath.."spell_shadow_unholyfrenzy"] = true,
		[icopath.."inv_shield_05"] = true,
		[icopath.."ability_thunderbolt"] = true,
		[icopath.."ability_warrior_revenge"] = true,
		[icopath.."spell_nature_bloodlust"] = true,
		[icopath.."ability_whirlwind"] = true,
		[icopath.."Spell_Nature_BloodLust"] = true,
		[icopath.."Ability_BullRush"] = true,
		[icopath.."Ability_Warrior_Charge"] = true,
		[icopath.."Ability_Warrior_Cleave"] = true,
		[icopath.."Ability_Warrior_Riposte"] = true,
		[icopath.."INV_Sword_48"] = true,
		[icopath.."Ability_Rogue_Ambush"] = true,
		[icopath.."Ability_Rogue_Sprint"] = true,
		[icopath.."Ability_MeleeDamage"] = true,
		[icopath.."INV_Gauntlets_04"] = true,
		[icopath.."Ability_Warrior_ShieldBash"] = true,
		[icopath.."Ability_Warrior_DecisiveStrike_New"] = true,
		
	},
	["rogue"] = {
		[icopath.."Ability_Sap"] = true,
		[icopath.."Ability_Rogue_Sprint"] = true,
		[icopath.."Ability_Rogue_SliceDice"] = true,
		[icopath.."Ability_Rogue_Rupture"] = true,
		[icopath.."Ability_Rogue_KidneyShot"] = true,
		[icopath.."Ability_Rogue_Garrote"] = true,
		[icopath.."Ability_Rogue_DualWeild"] = true,
		[icopath.."Ability_Warrior_Riposte"] = true,
		[icopath.."Spell_Shadow_ShadowWard"] = true,
		[icopath.."Ability_Stealth"] = true,
		[icopath.."Ability_Gouge"] = true,
		[icopath.."Ability_Kick"] = true,
		[icopath.."Spell_Shadow_ShadowWordDominate"] = true,
		[icopath.."Ability_Warrior_PunishingBlow"] = true,
		[icopath.."Ability_CheapShot"] = true,
		[icopath.."Ability_Vanish"] = true,
		[icopath.."Spell_Shadow_MindSteal"] = true,
		[icopath.."Spell_Ice_Lament"] = true,
		[icopath.."ABILITY_POISONSTING"] = true,
		[icopath.."Spell_Nature_NullifyDisease"] = true,
		[icopath.."ability_rogue_feint"] = true,
		[icopath.."ability_rogue_distract"] = true,
		[icopath.."INV_Misc_Bag_11"] = true,
		[icopath.."Ability_Rogue_Eviscerate"] = true,
		[icopath.."Spell_Nature_MoonKey"] = true,
		[icopath.."Ability_Rogue_BackStab"] = true,
		[icopath.."Spell_Shadow_RitualOfSacrifice"] = true,
		[icopath.."Trade_BrewPoison"] = true,
		[icopath.."Ability_Rogue_Ambush"] = true,
		[icopath.."Ability_PoisonSting"] = true,
		[icopath.."Ability_PoisonArrow"] = true,
		[icopath.."Spell_Nature_NullifyDisease"] = true,
		[icopath.."Ability_Spy"] = true,
		[icopath.."Spell_Shadow_GrimWard"] = true,
		[icopath.."Spell_Shadow_LifeDrain"] = true,
		[icopath.."INV_Misc_Herb_16"] = true,
		[icopath.."Ability_Rogue_Sprint"] = true,
		[icopath.."Ability_Rogue_FeignDeath"] = true,
		[icopath.."Ability_Rogue_FleetFooted"] = true,
		[icopath.."Ability_Rogue_Distract"] = true,
		[icopath.."INV_Sword_31"] = true,
		[icopath.."INV_ThrowingKnife_03"] = true,
		[icopath.."spell_double_dose_5"] = true,
		[icopath.."spell_smoke_bomb_7"] = true,
		[icopath.."Ability_Rogue_SurpriseAttack"] = true,

	},
	["priest"] = {
		[icopath.."Spell_Holy_WordFortitude"] = true,
		[icopath.."Spell_Shadow_Shadowform"] = true,
		[icopath.."Spell_Shadow_UnsummonBuilding"] = true,
		[icopath.."Spell_Shadow_PsychicScream"] = true,
		[icopath.."Spell_Shadow_SiphonMana"] = true,
		[icopath.."Spell_Holy_PrayerofShadowProtection"] = true,
		[icopath.."Spell_Holy_PrayerofSpirit"] = true,
		[icopath.."Spell_Holy_PrayerOfFortitude"] = true,
		[icopath.."Spell_Shadow_ShadowWordPain"] = true,
		[icopath.."Spell_Holy_PowerWordShield"] = true,
		[icopath.."Spell_Holy_Renew"] = true,
		[icopath.."Spell_Magic_LesserInvisibilty"] = true,
		[icopath.."Spell_Shadow_DeadofNight"] = true,
		[icopath.."Spell_Holy_InnerFire"] = true,
		[icopath.."Spell_Shadow_FingerOfDeath"] = true,
		[icopath.."Spell_Holy_NullifyDisease"] = true,
		[icopath.."Spell_Holy_MindSooth"] = true,
		[icopath.."Spell_Holy_ElunesGrace"] = true,
		[icopath.."Spell_Shadow_BlackPlague"] = true,
		[icopath.."Spell_Holy_Excorcism"] = true,
		[icopath.."Spell_Nature_Slow"] = true,
		[icopath.."Spell_Holy_MindVision"] = true,
		[icopath.."Spell_Shadow_RitualOfSacrifice"] = true,
		[icopath.."Spell_Nature_NullifyDisease"] = true,
		[icopath.."Spell_Holy_LayOnHands"] = true,
		[icopath.."spell_holy_powerinfusion"] = true,
		[icopath.."Spell_Holy_ChampionsGrace"] = true,
		[icopath.."Spell_Holy_ProclaimChampion_02"] = true,
		[icopath.."Spell_Holy_Resurrection"] = true,
		[icopath.."Spell_Holy_InnerFire"] = true,
		[icopath.."Spell_Shadow_UnholyFrenzy"] = true,
		[icopath.."Spell_Holy_HolySmite"] = true,
		[icopath.."Spell_Arcane_StarFire"] = true,
		[icopath.."Spell_Holy_LesserHeal"] = true,
		[icopath.."Spell_Holy_Restoration"] = true,
		[icopath.."Spell_Holy_SearingLight"] = true,
		[icopath.."Spell_Holy_FlashHeal"] = true,
		[icopath.."Spell_Holy_HolyNova"] = true,
		[icopath.."Spell_Holy_DispelMagic"] = true,
		[icopath.."Spell_Holy_ElunesGrace"] = true,
		[icopath.."Spell_Holy_InnerFire"] = true,
		[icopath.."Spell_Shadow_ManaBurn"] = true,
		[icopath.."Spell_Nature_LightningShield"] = true,
		[icopath.."Spell_Holy_PrayerOfHealing02"] = true,
		[icopath.."Spell_Holy_DivineSpirit"] = true,
		[icopath.."Spell_Shadow_ManaBurn"] = true,
		[icopath.."Spell_Holy_GreaterHeal"] = true,
		[icopath.."Spell_Holy_SummonLightwell"] = true,
		[icopath.."Spell_Shadow_AntiShadow"] = true,
		[icopath.."Spell_Holy_UnyieldingFaith"] = true,
		[icopath.."Spell_Shadow_PainSpike"] = true,
		[icopath.."Ability_SearingArrow"] = true,
		[icopath.."Spell_Holy_HolyProtection"] = true,
		[icopath.."Spell_Holy_BlessedRecovery"] = true,
	},
	["hunter"] = {
		[icopath.."Ability_Hunter_SniperShot"] = true,
		[icopath.."Ability_Hunter_RunningShot"] = true,
		[icopath.."Ability_Hunter_Quickshot"] = true,
		[icopath.."Ability_Hunter_MendPet"] = true,
		[icopath.."Ability_Hunter_CriticalShot"] = true,
		[icopath.."Ability_Hunter_AspectOfTheMonkey"] = true,
		[icopath.."INV_Spear_02"] = true,
		[icopath.."Spell_Nature_RavenForm"] = true,
		[icopath.."Spell_Frost_ChainsOfIce"] = true,
		[icopath.."Spell_Fire_SelfDestruct"] = true,
		[icopath.."Spell_Fire_FlameShock"] = true,
		[icopath.."Spell_Nature_ProtectionformNature"] = true,
		[icopath.."Ability_Rogue_Trip"] = true,
		[icopath.."Ability_Mount_WhiteTiger"] = true,
		[icopath.."Ability_Rogue_FeignDeath"] = true,
		[icopath.."Ability_GolemStormBolt"] = true,
		[icopath.."Spell_Fire_Flare"] = true,
		[icopath.."Ability_EyeOfTheOwl"] = true,
		[icopath.."Ability_Mount_JungleTiger"] = true,
		[icopath.."Spell_Nature_Web"] = true,
		[icopath.."Spell_Nature_Drowsy"] = true,
		[icopath.."Spell_Nature_StarFall"] = true,
		[icopath.."Ability_Druid_ImpalingBolt"] = true,
		[icopath.."Ability_Hunter_AspectOfTheFox"] = true,
		[icopath.."Ability_Hunter_Pet_Turtle"] = true,
		[icopath.."Ability_Hunter_Pet_WhiteDireWolf"] = true,
		[icopath.."Ability_Whirlwind"] = true,
		[icopath.."INV_Misc_Food_66"] = true,
		[icopath.."Ability_Physical_Taunt"] = true,
		[icopath.."Ability_Hunter_BeastCall02"] = true,
		[icopath.."Ability_Racial_Cannibalize"] = true,
		[icopath.."Ability_TheBlackArrow"] = true,
		[icopath.."spell_bubl1"] = true,
		[icopath.."Ability_Hunter_BeastCall"] = true,
		[icopath.."INV_ThrowingKnife_06"] = true,
		[icopath.."Ability_Hunter_Pet_Boar"] = true,
		[icopath.."Ability_Druid_Rake"] = true,
	    [icopath.."Spell_Nature_GuardianWard"] = true,
		[icopath.."Spell_Frost_Stun"] = true,
		[icopath.."Ability_Druid_Cower"] = true,
		[icopath.."Ability_Warrior_Challange"] = true,
		[icopath.."Ability_Druid_Dash"] = true,
		[icopath.."INV_Misc_Milk_02"] = true,
		[icopath.."Spell_Nature_SpiritWolf"] = true,
		[icopath.."Spell_Arcane_Blink"] = true,
		[icopath.."Ability_Hunter_EagleEye"] = true,
		[icopath.."Spell_Frost_FreezingBreath"] = true,
		[icopath.."Ability_Hunter_KillCommand"] = true,
		[icopath.."spell_lacerate_1C"] = true,
		[icopath.."Ability_Hunter_SwiftStrike"] = true,
		[icopath.."Ability_MeleeDamage"] = true,
		[icopath.."Ability_UpgradeMoonGlaive"] = true,
		[icopath.."Spell_Nature_UnyeildingStamina"] = true,
		[icopath.."Ability_Hunter_BeastSoothe"] = true,
		[icopath.."Ability_Hunter_SteadyShot"] = true,
		[icopath.."Ability_Hunter_AimedShot"] = true,
		[icopath.."INV_Spear_07"] = true,
		[icopath.."Ability_Parry"] = true,
	},
	["druid"] = {
		[icopath.."Ability_Druid_TravelForm"] = true,
		[icopath.."Ability_Druid_SupriseAttack"] = true,
		[icopath.."Ability_Druid_Mangle"] = true,
		[icopath.."Ability_Druid_Enrage"] = true,
		[icopath.."Ability_Druid_Dash"] = true,
		[icopath.."Ability_Druid_CatForm"] = true,
		[icopath.."Ability_Druid_Bash"] = true,
		[icopath.."Ability_Druid_AquaticForm"] = true,
		[icopath.."Spell_Nature_Regeneration"] = true,
		[icopath.."Spell_Nature_RavenForm"] = true,
		[icopath.."Ability_Racial_BearForm"] = true,
		[icopath.."Spell_Nature_Rejuvenation"] = true,
		[icopath.."Spell_Nature_StarFall"] = true,
		[icopath.."Spell_Nature_Thorns"] = true,
		[icopath.."Spell_Nature_StrangleVines"] = true,
		[icopath.."ABILITY_DRUID_DEMORALIZINGROAR"] = true,
		[icopath.."Ability_Physical_Taunt"] = true,
		[icopath.."Spell_Nature_NaturesWrath"] = true,
		[icopath.."Spell_Nature_ResistNature"] = true,
		[icopath.."Spell_Nature_NullifyPoison"] = true,
		[icopath.."Spell_Nature_FaerieFire"] = true,
		[icopath.."Spell_Nature_Sleep"] = true,
		[icopath.."Ability_GhoulFrenzy"] = true,
		[icopath.."Spell_Nature_InsectSwarm"] = true,
		[icopath.."Ability_Hunter_Pet_Bear"] = true,
		[icopath.."Spell_Nature_Tranquility"] = true,
		[icopath.."Spell_Nature_Cyclone"] = true,
		[icopath.."Ability_Hunter_BeastSoothe"] = true,
		[icopath.."Spell_Holy_RemoveCurse"] = true,
		[icopath.."Ability_BullRush"] = true,
		[icopath.."Ability_Ambush"] = true,
		[icopath.."Ability_Druid_FerociousBite"] = true,
		[icopath.."Spell_Nature_ForceOfNature"] = true,
		[icopath.."Spell_Nature_Lightning"] = true,
		[icopath.."Spell_Nature_StoneClawTotem"] = true,
		[icopath.."Spell_Nature_AbolishMagic"] = true,
		[icopath.."Spell_Arcane_StarFire"] = true,
		[icopath.."Ability_Druid_OwlkinFrenzy"] = true,
		[icopath.."Ability_Druid_Berserk"] = true,
		[icopath.."Ability_Druid_Rake"] = true,
		[icopath.."Ability_Druid_Cower"] = true,
		[icopath.."Spell_Nature_HealingTouch"] = true,
		[icopath.."Ability_Druid_Maul"] = true,
		[icopath.."Spell_Nature_MoonGlow"] = true,
		[icopath.."Ability_Druid_Disembowel"] = true,
		[icopath.."Ability_Druid_Ravage"] = true,
		[icopath.."Spell_Nature_Reincarnation"] = true,
		[icopath.."Ability_Racial_Cannibalize"] = true,
		[icopath.."Spell_Shadow_VampiricAura"] = true,
		[icopath.."Ability_Druid_TravelForm"] = true,
		[icopath.."INV_Misc_MonsterClaw_03"] = true,
		[icopath.."Spell_Arcane_TeleportMoonglade"] = true,
		[icopath.."Ability_Mount_JungleTiger"] = true,
		[icopath.."Ability_Tracking"] = true,
	},
	["mage"] = {
		[icopath.."Spell_Fire_FlameBolt"] = true,
		[icopath.."Spell_Frost_FrostArmor02"] = true,
		[icopath.."Spell_Holy_MagicalSentry"] = true,
		[icopath.."Spell_Frost_FrostBolt02"] = true,
		[icopath.."Spell_Frost_FrostArmor"] = true,
		[icopath.."Spell_Fire_Incinerate"] = true,
		[icopath.."Spell_Frost_FreezingBreath"] = true,
		[icopath.."Spell_Frost_ChillingBlast"] = true,
		[icopath.."Spell_Frost_IceStorm"] = true,
		[icopath.."Spell_Frost_Glacier"] = true,
		[icopath.."Spell_Frost_ManaBurn"] = true,
		[icopath.."Spell_Nature_AbolishMagic"] = true,
		[icopath.."Spell_Shadow_DetectLesserInvisibility"] = true,
		[icopath.."Spell_Frost_IceShock"] = true,
		[icopath.."Spell_Nature_Lightning"] = true,
		[icopath.."Spell_Nature_EnchantArmor"] = true,
		[icopath.."Spell_Fire_SelfDestruct"] = true,
		[icopath.."Spell_Nature_Polymorph"] = true,
		[icopath.."Spell_Fire_SoulBurn"] = true,
		[icopath.."Spell_Frost_Frost"] = true,
		[icopath.."Spell_Magic_FeatherFall"] = true,
		[icopath.."Spell_Holy_FlashHeal"] = true,
		[icopath.."Spell_Fire_Fireball02"] = true,
		[icopath.."Spell_Nature_Purge"] = true,
		[icopath.."Spell_Holy_Excorcism_02"] = true,
		[icopath.."Spell_MageArmor"] = true,
		[icopath.."Spell_Fire_SealOfFire"] = true,
		[icopath.."Spell_Ice_Lament"] = true,
		[icopath.."Spell_Holy_ArcaneIntellect"] = true,
		[icopath.."Spell_Nature_Polymorph_Cow"] = true,
		[icopath.."Spell_Magic_PolymorphPig"] = true,
		[icopath.."Ability_Hunter_Pet_Turtle"] = true,
		[icopath.."Spell_Frost_WizardMark"] = true,
		[icopath.."Spell_Ice_MagicDamage"] = true,
		[icopath.."Spell_Frost_IceShard"] = true,
		[icopath.."Spell_Frost_Stun"] = true,
		[icopath.."Spell_Frost_FrostWard"] = true,
		[icopath.."Spell_Fire_MasterOfElements"] = true,
		[icopath.."Spell_Fire_MeteorStorm"] = true,
		[icopath.."Spell_Holy_DispelMagic"] = true,
		[icopath.."Spell_Nature_AstralRecallGroup"] = true,
		[icopath.."Spell_Fire_Immolation"] = true,
		[icopath.."Spell_Nature_WispHeal"] = true,
		[icopath.."Spell_Holy_Dizzy"] = true,
		[icopath.."Spell_Holy_RemoveCurse"] = true,
		[icopath.."Spell_Arcane_TeleportDarnassus"] = true,
		[icopath.."Spell_Arcane_TeleportIronForge"] = true,
		[icopath.."Spell_Arcane_TeleportMoonglade"] = true,
		[icopath.."Spell_Arcane_TeleportOrgrimmar"] = true,
		[icopath.."Spell_Arcane_TeleportStormWind"] = true,
		[icopath.."Spell_Arcane_TeleportThunderBluff"] = true,
		[icopath.."Spell_Arcane_TeleportUnderCity"] = true,
		[icopath.."Spell_Fire_FireArmor"] = true,
		[icopath.."Spell_Nature_StarFall"] = true,
		[icopath.."Spell_Arcane_Blast"] = true,
		[icopath.."Spell_Nature_WispSplode"] = true,
		[icopath.."Spell_Arcane_Blink"] = true,
		[icopath.."Spell_Fire_Fireball"] = true,
		[icopath.."spell_portal_alahthalas"] = true,
		[icopath.."Spell_Arcane_PortalUnderCity"] = true,
		[icopath.."Spell_Arcane_PortalThunderBluff"] = true,
		[icopath.."Spell_Arcane_PortalStormWind"] = true,
		[icopath.."Spell_Arcane_PortalOrgrimmar"] = true,
		[icopath.."Spell_Arcane_PortalIronForge"] = true,
		[icopath.."Spell_Arcane_PortalDarnassus"] = true,
		[icopath.."Spell_Nature_RemoveCurse"] = true,
		[icopath.."Spell_Shadow_RainOfFire"] = true,
	},
	["warlock"] = {
		[icopath.."Spell_Shadow_DemonBreath"] = true,
		[icopath.."Spell_Fire_Immolation"] = true,
		[icopath.."Spell_Shadow_ShadowBolt"] = true,
		[icopath.."Spell_Shadow_CurseOfSargeras"] = true,
		[icopath.."INV_Misc_Orb_04"] = true,
		[icopath.."Spell_Shadow_AbominationExplosion"] = true,
		[icopath.."Spell_Shadow_CurseOfMannoroth"] = true,
		[icopath.."Spell_Shadow_BloodBoil"] = true,
		[icopath.."Spell_Shadow_Possession"] = true,
		[icopath.."Spell_Shadow_Haunting"] = true,
		[icopath.."Spell_Shadow_GatherShadows"] = true,
		[icopath.."Spell_Shadow_LifeDrain"] = true,
		[icopath.."Spell_Shadow_LifeDrain02"] = true,
		[icopath.."Spell_Shadow_AntiShadow"] = true,
		[icopath.."Spell_Shadow_ScourgeBuild"] = true,
		[icopath.."Spell_Shadow_SiphonMana"] = true,
		[icopath.."Spell_Fire_FireArmor"] = true,
		[icopath.."Spell_Shadow_CurseOfTounges"] = true,
		[icopath.."Spell_Shadow_MindSteal"] = true,
		[icopath.."Spell_Shadow_Cripple"] = true,
		[icopath.."Spell_Shadow_UnholyStrength"] = true,
		[icopath.."Spell_Shadow_EnslaveDemon"] = true,
		[icopath.."Spell_Shadow_Requiem"] = true,
		[icopath.."Spell_Fire_Incinerate"] = true,
		[icopath.."Spell_Shadow_MindRot"] = true,
		[icopath.."Spell_Shadow_DeathScream"] = true,
		[icopath.."Spell_Shadow_AuraOfDarkness"] = true,
		[icopath.."Spell_Shadow_DeathCoil"] = true,
		[icopath.."Spell_Shadow_CurseOfAchimonde"] = true,
		[icopath.."Spell_Shadow_ChillTouch"] = true,
		[icopath.."Spell_Shadow_RagingScream"] = true,
		[icopath.."Spell_Fire_Fireball"] = true,
		[icopath.."INV_Stone_04"] = true,
		[icopath.."inv_misc_gem_felstone"] = true,
		[icopath.."INV_Misc_Gem_Bloodstone_01"] = true,
		[icopath.."INV_Ammo_FireTar"] = true,
		[icopath.."INV_Misc_Gem_Sapphire_01"] = true,
		[icopath.."Spell_Shadow_CurseOfSargeras"] = true,
		[icopath.."Spell_Nature_Swiftness"] = true,
		[icopath.."Spell_Arcane_PortalDarnassus"] = true,
		[icopath.."Spell_Shadow_DarkRitual"] = true,
		[icopath.."Spell_Shadow_SoulLeech"] = true,
		[icopath.."Spell_Shadow_DetectInvisibility"] = true,
		[icopath.."Spell_Shadow_SummonFelGuard"] = true,
		[icopath.."Spell_Shadow_EvilEye"] = true,
		[icopath.."Spell_Shadow_SummonInfernal"] = true,
		[icopath.."Spell_Shadow_BurningSpirit"] = true,
		[icopath.."Spell_Shadow_RainOfFire"] = true,
		[icopath.."ability_warlock_power_overwhelming"] = true,
		[icopath.."Spell_Fire_SoulBurn"] = true,
		[icopath.."Spell_Shadow_Twilight"] = true,
		[icopath.."Spell_Fire_SoulBurn"] = true,
		[icopath.."Spell_Shadow_AntiMagicShell"] = true,
		[icopath.."Spell_Fire_Fireball02"] = true,
		[icopath.."Spell_Shadow_SummonFelHunter"] = true,
		[icopath.."Spell_Shadow_SummonImp"] = true,
		[icopath.."Spell_Shadow_SummonSuccubus"] = true,
		[icopath.."Spell_Nature_Rejuvenation"] = true,
	},
	["paladin"] = {
		[icopath.."SPELL_HOLY_DEVOTIONAURA"] = true,
		[icopath.."Ability_ThunderBolt"] = true,
		[icopath.."Spell_Holy_SealOfFury"] = true,
		[icopath.."Spell_Holy_HealingAura"] = true,
		[icopath.."Spell_Holy_GreaterBlessingofWisdom"] = true,
		[icopath.."Spell_Holy_GreaterBlessingofSanctuary"] = true,
		[icopath.."Spell_Holy_GreaterBlessingofSalvation"] = true,
		[icopath.."Spell_Holy_GreaterBlessingofLight"] = true,
		[icopath.."Spell_Magic_GreaterBlessingofKings"] = true,
		[icopath.."Spell_Holy_GreaterBlessingofKings"] = true,
		[icopath.."Spell_Holy_FistOfJustice"] = true,
		[icopath.."Spell_Holy_RighteousFury"] = true,
		[icopath.."Spell_Holy_HolySmite"] = true,
		[icopath.."Spell_Holy_SealOfMight"] = true,
		[icopath.."Spell_Holy_LayOnHands"] = true,
		[icopath.."Spell_Holy_SealOfProtection"] = true,
		[icopath.."Spell_Holy_SealOfSacrifice"] = true,
		[icopath.."Spell_Holy_SealOfValor"] = true,
		[icopath.."Spell_Holy_SealOfSalvation"] = true,
		[icopath.."Spell_Holy_SealOfWisdom"] = true,
		[icopath.."Spell_Holy_AuraOfLight"] = true,
		[icopath.."Spell_Holy_PrayerOfHealing"] = true,
		[icopath.."Spell_Nature_LightningShield"] = true,
		[icopath.."Spell_Magic_MageArmor"] = true,
		[icopath.."Ability_Warrior_InnerRage"] = true,
		[icopath.."Spell_Holy_MindSooth"] = true,
		[icopath.."Spell_Holy_SealOfWrath"] = true,
		[icopath.."Spell_Shadow_SealOfKings"] = true,
		[icopath.."Spell_Nature_TimeStop"] = true,
		[icopath.."Spell_Holy_BlessingOfProtection"] = true,
		[icopath.."Spell_Holy_MindVision"] = true,
		[icopath.."Spell_Frost_WizardMark"] = true,
		[icopath.."Spell_Fire_SealOfFire"] = true,
		[icopath.."Spell_Holy_RighteousnessAura"] = true,
		[icopath.."Spell_Holy_PrayerOfHealing02"] = true,
		[icopath.."spell_holy_divineintervention"] = true,
		[icopath.."Spell_Magic_LesserInvisibilty"] = true,
		[icopath.."Spell_Holy_Renew"] = true,
		[icopath.."Spell_Holy_InnerFire"] = true,
		[icopath.."INV_Sword_01"] = true,
		[icopath.."Spell_Holy_CrusaderStrike"] = true,
		[icopath.."Spell_Holy_Restoration"] = true,
		[icopath.."Spell_Holy_MagicalSentry"] = true,
		[icopath.."Spell_Holy_EyeforanEye"] = true,
		[icopath.."Spell_Holy_FlashHeal"] = true,
		[icopath.."Spell_Nature_ThunderClap"] = true,
		[icopath.."Spell_Holy_UnyieldingFaith"] = true,
		[icopath.."Spell_Holy_HolyBolt"] = true,
		[icopath.."Spell_Holy_SearingLight"] = true,
		[icopath.."Spell_Holy_Excorcism"] = true,
		[icopath.."Spell_Holy_Redemption"] = true,
		[icopath.."Spell_Holy_Purify"] = true,
		[icopath.."Spell_Holy_Restoration"] = true,
		[icopath.."Ability_Defend"] = true,
		[icopath.."Ability_Parry"] = true,
		[icopath.."Spell_Shadow_Haunting"] = true,
		[icopath.."Ability_Mount_Charger"] = true,
		[icopath.."Spell_Nature_Swiftness"] = true,
		[icopath.."Spell_Holy_TurnUndead"] = true,
		[icopath.."Spell_Holy_SealOfBlood"] = true,
		[icopath.."Spell_Holy_Power"] = true,
	},
	["shaman"] = {
		[icopath.."Spell_Nature_WispHeal"] = true,
		[icopath.."Spell_Nature_RavenForm"] = true,
		[icopath.."Ability_GhoulFrenzy"] = true,
		[icopath.."Spell_Nature_StoneClawTotem"] = true,
		[icopath.."Spell_Nature_StoneSkinTotem"] = true,
		[icopath.."Spell_Nature_StrengthOfEarthTotem02"] = true,
		[icopath.."Spell_Nature_LightningShield"] = true,
		[icopath.."Spell_Fire_FlameShock"] = true,
		[icopath.."Spell_Nature_EarthBindTotem"] = true,
		[icopath.."Spell_Nature_TremorTotem"] = true,
		[icopath.."Spell_Nature_SpiritWolf"] = true,
		[icopath.."INV_Spear_04"] = true,
		[icopath.."Spell_Nature_PoisonCleansingTotem"] = true,
		[icopath.."Spell_FrostResistanceTotem_01"] = true,
		[icopath.."Spell_Nature_ManaRegenTotem"] = true,
		[icopath.."Spell_FireResistanceTotem_01"] = true,
		[icopath.."Spell_Nature_GroundingTotem"] = true,
		[icopath.."Spell_Nature_Cyclone"] = true,
		[icopath.."Spell_Nature_NatureResistanceTotem"] = true,
		[icopath.."Spell_Nature_Windfury"] = true,
		[icopath.."Spell_Nature_RemoveCurse"] = true,
		[icopath.."Spell_Nature_EarthBind"] = true,
		[icopath.."Spell_Nature_DiseaseCleansingTotem"] = true,
		[icopath.."Spell_Frost_SummonWaterElemental"] = true,
		[icopath.."Spell_Nature_InvisibilityTotem"] = true,
		[icopath.."Spell_Nature_GuardianWard"] = true,
		[icopath.."Spell_Nature_Brilliance"] = true,
		[icopath.."Spell_Nature_Regeneration"] = true,
		[icopath.."Spell_Nature_AstralRecal"] = true,
		[icopath.."Spell_Nature_BloodLust"] = true,
		[icopath.."Spell_Nature_Swiftness"] = true,
		[icopath.."Spell_Nature_HealingWaveGreater"] = true,
		[icopath.."Spell_Nature_LightningBolt"] = true,
		[icopath.."Spell_Nature_RemoveDisease"] = true,
		[icopath.."Spell_Nature_NullifyPoison"] = true,
		[icopath.."Spell_Nature_DiseaseCleansingTotem"] = true,
		[icopath.."Spell_Nature_SkinofEarth"] = true,
		[icopath.."Spell_Nature_EarthShock"] = true,
		[icopath.."Spell_Nature_Earthquake"] = true,
		[icopath.."earthshaker_slam_11"] = true,
		[icopath.."INV_Axe_02"] = true,
		[icopath.."Spell_Arcane_TeleportOrgrimmar"] = true,
		[icopath.."Spell_Shaman_FeralSpirit"] = true,
		[icopath.."Ability_Hunter_RunningShot"] = true,
		[icopath.."Spell_Fire_FlameTounge"] = true,
		[icopath.."Spell_Frost_FrostShock"] = true,
		[icopath.."Spell_Nature_HealingWay"] = true,
		[icopath.."Spell_Nature_ThunderClap"] = true,
		[icopath.."Ability_Shaman_StormStrike"] = true,
		[icopath.."Spell_Fire_SelfDestruct"] = true,
		[icopath.."Spell_Fire_MeteorStorm"] = true,
		[icopath.."Ability_Parry"] = true,
		[icopath.."Spell_Nature_Purge"] = true,
		[icopath.."Spell_Nature_Reincarnation"] = true,
		[icopath.."Spell_Nature_RockBiter"] = true,
		[icopath.."Spell_Fire_SearingTotem"] = true,
		[icopath.."Spell_Shadow_GatherShadows"] = true,
		[icopath.."Ability_Smash"] = true,
		[icopath.."Spell_Shadow_DemonBreath"] = true,
		[icopath.."Spell_Frost_FrostArmor02"] = true,
		[icopath.."Spell_Frost_WindWalkOn"] = true,
	},
	["misc1"] = {
		[icopath.."Spell_Nature_AbolishMagic"] = true,
		[icopath.."INV_Potion_04"] = true,
		[icopath.."INV_Potion_62"] = true,
		[icopath.."Spell_Nature_Sleep"] = true,
		[icopath.."Spell_Shadow_RaiseDead"] = true,
		[icopath.."RACIAL_ORC_BERSERKERSTRENGTH"] = true,
		[icopath.."RACIAL_TROLL_BERSERK"] = true,
		[icopath.."Ability_WarStomp"] = true,
		[icopath.."Spell_Frost_FrostWard"] = true,
		[icopath.."Spell_Shadow_AntiShadow"] = true,
		[icopath.."INV_Misc_Gem_Pearl_04"] = true,
		[icopath.."INV_Jewelry_Talisman_06"] = true,
		[icopath.."Spell_Nature_WispHeal"] = true,
		[icopath.."Spell_Totem_WardOfDraining"] = true,
		[icopath.."INV_Misc_Gem_Pearl_05"] = true,
		[icopath.."Spell_Holy_SearingLight"] = true,
		[icopath.."Spell_Nature_SpiritArmor"] = true,
		[icopath.."Spell_Magic_LesserInvisibilty"] = true,
		[icopath.."INV_Trinket_Naxxramas04"] = true,
		[icopath.."INV_Trinket_Naxxramas05"] = true,
		[icopath.."INV_Trinket_Naxxramas01"] = true,
		[icopath.."INV_Trinket_Naxxramas06"] = true,
		[icopath.."INV_Trinket_Naxxramas03"] = true,
		[icopath.."Spell_Frost_WizardMark"] = true,
		[icopath.."INV_Misc_AhnQirajTrinket_04"] = true,
		[icopath.."Spell_Arcane_TeleportOrgrimmar"] = true,
		[icopath.."Spell_Shadow_GrimWard"] = true,
		[icopath.."INV_Misc_AhnQirajTrinket_06"] = true,
		[icopath.."INV_Misc_EngGizmos_19"] = true,
		[icopath.."Spell_ChargeNegative"] = true,
		[icopath.."Spell_ChargePositive"] = true,
		[icopath.."INV_Misc_Head_Dragon_01"] = true,
		[icopath.."Spell_Holy_BlessingOfStrength"] = true,
		[icopath.."Spell_Frost_Wisp"] = true,
		[icopath.."inv_misc_rune_01"] = true,
		[icopath.."inv_potion_69"] = true,
		[icopath.."inv_square_rune_1"] = true,
		[icopath.."inv_square_rune_2"] = true,
		[icopath.."inv_square_rune_3"] = true,
		[icopath.."inv_square_rune_4"] = true,
		[icopath.."inv_square_rune_5"] = true,
		[icopath.."inv_square_rune_6"] = true,
		[icopath.."INV_Thunderfall"] = true,
		[icopath.."INV_PVPPandarenSerpentMount"] = true,
		[icopath.."INV_pendant_of_pestilence"] = true,
		[icopath.."INV_pendant_of_the_guardian"] = true,
		[icopath.."INV_pendant_of_the_stormhowl"] = true,
		[icopath.."INV_pendant_of_the_talon"] = true,
		[icopath.."INV_Offhand_Naxxramas_02"] = true,
		[icopath.."INV_Offhand_Naxxramas_03"] = true,
		[icopath.."INV_Offhand_Naxxramas_04"] = true,
		[icopath.."INV_Offhand_Naxxramas_D_01"] = true,
		[icopath.."INV_Offhand_Stratholme_A_01"] = true,
		[icopath.."INV_Offhand_Stratholme_A_02"] = true,
		[icopath.."INV_nathrezim_amulet"] = true,
		[icopath.."INV_nathrezim_pendant"] = true,
		[icopath.."Inv_Misc_SummerFest_BrazierBlue"] = true,
		[icopath.."Inv_Misc_SummerFest_BrazierGreen"] = true,
		[icopath.."Inv_Misc_SummerFest_BrazierOrange"] = true,
		[icopath.."Inv_Misc_SummerFest_BrazierRed"] = true,
		[icopath.."INV_Misc_Book_01"] = true,
		[icopath.."INV_Misc_Book_02"] = true,
		[icopath.."INV_Misc_Book_03"] = true,
		[icopath.."INV_Misc_Book_04"] = true,
		[icopath.."INV_Misc_Book_05"] = true,
		[icopath.."INV_Misc_Book_06"] = true,
		[icopath.."INV_Misc_Book_07"] = true,
		[icopath.."INV_Misc_Book_08"] = true,
		[icopath.."INV_Misc_Book_09"] = true,
		[icopath.."INV_Misc_Book_10"] = true,
		[icopath.."INV_Misc_Book_11"] = true,
		[icopath.."INV_Misc_Book_12"] = true,
		[icopath.."INV_Misc_Book_13"] = true,
		[icopath.."INV_Misc_Book_14"] = true,
		[icopath.."INV_Misc_Book_15"] = true,
		[icopath.."INV_Misc_Book_Azyr"] = true,
		[icopath.."INV_Misc_Book_KulTiran"] = true,
		[icopath.."INV_Misc_AhnQirajTrinket_01"] = true,
		[icopath.."INV_Misc_AhnQirajTrinket_03"] = true,
		[icopath.."inv_magmafire_shield_1"] = true,
		[icopath.."INV_lionheart_pendant"] = true,
		[icopath.."INV_lionheart_amulet"] = true,
		[icopath.."INV_lionheart_choker"] = true,
		[icopath.."INV_Jewelry_Talisman_Health"] = true,
		[icopath.."INV_Jewelry_Talisman_Mana"] = true,
		[icopath.."INV_Jewelry_Talisman_FireIce"] = true,
		[icopath.."INV_Jewelry_Ring_Emerald"] = true,
		[icopath.."INV_Jewelry_Ring_Gilneas"] = true,
		[icopath.."INV_Jewelry_Ring_Gold"] = true,
		[icopath.."INV_Jewelry_Ring_Jade"] = true,
		[icopath.."INV_Jewelry_Ring_Nightbreaker"] = true,
		[icopath.."INV_Jewelry_Ring_OfInfiniteGems"] = true,
		[icopath.."INV_Jewelry_Ring_Opal"] = true,
		[icopath.."INV_Jewelry_Ring_RoyalOpal"] = true,
		[icopath.."INV_Jewelry_Necklace_Banshee"] = true,
	},
	["misc2"] = {},
	["misc3"] = {},
	["misc4"] = {},
	["misc5"] = {},
	["misc6"] = {},
	["misc7"] = {}
}

local timerfont = {
	UNIT_NAME_FONT, 
	"Fonts\\ARIALN.TTF", 
	"Fonts\\MORPHEUS.TTF", 
	"Interface\\AddOns\\ModifiedPowerAuras\\fonts\\visitor2.TTF", 
	"Interface\\AddOns\\ModifiedPowerAuras\\fonts\\Accidental_Presidency.TTF", 
	"Interface\\AddOns\\ModifiedPowerAuras\\fonts\\Enigma__2.TTF", 
	"Interface\\AddOns\\ModifiedPowerAuras\\fonts\\VeraSe.TTF", 
	"Interface\\AddOns\\ModifiedPowerAuras\\fonts\\AlteHaas.TTF", 
	"Interface\\AddOns\\ModifiedPowerAuras\\fonts\\CaviarDreams.TTF", 
	"Interface\\AddOns\\ModifiedPowerAuras\\fonts\\Expressway.TTF", 
	"Interface\\AddOns\\ModifiedPowerAuras\\fonts\\ExpresswayBold.TTF", 
	"Interface\\AddOns\\ModifiedPowerAuras\\fonts\\Roboto.TTF", 
	"Interface\\AddOns\\ModifiedPowerAuras\\fonts\\The Bad Times.TTF", 
	"Interface\\AddOns\\ModifiedPowerAuras\\fonts\\Vegur.TTF"
}

for i=1,98 do icons["misc2"][locpath.."Aura"..i] = true; end
for i=99,196 do icons["misc3"][locpath.."Aura"..i] = true; end
for i=197,234 do icons["misc4"][locpath.."Aura"..i] = true; end
--for i=127,168 do icons["misc5"][locpath.."Aura"..i] = true; end
--for i=169,210 do icons["misc6"][locpath.."Aura"..i] = true; end
--for i=211,246 do icons["misc7"][locpath.."Aura"..i] = true; end

function MPOWA:FillButtonContainer(key)
	-- First hide all icons
	local button
	local i = 0
	while true do
		button = _G("MPowa_IconFrame_ButtonContainer_Button"..i)
		if button then
			button:Hide()
		else
			break
		end
		i = i + 1
	end
	
	-- Second fill list
	local i = 0
	for cat, _ in pairs(icons[key]) do
		button = _G("MPowa_IconFrame_ButtonContainer_Button"..i)
		if not button then
			CreateFrame("Button", "MPowa_IconFrame_ButtonContainer_Button"..i, MPowa_IconFrame_ButtonContainer, "MPowa_IconFrameButtonTemplate")
			button = _G("MPowa_IconFrame_ButtonContainer_Button"..i)
		end
		_G("MPowa_IconFrame_ButtonContainer_Button"..i.."_Icon"):SetTexture(cat)
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", MPowa_IconFrame_ButtonContainer, "TOPLEFT", 6+mod(i, 7)*42, -11-floor(i/7)*41)
		button:Show()
		i = i + 1
	end
end


function MPOWA:TernaryReturn(id, var, real)
	if self.SAVE[id][var] == 0 then
		return true
	elseif self.SAVE[id][var] == true and real then
		return true
	elseif self.SAVE[id][var] == false and (not real) then
		return true
	end
end

function MPOWA:Pager(left)
	if left then
		if self.Page<=1 then
			self.Page = 1
		else
			self.Page = self.Page - 1
		end
	else
		if self.Page >= 10 then
			self.Page = 10
		else
			self.Page = self.Page + 1
		end
	end
	self:UpdatePage()
end

function MPOWA:UpdatePage()
	MPowa_MainFrame_Pages:SetText(self.Page.."/10")
	self:Show()
	self:Reposition()
end

function MPOWA:Show()
	local coeff = (self.Page - 1)*49
	local bool = false
	local p = self.NumBuffs-coeff
	if (p<=0) then
		p = self.NumBuffs
		bool = true
	end
	if (not self.Cloaded) then
		for i=1, 49 do
			if i<=self.NumBuffs then
				MPOWA:CreateButton(i)
			end
		end
		self.Cloaded = true
	end
	for i=1, 49 do
		if getglobal("ConfigButton"..i) then
			getglobal("ConfigButton"..i):Hide()
		end
	end
	local e = self.Page * 49
	if e>self.NumBuffs then
		e = self.NumBuffs
	end
	for i=(1+coeff), e do
		MPOWA:ApplyAttributesToButton(i, getglobal("ConfigButton"..(i-coeff)))
	end
	if self.NumBuffs > 0 and self.NumBuffs > coeff then
		getglobal("ConfigButton"..self.selected.."_Border"):Show()
	end
	MPowa_MainFrame:Show()
end

function MPOWA:CreateButton(i)
	local button
	if not getglobal("ConfigButton"..i) then
		button = CreateFrame("Button", "ConfigButton"..i, MPowa_ButtonContainer, "MPowa_ContainerBuffButtonTemplate")
	else
		button = getglobal("ConfigButton"..i)
	end
	MPOWA:ApplyAttributesToButton(i, button)
end

function MPOWA:CreateIcon(i, id)
	if not self.frames[id] then
		self.frames[id] = {}
	end
	CreateFrame("Frame", "TextureFrame"..i, UIParent, "MPowa_IconTemplate")
	self.frames[id][1] = _G("TextureFrame"..i)
	self.frames[id][2] = _G("TextureFrame"..i.."_Icon")
	self.frames[id][3] = _G("TextureFrame"..i.."_Timer")
	self.frames[id][4] = _G("TextureFrame"..i.."_Count")
	self.frames[id][1]:SetID(i)
	self.frames[id][1]:EnableMouse(0)
	self.frames[id][1]:Hide()
end

local blendModes = {"BLEND", "DISABLE", "ALPHAKEY", "ADD", "MOD"}
function MPOWA:ApplyConfig(i)
	local val = self.SAVE[i]
	if not val then return end
	self.frames[i][2]:SetTexture(val["texture"])
	self.frames[i][2]:SetBlendMode(blendModes[val["blendmode"]])
	self.frames[i][1]:SetAlpha(val["alpha"])
	self.frames[i][1]:ClearAllPoints()
	self.frames[i][1]:SetPoint("CENTER", UIParent, "CENTER", val["x"], val["y"])
	self.frames[i][1]:SetScale(val["size"])
	self.frames[i][3]:SetFont(timerfont[val["timerfont"] or 1], val["fontsize"]*12, "OUTLINE")
	self.frames[i][3]:SetAlpha(val["fontalpha"])
	self.frames[i][4]:SetFont(timerfont[val["timerfont"] or 1], val["timerfontsize"]*12, "OUTLINE")
	self.frames[i][3]:ClearAllPoints()
	self.frames[i][3]:SetPoint("CENTER", self.frames[i][1], "CENTER", val["fontoffsetx"], val["fontoffsety"])
	self.frames[i][2]:SetVertexColor(val.icon_r or 1, val.icon_g or 1, val.icon_b or 1)
	if val["usefontcolor"] then
		self.frames[i][3]:SetTextColor(val["fontcolor_r"],val["fontcolor_g"],val["fontcolor_b"],val["fontalpha"])
	end
	if val["isdynamicgroup"] then
		self:ApplyDynamicGroup(i)
	elseif val["groupnumber"] and tnbr(val["groupnumber"])>0 then
		self:ApplyDynamicGroup(tnbr(val["groupnumber"]))
	end
	MPOWA_SAVE = table.copy(self.SAVE, true)
end

function MPOWA:ApplyDynamicGroup(i)
	local val = self.SAVE[i]
	if self.frames[i] and val["isdynamicgroup"] then
		if not self.frames[i][5] then
			self.frames[i][5] = CreateFrame("Frame", nil, UIParent)
		end
		local inc = 0
		local spacing = val["dynamicspacing"] + 65
		if val["dynamicsorted"] then
			local grp, final, time = {}, {}
			for cat, va in pairs(self.SAVE) do
				if self.frames[cat] and (tnbr(va["groupnumber"])==i or cat==i) then
					if va["test"] or self.testAll then
						grp[cat] = 1
					else
						if (self.active[cat] and not self.NeedUpdate[cat]) then
							grp[cat] = self:GetDuration(self.active[cat], cat)
						else
							time = self:GetCooldown(va["buffname"]) or 0
							if (self.NeedUpdate[cat] and not self.active[cat] and (time>0 or not va["cooldown"])) then
								grp[cat] = time
							end
						end 
					end
				end
			end
			local p
			for cat, va in pairs(grp) do
				p = 1
				while true do
					if not final[p] then
						tinsert(final, p, {cat, va})
						break
					elseif final[p][2]<va then
						tinsert(final, p, {cat, va})
						break;
					end
					p = p +1
				end
			end
			for _, va in pairs(final) do
				self.frames[va[1]][1]:ClearAllPoints()
				if val["dynamicorientation"] == 1 then
					self.frames[va[1]][1]:SetPoint("TOPLEFT", self.frames[i][5], "TOPLEFT", inc*spacing, 0)
				elseif val["dynamicorientation"] == 2 then
					self.frames[va[1]][1]:SetPoint("TOPRIGHT", self.frames[i][5], "TOPRIGHT", -inc*spacing, 0)
				elseif val["dynamicorientation"] == 3 then
					self.frames[va[1]][1]:SetPoint("TOP", self.frames[i][5], "TOP", 0, -inc*spacing)
				else
					self.frames[va[1]][1]:SetPoint("BOTTOM", self.frames[i][5], "BOTTOM", 0, inc*spacing)
				end
				inc = inc + 1;
			end
		else
			for cat, va in pairs(self.SAVE) do
				if self.frames[cat] and (tnbr(va["groupnumber"])==i or cat==i) and (self.active[cat] and not self.NeedUpdate[cat]) or (self.NeedUpdate[cat] and not self.active[cat] and (((self:GetCooldown(va["buffname"]) or 0)>0) or not va["cooldown"]) or va["test"] or self.testAll) then
					self.frames[cat][1]:ClearAllPoints()
					if val["dynamicorientation"] == 1 then
						self.frames[cat][1]:SetPoint("TOPLEFT", self.frames[i][5], "TOPLEFT", inc*spacing, 0)
					elseif val["dynamicorientation"] == 2 then
						self.frames[cat][1]:SetPoint("TOPRIGHT", self.frames[i][5], "TOPRIGHT", -inc*spacing, 0)
					elseif val["dynamicorientation"] == 3 then
						self.frames[cat][1]:SetPoint("TOP", self.frames[i][5], "TOP", 0, -inc*spacing)
					else
						self.frames[cat][1]:SetPoint("BOTTOM", self.frames[i][5], "BOTTOM", 0, inc*spacing)
					end
					inc = inc + 1;
				end
			end
		end
		if val["dynamiccenter"] then
			self.frames[i][5]:SetWidth(spacing)
			self.frames[i][5]:SetHeight(spacing)
			self.frames[i][5]:ClearAllPoints()
			if val["dynamicorientation"] == 1 then
				self.frames[i][5]:SetPoint("CENTER", UIParent, "CENTER", val["x"]-(inc-1)*(val["size"]*spacing), val["y"])
			elseif val["dynamicorientation"] == 2 then
				self.frames[i][5]:SetPoint("CENTER", UIParent, "CENTER", val["x"]+(inc-1)*(val["size"]*spacing), val["y"])
			elseif val["dynamicorientation"] == 3 then
				self.frames[i][5]:SetPoint("CENTER", UIParent, "CENTER", val["x"], val["y"]+(inc-1)*(val["size"]*spacing))
			else
				self.frames[i][5]:SetPoint("CENTER", UIParent, "CENTER", val["x"], val["y"]-(inc-1)*(val["size"]*spacing))
			end
		else
			if val["dynamicorientation"]<3 then
				self.frames[i][5]:SetWidth(inc*spacing)
				self.frames[i][5]:SetHeight(spacing)
			else
				self.frames[i][5]:SetWidth(spacing)
				self.frames[i][5]:SetHeight(inc*spacing)
			end
			self.frames[i][5]:ClearAllPoints()
			if val["dynamicorientation"] == 1 then
				self.frames[i][5]:SetPoint("CENTER", UIParent, "CENTER", val["x"]+(inc-1)*10, val["y"])
			elseif val["dynamicorientation"] == 2 then
				self.frames[i][5]:SetPoint("CENTER", UIParent, "CENTER", val["x"]-(inc-1)*10, val["y"])
			elseif val["dynamicorientation"] == 3 then
				self.frames[i][5]:SetPoint("CENTER", UIParent, "CENTER", val["x"], val["y"]-(inc-1)*10)
			else
				self.frames[i][5]:SetPoint("CENTER", UIParent, "CENTER", val["x"], val["y"]+(inc-1)*10)
			end
		end
	end
end

function MPOWA:ApplyAttributesToButton(i, button)
	if not button then return end
	local coeff = (self.Page - 1)*49
	local p = (i-coeff)
	local bool = false
	if (p<=0) then
		p = i
		bool = true
	end
	if not _G("ConfigButton"..p) or not self.SAVE[i] then return end
	button:ClearAllPoints()
	button:SetPoint("TOPLEFT",MPowa_ButtonContainer,"TOPLEFT",42*(p-1)+6 - floor((p-1)/7)*7*42,-11-floor((p-1)/7)*41)
	button:SetID(i)
	_G("ConfigButton"..p.."_Icon"):SetTexture(self.SAVE[i]["texture"])
	_G("ConfigButton"..p.."_Count"):SetText(i)
	_G("ConfigButton"..p.."_Border"):Hide()
	
	if not bool and i<=self.Page*49 then
		button:Show()
	else
		button:Hide()
	end
	
end

function MPOWA:AddAura()
	if self.NumBuffs < 490 then
		self.NumBuffs = self.NumBuffs + 1
		local actualLength = self:GetTableLength(self.SAVE)+1
		local coeff = (self.Page - 1)*49
		local bool = false
		local p = actualLength-coeff
		if (p<=0) then
			p = actualLength
			bool = true
		end
		-- Wont recycle anymore
		self:CreateSave(actualLength)
		self:CreateIcon(self.NumBuffs, actualLength)
		self:ApplyConfig(actualLength)
		self:CreateButton(actualLength)

		self.SAVE[actualLength]["used"] = true
		self:DeselectAll()
		if not bool and actualLength<coeff then
			_G("ConfigButton"..p.."_Border"):Show();
			_G("ConfigButton"..p):Show();
		end
		self.selected = p
	end
end

function MPOWA:DeselectAll()
	for i=1, 49 do
		if _G("ConfigButton"..i.."_Border") then 
			_G("ConfigButton"..i.."_Border"):Hide()
		end
	end
end

function MPOWA:Remove()
	if ConfigButton1 and ConfigButton1:IsVisible() then
		local coeff = (self.Page - 1)*49
		--self.NumBuffs = self.NumBuffs - 1
		if (self.selected+coeff) == self.CurEdit then
			MPowa_ConfigFrame:Hide()
		end
		-- Reordering the array now
		self:CreateSave(self.selected+coeff)
		if self.SAVE[self.selected+coeff] then
			self.SAVE[self.selected+coeff]["used"] = false
		end
		if self.frames[self.selected+coeff] and self.frames[self.selected+coeff][1] then
			self.frames[self.selected+coeff][1]:Hide()
		end
		_G("ConfigButton"..self.selected):Hide();
		_G("ConfigButton"..self.selected.."_Border"):Hide();
		local newSave = {}
		local newFrames = {}
		local count = 0
		for i=1, self:GetTableLength(self.SAVE) do
			if self.SAVE[i] and self.SAVE[i]["used"] then
				table.insert(newSave, self.SAVE[i])
				count = count + 1
				if self.frames[i] then
					newFrames[count] = self.frames[i]
				else
					newFrames[count] = {}
				end
			end
		end
		self.SAVE = table.copy(newSave)
		--self.Save = newSave
		self.frames = table.copy(newFrames)
		newSave = nil
		newFrames = nil
		self.auras = {}
		self.NeedUpdate = {}

		for cat, val in pairs(self.SAVE) do
			if not self.auras[val["buffname"]] then
				self.auras[val["buffname"]] = {}
			end
			tinsert(self.auras[val["buffname"]], cat)
			
			if (val["inverse"] or val["cooldown"]) and val["buffname"] ~= "unitpower" then
				self.NeedUpdate[cat] = true
			end
		end

		self.selected = self:GetTableLength(self.SAVE)-coeff
		if self.selected == 0 then
			self.selected = 1
		end
		self:Reposition()
		_G("ConfigButton"..self.selected.."_Border"):Show()
		MPOWA_SAVE = table.copy(self.SAVE, true)
	end
end

function MPOWA:Reposition()
	local coeff = (self.Page - 1)*49
	for i=(1+coeff), self:GetTableLength(self.SAVE) +1 do
		if _G("ConfigButton"..(i-coeff)) then
			_G("ConfigButton"..(i-coeff)):Hide()
		end
	end
	for i=1, self:GetTableLength(self.SAVE) do
		self:ApplyAttributesToButton(i+coeff,_G("ConfigButton"..i))
	end
end

function MPOWA:SelectAura(button)
	local coeff = (self.Page - 1)*49
	self.selected = button:GetID() - coeff
	if MPowa_ConfigFrame:IsVisible() then
		self.CurEdit = self.selected
		self:Edit()
	end
	self:DeselectAll()
	if _G("ConfigButton"..self.selected.."_Border") then
		_G("ConfigButton"..self.selected.."_Border"):Show()
	end
end

function MPOWA:Edit()
	if ConfigButton1 then
		local coeff = (self.Page - 1)*49
		self.CurEdit = self.selected+coeff
		if not self.SAVE[self.CurEdit] then return end
		for i=1, self.NumBuffs do
			if self.frames[i] then
				self.frames[i][1]:EnableMouse(false)
			end
		end
		if self.frames[self.CurEdit] then
			self.frames[self.CurEdit][1]:EnableMouse(1)
		end
		MPowa_ConfigFrame:Hide()
		MPowa_ConfigFrame_Container_1_Icon_Texture:SetTexture(self.SAVE[self.CurEdit].texture)
		MPowa_ConfigFrame_Container_1_Slider_Opacity:SetValue(self.SAVE[self.CurEdit].alpha)
		MPowa_ConfigFrame_Container_1_Slider_OpacityText:SetText(MPOWA_SLIDER_OPACITY.." "..self.SAVE[self.CurEdit].alpha)
		
		MPowa_ConfigFrame_Container_1_Slider_PosX:SetMinMaxValues(MPOWA:GetMinValues(self.SAVE[self.CurEdit].x),MPOWA:GetMaxValues(self.SAVE[self.CurEdit].x))
		MPowa_ConfigFrame_Container_1_Slider_PosX:SetValue(self.SAVE[self.CurEdit].x)
		MPowa_ConfigFrame_Container_1_Slider_PosXText:SetText(MPOWA_SLIDER_POSX.." "..self.SAVE[self.CurEdit].x)
		MPowa_ConfigFrame_Container_1_Slider_PosXLow:SetText(MPOWA:GetMinValues(self.SAVE[self.CurEdit].x))
		MPowa_ConfigFrame_Container_1_Slider_PosXHigh:SetText(MPOWA:GetMaxValues(self.SAVE[self.CurEdit].x))
		
		MPowa_ConfigFrame_Container_1_Slider_PosY:SetMinMaxValues(MPOWA:GetMinValues(self.SAVE[self.CurEdit].y),MPOWA:GetMaxValues(self.SAVE[self.CurEdit].y))
		MPowa_ConfigFrame_Container_1_Slider_PosY:SetValue(self.SAVE[self.CurEdit].y)
		MPowa_ConfigFrame_Container_1_Slider_PosYText:SetText(MPOWA_SLIDER_POSY.." "..self.SAVE[self.CurEdit].y)
		MPowa_ConfigFrame_Container_1_Slider_PosYLow:SetText(MPOWA:GetMinValues(self.SAVE[self.CurEdit].y))
		MPowa_ConfigFrame_Container_1_Slider_PosYHigh:SetText(MPOWA:GetMaxValues(self.SAVE[self.CurEdit].y))
		
		MPowa_ConfigFrame_Container_2_Slider_PosX:SetMinMaxValues(MPOWA:GetMinValues(self.SAVE[self.CurEdit].fontoffsetx),MPOWA:GetMaxValues(self.SAVE[self.CurEdit].fontoffsetx))
		MPowa_ConfigFrame_Container_2_Slider_PosX:SetValue(self.SAVE[self.CurEdit].fontoffsetx)
		MPowa_ConfigFrame_Container_2_Slider_PosXText:SetText(MPOWA_SLIDER_POSX.." "..self.SAVE[self.CurEdit].fontoffsetx)
		MPowa_ConfigFrame_Container_2_Slider_PosXLow:SetText(MPOWA:GetMinValues(self.SAVE[self.CurEdit].fontoffsetx))
		MPowa_ConfigFrame_Container_2_Slider_PosXHigh:SetText(MPOWA:GetMaxValues(self.SAVE[self.CurEdit].fontoffsetx))
		
		MPowa_ConfigFrame_Container_2_Slider_PosY:SetMinMaxValues(MPOWA:GetMinValues(self.SAVE[self.CurEdit].fontoffsety),MPOWA:GetMaxValues(self.SAVE[self.CurEdit].fontoffsety))
		MPowa_ConfigFrame_Container_2_Slider_PosY:SetValue(self.SAVE[self.CurEdit].fontoffsety)
		MPowa_ConfigFrame_Container_2_Slider_PosYText:SetText(MPOWA_SLIDER_POSY.." "..self.SAVE[self.CurEdit].fontoffsety)
		MPowa_ConfigFrame_Container_2_Slider_PosYLow:SetText(MPOWA:GetMinValues(self.SAVE[self.CurEdit].fontoffsety))
		MPowa_ConfigFrame_Container_2_Slider_PosYHigh:SetText(MPOWA:GetMaxValues(self.SAVE[self.CurEdit].fontoffsety))
		
		MPowa_ConfigFrame_Container_1_Slider_Size:SetValue(tnbr(self.SAVE[self.CurEdit].size))
		MPowa_ConfigFrame_Container_1_Slider_SizeText:SetText(MPOWA_SLIDER_SIZE.." "..self.SAVE[self.CurEdit].size)
		MPowa_ConfigFrame_Container_1_ColorpickerNormalTexture:SetVertexColor(self.SAVE[self.CurEdit].icon_r or 1, self.SAVE[self.CurEdit].icon_g or 1, self.SAVE[self.CurEdit].icon_b or 1)
		MPowa_ConfigFrame_Container_1_Colorpicker_SwatchBg.r = self.SAVE[self.CurEdit].icon_r or 1
		MPowa_ConfigFrame_Container_1_Colorpicker_SwatchBg.g = self.SAVE[self.CurEdit].icon_g or 1
		MPowa_ConfigFrame_Container_1_Colorpicker_SwatchBg.b = self.SAVE[self.CurEdit].icon_b or 1
		MPowa_ConfigFrame_Container_1_Icon_Texture:SetVertexColor(self.SAVE[self.CurEdit].icon_r or 1, self.SAVE[self.CurEdit].icon_g or 1, self.SAVE[self.CurEdit].icon_b or 1)
		MPowa_ConfigFrame_Container_2_Slider_Size:SetValue(tnbr(self.SAVE[self.CurEdit].fontsize))
		MPowa_ConfigFrame_Container_2_Slider_SizeText:SetText(MPOWA_SLIDER_SIZE.." "..self.SAVE[self.CurEdit].fontsize)
		MPowa_ConfigFrame_Container_2_Slider_Opacity:SetValue(tnbr(self.SAVE[self.CurEdit].fontalpha))
		MPowa_ConfigFrame_Container_2_Slider_OpacityText:SetText(MPOWA_SLIDER_OPACITY.." "..self.SAVE[self.CurEdit].fontalpha)
		MPowa_ConfigFrame_Container_1_2_Editbox:SetText(self.SAVE[self.CurEdit].buffname)
		MPowa_ConfigFrame_Container_1_2_Editbox_Stacks:SetText(self.SAVE[self.CurEdit].stacks)
		MPowa_ConfigFrame_Container_1_2_Editbox_CPStacks:SetText(self.SAVE[self.CurEdit].cpstacks)
		MPowa_ConfigFrame_Container_1_2_Editbox_Player:SetText(self.SAVE[self.CurEdit].rgmname or "")
		MPowa_ConfigFrame_Container_1_2_Editbox_DebuffDuration:SetText(self.SAVE[self.CurEdit].targetduration)
		MPowa_ConfigFrame_Container_1_2_Editbox_SECLEFT:SetText(self.SAVE[self.CurEdit].secsleftdur or "")
		MPowa_ConfigFrame_Container_1_2_Checkbutton_Debuff:SetChecked(self.SAVE[self.CurEdit].isdebuff)
		MPowa_ConfigFrame_Container_1_2_Checkbutton_ShowIfNotActive:SetChecked(self.SAVE[self.CurEdit].inverse)
		MPowa_ConfigFrame_Container_2_2_Checkbutton_Timer:SetChecked(self.SAVE[self.CurEdit].timer)
		MPowa_ConfigFrame_Container_2_2_Checkbutton_Minutes:SetChecked(self.SAVE[self.CurEdit].minutes)
		MPowa_ConfigFrame_Container_1_2_Checkbutton_ShowCooldowns:SetChecked(self.SAVE[self.CurEdit].cooldown)
		MPowa_ConfigFrame_Container_1_2_Checkbutton_EnemyTarget:SetChecked(self.SAVE[self.CurEdit].enemytarget)
		MPowa_ConfigFrame_Container_1_2_Checkbutton_FriendlyTarget:SetChecked(self.SAVE[self.CurEdit].friendlytarget)
		MPowa_ConfigFrame_Container_1_2_Checkbutton_RaidMember:SetChecked(self.SAVE[self.CurEdit].raidgroupmember)
		MPowa_ConfigFrame_Container_1_2_Checkbutton_XSecsRemaining:SetChecked(self.SAVE[self.CurEdit].secsleft)
		MPowa_ConfigFrame_Container_1_2_Checkbutton_HideStacks:SetChecked(self.SAVE[self.CurEdit].hidestacks)
		MPowa_ConfigFrame_Container_2_2_Checkbutton_Hundreds:SetChecked(self.SAVE[self.CurEdit].hundredth)
		MPowa_ConfigFrame_Container_2_2_Checkbutton_FlashAnim:SetChecked(self.SAVE[self.CurEdit].flashanim)
		MPowa_ConfigFrame_Container_2_2_Editbox_FlashAnim:SetText(self.SAVE[self.CurEdit].flashanimstart)
		MPowa_ConfigFrame_Container_2_2_Checkbutton_Color:SetChecked(self.SAVE[self.CurEdit].usefontcolor)
		MPowa_ConfigFrame_Container_2_2_ColorpickerNormalTexture:SetVertexColor(self.SAVE[self.CurEdit].fontcolor_r, self.SAVE[self.CurEdit].fontcolor_g, self.SAVE[self.CurEdit].fontcolor_b)
		MPowa_ConfigFrame_Container_2_2_Colorpicker_SwatchBg.r = self.SAVE[self.CurEdit].fontcolor_r
		MPowa_ConfigFrame_Container_2_2_Colorpicker_SwatchBg.g = self.SAVE[self.CurEdit].fontcolor_g
		MPowa_ConfigFrame_Container_2_2_Colorpicker_SwatchBg.b = self.SAVE[self.CurEdit].fontcolor_b
		MPowa_ConfigFrame_Container_3_Slider_BeginSound:SetValue(self.SAVE[self.CurEdit].beginsound)
		MPowa_ConfigFrame_Container_3_Slider_BeginSoundText:SetText(MPOWA_SLIDER_BEGINSOUND..MPOWA.SOUND[self.SAVE[self.CurEdit].beginsound])
		MPowa_ConfigFrame_Container_3_Slider_EndSound:SetValue(self.SAVE[self.CurEdit].endsound)
		MPowa_ConfigFrame_Container_3_Slider_EndSoundText:SetText(MPOWA_SLIDER_BEGINSOUND..MPOWA.SOUND[self.SAVE[self.CurEdit].endsound])
		MPowa_ConfigFrame_Container_3_Checkbutton_BeginSound:SetChecked(self.SAVE[self.CurEdit].usebeginsound)
		MPowa_ConfigFrame_Container_3_Checkbutton_EndSound:SetChecked(self.SAVE[self.CurEdit].useendsound)
		if (self.SAVE[self.CurEdit].funct ~= nil) then
			MPowa_ConfigFrame_Container_7_Funct_Editbox:SetText(self.SAVE[self.CurEdit].funct)
		else
			self.SAVE[self.CurEdit].funct = nil
			MPowa_ConfigFrame_Container_7_Funct_Editbox:SetText("")
		end

		MPowa_ConfigFrame_Container_7_Funct_Editbox:SetBackdrop({
			bgFile = [[Interface\Buttons\WHITE8x8]],
			edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
			edgeSize = 0,
			insets = {left = 3, right = 3, top = 3, bottom = 3},
		})
		MPowa_ConfigFrame_Container_7_Funct_Editbox:SetBackdropColor(0, 0, 0, 0)
		MPowa_ConfigFrame_Container_7_Funct_Editbox:SetBackdropBorderColor(0, 0, 0, 0)
		-- ANIM START
		MPowa_ConfigFrame_Container_5_Slider_AnimDuration:SetValue(tnbr(self.SAVE[self.CurEdit].animduration))
		MPowa_ConfigFrame_Container_5_Slider_AnimDurationText:SetText(MPOWA_SLIDER_ANIMDURATION.." - "..self.SAVE[self.CurEdit].animduration)
		MPowa_ConfigFrame_Container_5_Slider_TranslateX:SetValue(tnbr(self.SAVE[self.CurEdit].translateoffsetx))
		MPowa_ConfigFrame_Container_5_Slider_TranslateXText:SetText(MPOWA_SLIDER_TRANSLATEX.." - "..self.SAVE[self.CurEdit].translateoffsetx)
		MPowa_ConfigFrame_Container_5_Slider_TranslateY:SetValue(tnbr(self.SAVE[self.CurEdit].translateoffsety))
		MPowa_ConfigFrame_Container_5_Slider_TranslateYText:SetText(MPOWA_SLIDER_TRANSLATEY.." - "..self.SAVE[self.CurEdit].translateoffsety)
		MPowa_ConfigFrame_Container_5_Slider_FadeAlpha:SetValue(tnbr(self.SAVE[self.CurEdit].fadealpha))
		MPowa_ConfigFrame_Container_5_Slider_FadeAlphaText:SetText(MPOWA_SLIDER_FADEALPHA.." - "..self.SAVE[self.CurEdit].fadealpha)
		MPowa_ConfigFrame_Container_5_Slider_ScaleFactor:SetValue(tnbr(self.SAVE[self.CurEdit].scalefactor))
		MPowa_ConfigFrame_Container_5_Slider_ScaleFactorText:SetText(MPOWA_SLIDER_SCALEFACTOR.." - "..self.SAVE[self.CurEdit].scalefactor)
		
		MPowa_ConfigFrame_Container_5_FadeIn:SetChecked(self.SAVE[self.CurEdit].fadein)
		MPowa_ConfigFrame_Container_5_GrowIn:SetChecked(self.SAVE[self.CurEdit].growin)
		MPowa_ConfigFrame_Container_5_RotateIn:SetChecked(self.SAVE[self.CurEdit].rotateanimin)
		MPowa_ConfigFrame_Container_5_SizeIn:SetChecked(self.SAVE[self.CurEdit].sizeanim)
		MPowa_ConfigFrame_Container_5_EscapeIn:SetChecked(self.SAVE[self.CurEdit].escapeanimin)
		MPowa_ConfigFrame_Container_5_BatmanIn:SetChecked(self.SAVE[self.CurEdit].batmananimin)
		MPowa_ConfigFrame_Container_5_FadeOut:SetChecked(self.SAVE[self.CurEdit].fadeout)
		MPowa_ConfigFrame_Container_5_GrowOut:SetChecked(self.SAVE[self.CurEdit].growout)
		MPowa_ConfigFrame_Container_5_RotateOut:SetChecked(self.SAVE[self.CurEdit].rotateanimout)
		MPowa_ConfigFrame_Container_5_Shrink:SetChecked(self.SAVE[self.CurEdit].shrinkanim)
		MPowa_ConfigFrame_Container_5_EscapeOut:SetChecked(self.SAVE[self.CurEdit].escapeanimout)
		MPowa_ConfigFrame_Container_5_BatmanOut:SetChecked(self.SAVE[self.CurEdit].batmananimout)
		MPowa_ConfigFrame_Container_5_Translate:SetChecked(self.SAVE[self.CurEdit].translateanim)
		-- ANIM END
		
		MPowa_ConfigFrame_Container_6_IsDynamicGroup:SetChecked(self.SAVE[self.CurEdit].isdynamicgroup)
		MPowa_ConfigFrame_Container_6_Sorted:SetChecked(self.SAVE[self.CurEdit].dynamicsorted)
		MPowa_ConfigFrame_Container_6_TrunToCenter:SetChecked(self.SAVE[self.CurEdit].dynamiccenter)
		MPowa_ConfigFrame_Container_6_Editbox_GroupNumber:SetText(""..(self.SAVE[self.CurEdit].groupnumber or ""))
		MPowa_ConfigFrame_Container_6_Slider_Orientation:SetValue(tnbr(self.SAVE[self.CurEdit].dynamicorientation))
		MPowa_ConfigFrame_Container_6_Slider_OrientationText:SetText(MPOWA_SLIDER_DYNAMICORIENTATION..MPowa_ConfigFrame_Container_6_Slider_Orientation.valuetext[tnbr(self.SAVE[self.CurEdit].dynamicorientation)])
		MPowa_ConfigFrame_Container_6_Slider_Spacing:SetValue(tnbr(self.SAVE[self.CurEdit].dynamicspacing))
		MPowa_ConfigFrame_Container_6_Slider_SpacingText:SetText(MPOWA_SLIDER_SPACING..tnbr(self.SAVE[self.CurEdit].dynamicspacing))
		
		MPowa_ConfigFrame_Container_1_Slider_BlendMode:SetValue(tnbr(self.SAVE[self.CurEdit].blendmode))
		MPowa_ConfigFrame_Container_1_Slider_BlendModeText:SetText(MPOWA_SLIDER_BLENDMODE..MPowa_ConfigFrame_Container_1_Slider_BlendMode.valuetext[tnbr(self.SAVE[self.CurEdit].blendmode)])
		MPowa_ConfigFrame_Container_1_Icon_Texture:SetBlendMode(MPowa_ConfigFrame_Container_1_Slider_BlendMode.valuetext[tnbr(self.SAVE[self.CurEdit].blendmode)])

		MPowa_ConfigFrame_Container_2_2_Slider_Font:SetValue(tnbr(self.SAVE[self.CurEdit].timerfont))
		MPowa_ConfigFrame_Container_2_2_Slider_FontText:SetText(MPOWA_SLIDER_FONT..MPowa_ConfigFrame_Container_2_2_Slider_Font.valuetext[tnbr(self.SAVE[self.CurEdit].timerfont)])
		MPowa_ConfigFrame_Container_2_2_Slider_FontSize:SetValue(tnbr(self.SAVE[self.CurEdit].timerfontsize))
		MPowa_ConfigFrame_Container_2_2_Slider_FontSizeText:SetText(MPOWA_SLIDER_FONTSIZE..tnbr(self.SAVE[self.CurEdit].timerfontsize))
		
		if self.SAVE[self.CurEdit].enemytarget or self.SAVE[self.CurEdit].friendlytarget then
			MPowa_ConfigFrame_Container_1_2_Editbox_DebuffDuration:Show()
		else
			MPowa_ConfigFrame_Container_1_2_Editbox_DebuffDuration:Hide()
		end
		if self.SAVE[self.CurEdit].flashanim then
			MPowa_ConfigFrame_Container_2_2_Editbox_FlashAnim:Show()
		else
			MPowa_ConfigFrame_Container_2_2_Editbox_FlashAnim:Hide()
		end
		if self.SAVE[self.CurEdit]["raidgroupmember"] then
			MPowa_ConfigFrame_Container_1_2_Editbox_Player:Show()
		else
			MPowa_ConfigFrame_Container_1_2_Editbox_Player:Hide()
		end
		if self.SAVE[self.CurEdit]["secsleft"] then
			MPowa_ConfigFrame_Container_1_2_Editbox_SECLEFT:Show()
		else
			MPowa_ConfigFrame_Container_1_2_Editbox_SECLEFT:Hide()
		end
		MPowa_ConfigFrame_Container_1_2_Checkbutton_SecondSpecifier:SetChecked(self.SAVE[self.CurEdit].secondspecifier)
		MPowa_ConfigFrame_Container_1_2_Editbox_SecondSpecifier:SetText(self.SAVE[self.CurEdit].secondspecifiertext)
		if self.SAVE[MPOWA.CurEdit]["secondspecifier"] then
			MPowa_ConfigFrame_Container_1_2_Editbox:SetWidth(135)
			MPowa_ConfigFrame_Container_1_2_Editbox:ClearAllPoints()
			MPowa_ConfigFrame_Container_1_2_Editbox:SetPoint("TOP", MPowa_ConfigFrame_Container_1_2, "TOP", -67.5, -20)
			MPowa_ConfigFrame_Container_1_2_Editbox_SecondSpecifier:Show()
		else
			MPowa_ConfigFrame_Container_1_2_Editbox:SetWidth(270)
			MPowa_ConfigFrame_Container_1_2_Editbox:ClearAllPoints()
			MPowa_ConfigFrame_Container_1_2_Editbox:SetPoint("TOP", MPowa_ConfigFrame_Container_1_2, "TOP", 0, -20)
			MPowa_ConfigFrame_Container_1_2_Editbox_SecondSpecifier:Hide()
		end

		MPowa_ConfigFrame_Container_1_Editbox_PosX:SetText(self.SAVE[self.CurEdit].x)
		MPowa_ConfigFrame_Container_1_Editbox_PosY:SetText(self.SAVE[self.CurEdit].y)

		MPOWA:TernarySetState(MPowa_ConfigFrame_Container_1_2_Checkbutton_Alive, self.SAVE[self.CurEdit].alive)
		MPOWA:TernarySetState(MPowa_ConfigFrame_Container_1_2_Checkbutton_Mounted, self.SAVE[self.CurEdit].mounted)
		MPOWA:TernarySetState(MPowa_ConfigFrame_Container_1_2_Checkbutton_InCombat, self.SAVE[self.CurEdit].incombat)
		MPOWA:TernarySetState(MPowa_ConfigFrame_Container_1_2_Checkbutton_InParty, self.SAVE[self.CurEdit].inparty)
		MPOWA:TernarySetState(MPowa_ConfigFrame_Container_1_2_Checkbutton_InRaid, self.SAVE[self.CurEdit].inraid)
		MPOWA:TernarySetState(MPowa_ConfigFrame_Container_1_2_Checkbutton_InBattleground, self.SAVE[self.CurEdit].inbattleground)
		MPOWA:TernarySetState(MPowa_ConfigFrame_Container_1_2_Checkbutton_InRaidInstance, self.SAVE[self.CurEdit].inraidinstance)
		MPowa_ConfigFrame:Show()
	end
end

function MPOWA:TernarySetState(button, value)
	local label = _G(button:GetName().."Text")
	button:Enable()
	label:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)

	if value==0 then
		button:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
		button:SetChecked(0)
	elseif value==false then
		button:SetCheckedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
		button:SetChecked(1)
	elseif value==true then
		button:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
		button:SetChecked(1)
	end
end

function MPOWA:Ternary_OnClick(obj, var)
	if (self.SAVE[self.CurEdit][var]==0) then
		self.SAVE[self.CurEdit][var] = true -- Ignore => On
	elseif (self.SAVE[self.CurEdit][var]==true) then
		self.SAVE[self.CurEdit][var] = false -- On => Off
	else
		self.SAVE[self.CurEdit][var] = 0 -- Off => Ignore
	end	

	self:TernarySetState(obj, self.SAVE[self.CurEdit][var])
	if self.SAVE[self.CurEdit]["test"] or self.testAll then
		_G("TextureFrame"..self.CurEdit):Hide()
		_G("TextureFrame"..self.CurEdit):Show()
	else
		self:Iterate("player")
		self:Iterate("target")
	end
end

function MPOWA:SliderChange(var, obj, text)
	self.SAVE[self.CurEdit][var] = tnbr(strform("%.2f", obj:GetValue()))
	_G(obj:GetName().."Text"):SetText(text.." "..self.SAVE[self.CurEdit][var])
	self:ApplyConfig(self.CurEdit)
end

function MPOWA:SoundSliderChange(obj, var)
	local oldvar = self.SAVE[self.CurEdit][var]
	self.SAVE[self.CurEdit][var] = obj:GetValue()
	_G(obj:GetName().."Text"):SetText(MPOWA_SLIDER_BEGINSOUND..self.SOUND[self.SAVE[self.CurEdit][var]])
	if self.SAVE[self.CurEdit][var] ~= oldvar then
		if self.SAVE[self.CurEdit][var] < 16 then
			PlaySound(self.SOUND[self.SAVE[self.CurEdit][var]], "master")
		else
			PlaySoundFile("Interface\\AddOns\\ModifiedPowerAuras\\Sounds\\"..self.SOUND[self.SAVE[self.CurEdit][var]], "master", "throttle=false")
		end
	end
end

function MPOWA:Checkbutton(var)
	if self.SAVE[self.CurEdit][var] then
		self.SAVE[self.CurEdit][var] = false
	else
		self.SAVE[self.CurEdit][var] = true
	end
	
	if self.SAVE[self.CurEdit]["test"] or self.testAll then
		_G("TextureFrame"..self.CurEdit):Hide()
		_G("TextureFrame"..self.CurEdit):Show()
	else
		self:Iterate("player")
		self:Iterate("target")
	end
	self:ApplyConfig(self.CurEdit)
end

function MPOWA:Checkbutton_FlashAnim()
	if self.SAVE[self.CurEdit]["flashanim"] then
		self.SAVE[self.CurEdit]["flashanim"] = false
		MPowa_ConfigFrame_Container_2_2_Editbox_FlashAnim:Hide()
		self.frames[self.CurEdit][1].flash = nil
	else
		self.SAVE[self.CurEdit]["flashanim"] = true
		MPowa_ConfigFrame_Container_2_2_Editbox_FlashAnim:Show()
		self:AddAnimFlash(self.CurEdit)
	end
end

function MPOWA:Checkbutton_USEFONTCOLOR()
	if self.SAVE[self.CurEdit].usefontcolor then
		self.SAVE[self.CurEdit].usefontcolor = false
		_G("TextureFrame"..self.CurEdit.."_Timer"):SetTextColor(1,1,1,self.SAVE[self.CurEdit].usefontcolor)
	else
		self.SAVE[self.CurEdit].usefontcolor = true
		_G("TextureFrame"..self.CurEdit.."_Timer"):SetTextColor(self.SAVE[self.CurEdit].fontcolor_r,self.SAVE[self.CurEdit].fontcolor_g,self.SAVE[self.CurEdit].fontcolor_b,self.SAVE[self.CurEdit].usefontcolor)
	end
end

local name = ""
local name_button = ""
function MPOWA:OpenColorPicker(n, m)
	CloseMenus()
	name = n
	name_button = m
	
	button = getglobal(m.."_SwatchBg") -- MPowa_ConfigFrame_Container_2_2_Colorpicker_SwatchBg

	ColorPickerFrame.func = MPOWA.OptionsFrame_SetColor -- button.swatchFunc
	ColorPickerFrame:SetColorRGB(button.r, button.g, button.b)
	ColorPickerFrame.previousValues = {r = button.r, g = button.g, b = button.b, opacity = button.opacity}
	ColorPickerFrame.cancelFunc = MPOWA.OptionsFrame_CancelColor
	
	ColorPickerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	
	ColorPickerFrame:SetMovable()
	ColorPickerFrame:EnableMouse()
	--ColorPickerFrame:SetScript("OnMouseDown", function() ColorPickerFrame:StartMoving() end)
	--ColorPickerFrame:SetScript("OnMouseUp", function() ColorPickerFrame:StopMovingOrSizing() end)
	
	ColorPickerFrame:Show()
end

function MPOWA:OptionsFrame_SetColor()
	local r,g,b = ColorPickerFrame:GetColorRGB()
	local swatch,frame
	swatch = getglobal(name_button.."NormalTexture") --MPowa_ConfigFrame_Container_2_2_ColorpickerNormalTexture
	frame = getglobal(name_button.."_SwatchBg") --MPowa_ConfigFrame_Container_2_2_Colorpicker_SwatchBg
	swatch:SetVertexColor(r,g,b)
	frame.r = r
	frame.g = g
	frame.b = b

	MPOWA.SAVE[MPOWA.CurEdit][name.."_r"] = r
	MPOWA.SAVE[MPOWA.CurEdit][name.."_g"] = g
	MPOWA.SAVE[MPOWA.CurEdit][name.."_b"] = b
	
	if name == "fontcolor" then
		if MPOWA.SAVE[MPOWA.CurEdit].usefontcolor then
			_G("TextureFrame"..MPOWA.CurEdit.."_Timer"):SetTextColor(r,g,b,MPOWA.SAVE[MPOWA.CurEdit].fontalpha)
		else
			_G("TextureFrame"..MPOWA.CurEdit.."_Timer"):SetTextColor(1,1,1,MPOWA.SAVE[MPOWA.CurEdit].fontalpha)
		end
	elseif name == "icon" then
		MPowa_ConfigFrame_Container_1_Icon_Texture:SetVertexColor(r,g,b)
		MPOWA.frames[MPOWA.CurEdit][2]:SetVertexColor(r,g,b)
	end
end

function MPOWA:OptionsFrame_CancelColor()
	local r = ColorPickerFrame.previousValues.r
	local g = ColorPickerFrame.previousValues.g
	local b = ColorPickerFrame.previousValues.b
	local swatch,frame
	swatch = getglobal(name_button.."NormalTexture") --MPowa_ConfigFrame_Container_2_2_ColorpickerNormalTexture
	frame = getglobal(name_button.."_SwatchBg") --MPowa_ConfigFrame_Container_2_2_Colorpicker_SwatchBg
	swatch:SetVertexColor(r,g,b)
	frame.r = r
	frame.g = g
	frame.b = b
	
	if name == "fontcolor" then
		if MPOWA.SAVE[MPOWA.CurEdit].usefontcolor then
			_G("TextureFrame"..MPOWA.CurEdit.."_Timer"):SetTextColor(r,g,b,MPOWA.SAVE[MPOWA.CurEdit].fontalpha)
		else
			_G("TextureFrame"..MPOWA.CurEdit.."_Timer"):SetTextColor(1,1,1,MPOWA.SAVE[MPOWA.CurEdit].fontalpha)
		end
	elseif name == "icon" then
		MPowa_ConfigFrame_Container_1_Icon_Texture:SetVertexColor(r,g,b)
		MPOWA.frames[MPOWA.CurEdit][2]:SetVertexColor(r,g,b)
	end
end

function MPOWA:Editbox_GroupNumber(obj)
	if obj:GetText() then
		self.SAVE[self.CurEdit]["groupnumber"] = tnbr(obj:GetText())
	else
		self.SAVE[self.CurEdit]["groupnumber"] = ""
	end
	MPOWA:ApplyConfig(self.CurEdit)
	self:Iterate("player")
end

function MPOWA:Editbox_Duration(obj)
	if tnbr(obj:GetText()) ~= nil then
		self.SAVE[self.CurEdit]["targetduration"] = tnbr(obj:GetText())
		self:Iterate("target")
	end
end

function MPOWA:Editbox_SECSLEFT(obj)
	if tnbr(obj:GetText()) ~= nil then
		self.SAVE[self.CurEdit]["secsleftdur"] = tnbr(obj:GetText())
		if self.SAVE[self.CurEdit]["test"] or self.testAll then
			_G("TextureFrame"..self.CurEdit):Hide()
			_G("TextureFrame"..self.CurEdit):Show()
		else
			self:Iterate("target")
			self:Iterate("player")
		end
	end
end

function MPOWA:Editbox_ICONPATH(obj)
	if obj:GetText() == "" then
		if self.SAVE[self.CurEdit].texture == "" then
			self.SAVE[self.CurEdit].texture = "Interface\\AddOns\\ModifiedPowerAuras\\images\\dummy.tga"
		end
		obj:SetText(self.SAVE[self.CurEdit].texture)
	end
end

function MPOWA:Editbox_Name(obj)
	local oldname = self.SAVE[self.CurEdit].buffname
	self.SAVE[self.CurEdit].buffname = obj:GetText()
 
	if oldname ~= self.SAVE[self.CurEdit].buffname then
		self.SAVE[self.CurEdit].texture = "Interface\\AddOns\\ModifiedPowerAuras\\images\\dummy.tga"
		MPowa_ConfigFrame_Container_1_Icon_Texture:SetTexture(self.SAVE[self.CurEdit].texture)
		_G("ConfigButton"..self.selected.."_Icon"):SetTexture(self.SAVE[self.CurEdit].texture)
		_G("TextureFrame"..self.CurEdit.."_Icon"):SetTexture(self.SAVE[self.CurEdit].texture)
	end
	
	if not self.auras[self.SAVE[self.CurEdit].buffname] then
		self.auras[self.SAVE[self.CurEdit].buffname] = {}
	end
	if not self:GetTablePosition(self.auras[self.SAVE[self.CurEdit].buffname], self.CurEdit) then
		tinsert(self.auras[self.SAVE[self.CurEdit].buffname], self.CurEdit)
	end
	--self:Print(self.CurEdit)
	
	if self.SAVE[self.CurEdit].test or self.testAll then
		_G("TextureFrame"..self.CurEdit):Hide()
		_G("TextureFrame"..self.CurEdit):Show()
	else
		self:Iterate("player")
		self:Iterate("target")
	end
end

function MPOWA:Editbox_Function(obj)
	if (obj:GetText() ~= nil) then
		local f = string.gsub(obj:GetText(), "\n", "");
		if (f ~= "") then
			self.SAVE[self.CurEdit].funct = f;
		elseif (f == "") then
			self.SAVE[self.CurEdit].funct = nil;
		end
	end
end

function MPOWA:Editbox_SecondSpecifier(obj)
	local oldname = self.SAVE[self.CurEdit].secondspecifiertext
	self.SAVE[self.CurEdit].secondspecifiertext = obj:GetText()

	if oldname ~= self.SAVE[self.CurEdit].secondspecifiertext then
		self.SAVE[self.CurEdit].texture = "Interface\\AddOns\\ModifiedPowerAuras\\images\\dummy.tga"
		MPowa_ConfigFrame_Container_1_Icon_Texture:SetTexture(self.SAVE[self.CurEdit].texture)
		_G("ConfigButton"..self.CurEdit.."_Icon"):SetTexture(self.SAVE[self.CurEdit].texture)
		_G("TextureFrame"..self.CurEdit.."_Icon"):SetTexture(self.SAVE[self.CurEdit].texture)
	end
	
	if self.SAVE[self.CurEdit].test or self.testAll then
		_G("TextureFrame"..self.CurEdit):Hide()
		_G("TextureFrame"..self.CurEdit):Show()
	else
		self:Iterate("player")
		self:Iterate("target")
	end
end

function MPOWA:Editbox_Stacks(obj)
	local oldcon = self.SAVE[self.CurEdit].stacks
	self.SAVE[self.CurEdit].stacks = obj:GetText()
	if oldcon ~= self.SAVE[self.CurEdit].stacks then
		if self.SAVE[self.CurEdit]["test"] or self.testAll then
			_G("TextureFrame"..self.CurEdit):Hide()
			_G("TextureFrame"..self.CurEdit):Show()
		else
			self:Iterate("player")
			self:Iterate("target")
		end
	end
end

function MPOWA:Editbox_CPStacks(obj)
	local oldcon = self.SAVE[self.CurEdit].cpstacks
	self.SAVE[self.CurEdit].cpstacks = obj:GetText()
	if oldcon ~= self.SAVE[self.CurEdit].cpstacks then
		if self.SAVE[self.CurEdit]["test"] or self.testAll then
			_G("TextureFrame"..self.CurEdit):Hide()
			_G("TextureFrame"..self.CurEdit):Show()
		else
			self:Iterate("player")
			self:Iterate("target")
		end
	end
end

function MPOWA:Editbox_FlashAnimStart(obj)
	local oldcon = self.SAVE[self.CurEdit].flashanimstart
	if tnbr(obj:GetText()) ~= nil then
		self.SAVE[self.CurEdit].flashanimstart = tnbr(obj:GetText())
	end
	if oldcon ~= self.SAVE[self.CurEdit].flashanimstart then
		if self.SAVE[self.CurEdit]["test"] or self.testAll then
			_G("TextureFrame"..self.CurEdit):Hide()
			_G("TextureFrame"..self.CurEdit):Show()
		else
			self:Iterate("player")
			self:Iterate("target")
		end
	end
end

function MPOWA:Editbox_Player(obj)
	local oldcon = self.SAVE[self.CurEdit]["rgmname"]
	if obj:GetText() ~= nil and obj:GetText() ~= "" then
		self.SAVE[self.CurEdit]["rgmname"] = obj:GetText()
		self.RaidGroupMembers[self.SAVE[self.CurEdit]["rgmname"]] = true
		self:GetGroup()
	end
end

function MPOWA:TestAll()
	if ConfigButton1 then
		if self.testAll then
			self.testAll = false
			for i=1, self.NumBuffs do
				if self.SAVE[i] and self.SAVE[i]["used"] then
					if not self.active[i] then
						MPOWA:ApplyConfig(i)
						_G("TextureFrame"..i):Hide()
					end
					self.SAVE[i]["test"] = false
				end
			end
		else
			self.testAll = true
			for i=1, self.NumBuffs do
				if self.SAVE[i] and self.SAVE[i]["used"] then
					MPOWA:ApplyConfig(i)
					_G("TextureFrame"..i):Show()
				end
			end
		end
	end
end

function MPOWA:Test()
	if ConfigButton1 then
		local coeff = (self.Page - 1)*49
		local tested = self.selected+coeff
		if self.SAVE[tested].test then
			self.SAVE[tested].test = false
			if not self.active[tested] then
				_G("TextureFrame"..tested):Hide()
			end
		else
			self.SAVE[tested].test = true
			_G("TextureFrame"..tested):Show()
		end
		MPOWA:ApplyConfig(tested)
	end
end

function MPOWA:ProfileSave()
	tinsert(MPOWA_PROFILE, self.SAVE[self.selected])
	self:ScrollFrame_Update()
end

function MPOWA:SaveAllAurasToFile()
	-- 将滚动条中的光环信息保存到文件
	-- MPOWA_PROFILE已经包含了滚动条中显示的所有光环信息
	-- 这里我们直接显示成功消息，因为MPOWA_PROFILE的数据会自动保存到SavedVariables文件中
	
	-- 显示成功消息
	DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00已将配置文件窗口中的所有光环保存到游戏目录：\\WTF\\Account\\[游戏账号]\\SavedVariables文件中！存储的文件名是：ModifiedPowerAuras.lua|r\n|cFF00FFFF注意：这个配置文件是同账号下共享的配置。比如你法师制作的光环也会显示到同账号下的骑士身上。|r")
end

function MPOWA:ProfileRemove()
	if MPOWA_PROFILE[MPOWA_PROFILE_SELECTED] ~= nil then
		tremove(MPOWA_PROFILE, MPOWA_PROFILE_SELECTED)
		MPOWA_PROFILE_SELECTED = 1
		self:ScrollFrame_Update()
	end
end

function MPOWA:Import()
	if MPOWA_PROFILE[MPOWA_PROFILE_SELECTED] ~= nil then
		if self.NumBuffs < 490 then
			-- 增加计数器
			self.NumBuffs = self.NumBuffs + 1
			local actualLength = self:GetTableLength(self.SAVE) + 1
			local coeff = (self.Page - 1) * 49
			local bool = false
			local p = actualLength - coeff
			
			if (p <= 0) then
				p = actualLength
				bool = true
			end
			
			-- 直接使用导入的配置，添加新的光环配置而不是替换
			-- 移除tremove操作，确保总是添加新光环而不是覆盖
			tinsert(self.SAVE, actualLength, table.copy(MPOWA_PROFILE[MPOWA_PROFILE_SELECTED]))
			self.SAVE[actualLength]["used"] = true
			
			-- 创建必要的UI元素
			self:CreateIcon(self.NumBuffs, actualLength)
			self:ApplyConfig(actualLength)
			self:CreateButton(actualLength)
			
			-- 更新选择状态
			self:DeselectAll()
			if not bool and actualLength >= coeff + 1 and actualLength <= coeff + 49 then
				p = actualLength - coeff
				_G("ConfigButton"..p.."_Border"):Show()
				_G("ConfigButton"..p):Show()
			end
			self.selected = actualLength
			
			-- 更新auras表和NeedUpdate表
			local currentAura = self.SAVE[actualLength]
			if not self.auras[currentAura["buffname"]] then
				self.auras[currentAura["buffname"]] = {}
			end
			tinsert(self.auras[currentAura["buffname"]], actualLength)
			
			if (currentAura["inverse"] or currentAura["cooldown"]) and currentAura["buffname"] ~= "unitpower" then
				self.NeedUpdate[actualLength] = true
			end
			
			-- 重新定位UI元素以显示新添加的光环
			self:Reposition()
			
			-- 保存更改
			MPOWA_SAVE = table.copy(self.SAVE, true)
		end
	end
end
	

function MPOWA:GetTableLength(T)
	local count = 0
	for _ in T do 
		count = count + 1 
	end 
	return count
end

function MPOWA:ScrollFrame_Update()
	local line -- 1 through 5 of our window to scroll
	local lineplusoffset -- an index into our data calculated from the scroll offset
	local FRAME = MPowa_ProfileFrame_ScrollFrame
	FauxScrollFrame_Update(FRAME,MPOWA:GetTableLength(MPOWA_PROFILE),7,40)
	for line=1,7 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(FRAME)
		if MPOWA_PROFILE[lineplusoffset] ~= nil then
			_G("MPowa_ProfileFrame_ScrollFrame_Button"..line.."_Name"):SetText(MPOWA_PROFILE[lineplusoffset].buffname)
			_G("MPowa_ProfileFrame_ScrollFrame_Button"..line.."_Icon"):SetTexture(MPOWA_PROFILE[lineplusoffset].texture)
			_G("MPowa_ProfileFrame_ScrollFrame_Button"..line).line = lineplusoffset
			_G("MPowa_ProfileFrame_ScrollFrame_Button"..line):Show()
			
			-- 设置边框显示状态
			if MPOWA_PROFILE_SELECTED == lineplusoffset then
				_G("MPowa_ProfileFrame_ScrollFrame_Button"..line.."_BG"):SetAlpha(0.5)
				_G("MPowa_ProfileFrame_ScrollFrame_Button"..line.."_Border"):Show()
			else
				_G("MPowa_ProfileFrame_ScrollFrame_Button"..line.."_BG"):SetAlpha(1)
				_G("MPowa_ProfileFrame_ScrollFrame_Button"..line.."_Border"):Hide()
			end
		else
			_G("MPowa_ProfileFrame_ScrollFrame_Button"..line):Hide()
		end
	end
end

function MPOWA:SelectIcon(obj)
	SELECTEDICON = _G(obj:GetName().."_Icon"):GetTexture()
	MPowa_IconFrame_Editbox:SetText(SELECTEDICON)
	for i=0,110 do
		if _G("MPowa_IconFrame_ButtonContainer_Button"..i.."_Border") then
			_G("MPowa_IconFrame_ButtonContainer_Button"..i.."_Border"):Hide()
		end
	end
	_G(obj:GetName().."_Border"):Show()
end

function MPOWA:IconFrameOkay()
	if (MPowa_IconFrame_Editbox:GetText()~="" and MPowa_IconFrame_Editbox:GetText()~=SELECTEDICON) then
		SELECTEDICON = MPowa_IconFrame_Editbox:GetText()
	end
	MPowa_ConfigFrame_Container_1_Icon_Texture:SetTexture(SELECTEDICON)
	_G("ConfigButton"..self.selected.."_Icon"):SetTexture(SELECTEDICON)
	_G("TextureFrame"..self.CurEdit.."_Icon"):SetTexture(SELECTEDICON)
	self.SAVE[self.CurEdit].texture = SELECTEDICON
	MPowa_IconFrame:Hide()
end
