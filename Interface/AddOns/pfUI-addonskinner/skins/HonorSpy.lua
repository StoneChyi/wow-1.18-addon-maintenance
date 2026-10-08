pfUI.addonskinner:RegisterSkin("HonorSpy", function()
  -- place main code below
pfUI.api.StripTextures(Tablet20DetachedFrame1)
pfUI.api.CreateBackdrop(Tablet20DetachedFrame1,nil, nil, .75)

  -- remove from pending list when applied
  pfUI.addonskinner:UnregisterSkin("HonorSpy")
end)