pfUI.addonskinner:RegisterSkin("KLHThreatMeter", function()
-- title Frame
getglobal("KLHTM_TitleFrame".."LongTitle".."Text"):SetFont(pfUI.font_default, 10, "OUTLINE")
getglobal("KLHTM_TitleFrame".."ShortTitle".."Text"):SetFont(pfUI.font_default, 10, "OUTLINE")

-- raidframe
getglobal("KLHTM_RaidFrame".."HeaderName".."Text"):SetFont(pfUI.font_default, 10, "OUTLINE")
getglobal("KLHTM_RaidFrame".."HeaderThreat".."Text"):SetFont(pfUI.font_default, 10, "OUTLINE")
getglobal("KLHTM_RaidFrame".."HeaderPercentThreat".."Text"):SetFont(pfUI.font_default, 10, "OUTLINE")

for i=1,20 do
	getglobal("KLHTM_RaidFrame".."Row"..i.."Name".."Text"):SetFont(pfUI.font_default, 12, "OUTLINE")
	getglobal("KLHTM_RaidFrame".."Row"..i.."Threat".."Text"):SetFont(pfUI.font_default, 12, "OUTLINE")
	getglobal("KLHTM_RaidFrame".."Row"..i.."PercentThreat".."Text"):SetFont(pfUI.font_default, 12, "OUTLINE")
	getglobal("KLHTM_RaidFrame".."Row"..i.."Bar"):SetTexture("Interface\\AddOns\\KLHThreatMeter\\Images\\bar")
end

getglobal("KLHTM_RaidFrame".."Bottom".."ThreatDefecit".."Text"):SetFont(pfUI.font_default, 12, "OUTLINE")
getglobal("KLHTM_RaidFrame".."Bottom".."MasterTarget".."Text"):SetFont(pfUI.font_default, 12, "OUTLINE")

--self frame
getglobal("KLHTM_SelfFrame".."HeaderName".."Text"):SetFont(pfUI.font_default, 10, "OUTLINE")
getglobal("KLHTM_SelfFrame".."HeaderHits".."Text"):SetFont(pfUI.font_default, 10, "OUTLINE")
getglobal("KLHTM_SelfFrame".."HeaderRage".."Text"):SetFont(pfUI.font_default, 10, "OUTLINE")
getglobal("KLHTM_SelfFrame".."HeaderDamage".."Text"):SetFont(pfUI.font_default, 10, "OUTLINE")
getglobal("KLHTM_SelfFrame".."HeaderThreat".."Text"):SetFont(pfUI.font_default, 10, "OUTLINE")
getglobal("KLHTM_SelfFrame".."HeaderPercentThreat".."Text"):SetFont(pfUI.font_default, 10, "OUTLINE")

for i=1,15 do
	getglobal("KLHTM_SelfFrame".."Row"..i.."Name".."Text"):SetFont(pfUI.font_default, 12, "OUTLINE")
	getglobal("KLHTM_SelfFrame".."Row"..i.."Hits".."Text"):SetFont(pfUI.font_default, 12, "OUTLINE")
	getglobal("KLHTM_SelfFrame".."Row"..i.."Rage".."Text"):SetFont(pfUI.font_default, 12, "OUTLINE")
	getglobal("KLHTM_SelfFrame".."Row"..i.."Damage".."Text"):SetFont(pfUI.font_default, 12, "OUTLINE")
	getglobal("KLHTM_SelfFrame".."Row"..i.."Threat".."Text"):SetFont(pfUI.font_default, 12, "OUTLINE")
	getglobal("KLHTM_SelfFrame".."Row"..i.."PercentThreat".."Text"):SetFont(pfUI.font_default, 12, "OUTLINE")
	getglobal("KLHTM_SelfFrame".."Row"..i.."Bar"):SetTexture("Interface\\AddOns\\KLHThreatMeter\\Images\\bar")
end

getglobal("KLHTM_SelfFrame".."Bottom".."Name".."Text"):SetFont(pfUI.font_default, 12, "OUTLINE")
getglobal("KLHTM_SelfFrame".."Bottom".."Hits".."Text"):SetFont(pfUI.font_default, 12, "OUTLINE")
getglobal("KLHTM_SelfFrame".."Bottom".."Rage".."Text"):SetFont(pfUI.font_default, 12, "OUTLINE")
getglobal("KLHTM_SelfFrame".."Bottom".."Damage".."Text"):SetFont(pfUI.font_default, 12, "OUTLINE")
getglobal("KLHTM_SelfFrame".."Bottom".."Threat".."Text"):SetFont(pfUI.font_default, 12, "OUTLINE")
getglobal("KLHTM_SelfFrame".."Bottom".."PercentThreat".."Text"):SetFont(pfUI.font_default, 12, "OUTLINE")

pfUI.api.StripTextures(KLHTM_OptionsFrame)
pfUI.api.CreateBackdrop(KLHTM_OptionsFrame,nil, nil, .75)
pfUI.api.StripTextures(KLHTM_OptionsFrameTitle)
pfUI.api.CreateBackdrop(KLHTM_OptionsFrameTitle,nil, nil, .9)

pfUI.api.SkinButton(KLHTM_OptionsFrameControlsGeneral)
pfUI.api.SkinButton(KLHTM_OptionsFrameControlsSelf)
pfUI.api.SkinButton(KLHTM_OptionsFrameControlsRaid)
pfUI.api.SkinButton(KLHTM_OptionsFrameControlsClose)
--pfUI.api.StripTextures(KLHTM_TitleFrame)


pfUI.api.SkinCheckbox(KLHTM_OptionsFrameGeneralMinimisedPin)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameGeneralMinimisedOptions)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameGeneralMinimisedView)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameGeneralMinimisedMasterTarget)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameGeneralMinimisedClearThreat)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameGeneralMaximisedPin)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameGeneralMaximisedView)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameGeneralMaximisedMasterTarget)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameGeneralMaximisedClearThreat)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameSelfColumnHits)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameSelfColumnRage)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameSelfColumnDamage)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameSelfColumnThreat)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameRaidColumnSunder)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameSelfColumnThreatPercent)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameSelfHideZero)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameSelfAbbreviate)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameSelfMinimisedThreat)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameRaidColumnThreat)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameRaidColumnThreatPercent)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameRaidMinimisedRank)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameRaidMinimisedThreatPercent)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameRaidMinimisedDeficit)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameRaidHideZero)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameRaidResize)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameRaidAggroGain)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameRaidAbbreviate)
pfUI.api.SkinCheckbox(KLHTM_OptionsFrameRaidHideBottom)

pfUI.api.SkinSlider(KLHTM_OptionsFrameGeneralScale)
pfUI.api.SkinSlider(KLHTM_OptionsFrameRaidRows)

 
  pfUI.addonskinner:UnregisterSkin("KLHThreatMeter")
end)


