pfUI.addonskinner:RegisterSkin("Worldmap", function()
 
  pfUI.api.SkinButton(pfQuestMines)
  pfUI.api.SkinButton(pfQuestherbs)
  pfUI.api.SkinButton(pfQuestchests)
  pfUI.api.SkinButton(pfQuestrares)
  pfUI.api.SkinButton(pfQuesttaxi)
  pfUI.api.SkinButton(pfQuestfish)
  pfUI.api.SkinButton(pfQuestrepair)
  pfUI.api.SkinButton(pfQuestSerach)
  pfUI.api.SkinButton(pfQuestclean)
  
  --WorldMapTextFont:SetFont(pfUI.font_combat, 150, "THICK")
     
  pfUI.addonskinner:UnregisterSkin("Worldmap")
end)