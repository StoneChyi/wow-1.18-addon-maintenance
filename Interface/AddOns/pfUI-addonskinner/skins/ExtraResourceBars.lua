pfUI.addonskinner:RegisterSkin("ExtraResourceBars", function()
  -- place main code below
  --pfUI.api.SkinButton(DistanceWarningBar)
  pfUI.api.CreateBackdrop(erb_hp, nil, nil, .5)
  pfUI.api.CreateBackdrop(erb_pp, nil, nil, .5)
  erb_pp_bar:SetWidth(erb_pp:GetWidth() )
  erb_pp_bar:SetHeight(erb_pp:GetHeight())
  -- remove from pending list when applied
  pfUI.addonskinner:UnregisterSkin("ExtraResourceBars")
end)