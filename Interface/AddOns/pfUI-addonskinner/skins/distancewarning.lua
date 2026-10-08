pfUI.addonskinner:RegisterSkin("distancewarning", function()
  -- place main code below
  --pfUI.api.SkinButton(DistanceWarningBar)
  pfUI.api.CreateBackdrop(DistanceWarningBar, nil, nil, .3)

  -- remove from pending list when applied
  pfUI.addonskinner:UnregisterSkin("distancewarning")
end)